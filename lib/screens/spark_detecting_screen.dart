import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cheers/widgets/spark_theme.dart';
import 'package:cheers/screens/spark_forming_screen.dart';
import 'package:cheers/services/spark_service.dart';
import 'package:cheers/models/spark.dart';

/// Écran "Detecting Proximity..." - Animation de recherche de sparks
class SparkDetectingScreen extends StatefulWidget {
  const SparkDetectingScreen({super.key});

  @override
  State<SparkDetectingScreen> createState() => _SparkDetectingScreenState();
}

class _SparkDetectingScreenState extends State<SparkDetectingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;

  final SparkService _sparkService = SparkService();
  StreamSubscription<List<Spark>>? _sparkSubscription;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startListeningForSparks();
  }

  void _initAnimations() {
    // Animation de pulsation pour le logo du bas
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Animation de rotation subtile
    _rotationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
  }

  void _startListeningForSparks() {
    _sparkSubscription = _sparkService.watchActiveSparks().listen((sparks) {
      if (sparks.isNotEmpty && mounted) {
        // Un spark a été trouvé! Naviguer vers l'écran suivant
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                SparkFormingScreen(spark: sparks.first),
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
    _pulseController.dispose();
    _rotationController.dispose();
    _sparkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SparkBackground(
        showGlow: false,
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Logo principal
              const SparkLogo(size: 100),

              const SizedBox(height: 60),

              // Texte "Detecting Proximity..."
              const Text(
                'Detecting\nProximity...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: SparkTheme.textPrimary,
                  height: 1.2,
                ),
              ),

              const Spacer(flex: 3),

              // Logo animé en bas
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Opacity(
                      opacity: 0.6,
                      child: Image.asset(
                        'assets/images/logo-no-bg.png',
                        width: 40,
                        height: 40,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
