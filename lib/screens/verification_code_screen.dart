import 'package:cheers/dialogs/common_dialogs.dart';
import 'package:cheers/dialogs/progress_dialog.dart';
import 'package:cheers/helpers/app_localizations.dart';
import 'package:cheers/models/user_model.dart';
import 'package:cheers/plugins/otp_screen/otp_screen.dart';
import 'package:cheers/screens/welcome_screen.dart';
import 'package:cheers/screens/home_screen.dart';
import 'package:cheers/screens/sign_up_screen.dart';
import 'package:cheers/screens/update_location_sceen.dart';
import 'package:cheers/widgets/svg_icon.dart';
import 'package:flutter/material.dart';

class VerificationCodeScreen extends StatefulWidget {
  // Variables
  final String verificationId;

  // Constructor
  const VerificationCodeScreen({super.key, required this.verificationId});

  @override
  VerificationCodeScreenState createState() => VerificationCodeScreenState();
}

class VerificationCodeScreenState extends State<VerificationCodeScreen> {
  // Variables
  late AppLocalizations _i18n;
  late ProgressDialog _pr;

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

  /// logic to validate otp return [null] when success else error [String]
  Future<String?> validateOtp(String otp) async {
    /// Handle entered verification code here
    ///
    /// Show progress dialog
    _pr.show(_i18n.translate("processing"));

    await UserModel().signInWithOTP(
      verificationId: widget.verificationId,
      otp: otp,
      checkUserAccount: () {
        /// Auth user account
        UserModel().authUserAccount(
          updateLocationScreen: () => _nextScreen(const UpdateLocationScreen()),
          homeScreen: () => _nextScreen(const HomeScreen()),
          signUpScreen: () => _nextScreen(const SignUpScreen()),
          completePreferencesScreen: () => _nextScreen(const WelcomeScreen()),
        );
      },
      onError: () async {
        // Hide dialog
        await _pr.hide();
        // Show error message to user
        Future(
          () => errorDialog(
            context,
            message: _i18n.translate("we_were_unable_to_verify_your_number"),
          ),
        );
      },
    );

    // Hide progress dialog
    await _pr.hide();

    return null;
  }

  @override
  Widget build(BuildContext context) {
    /// Initialization
    _i18n = AppLocalizations.of(context);
    _pr = ProgressDialog(context, isDismissible: false);

    return OtpScreen.withGradientBackground(
      topColor: Theme.of(context).primaryColor,
      bottomColor: Theme.of(context).primaryColor.withValues(alpha: .7),
      otpLength: 6,
      validateOtp: validateOtp,
      routeCallback: (context) {},
      icon: CircleAvatar(
        radius: 50,
        backgroundColor: Colors.white,
        child: SvgIcon(
          "assets/icons/phone_icon.svg",
          width: 40,
          height: 40,
          color: Theme.of(context).primaryColor,
        ),
      ),
      title: _i18n.translate("verification_code"),
      subTitle: _i18n.translate("please_enter_the_sms_code_sent"),
    );
  }
}
