import 'package:cheers/models/user_model.dart';
import 'package:cheers/widgets/delete_account_button.dart';
import 'package:cheers/widgets/profile_basic_info_card.dart';
import 'package:cheers/widgets/profile_statistics_card.dart';
import 'package:cheers/widgets/sign_out_button_card.dart';
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(8.0),
      child: ScopedModelDescendant<UserModel>(
        builder: (context, child, userModel) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Basic profile info
              const ProfileBasicInfoCard(),

              const SizedBox(height: 10),

              /// Profile Statistics Card
              const ProfileStatisticsCard(),

              const SizedBox(height: 25.0),

              /// Modern Settings Section
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 0,
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    children: [
                      /// Settings Option
                      Container(
                        padding: const EdgeInsets.all(20),
                        child: InkWell(
                          onTap: showAccountOption,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.1),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.05),
                                  spreadRadius: 0,
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.red[400]!,
                                        Colors.red[300]!,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.exit_to_app_outlined,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Options du compte",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF2D3748),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Déconnexion & suppression",
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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
          );
        },
      ),
    );
  }
}
