import 'dart:io';

import 'package:cheers/screens/blocked_account_screen.dart';
import 'package:cheers/screens/welcome_screen.dart';
import 'package:cheers/screens/home_screen.dart';
import 'package:cheers/screens/update_location_sceen.dart';
import 'package:flutter/material.dart';
import 'package:cheers/constants/constants.dart';
import 'package:cheers/helpers/app_localizations.dart';
import 'package:cheers/helpers/app_helper.dart';
import 'package:cheers/screens/update_app_screen.dart';
import 'package:cheers/widgets/app_logo.dart';
import 'package:cheers/widgets/my_circular_progress.dart';
import 'package:cheers/models/user_model.dart';
import 'package:cheers/screens/multi_step_sign_up_screen.dart';
import 'package:cheers/screens/sign_in_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  // Variables
  final AppHelper _appHelper = AppHelper();
  late AppLocalizations _i18n;

  /// Navigate to next page
  void _nextScreen(dynamic screen) {
    // Go to next page route
    Future(() {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => screen),
        (route) => false,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _appHelper.getAppStoreVersion().then((storeVersion) async {
      debugPrint('storeVersion: $storeVersion');

      // Get hard coded App current version
      int appCurrentVersion = 1;
      // Check Platform
      if (Platform.isAndroid) {
        // Get Android version number
        appCurrentVersion = ANDROID_APP_VERSION_NUMBER;
      } else if (Platform.isIOS) {
        // Get iOS version number
        appCurrentVersion = IOS_APP_VERSION_NUMBER;
      }

      /// Compare both versions
      if (storeVersion > appCurrentVersion) {
        /// Go to update app screen
        _nextScreen(const UpdateAppScreen());
        debugPrint("Go to update screen");
      } else {
        /// Authenticate User Account
        UserModel().authUserAccount(
          updateLocationScreen: () => _nextScreen(const UpdateLocationScreen()),
          signInScreen: () => _nextScreen(const SignInScreen()),
          signUpScreen: () => _nextScreen(const MultiStepSignUpScreen()),
          homeScreen: () => _nextScreen(const HomeScreen()),
          blockedScreen: () => _nextScreen(const BlockedAccountScreen()),
          completePreferencesScreen: () => _nextScreen(const WelcomeScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _i18n = AppLocalizations.of(context);
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFF120024),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const AppLogo(width: 150, height: 150),
                const SizedBox(height: 20),
                const Text(
                  APP_NAME,
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 40),
                const MyCircularProgress(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
