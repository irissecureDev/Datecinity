import 'package:cheers/helpers/app_localizations.dart';
import 'package:cheers/models/user_model.dart';
import 'package:cheers/widgets/default_card_border.dart';
import 'package:cheers/widgets/delete_account_button.dart';
import 'package:cheers/widgets/profile_basic_info_card.dart';
import 'package:cheers/widgets/profile_statistics_card.dart';
import 'package:cheers/widgets/sign_out_button_card.dart';
// import 'package:cheers/widgets/vip_account_card.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  // Variables

  @override
  Widget build(BuildContext context) {
    void showAccountOption() {
      showModalBottomSheet(
        context: context,
        showDragHandle: true,
        builder: (ctx) {
          return SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SignOutButtonCard(),

                    const SizedBox(height: 25),

                    /// Delete Account Button
                    const DeleteAccountButton(),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    final i18n = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8.0),
      child: ScopedModelDescendant<UserModel>(
        builder: (context, child, userModel) {
          return Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Basic profile info
                const ProfileBasicInfoCard(),

                const SizedBox(height: 10),

                /// Profile Statistics Card
                const ProfileStatisticsCard(),

                const SizedBox(height: 25.0),
                Card(
                  clipBehavior: Clip.antiAlias,
                  elevation: 4.0,
                  shape: defaultCardBorder(),
                  child: ListTile(
                    leading: const Icon(Icons.exit_to_app),
                    title: Text(
                      "Settings",
                      style: const TextStyle(fontSize: 18),
                    ),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: showAccountOption,
                  ),
                ),

                // const Spacer(),

                // const SizedBox(height: 10),

                /// Show VIP dialog
                // const VipAccountCard(),
                // const SizedBox(height: 10),

                /// App Section Card
                // AppSectionCard(),
                // const SizedBox(height: 20),

                /// Sign out button card
                // const SignOutButtonCard(),

                // const SizedBox(height: 25),

                /// Delete Account Button
                // const DeleteAccountButton(),
                // const SizedBox(height: 25),
              ],
            ),
          );
        },
      ),
    );
  }
}
