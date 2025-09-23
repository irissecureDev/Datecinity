import 'package:flutter/material.dart';
import 'package:cheers/constants/constants.dart';
import 'package:cheers/helpers/app_localizations.dart';
import 'package:cheers/screens/complete_profile_screen.dart';
import 'package:cheers/widgets/app_logo.dart';
import 'package:cheers/widgets/default_button.dart';
import 'package:cheers/models/user_model.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),

              // App Logo
              const AppLogo(width: 120, height: 120),

              const SizedBox(height: 40),

              // Welcome Title
              Text(
                i18n.translate("welcome_to_cheers_dating_app"),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: APP_PRIMARY_COLOR,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Description Text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  i18n.translate("welcome_description"),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const Spacer(),

              // Fill Compatibility Quiz Button
              DefaultButton(
                child: Text(
                  i18n.translate("fill_compatibility_quiz"),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () async {
                  // Mark user as having seen welcome screen
                  await UserModel().updateUserData(
                    userId: UserModel().user.userId,
                    data: {USER_HAS_SEEN_WELCOME: true},
                  );

                  // Navigate to Complete Profile Screen (Compatibility Quiz)
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const CompleteProfileScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
