import 'dart:async';
import 'dart:math';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:cheers/widgets/spark_theme.dart';
import 'package:cheers/models/spark.dart';
import 'package:cheers/datas/user.dart';
import 'package:cheers/services/spark_service.dart';
import 'package:cheers/screens/spark_match_success_screen.dart';

/// Écran affiché quand l'utilisateur reçoit un like d'un Spark
/// Affiche un cœur, les deux photos floues, et un bouton "SWIPE TO ADD"
class SparkLikeReceivedScreen extends StatefulWidget {
  final Spark spark;
  final User currentUser;

  const SparkLikeReceivedScreen({
    super.key,
    required this.spark,
    required this.currentUser,
  });

  @override
  State<SparkLikeReceivedScreen> createState() =>
      _SparkLikeReceivedScreenState();
}

class _SparkLikeReceivedScreenState extends State<SparkLikeReceivedScreen>
    with TickerProviderStateMixin {
  late Timer _countdownTimer;
  late Duration _timeRemaining;
  late AnimationController _heartPulseController;
  late AnimationController _glowController;
  late Animation<double> _heartPulseAnimation;
  late Animation<double> _glowAnimation;

  final SparkService _sparkService = SparkService();

  // Pour le swipe
  double _dragOffset = 0;
  bool _isSwiping = false;
  bool _isMatching = false;

  @override
  void initState() {
    super.initState();
    _timeRemaining = widget.spark.timeRemaining;
    _initAnimations();
    _startCountdown();
  }

  void _initAnimations() {
    // Animation de pulsation du cœur
    _heartPulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _heartPulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _heartPulseController, curve: Curves.easeInOut),
    );

    // Animation du glow
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.4, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeRemaining = widget.spark.expiresAt.difference(DateTime.now());
        if (_timeRemaining.isNegative) {
          _timeRemaining = Duration.zero;
          timer.cancel();
          _handleExpired();
        }
      });
    });
  }

  void _handleExpired() {
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: SparkTheme.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Time\'s up!',
            style: TextStyle(color: SparkTheme.textPrimary),
          ),
          content: const Text(
            'This spark has expired. Don\'t worry, new connections will come your way!',
            style: TextStyle(color: SparkTheme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text(
                'OK',
                style: TextStyle(color: SparkTheme.primaryOrange),
              ),
            ),
          ],
        ),
      );
    }
  }

  String get _formattedTime {
    final minutes = _timeRemaining.inMinutes;
    final seconds = _timeRemaining.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _handleSwipeComplete() async {
    if (_isMatching) return;

    setState(() => _isMatching = true);

    // Confirmer le match
    final success = await _sparkService.likeSpark(widget.spark.sparkId);

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              SparkMatchSuccessScreen(spark: widget.spark),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    _heartPulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: SparkTheme.backgroundWithGlow(
                glowIntensity: _glowAnimation.value * 0.5,
              ),
            ),
            child: SafeArea(
              child: GestureDetector(
                onVerticalDragUpdate: (details) {
                  if (!_isMatching) {
                    setState(() {
                      _dragOffset -= details.delta.dy;
                      _dragOffset = _dragOffset.clamp(0.0, screenHeight * 0.4);
                      _isSwiping = _dragOffset > 20;
                    });
                  }
                },
                onVerticalDragEnd: (details) {
                  if (_dragOffset > screenHeight * 0.15) {
                    // Swipe suffisant → match!
                    _handleSwipeComplete();
                  } else {
                    // Retour à la position initiale
                    setState(() {
                      _dragOffset = 0;
                      _isSwiping = false;
                    });
                  }
                },
                child: Stack(
                  children: [
                    // Contenu principal
                    Transform.translate(
                      offset: Offset(0, -_dragOffset * 0.3),
                      child: Opacity(
                        opacity: _isSwiping
                            ? max(0.3, 1 - (_dragOffset / 200))
                            : 1,
                        child: Column(
                          children: [
                            const SizedBox(height: 60),

                            // Compte à rebours
                            Text(
                              _formattedTime,
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w300,
                                color: SparkTheme.textPrimary,
                                letterSpacing: 4,
                              ),
                            ),

                            const Spacer(),

                            // Cœur animé avec glow
                            AnimatedBuilder(
                              animation: _heartPulseAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _heartPulseAnimation.value,
                                  child: _buildGlowingHeart(),
                                );
                              },
                            ),

                            const SizedBox(height: 40),

                            // Photos des deux utilisateurs (floues)
                            _buildUserPhotos(),

                            const Spacer(),

                            // Bouton SWIPE TO ADD
                            _buildSwipeButton(),

                            const SizedBox(height: 50),
                          ],
                        ),
                      ),
                    ),

                    // Effet de blur lors du swipe
                    if (_isSwiping)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  SparkTheme.warmGlow.withOpacity(
                                    _dragOffset / 300,
                                  ),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGlowingHeart() {
    return Container(
      width: 180,
      height: 160,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: SparkTheme.warmGlow.withOpacity(_glowAnimation.value),
            blurRadius: 60,
            spreadRadius: 20,
          ),
        ],
      ),
      child: CustomPaint(painter: HeartPainter()),
    );
  }

  Widget _buildUserPhotos() {
    final otherUser = widget.spark.user;
    final currentUser = widget.currentUser;
    final otherAge = DateTime.now().year - otherUser.userBirthYear;
    final currentAge = DateTime.now().year - currentUser.userBirthYear;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Photo User A (flou)
        _buildBlurredUserPhoto(
          imageUrl: currentUser.userProfilePhoto,
          name: currentUser.userFullname.split(' ')[0],
          age: currentAge,
        ),
        const SizedBox(width: 30),
        // Photo User B (flou)
        _buildBlurredUserPhoto(
          imageUrl: otherUser.userProfilePhoto,
          name: otherUser.userFullname.split(' ')[0],
          age: otherAge,
        ),
      ],
    );
  }

  Widget _buildBlurredUserPhoto({
    required String imageUrl,
    required String name,
    required int age,
  }) {
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: SparkTheme.cardBackgroundLight, width: 3),
          ),
          child: ClipOval(
            child: Stack(
              children: [
                // Image avec flou
                imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        width: 90,
                        height: 90,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
                // Overlay de flou
                Container(
                  decoration: BoxDecoration(
                    color: SparkTheme.backgroundColor.withOpacity(0.4),
                  ),
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '$name, $age',
          style: const TextStyle(
            color: SparkTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: SparkTheme.cardBackground,
      child: const Icon(
        Icons.person,
        size: 40,
        color: SparkTheme.textSecondary,
      ),
    );
  }

  Widget _buildSwipeButton() {
    return Container(
      width: 220,
      height: 56,
      decoration: BoxDecoration(
        gradient: SparkTheme.buttonGradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: SparkTheme.primaryOrange.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.swipe_up_rounded, color: Colors.white, size: 24),
            SizedBox(width: 10),
            Text(
              'SWIPE TO ADD',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Painter pour dessiner un cœur
class HeartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFB347), // Orange clair en haut
          Color(0xFFFF8C42), // Orange au milieu
          Color(0xFFFF6B4A), // Orange-rouge en bas
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();

    final width = size.width;
    final height = size.height;

    // Point de départ en bas du cœur
    path.moveTo(width / 2, height);

    // Côté gauche du cœur
    path.cubicTo(
      width * 0.1,
      height * 0.7, // Point de contrôle 1
      0,
      height * 0.4, // Point de contrôle 2
      width * 0.1,
      height * 0.25, // Point d'arrivée
    );

    // Partie supérieure gauche
    path.cubicTo(
      width * 0.2,
      height * 0.05,
      width * 0.4,
      0,
      width / 2,
      height * 0.2,
    );

    // Partie supérieure droite
    path.cubicTo(
      width * 0.6,
      0,
      width * 0.8,
      height * 0.05,
      width * 0.9,
      height * 0.25,
    );

    // Côté droit du cœur
    path.cubicTo(
      width,
      height * 0.4,
      width * 0.9,
      height * 0.7,
      width / 2,
      height,
    );

    path.close();

    canvas.drawPath(path, paint);

    // Reflet lumineux
    final highlightPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        radius: 0.8,
        colors: [Colors.white.withOpacity(0.3), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
