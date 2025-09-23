import 'package:cheers/helpers/app_localizations.dart';
import 'package:cheers/screens/phone_number_screen.dart';
import 'package:cheers/widgets/app_logo.dart';
import 'package:cheers/widgets/default_button.dart';
import 'package:cheers/widgets/terms_of_service_row.dart';
import 'package:flutter/material.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  SignInScreenState createState() => SignInScreenState();
}

class SignInScreenState extends State<SignInScreen> {
  // Variables
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late AppLocalizations _i18n;

  @override
  Widget build(BuildContext context) {
    /// Initialization
    _i18n = AppLocalizations.of(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/background_image.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Colors.black.withValues(alpha: .4),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              /// App logo
              const AppLogo(),

              const SizedBox(height: 15),

              Text(
                _i18n.translate("app_short_description"),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),

              const SizedBox(height: 100),

              /// Sign in with Phone Number
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: SizedBox(
                  width: double.maxFinite,
                  child: DefaultButton(
                    child: Text(
                      _i18n.translate("sign_in_with_phone_number"),
                      style: const TextStyle(fontSize: 18),
                    ),
                    onPressed: () {
                      /// Go to phone number screen
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const PhoneNumberScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Terms of Service section
              Text(
                _i18n.translate("by_tapping_log_in_you_agree_with_our"),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 7),
              TermsOfServiceRow(),

              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }
}
