import 'dart:async';
import 'package:flutter/material.dart';
import 'package:datecinity/widgets/spark_theme.dart';
import 'package:datecinity/models/spark.dart';
import 'package:datecinity/screens/chat_screen.dart';

/// Écran "Your Spark has become a Flame" - Match confirmé !
class SparkMatchSuccessScreen extends StatefulWidget {
  final Spark spark;

  const SparkMatchSuccessScreen({super.key, required this.spark});

  @override
  State<SparkMatchSuccessScreen> createState() =>
      _SparkMatchSuccessScreenState();
}

class _SparkMatchSuccessScreenState extends State<SparkMatchSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _flameController;
  late AnimationController _textController;
  late AnimationController _glowController;
  late Animation<double> _flameAnimation;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    // Animation de la flamme
    _flameController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _flameAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _flameController, curve: Curves.easeInOut),
    );

    // Animation du texte
    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _textOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _textSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _textController,
            curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
          ),
        );

    // Animation du glow
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.5, end: 0.9).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Démarrer l'animation du texte après un délai
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _textController.forward();
      }
    });
  }

  void _goToChat() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ChatScreen(user: widget.spark.user),
      ),
    );
  }

  void _goHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  void dispose() {
    _flameController.dispose();
    _textController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: SparkTheme.backgroundWithGlow(
                glowIntensity: _glowAnimation.value * 0.4,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Flamme animée
                  AnimatedBuilder(
                    animation: _flameAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _flameAnimation.value,
                        child: _buildFlameIcon(),
                      );
                    },
                  ),

                  const SizedBox(height: 50),

                  // Texte "Your Spark has become a Flame"
                  SlideTransition(
                    position: _textSlide,
                    child: FadeTransition(
                      opacity: _textOpacity,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          'Your Spark\nhas become\na Flame',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: SparkTheme.textPrimary,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Boutons d'action
                  FadeTransition(
                    opacity: _textOpacity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        children: [
                          // Bouton Start Chatting
                          SparkGradientButton(
                            text: 'Start Chatting',
                            onPressed: _goToChat,
                          ),

                          const SizedBox(height: 16),

                          // Bouton Later
                          TextButton(
                            onPressed: _goHome,
                            child: const Text(
                              'Later',
                              style: TextStyle(
                                color: SparkTheme.textMuted,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 50),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFlameIcon() {
    return Container(
      width: 180,
      height: 220,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: SparkTheme.warmGlow.withOpacity(_glowAnimation.value),
            blurRadius: 80,
            spreadRadius: 30,
          ),
        ],
      ),
      child: CustomPaint(painter: FlamePainter()),
    );
  }
}

/// Painter pour dessiner la flamme
class FlamePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          const Color(0xFFFFD700), // Jaune doré en bas
          const Color(0xFFFF8C00), // Orange au milieu
          const Color(0xFFFF4500), // Rouge-orange en haut
          const Color(0xFFFF6B4A), // Orange-rose au sommet
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();

    final centerX = size.width / 2;
    final bottomY = size.height;

    // Point de départ en bas au centre
    path.moveTo(centerX, bottomY);

    // Côté gauche de la flamme
    path.quadraticBezierTo(
      size.width * 0.1,
      bottomY * 0.7,
      size.width * 0.15,
      bottomY * 0.5,
    );
    path.quadraticBezierTo(
      size.width * 0.2,
      bottomY * 0.3,
      size.width * 0.3,
      bottomY * 0.2,
    );
    path.quadraticBezierTo(size.width * 0.4, bottomY * 0.05, centerX, 0);

    // Côté droit de la flamme (symétrique)
    path.quadraticBezierTo(
      size.width * 0.6,
      bottomY * 0.05,
      size.width * 0.7,
      bottomY * 0.2,
    );
    path.quadraticBezierTo(
      size.width * 0.8,
      bottomY * 0.3,
      size.width * 0.85,
      bottomY * 0.5,
    );
    path.quadraticBezierTo(size.width * 0.9, bottomY * 0.7, centerX, bottomY);

    path.close();

    canvas.drawPath(path, paint);

    // Flamme intérieure (plus claire)
    final innerPaint = Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              const Color(0xFFFFE4B5), // Crème en bas
              const Color(0xFFFFD700), // Jaune doré au milieu
              const Color(0xFFFF8C00).withOpacity(0.8), // Orange en haut
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(
            Rect.fromLTWH(
              size.width * 0.3,
              size.height * 0.4,
              size.width * 0.4,
              size.height * 0.5,
            ),
          );

    final innerPath = Path();
    final innerCenterX = centerX;
    final innerBottomY = bottomY * 0.95;

    innerPath.moveTo(innerCenterX, innerBottomY);
    innerPath.quadraticBezierTo(
      size.width * 0.35,
      bottomY * 0.7,
      size.width * 0.38,
      bottomY * 0.55,
    );
    innerPath.quadraticBezierTo(
      size.width * 0.42,
      bottomY * 0.4,
      innerCenterX,
      bottomY * 0.35,
    );
    innerPath.quadraticBezierTo(
      size.width * 0.58,
      bottomY * 0.4,
      size.width * 0.62,
      bottomY * 0.55,
    );
    innerPath.quadraticBezierTo(
      size.width * 0.65,
      bottomY * 0.7,
      innerCenterX,
      innerBottomY,
    );
    innerPath.close();

    canvas.drawPath(innerPath, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
