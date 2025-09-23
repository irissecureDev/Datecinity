import 'dart:io';

import 'package:country_code_picker/country_code_picker.dart';
import 'package:cheers/helpers/app_localizations.dart';
import 'package:cheers/models/user_model.dart';
import 'package:cheers/models/app_model.dart';
import 'package:cheers/screens/splash_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cheers/constants/constants.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

void main() async {
  // Initialized before calling runApp to init firebase app
  WidgetsFlutterBinding.ensureInitialized();

  /// ***  Initialize Firebase App *** ///
  /// 👉 Please check the [Documentation - README FIRST] instructions in the
  /// Table of Contents at section: [NEW - Firebase initialization for Dating App]
  /// in order to fix it and generate the required [firebase_options.dart] for your app.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Google Mobile Ads SDK
  await MobileAds.instance.initialize();

  /// Update the iOS foreground notification presentation options to allow
  /// heads up notifications.
  /// Check iOS device
  if (Platform.isIOS) {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  runApp(const MyApp());
}

// Define the Navigator global key state to be used when the build context is not available!
final navigatorKey = GlobalKey<NavigatorState>();
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScopedModel<AppModel>(
      model: AppModel(),
      child: ScopedModel<UserModel>(
        model: UserModel(),
        child: MaterialApp(
          navigatorKey: navigatorKey,
          scaffoldMessengerKey: scaffoldMessengerKey,
          title: APP_NAME,
          debugShowCheckedModeBanner: false,

          /// Setup translations
          localizationsDelegates: const [
            // AppLocalizations is where the lang translations is loaded
            AppLocalizations.delegate,
            CountryLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: SUPPORTED_LOCALES,

          /// Returns a locale which will be used by the app
          localeResolutionCallback: (locale, supportedLocales) {
            // Check if the current device locale is supported
            for (var supportedLocale in supportedLocales) {
              if (supportedLocale.languageCode == locale!.languageCode) {
                return supportedLocale;
              }
            }

            /// If the locale of the device is not supported, use the first one
            /// from the list (English, in this case).
            return supportedLocales.first;
          },
          home: const SplashScreen(),
          theme: _appTheme(),
        ),
      ),
    );
  }

  // App theme
  ThemeData _appTheme() {
    return ThemeData(
      primaryColor: APP_PRIMARY_COLOR,
      colorScheme: const ColorScheme.light().copyWith(
        primary: APP_PRIMARY_COLOR,
        secondary: APP_ACCENT_COLOR,
        surface: APP_PRIMARY_COLOR,
      ),
      scaffoldBackgroundColor: Colors.white,
      inputDecorationTheme: InputDecorationTheme(
        errorStyle: const TextStyle(fontSize: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(28)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: Platform.isIOS ? 0 : 4.0,
        iconTheme: const IconThemeData(color: Colors.black),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: const TextStyle(color: Colors.grey, fontSize: 18),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: APP_PRIMARY_COLOR,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        thickness: 0.0,
        color: Color(0xFFCCCCCC),
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
      ),
    );
  }
}
