import 'package:datecinity/helpers/app_localizations.dart';
import 'package:datecinity/models/user_model.dart';
import 'package:datecinity/screens/edit_profile_screen.dart';
import 'package:datecinity/screens/profile_screen.dart';
import 'package:datecinity/screens/settings_screen.dart';
import 'package:flutter/material.dart';

class ProfileBasicInfoCard extends StatelessWidget {
  const ProfileBasicInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    /// Initialization
    final i18n = AppLocalizations.of(context);
    //
    // Get User Birthday
    final DateTime userBirthday = DateTime(
      UserModel().user.userBirthYear,
      UserModel().user.userBirthMonth,
      UserModel().user.userBirthDay,
    );
    // Get User Current Age
    final int userAge = UserModel().calculateUserAge(userBirthday);

    return Container(
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          /// Large Centered Profile Avatar
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.grey.withOpacity(0.2),
                width: 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 0,
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              radius: 70,
              child: CircleAvatar(
                backgroundColor: Colors.grey[200],
                radius: 66,
                backgroundImage: NetworkImage(
                  UserModel().user.userProfilePhoto,
                ),
                onBackgroundImageError: (e, s) {
                  debugPrint(e.toString());
                },
              ),
            ),
          ),

          const SizedBox(height: 20),

          /// Name and Age - Centered
          Text(
            "${UserModel().user.userFullname.split(' ')[0]}, $userAge",
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              letterSpacing: 0.3,
            ),
          ),

          const SizedBox(height: 32),

          /// Action Buttons Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              /// Settings Button
              _buildActionButton(
                context: context,
                icon: Icons.settings_outlined,
                label: i18n.translate("settings"),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),

              /// Add Photos Button (larger, center)
              _buildCenterButton(
                context: context,
                icon: Icons.camera_alt_outlined,
                label: i18n.translate("view"),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(
                        user: UserModel().user,
                        showButtons: false,
                      ),
                    ),
                  );
                },
              ),

              /// Edit Info Button
              _buildActionButton(
                context: context,
                icon: Icons.edit_outlined,
                label: i18n.translate("edit"),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.grey[700],
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildCenterButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(35),
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
