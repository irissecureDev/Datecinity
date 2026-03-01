import 'package:flutter/material.dart';
import 'package:cheers/widgets/spark_theme.dart';
import 'package:cheers/models/spark.dart';
import 'package:cheers/screens/spark_conversation_screen.dart';
import 'package:cheers/services/spark_service.dart';

/// Écran de compatibilité - Montre pourquoi ils sont compatibles
class SparkCompatibilityScreen extends StatefulWidget {
  final Spark spark;

  const SparkCompatibilityScreen({super.key, required this.spark});

  @override
  State<SparkCompatibilityScreen> createState() =>
      _SparkCompatibilityScreenState();
}

class _SparkCompatibilityScreenState extends State<SparkCompatibilityScreen> {
  final SparkService _sparkService = SparkService();
  bool _isLiking = false;

  Future<void> _likeSpark() async {
    if (_isLiking) return;
    setState(() => _isLiking = true);

    final success = await _sparkService.likeSpark(widget.spark.sparkId);

    if (success && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SparkConversationScreen(spark: widget.spark),
        ),
      );
    }

    setState(() => _isLiking = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.spark.user;
    final firstName = user.userFullname.split(' ')[0];
    final details = widget.spark.compatibilityDetails ?? {};

    return Scaffold(
      body: SparkBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header avec bouton retour
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: SparkTheme.textPrimary,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Logo
                      const SparkLogo(size: 60),

                      const SizedBox(height: 24),

                      // Titre
                      Text(
                        'Compatibility\nwith $firstName',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: SparkTheme.textPrimary,
                          height: 1.2,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Cartes de compatibilité
                      _buildCompatibilityCard(
                        icon: Icons.star_rounded,
                        iconColor: SparkTheme.warmGlow,
                        title: 'Values Alignment',
                        score:
                            (details['values_alignment']?['score'] ?? 0.75)
                                as double,
                      ),

                      const SizedBox(height: 12),

                      _buildCompatibilityCard(
                        icon: Icons.chat_bubble_rounded,
                        iconColor: SparkTheme.primaryOrange,
                        title: 'Communication Style',
                        score:
                            (details['communication_style']?['score'] ?? 0.8)
                                as double,
                      ),

                      const SizedBox(height: 12),

                      _buildCompatibilityCard(
                        icon: Icons.bolt_rounded,
                        iconColor: SparkTheme.secondaryOrange,
                        title: 'Pace & Energy',
                        score:
                            (details['pace_energy']?['score'] ?? 0.7) as double,
                      ),

                      const SizedBox(height: 32),

                      // Section "Why You Two Sparked"
                      _buildSparkReasonsSection(details),

                      const SizedBox(height: 32),

                      // Bouton Like
                      SparkGradientButton(
                        text: 'Like $firstName',
                        isLoading: _isLiking,
                        onPressed: _likeSpark,
                      ),

                      const SizedBox(height: 16),

                      // Bouton Skip
                      TextButton(
                        onPressed: () async {
                          await _sparkService.declineSpark(
                            widget.spark.sparkId,
                          );
                          if (mounted) {
                            Navigator.of(
                              context,
                            ).popUntil((route) => route.isFirst);
                          }
                        },
                        child: const Text(
                          'Skip for now',
                          style: TextStyle(
                            color: SparkTheme.textMuted,
                            fontSize: 16,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompatibilityCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required double score,
  }) {
    return SparkCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: SparkTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                // Barre de progression
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: score,
                    backgroundColor: SparkTheme.cardBackgroundLight,
                    valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${(score * 100).toInt()}%',
            style: const TextStyle(
              color: SparkTheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSparkReasonsSection(Map<String, dynamic> details) {
    final reasons = details['spark_reasons'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Why You Two Sparked',
          style: TextStyle(
            color: SparkTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (reasons.isNotEmpty)
          ...reasons.map(
            (reason) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: const BoxDecoration(
                      color: SparkTheme.warmGlow,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      reason.toString(),
                      style: const TextStyle(
                        color: SparkTheme.textSecondary,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          const Text(
            'You both share similar interests and values that make you a great match!',
            style: TextStyle(
              color: SparkTheme.textSecondary,
              fontSize: 15,
              height: 1.4,
            ),
          ),
      ],
    );
  }
}
