import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cheers/widgets/spark_theme.dart';
import 'package:cheers/models/spark.dart';
import 'package:cheers/screens/spark_crossed_paths_screen.dart';

/// Écran "A Spark is forming..." - Animation de transition
class SparkFormingScreen extends StatefulWidget {
  final Spark spark;

  const SparkFormingScreen({super.key, required this.spark});

  @override
  State<SparkFormingScreen> createState() => _SparkFormingScreenState();
}

class _SparkFormingScreenState extends State<SparkFormingScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _navigateToNextScreen();
  }

  void _initAnimations() {
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  void _navigateToNextScreen() {
    // Attendre 3 secondes puis naviguer vers l'écran suivant
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                SparkCrossedPathsScreen(spark: widget.spark),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
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
                glowIntensity: _glowAnimation.value,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Logo principal
                  const SparkLogo(size: 100),

                  const SizedBox(height: 60),

                  // Texte "A Spark is forming..."
                  const Text(
                    'A Spark\nis forming...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: SparkTheme.textPrimary,
                      height: 1.2,
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Effet de glow en bas
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          SparkTheme.warmGlow.withOpacity(_glowAnimation.value),
                          SparkTheme.warmGlow.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
