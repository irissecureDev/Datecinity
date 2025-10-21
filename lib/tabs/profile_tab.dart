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
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) {
          return SafeArea(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).primaryColor.withOpacity(0.1),
                              Theme.of(context).primaryColor.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.manage_accounts_outlined,
                          color: Theme.of(context).primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Account Management",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            Text(
                              "Manage your account settings",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  /// Divider
                  Container(
                    height: 1,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.grey[300]!,
                          Colors.grey[100]!,
                          Colors.grey[300]!,
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// Sign Out Option
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: const SignOutButtonCard(),
                  ),

                  /// Delete Account Option
                  Container(child: const DeleteAccountButton()),

                  const SizedBox(height: 16),

                  /// Info Footer
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!, width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue[600],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "These actions are irreversible. Please confirm your choice before proceeding.",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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

              /// Spacer to push button to bottom
              const SizedBox(height: 100),

              /// Modern Account Options Button - Moved to bottom
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8.0),
                width: double.infinity,
                child: InkWell(
                  onTap: showAccountOption,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.red[400]!.withOpacity(0.1),
                          Colors.red[300]!.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.red[300]!.withOpacity(0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red[300]!.withOpacity(0.1),
                          spreadRadius: 0,
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.red[400]!, Colors.red[300]!],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.settings_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Account Options",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.red[600],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: Colors.red[400],
                        ),
                      ],
                    ),
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
