import 'dart:async';
import 'package:flutter/material.dart';
import 'package:datecinity/widgets/spark_theme.dart';
import 'package:datecinity/models/spark.dart';
import 'package:datecinity/screens/spark_crossed_paths_screen.dart';

/// Écran du compte à rebours - "Time to connect"
/// Affiché quand l'utilisateur ouvre l'app depuis une notification
class SparkCountdownScreen extends StatefulWidget {
  final Spark spark;

  const SparkCountdownScreen({super.key, required this.spark});

  @override
  State<SparkCountdownScreen> createState() => _SparkCountdownScreenState();
}

class _SparkCountdownScreenState extends State<SparkCountdownScreen>
    with TickerProviderStateMixin {
  late Timer _countdownTimer;
  late Duration _timeRemaining;
  late AnimationController _flameController;
  late Animation<double> _flameAnimation;

  @override
  void initState() {
    super.initState();
    _timeRemaining = widget.spark.timeRemaining;
    _initAnimations();
    _startCountdown();
  }

  void _initAnimations() {
    _flameController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _flameAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _flameController, curve: Curves.easeInOut),
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
            'Spark Expired',
            style: TextStyle(color: SparkTheme.textPrimary),
          ),
          content: const Text(
            'This spark has expired. Don\'t worry, new sparks will come your way!',
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

  void _connectNow() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            SparkCrossedPathsScreen(spark: widget.spark),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    _flameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SparkTheme.backgroundGradientEnd,
      body: SparkBackground(
        child: SafeArea(
          child: GestureDetector(
            onTap: _connectNow,
            behavior: HitTestBehavior.opaque,
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Icône de flamme animée
                AnimatedBuilder(
                  animation: _flameAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _flameAnimation.value,
                      child: _buildFlameIcon(),
                    );
                  },
                ),

                const SizedBox(height: 60),

                // Temps restant
                Text(
                  _formattedTime,
                  style: const TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.w300,
                    color: Color(0xFFFFF5E6), // Crème/beige clair
                    letterSpacing: 4,
                  ),
                ),

                const SizedBox(height: 16),

                // Texte "Time to connect"
                const Text(
                  'Time to connect',
                  style: TextStyle(
                    fontSize: 20,
                    color: SparkTheme.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const Spacer(flex: 2),

                // Indication de tap
                const Padding(
                  padding: EdgeInsets.only(bottom: 40),
                  child: Text(
                    'Tap anywhere to reveal your spark',
                    style: TextStyle(fontSize: 14, color: SparkTheme.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ),
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
            color: SparkTheme.warmGlow.withOpacity(0.5),
            blurRadius: 60,
            spreadRadius: 20,
          ),
        ],
      ),
      child: CustomPaint(painter: FlamePainter()),
    );
  }
}

/// Painter personnalisé pour dessiner la flamme
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

    // Forme de la flamme
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
