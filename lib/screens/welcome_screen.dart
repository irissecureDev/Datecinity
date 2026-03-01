import 'package:flutter/material.dart';
import 'package:cheers/screens/complete_profile_screen.dart';
import 'package:cheers/models/user_model.dart';
import 'package:cheers/constants/constants.dart';
import 'package:cheers/widgets/spark_theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Future<void> _goToCompatibilityQuiz(BuildContext context) async {
    // Mark user as having seen welcome screen
    await UserModel().updateUserData(
      userId: UserModel().user.userId,
      data: {USER_HAS_SEEN_WELCOME: true},
    );

    // Navigate to Complete Profile Screen (Compatibility Quiz)
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const CompleteProfileScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SparkBackground(
        showGlow: true,
        glowIntensity: 0.4,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 32.0,
              vertical: 24.0,
            ),
            child: Column(
              children: [
                const Spacer(flex: 1),

                // App Logo
                const SparkLogo(size: 130),
                const SizedBox(height: 16),

                // Datecinity Title
                const Text(
                  APP_NAME,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: SparkTheme.textPrimary,
                    letterSpacing: 1.2,
                  ),
                ),

                const Spacer(flex: 1),

                // First paragraph
                const Text(
                  "Before you begin your compatibility test, take a moment to slow down.",
                  style: TextStyle(
                    fontSize: 16,
                    color: SparkTheme.textPrimary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.left,
                ),

                const SizedBox(height: 20),

                // Second paragraph
                Text(
                  "$APP_NAME isn't another swiping app – it's built to help you find real, lasting connection, not just instant attraction.",
                  style: const TextStyle(
                    fontSize: 16,
                    color: SparkTheme.textPrimary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.left,
                ),

                const SizedBox(height: 20),

                // Third paragraph
                const Text(
                  "Most dating apps focus on looks and quick matches – and we get it, that can be exciting. But it often leads to ghosting and endless scrolling without real results, leading to burnout.",
                  style: TextStyle(
                    fontSize: 16,
                    color: SparkTheme.textPrimary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.left,
                ),

                const SizedBox(height: 20),

                // Fourth paragraph
                const Text(
                  "And if it doesn't work out, that's okay. Rejection isn't failure; it's protection – guiding you closer to someone who truly fits.",
                  style: TextStyle(
                    fontSize: 16,
                    color: SparkTheme.textPrimary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.left,
                ),

                const Spacer(flex: 2),

                // Begin Test Button
                SparkGradientButton(
                  text: "Begin Test",
                  onPressed: () => _goToCompatibilityQuiz(context),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
