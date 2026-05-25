import 'dart:async';
import 'package:flutter/material.dart';
import 'package:datecinity/widgets/spark_theme.dart';
import 'package:datecinity/models/spark.dart';
import 'package:datecinity/screens/spark_profile_screen.dart';
import 'package:datecinity/services/spark_service.dart';

/// Écran "You crossed paths!" - Notification de spark trouvé
class SparkCrossedPathsScreen extends StatefulWidget {
  final Spark spark;

  const SparkCrossedPathsScreen({super.key, required this.spark});

  @override
  State<SparkCrossedPathsScreen> createState() =>
      _SparkCrossedPathsScreenState();
}

class _SparkCrossedPathsScreenState extends State<SparkCrossedPathsScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  final SparkService _sparkService = SparkService();
  bool _isRevealing = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.4, end: 0.7).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  Future<void> _revealSpark() async {
    if (_isRevealing) return;

    setState(() => _isRevealing = true);

    // Révéler le spark
    await _sparkService.revealSpark(widget.spark.sparkId);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              SparkProfileScreen(spark: widget.spark),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    const Spacer(flex: 2),

                    // Logo principal
                    const SparkLogo(size: 100),

                    const SizedBox(height: 50),

                    // Texte "You crossed paths!"
                    const Text(
                      'You crossed\npaths!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: SparkTheme.textPrimary,
                        height: 1.1,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Sous-texte
                    const Text(
                      'You crossed paths with\nsomeone compatible.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: SparkTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),

                    const Spacer(flex: 2),

                    // Bouton "Reveal Spark"
                    SparkGradientButton(
                      text: 'Reveal Spark',
                      isLoading: _isRevealing,
                      onPressed: _revealSpark,
                    ),

                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
