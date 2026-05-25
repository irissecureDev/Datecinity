import 'package:datecinity/dialogs/common_dialogs.dart';
import 'package:datecinity/helpers/app_localizations.dart';
import 'package:datecinity/screens/delete_account_screen.dart';
import 'package:flutter/material.dart';

class DeleteAccountButton extends StatelessWidget {
  const DeleteAccountButton({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Colors.red[400]!, Colors.red[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red[300]!.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            infoDialog(
              context,
              icon: const CircleAvatar(
                backgroundColor: Colors.red,
                child: Icon(Icons.close, color: Colors.white),
              ),
              title: '${i18n.translate("delete_account")} ?',
              message: i18n.translate(
                'all_your_profile_data_will_be_permanently_deleted',
              ),
              negativeText: i18n.translate("CANCEL"),
              positiveText: i18n.translate("DELETE"),
              negativeAction: () => Navigator.of(context).pop(),
              positiveAction: () async {
                // Close confirm dialog
                Future(() => Navigator.of(context).pop());

                /// Go to delete account screen
                Future(() {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const DeleteAccountScreen(),
                    ),
                  );
                });
              },
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.delete_forever_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    i18n.translate("delete_account"),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    // return Center(
    //   child: DefaultButton(
    //     child: Text(
    //       i18n.translate("delete_account"),
    //       style: const TextStyle(fontSize: 18),
    //     ),
    //     onPressed: () {
    //       /// Delete account
    //       ///
    //       /// Confirm dialog
    //       infoDialog(
    //         context,
    //         icon: const CircleAvatar(
    //           backgroundColor: Colors.red,
    //           child: Icon(Icons.close, color: Colors.white),
    //         ),
    //         title: '${i18n.translate("delete_account")} ?',
    //         message: i18n.translate(
    //           'all_your_profile_data_will_be_permanently_deleted',
    //         ),
    //         negativeText: i18n.translate("CANCEL"),
    //         positiveText: i18n.translate("DELETE"),
    //         negativeAction: () => Navigator.of(context).pop(),
    //         positiveAction: () async {
    //           // Close confirm dialog
    //           Future(() => Navigator.of(context).pop());

    //           /// Go to delete account screen
    //           Future(() {
    //             Navigator.of(context).popUntil((route) => route.isFirst);
    //             Navigator.of(context).pushReplacement(
    //               MaterialPageRoute(
    //                 builder: (context) => const DeleteAccountScreen(),
    //               ),
    //             );
    //           });
    //         },
    //       );
    //     },
    //   ),
    // );
  }
}
