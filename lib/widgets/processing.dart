import 'package:cheers/helpers/app_localizations.dart';
import 'package:cheers/widgets/my_circular_progress.dart';
import 'package:flutter/material.dart';

class Processing extends StatelessWidget {
  final String? text;

  const Processing({super.key, this.text});

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const MyCircularProgress(),
          const SizedBox(height: 10),
          Text(
            text ?? i18n.translate("processing"),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 5),
          Text(
            i18n.translate("please_wait"),
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
