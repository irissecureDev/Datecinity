import 'package:flutter/gestures.dart';
import 'package:datecinity/helpers/app_helper.dart';
import 'package:datecinity/helpers/app_localizations.dart';
import 'package:flutter/material.dart';

class TermsOfServiceRow extends StatelessWidget {
  // Params
  final Color color;

  TermsOfServiceRow({super.key, this.color = Colors.white});

  // Private variables
  final _appHelper = AppHelper();

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);

    return Text.rich(
      TextSpan(
        text: "",
        children: [
          TextSpan(
            text: i18n.translate("terms_of_service"),
            style: TextStyle(
              color: color,
              fontSize: 17.0,
              decoration: TextDecoration.underline,
              fontWeight: FontWeight.bold,
              decorationColor: color,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                _appHelper.openTermsPage();
              },
          ),
          TextSpan(
            text: "   |   ",
            style: TextStyle(color: color),
          ),
          TextSpan(
            text: i18n.translate("privacy_policy"),
            style: TextStyle(
              color: color,
              fontSize: 17.0,
              decoration: TextDecoration.underline,
              fontWeight: FontWeight.bold,
              decorationColor: color,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                _appHelper.openPrivacyPage();
              },
          ),
        ],
      ),
    );
  }
}
