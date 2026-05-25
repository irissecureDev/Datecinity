import 'dart:async';
import 'package:flutter/material.dart';
import 'package:datecinity/widgets/spark_theme.dart';
import 'package:datecinity/models/spark.dart';
import 'package:datecinity/screens/spark_compatibility_intro_video_screen.dart';

/// Écran de profil Spark - Affiche le profil de la personne avec countdown
class SparkProfileScreen extends StatefulWidget {
  final Spark spark;

  const SparkProfileScreen({super.key, required this.spark});

  @override
  State<SparkProfileScreen> createState() => _SparkProfileScreenState();
}

class _SparkProfileScreenState extends State<SparkProfileScreen> {
  late Timer _countdownTimer;
  late Duration _timeRemaining;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _timeRemaining = widget.spark.timeRemaining;
    _startCountdown();
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
    // Retourner à l'écran d'accueil si le temps est écoulé
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _seeCompatibility() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              SparkCompatibilityIntroVideoScreen(spark: widget.spark),
        ),
      );
    }

    setState(() => _isLoading = false);
  }

  String _getCompatibilityTraits() {
    final user = widget.spark.user;
    final traits = <String>[];

    if (user.hobbies.isNotEmpty) {
      traits.addAll(user.hobbies.take(2));
    }
    if (user.education.isNotEmpty) {
      traits.add(user.education);
    }

    return traits.isEmpty ? 'Adventurous' : traits.join(' • ');
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.spark.user;
    final age = DateTime.now().year - user.userBirthYear;

    return Scaffold(
      body: SparkBackground(
        showGlow: true,
        glowIntensity: 0.5,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Logo en haut
                const SparkLogo(size: 60),

                const Spacer(),

                // Photo de profil avec bordure
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: SparkTheme.cardBackgroundLight,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: SparkTheme.warmGlow.withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: user.userProfilePhoto.isNotEmpty
                        ? Image.network(
                            user.userProfilePhoto,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildPlaceholderAvatar(),
                          )
                        : _buildPlaceholderAvatar(),
                  ),
                ),

                const SizedBox(height: 30),

                // Nom et âge
                Text(
                  '${user.userFullname.split(' ')[0]}, $age',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: SparkTheme.textPrimary,
                  ),
                ),

                const SizedBox(height: 8),

                // Localité
                Text(
                  user.userLocality.isNotEmpty
                      ? user.userLocality
                      : user.userCountry,
                  style: const TextStyle(
                    fontSize: 16,
                    color: SparkTheme.textSecondary,
                  ),
                ),

                const SizedBox(height: 12),

                // Traits de compatibilité
                Text(
                  _getCompatibilityTraits(),
                  style: const TextStyle(
                    fontSize: 14,
                    color: SparkTheme.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),

                const Spacer(),

                // Bouton "See Compatibility"
                SparkGradientButton(
                  text: 'See Compatibility',
                  isLoading: _isLoading,
                  onPressed: _seeCompatibility,
                ),

                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderAvatar() {
    return Container(
      color: SparkTheme.cardBackground,
      child: const Icon(
        Icons.person,
        size: 80,
        color: SparkTheme.textSecondary,
      ),
    );
  }
}
