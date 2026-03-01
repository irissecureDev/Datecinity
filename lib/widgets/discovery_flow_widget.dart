import 'dart:async';
import 'dart:math';

import 'package:cheers/models/discovery_state.dart';
import 'package:cheers/services/spark_service.dart';
import 'package:cheers/services/suggestions_service.dart';
import 'package:cheers/widgets/discovery_animations.dart';
import 'package:cheers/widgets/advanced_profile_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DiscoveryFlowWidget extends StatefulWidget {
  const DiscoveryFlowWidget({super.key});

  @override
  State<DiscoveryFlowWidget> createState() => _DiscoveryFlowWidgetState();
}

class _DiscoveryFlowWidgetState extends State<DiscoveryFlowWidget>
    with TickerProviderStateMixin {
  final SuggestionsService _suggestionsService = SuggestionsService();
  final SparkService _sparkService = SparkService();

  DiscoveryState _state = const DiscoveryState(
    flow: DiscoveryStep.proximityDetected,
  );
  Timer? _countdownTimer;
  Timer? _stateTimer;

  late AnimationController _pulseController;
  late AnimationController _backgroundController;
  late AnimationController _bounceController;

  @override
  void initState() {
    super.initState();
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
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _stateTimer?.cancel();
    _pulseController.dispose();
    _backgroundController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  void _onTapSearchButton() {
    HapticFeedback.mediumImpact();
    _startDiscoveryFlow();
  }

  void _startDiscoveryFlow() {
    _stateTimer?.cancel();
    _updateState(
      _state.copyWith(
        flow: DiscoveryStep.proximitySearch,
        isAnimating: true,
        errorMessage: null,
      ),
    );

    _searchForMatch();
  }

  Future<void> _searchForMatch() async {
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
        _updateState(
          _state.copyWith(
            flow: DiscoveryStep.error,
            errorMessage: 'No person nearby right now.',
            isAnimating: false,
          ),
        );
        _stateTimer = Timer(const Duration(seconds: 2), _resetToStartScreen);
        return;
      }

      final selectedProfile = profiles.first;

      // await _sparkService.createSpark(
      //   targetUser: selectedProfile.user,
      //   distance: selectedProfile.distance,
      //   compatibility: selectedProfile.compatibility,
      // );

      _updateState(
        _state.copyWith(
          flow: DiscoveryStep.profileView,
          targetProfile: selectedProfile,
          isAnimating: true,
        ),
      );

      // _stateTimer = Timer(DiscoveryConfig.sparkFormingDuration, () {
      //   _updateState(
      //     _state.copyWith(flow: DiscoveryStep.matchFound, isAnimating: true),
      //   );
      //   _bounceController.forward(from: 0);

      //   _stateTimer = Timer(
      //     DiscoveryConfig.matchFoundDisplayDuration,
      //     _startCountdown,
      //   );
      // });
    } catch (_) {
      _updateState(
        _state.copyWith(
          flow: DiscoveryStep.error,
          errorMessage: 'Search failed. Please try again.',
          isAnimating: false,
        ),
      );
      _stateTimer = Timer(const Duration(seconds: 2), _resetToStartScreen);
    }
  }

  // void _startCountdown() {
  //   _updateState(
  //     _state.copyWith(
  //       flow: DiscoveryStep.timerCountdown,
  //       remainingTime: DiscoveryConfig.countdownDuration,
  //       isAnimating: false,
  //     ),
  //   );

  //   _countdownTimer?.cancel();
  //   _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
  //     final remaining = _state.remainingTime! - const Duration(seconds: 1);
  //     if (remaining.isNegative) {
  //       timer.cancel();
  //       _updateState(
  //         _state.copyWith(
  //           flow: DiscoveryStep.error,
  //           errorMessage: 'Time expired. Spark ended.',
  //           isAnimating: false,
  //         ),
  //       );
  //       _stateTimer = Timer(const Duration(seconds: 2), _resetToStartScreen);
  //       return;
  //     }
  //     _updateState(_state.copyWith(remainingTime: remaining));
  //   });
  // }

  void _onSwipeToAdd() {
    HapticFeedback.heavyImpact();
    _countdownTimer?.cancel();
    _updateState(
      _state.copyWith(flow: DiscoveryStep.swipeToAdd, isAnimating: true),
    );

    _stateTimer = Timer(const Duration(milliseconds: 1200), () {
      _updateState(
        _state.copyWith(flow: DiscoveryStep.flameSuccess, isAnimating: true),
      );
      _stateTimer = Timer(
        DiscoveryConfig.flameSuccessDuration,
        _resetToStartScreen,
      );
    });
  }

  void _resetToStartScreen() {
    _stateTimer?.cancel();
    _countdownTimer?.cancel();
    _updateState(
      const DiscoveryState(
        flow: DiscoveryStep.proximityDetected,
        isAnimating: false,
      ),
    );
  }

  void _updateState(DiscoveryState state) {
    if (!mounted) return;
    setState(() => _state = state);
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
          child: Padding(
            padding: const EdgeInsets.only(top: 18),
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
        return _buildProximityDetectedScreen();
      case DiscoveryStep.proximitySearch:
        return _buildProximitySearchScreen();
      case DiscoveryStep.profileView:
        return _buildProfileViewScreen();
      case DiscoveryStep.sparkForming:
        return _buildSparkFormingScreen();
      case DiscoveryStep.matchFound:
        return _buildMatchFoundScreen();
      case DiscoveryStep.timerCountdown:
        return _buildTimerCountdownScreen();
      case DiscoveryStep.swipeToAdd:
        return _buildSwipeToAddScreen();
      case DiscoveryStep.flameSuccess:
        return _buildFlameSuccessScreen();
      case DiscoveryStep.error:
        return _buildErrorScreen();
    }
  }

  Widget _buildProfileViewScreen() {
    if (_state.targetProfile == null) {
      return _buildErrorScreen();
    }

    // Animate transition to profile view
    if (_state.isAnimating) {
      _backgroundController.forward();
    }

    return Stack(
      children: [
        _buildFloatingParticles(), // Background particles
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: AdvancedProfileCard(
              user: _state.targetProfile!.user,
              compatibility: _state.targetProfile!.compatibility,
              distance: _state.targetProfile!.distance,
              isListView: false,
              onLike: () async {
                HapticFeedback.heavyImpact();
                // Créer le spark sur Like
                await _sparkService.createSpark(
                  targetUser: _state.targetProfile!.user,
                  distance: _state.targetProfile!.distance,
                  compatibility: _state.targetProfile!.compatibility,
                );
                _onSwipeToAdd();
              },
              onSuperLike: () async {
                HapticFeedback.heavyImpact();
                await _sparkService.createSpark(
                  targetUser: _state.targetProfile!.user,
                  distance: _state.targetProfile!.distance,
                  compatibility: _state.targetProfile!.compatibility,
                );
                _onSwipeToAdd();
              },
              onViewProfile: () {
                // Optionnel: Voir profil complet
              },
            ),
          ),
        ),
        // Add a back button or close button to return to search
        Positioned(
          top: 0,
          left: 16,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: _resetToStartScreen,
          ),
        ),
      ],
    );
  }

  Widget _buildProximityDetectedScreen() {
    return Stack(
      children: [
        _buildFloatingParticles(),
        Center(
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
                    fontSize: 60,
                    fontWeight: FontWeight.w500,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'There is a person nearby.',
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
        ),
      ],
    );
  }

  Widget _buildProximitySearchScreen() {
    return Stack(
      children: [
        _buildFloatingParticles(),
        Center(
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
                    fontSize: 60,
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
                _buildCentralPin(animate: true),
                const SizedBox(height: 26),
                const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    color: Color(0xFFFFB347),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSparkFormingScreen() {
    return Stack(
      children: [
        _buildFloatingParticles(),
        Center(
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
                    fontSize: 46,
                    fontWeight: FontWeight.w600,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFFF8C42).withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMatchFoundScreen() {
    final profile = _state.targetProfile;
    final user = profile?.user;
    final firstName = user == null
        ? 'Nearby Match'
        : user.userFullname.split(' ').first;

    return Stack(
      children: [
        _buildFloatingParticles(),
        Center(
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
                    fontSize: 42,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 24),
                AnimatedBuilder(
                  animation: _bounceController,
                  builder: (context, _) {
                    final scale =
                        0.92 + (sin(_bounceController.value * pi) * 0.08);
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 210,
                        height: 250,
                        padding: const EdgeInsets.all(8),
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
                          child:
                              user != null && user.userProfilePhoto.isNotEmpty
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
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimerCountdownScreen() {
    final remaining = _state.remainingTime ?? DiscoveryConfig.countdownDuration;
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;

    return Stack(
      children: [
        _buildFloatingParticles(),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 44,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildMiniProfileCard(
                      User(name: 'You', age: _currentUserAge()),
                    ),
                    const SizedBox(width: 12),
                    _buildMiniProfileCard(
                      User(
                        name:
                            _state.targetProfile?.user.userFullname
                                .split(' ')
                                .first ??
                            'Match',
                        age: _targetAge(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                GestureDetector(
                  onPanUpdate: (details) {
                    if (details.delta.dy < -8) {
                      _onSwipeToAdd();
                    }
                  },
                  onTap: _onSwipeToAdd,
                  child: Container(
                    width: 250,
                    height: 58,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF8C42), Color(0xFFE85A4F)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF8C42).withOpacity(0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'SWIPE TO ADD',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwipeToAddScreen() {
    final profile = _state.targetProfile;
    final user = profile?.user;
    return Stack(
      children: [
        _buildFloatingParticles(),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '5:16',
                  style: TextStyle(color: Colors.white, fontSize: 42),
                ),
                const SizedBox(height: 24),
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 900),
                  tween: Tween(begin: 0, end: 1),
                  builder: (context, value, child) {
                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..translate(0.0, 30 * (1 - value))
                        ..rotateZ(-0.15 * value)
                        ..scale(0.85 + (0.15 * value)),
                      child: child,
                    );
                  },
                  child: Container(
                    width: 200,
                    height: 280,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF8C42).withOpacity(0.3),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
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
                ),
                const SizedBox(height: 32),
                Container(
                  width: 250,
                  height: 58,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF8C42), Color(0xFFE85A4F)],
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'SWIPE TO ADD',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFlameSuccessScreen() {
    return Stack(
      children: [
        _buildFloatingParticles(),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                FlameAnimation(size: 180, baseColor: Color(0xFFFF8C42)),
                SizedBox(height: 24),
                Text(
                  'Your Spark\nhas become\na Flame',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFF4DFC0),
                    fontSize: 46,
                    fontWeight: FontWeight.w600,
                    height: 1.05,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 72),
          const SizedBox(height: 16),
          Text(
            _state.errorMessage ?? 'Something went wrong.',
            style: const TextStyle(color: Colors.white, fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ],
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

  Widget _buildMiniProfileCard(User user) {
    return Container(
      width: 110,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF2B1A47),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFF4A2E6A),
            backgroundImage: user.imageUrl.isNotEmpty
                ? NetworkImage(user.imageUrl)
                : null,
            child: user.imageUrl.isEmpty
                ? const Icon(Icons.person, color: Colors.white70)
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            '${user.name}, ${user.age}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  int _currentUserAge() {
    final birthYear = DateTime.now().year - 26;
    return DateTime.now().year - birthYear;
  }

  int _targetAge() {
    final target = _state.targetProfile?.user.userBirthYear;
    if (target == null || target <= 0) return 26;
    return DateTime.now().year - target;
  }
}

class User {
  final String name;
  final int age;
  final String imageUrl;

  const User({required this.name, required this.age, this.imageUrl = ''});
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
