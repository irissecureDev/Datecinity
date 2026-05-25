import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datecinity/models/discovery_state.dart';
import 'package:datecinity/screens/chat_screen.dart';
import 'package:datecinity/services/spark_service.dart';
import 'package:datecinity/services/suggestions_service.dart';
import 'package:datecinity/widgets/discovery_animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DiscoveryFlowWidget extends StatefulWidget {
  const DiscoveryFlowWidget({super.key});

  @override
  State<DiscoveryFlowWidget> createState() => _DiscoveryFlowWidgetState();
}

class _DiscoveryFlowWidgetState extends State<DiscoveryFlowWidget>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final SuggestionsService _suggestionsService = SuggestionsService();
  final SparkService _sparkService = SparkService();

  DiscoveryState _state = const DiscoveryState(
    flow: DiscoveryStep.proximityDetected,
  );

  Timer? _countdownTimer;
  Timer? _stateTimer;
  StreamSubscription<Map<String, dynamic>?>? _sparkWatcher;

  late AnimationController _pulseController;
  late AnimationController _backgroundController;
  late AnimationController _bounceController;

  DateTime? _sparkExpiresAt;
  bool _isSubmittingInterest = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _backgroundController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat();

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 650),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelAllTimersAndStreams();
    _pulseController.dispose();
    _backgroundController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncSparkStateAfterResume();
    }
  }

  void _cancelAllTimersAndStreams() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _stateTimer?.cancel();
    _stateTimer = null;
    _sparkWatcher?.cancel();
    _sparkWatcher = null;
  }

  Duration _remainingFromExpiry() {
    final expiry = _sparkExpiresAt;
    if (expiry == null) {
      return _state.remainingTime ?? DiscoveryConfig.countdownDuration;
    }

    final remaining = expiry.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  void _onTapSearchButton() {
    HapticFeedback.mediumImpact();
    _startDiscoveryFlow();
  }

  Future<void> _startDiscoveryFlow() async {
    _cancelAllTimersAndStreams();

    _updateState(
      _state.copyWith(
        flow: DiscoveryStep.sparkForming,
        isAnimating: true,
        errorMessage: null,
        infoMessage: null,
      ),
    );

    await _sparkService.trackStateEvent(
      sparkId: _state.sparkId ?? 'n/a',
      eventName: 'discover_started',
    );

    await _searchForBestMatchAndCreateSpark();
  }

  Future<void> _searchForBestMatchAndCreateSpark() async {
    try {
      await _suggestionsService.detectNewProximityProfiles(
        maxDistanceKm: DiscoveryConfig.maxProximityDistance,
        minCompatibility: DiscoveryConfig.minCompatibilityForMatch,
      );

      final profiles =
          _suggestionsService
              .getActiveProximityProfiles()
              .where(
                (profile) =>
                    !profile.isExpired &&
                    profile.distance <= DiscoveryConfig.maxProximityDistance &&
                    profile.compatibility >=
                        DiscoveryConfig.minCompatibilityForMatch,
              )
              .toList()
            ..sort((a, b) {
              final byCompatibility = b.compatibility.compareTo(
                a.compatibility,
              );
              return byCompatibility != 0
                  ? byCompatibility
                  : a.distance.compareTo(b.distance);
            });

      if (profiles.isEmpty) {
        _showErrorAndAutoReset('No compatible profile nearby right now.');
        return;
      }

      final selectedProfile = profiles.first;
      final spark = await _sparkService.createSpark(
        targetUser: selectedProfile.user,
        distance: selectedProfile.distance,
        compatibility: selectedProfile.compatibility,
      );

      if (spark == null) {
        _showErrorAndAutoReset('Unable to create spark session. Please retry.');
        return;
      }

      await _sparkService.revealSpark(spark.sparkId);
      await _sparkService.trackStateEvent(
        sparkId: spark.sparkId,
        eventName: 'profile_revealed',
      );

      _sparkExpiresAt = spark.expiresAt;

      _updateState(
        _state.copyWith(
          flow: DiscoveryStep.matchFound,
          targetProfile: selectedProfile,
          sparkId: spark.sparkId,
          remainingTime: spark.timeRemaining,
          isAnimating: true,
          errorMessage: null,
          infoMessage: null,
        ),
      );
    } on FirebaseException catch (e) {
      debugPrint('❌ Discovery Firebase error: ${e.code} ${e.message}');
      if (e.code == 'unavailable' || e.code == 'network-request-failed') {
        _showErrorAndAutoReset(
          'You appear to be offline. Please check your connection and retry.',
        );
        return;
      }
      _showErrorAndAutoReset(
        'Connection issue while searching. Please try again.',
      );
    } catch (e) {
      debugPrint('❌ Discovery flow error: $e');
      _showErrorAndAutoReset(
        'Connection issue while searching. Please try again.',
      );
    }
  }

  void _onRevealContinue() {
    final sparkId = _state.sparkId;
    if (sparkId != null) {
      unawaited(
        _sparkService.trackStateEvent(
          sparkId: sparkId,
          eventName: 'user_interested_prompt',
        ),
      );
    }

    final remaining = _remainingFromExpiry();
    _updateState(
      _state.copyWith(
        flow: DiscoveryStep.timerCountdown,
        remainingTime: remaining,
        isAnimating: true,
      ),
    );

    _startCountdownTimer();
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final next = _remainingFromExpiry();

      if (next <= Duration.zero) {
        timer.cancel();
        final sparkId = _state.sparkId;
        if (sparkId != null) {
          await _sparkService.checkAndHandleTimeout(sparkId);
          await _sparkService.trackStateEvent(
            sparkId: sparkId,
            eventName: 'user_timeout',
          );
        }
        _showInfoAndReset('Time out.');
        return;
      }

      _updateState(_state.copyWith(remainingTime: next));
    });
  }

  Future<void> _onSwipeToAdd() async {
    if (_isSubmittingInterest) return;
    if (_state.sparkId == null) {
      _showErrorAndAutoReset('Spark session is missing. Please try again.');
      return;
    }

    HapticFeedback.heavyImpact();
    _isSubmittingInterest = true;

    final sparkId = _state.sparkId!;
    final result = await _sparkService.submitInterest(sparkId);

    _isSubmittingInterest = false;

    switch (result) {
      case SparkActionResult.mutualMatch:
        await _sparkService.trackStateEvent(
          sparkId: sparkId,
          eventName: 'mutual_match_screen',
        );
        _countdownTimer?.cancel();
        _updateState(
          _state.copyWith(flow: DiscoveryStep.flameSuccess, isAnimating: true),
        );
        break;
      case SparkActionResult.waitingOther:
        await _sparkService.trackStateEvent(
          sparkId: sparkId,
          eventName: 'waiting_other_screen',
        );

        _updateState(
          _state.copyWith(
            flow: DiscoveryStep.swipeToAdd,
            isAnimating: true,
            infoMessage: 'Waiting for the other user response...',
          ),
        );
        _watchSparkState(sparkId);
        break;
      case SparkActionResult.declined:
        _showInfoAndReset('The other user declined.');
        break;
      case SparkActionResult.timeout:
        _showInfoAndReset('Time out.');
        break;
      case SparkActionResult.failed:
        _showErrorAndAutoReset('Could not submit your response.');
        break;
    }
  }

  void _watchSparkState(String sparkId) {
    _sparkWatcher?.cancel();
    _sparkWatcher = _sparkService.watchSparkDocument(sparkId).listen((data) {
      if (!mounted || data == null) return;

      final expiresAt = data['expires_at'] as Timestamp?;
      if (expiresAt != null) {
        _sparkExpiresAt = expiresAt.toDate();
        final remaining = _remainingFromExpiry();
        if (remaining > Duration.zero &&
            (_state.flow == DiscoveryStep.timerCountdown ||
                _state.flow == DiscoveryStep.swipeToAdd)) {
          _updateState(_state.copyWith(remainingTime: remaining));
        }
      }

      final flowState = (data['flow_state'] as String?) ?? '';
      final status = (data['status'] as String?) ?? '';

      if (flowState == SparkService.STATE_MUTUAL_MATCH || status == 'matched') {
        _updateState(
          _state.copyWith(flow: DiscoveryStep.flameSuccess, isAnimating: true),
        );
        return;
      }

      if (flowState == SparkService.STATE_DECLINED || status == 'declined') {
        _showInfoAndReset('The other user declined.');
        return;
      }

      if (flowState == SparkService.STATE_TIMEOUT || status == 'expired') {
        _showInfoAndReset('Time out.');
      }
    });
  }

  Future<void> _syncSparkStateAfterResume() async {
    final sparkId = _state.sparkId;
    if (sparkId == null) return;

    debugPrint('🔄 Discovery resumed, syncing spark state for $sparkId');

    await _sparkService.checkAndHandleTimeout(sparkId);
    final data = await _sparkService.getSparkDocument(sparkId);
    if (data == null || !mounted) return;

    final expiresAt = data['expires_at'] as Timestamp?;
    if (expiresAt != null) {
      _sparkExpiresAt = expiresAt.toDate();
      final remaining = _remainingFromExpiry();
      _updateState(_state.copyWith(remainingTime: remaining));

      if ((_state.flow == DiscoveryStep.timerCountdown ||
              _state.flow == DiscoveryStep.swipeToAdd) &&
          _countdownTimer == null &&
          remaining > Duration.zero) {
        _startCountdownTimer();
      }
    }

    final flowState = (data['flow_state'] as String?) ?? '';
    final status = (data['status'] as String?) ?? '';

    if (flowState == SparkService.STATE_MUTUAL_MATCH || status == 'matched') {
      _updateState(
        _state.copyWith(flow: DiscoveryStep.flameSuccess, isAnimating: true),
      );
      return;
    }

    if (flowState == SparkService.STATE_DECLINED || status == 'declined') {
      _showInfoAndReset('The other user declined.');
      return;
    }

    if (flowState == SparkService.STATE_TIMEOUT || status == 'expired') {
      _showInfoAndReset('Time out.');
    }
  }

  void _showErrorAndAutoReset(String message) {
    _updateState(
      _state.copyWith(
        flow: DiscoveryStep.error,
        errorMessage: message,
        isAnimating: false,
      ),
    );

    _stateTimer?.cancel();
    _stateTimer = Timer(const Duration(seconds: 2), _resetToStartScreen);
  }

  void _showInfoAndReset(String message) {
    _cancelAllTimersAndStreams();
    _updateState(
      _state.copyWith(
        flow: DiscoveryStep.error,
        errorMessage: message,
        isAnimating: false,
      ),
    );

    _stateTimer = Timer(const Duration(seconds: 2), _resetToStartScreen);
  }

  void _resetToStartScreen() {
    _cancelAllTimersAndStreams();
    _sparkExpiresAt = null;
    _isSubmittingInterest = false;
    _updateState(
      const DiscoveryState(
        flow: DiscoveryStep.proximityDetected,
        isAnimating: false,
      ),
    );
  }

  void _onClosePressed() {
    final sparkId = _state.sparkId;
    if (sparkId != null) {
      unawaited(
        _sparkService.trackStateEvent(
          sparkId: sparkId,
          eventName: 'flow_closed',
        ),
      );
    }
    _resetToStartScreen();
  }

  void _updateState(DiscoveryState state) {
    if (!mounted) return;
    setState(() => _state = state);
  }

  void _onStartChat() {
    final profile = _state.targetProfile;
    if (profile == null) {
      _showErrorAndAutoReset('Chat is unavailable right now.');
      return;
    }

    final sparkId = _state.sparkId;
    if (sparkId != null) {
      unawaited(
        _sparkService.trackStateEvent(
          sparkId: sparkId,
          eventName: 'start_chat_clicked',
        ),
      );
    }

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ChatScreen(user: profile.user)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0333),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2A0A4B), Color(0xFF1A0333), Color(0xFF2A0A4B)],
          ),
        ),
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: _buildCurrentScreen(),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_state.flow) {
      case DiscoveryStep.proximityDetected:
      case DiscoveryStep.idle:
        return _buildScreenShell(
          key: const ValueKey('screen1'),
          child: _buildScreenOne(),
        );
      case DiscoveryStep.sparkForming:
      case DiscoveryStep.proximitySearch:
        return _buildScreenShell(
          key: const ValueKey('screen2'),
          child: _buildScreenTwo(),
        );
      case DiscoveryStep.matchFound:
      case DiscoveryStep.profileView:
        return _buildScreenShell(
          key: const ValueKey('screen3'),
          child: _buildScreenThree(),
        );
      case DiscoveryStep.timerCountdown:
        return _buildScreenShell(
          key: const ValueKey('screen4'),
          child: _buildScreenFour(),
        );
      case DiscoveryStep.swipeToAdd:
        return _buildScreenShell(
          key: const ValueKey('screen5'),
          child: _buildScreenFive(),
        );
      case DiscoveryStep.flameSuccess:
        return _buildScreenShell(
          key: const ValueKey('screen6'),
          child: _buildScreenSix(),
        );
      case DiscoveryStep.error:
        return _buildScreenShell(
          key: const ValueKey('screenError'),
          child: _buildErrorScreen(),
        );
    }
  }

  Widget _buildScreenShell({required Widget child, required Key key}) {
    final showCloseButton =
        _state.flow != DiscoveryStep.proximityDetected &&
        _state.flow != DiscoveryStep.idle;

    return SizedBox(
      key: key,
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          _buildFloatingParticles(),
          Positioned.fill(child: child),
          if (showCloseButton)
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: _onClosePressed,
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                tooltip: 'Close',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScreenOne() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Proximity\nSpark',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFF4DFC0),
                fontSize: 56,
                fontWeight: FontWeight.w500,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Finding someone nearby...',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 34),
            GestureDetector(
              onTap: _onTapSearchButton,
              child: _buildCentralPin(animate: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScreenTwo() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SparkleAnimation(
              child: Icon(
                Icons.all_inclusive,
                size: 92,
                color: Color(0xFFFFB347),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'A Spark\nis forming...',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 44,
                fontWeight: FontWeight.w600,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.8,
                color: Color(0xFFFFB347),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScreenThree() {
    final profile = _state.targetProfile;
    final user = profile?.user;
    final firstName = user == null
        ? 'Nearby Match'
        : user.userFullname.split(' ').first;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Here’s who you\nmatched with",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.w600,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 24),
            AnimatedBuilder(
              animation: _bounceController,
              builder: (context, _) {
                final scale = 0.94 + (sin(_bounceController.value * pi) * 0.06);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 210,
                    height: 210,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFF8C42),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF8C42).withOpacity(0.45),
                          blurRadius: 25,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: user != null && user.userProfilePhoto.isNotEmpty
                          ? Image.network(
                              user.userProfilePhoto,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _matchAvatarFallback(),
                            )
                          : _matchAvatarFallback(),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            Text(
              firstName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 28),
            _buildPrimaryButton(
              text: 'I\'m interested',
              onPressed: _onRevealContinue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScreenFour() {
    final remaining = _state.remainingTime ?? DiscoveryConfig.countdownDuration;
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'You have 10 minutes to confirm your interest.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 30),
            GestureDetector(
              onPanUpdate: (details) {
                if (details.delta.dy < -8) {
                  _onSwipeToAdd();
                }
              },
              child: _buildPrimaryButton(
                text: _isSubmittingInterest ? 'Sending...' : 'SWIPE TO ADD',
                onPressed: _isSubmittingInterest ? null : _onSwipeToAdd,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScreenFive() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 42,
              height: 42,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Color(0xFFFFB347),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _state.infoMessage ?? 'Waiting for the other user response...',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
            const SizedBox(height: 12),
            Text(
              'Time left: ${(_state.remainingTime ?? Duration.zero).inMinutes.toString().padLeft(2, '0')}:${((_state.remainingTime ?? Duration.zero).inSeconds % 60).toString().padLeft(2, '0')}',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 18),
            TextButton(
              onPressed: _syncSparkStateAfterResume,
              child: const Text(
                'Refresh status',
                style: TextStyle(color: Color(0xFFFFB347), fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScreenSix() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const FlameAnimation(size: 180, baseColor: Color(0xFFFF8C42)),
            const SizedBox(height: 24),
            const Text(
              'Your Spark\nhas become\na Flame',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFF4DFC0),
                fontSize: 44,
                fontWeight: FontWeight.w600,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 28),
            _buildPrimaryButton(text: 'Start Chat', onPressed: _onStartChat),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 72),
            const SizedBox(height: 16),
            Text(
              _state.errorMessage ?? 'Something went wrong.',
              style: const TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _buildPrimaryButton(
              text: 'Try Again',
              onPressed: _startDiscoveryFlow,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback? onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 250,
        height: 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            colors: onPressed == null
                ? [const Color(0xFF8A7A9F), const Color(0xFF6D5F80)]
                : [const Color(0xFFFF8C42), const Color(0xFFE85A4F)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF8C42).withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCentralPin({required bool animate}) {
    final pin = SizedBox(
      width: 248,
      height: 248,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final t = _pulseController.value;
              return Container(
                width: 214 + (t * 10),
                height: 214 + (t * 10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFF8C42).withOpacity(0.55),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF8C42).withOpacity(0.25),
                      blurRadius: 20,
                      spreadRadius: 3,
                    ),
                  ],
                ),
              );
            },
          ),
          Container(
            width: 186,
            height: 186,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFFFB347).withOpacity(0.14),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const Icon(
            Icons.location_on_rounded,
            size: 96,
            color: Color(0xFFFF8C42),
          ),
        ],
      ),
    );

    if (!animate) return pin;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final scale = 0.95 + (_pulseController.value * 0.08);
        return Transform.scale(scale: scale, child: pin);
      },
    );
  }

  Widget _buildFloatingParticles() {
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, _) {
        return CustomPaint(
          size: Size.infinite,
          painter: _ParticlesPainter(progress: _backgroundController.value),
        );
      },
    );
  }

  Widget _matchAvatarFallback() {
    return Container(
      color: const Color(0xFF3B2458),
      child: const Icon(Icons.person, size: 70, color: Colors.white70),
    );
  }
}

class _ParticlesPainter extends CustomPainter {
  final double progress;

  const _ParticlesPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    const particleCount = 34;

    for (var index = 0; index < particleCount; index++) {
      final seed = index / particleCount;
      final x = ((seed * 997 + progress * 0.17) % 1.0) * size.width;
      final y = ((seed * 593 + progress * 0.12 + 0.2) % 1.0) * size.height;
      final radius = 0.7 + ((index % 5) * 0.35);
      final opacity = 0.08 + 0.22 * ((sin((progress + seed) * pi * 2) + 1) / 2);

      paint.color = const Color(0xFFFFA45C).withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
