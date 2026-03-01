import 'package:cheers/models/user_model.dart';
import 'package:cheers/widgets/delete_account_button.dart';
import 'package:cheers/widgets/sign_out_button_card.dart';
import 'package:cheers/screens/complete_profile_screen.dart';
import 'package:cheers/screens/edit_profile_screen.dart';
import 'package:cheers/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  // Light purple background color (close to white)
  static const Color _backgroundColor = Color(0xFFF5F0FA);

  @override
  Widget build(BuildContext context) {
    // Get User Birthday and Age
    final DateTime userBirthday = DateTime(
      UserModel().user.userBirthYear,
      UserModel().user.userBirthMonth,
      UserModel().user.userBirthDay,
    );
    final int userAge = UserModel().calculateUserAge(userBirthday);

    void showSafetyAndTrustOptions() {
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
                          color: Theme.of(context).primaryColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.shield_outlined,
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
                              "Safety & Trust",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            Text(
                              "Privacy controls and account settings",
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
                    color: Colors.grey[200],
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

    return ScopedModelDescendant<UserModel>(
      builder: (context, child, userModel) {
        return Container(
          color: _backgroundColor,
          child: SingleChildScrollView(
            child: Column(
              children: [
                /// Header Section with Profile Info
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(color: _backgroundColor),
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        const SizedBox(height: 30),

                        /// Large Circular Profile Photo
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).primaryColor.withAlpha(50),
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(25),
                                spreadRadius: 0,
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 55,
                            child: CircleAvatar(
                              backgroundColor: Colors.grey[200],
                              radius: 51,
                              backgroundImage: NetworkImage(
                                UserModel().user.userProfilePhoto,
                              ),
                              onBackgroundImageError: (e, s) {
                                debugPrint(e.toString());
                              },
                              child: UserModel().user.userProfilePhoto.isEmpty
                                  ? Icon(
                                      Icons.person,
                                      size: 55,
                                      color: Colors.grey[400],
                                    )
                                  : null,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        /// Name and Age
                        Text(
                          "${UserModel().user.userFullname.split(' ')[0]}, $userAge",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[800],
                            letterSpacing: 0.3,
                          ),
                        ),

                        const SizedBox(height: 8),

                        /// Dots indicator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            5,
                            (index) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(
                                  context,
                                ).primaryColor.withAlpha(150),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        /// Location
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              UserModel().user.userLocality.isNotEmpty
                                  ? UserModel().user.userLocality
                                  : "Location not set",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                /// Content Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      /// Complete Your Profile Section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(10),
                              spreadRadius: 0,
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              "Complete Your Profile",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Add a few more details to start making genuine connections.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 16),

                            /// Edit Profile Button (reduced size)
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const EditProfileScreen(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 28,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text(
                                    "Edit Profile",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Icon(Icons.arrow_forward_ios, size: 14),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      /// Compatibility Test Card
                      _buildProfileCard(
                        context: context,
                        icon: Icons.psychology_outlined,
                        iconColor: Theme.of(context).primaryColor,
                        title: "Compatibility Test",
                        subtitle: null,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const CompleteProfileScreen(
                                showBackButton: true,
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      /// Safety & Trust Card
                      _buildProfileCard(
                        context: context,
                        icon: Icons.shield_outlined,
                        iconColor: Colors.grey[700]!,
                        title: "Safety & Trust",
                        subtitle:
                            "Privacy controls, reporting, and verification",
                        onTap: showSafetyAndTrustOptions,
                      ),

                      const SizedBox(height: 12),

                      /// Tracking Card
                      _buildProfileCard(
                        context: context,
                        icon: Icons.track_changes,
                        iconColor: Theme.of(context).primaryColor,
                        title: "Tracking",
                        subtitle: "Location, distance and age preferences",
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SettingsScreen(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 30),
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

  /// Build Profile Card Widget
  Widget _buildProfileCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
