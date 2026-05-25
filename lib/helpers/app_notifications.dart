import 'package:datecinity/datas/user.dart';
import 'package:datecinity/dialogs/common_dialogs.dart';
import 'package:datecinity/models/user_model.dart';
import 'package:datecinity/screens/profile_likes_screen.dart';
import 'package:datecinity/screens/home_screen.dart';
import 'package:datecinity/screens/profile_screen.dart';
import 'package:datecinity/screens/profile_visits_screen.dart';
import 'package:flutter/material.dart';

class AppNotifications {
  /// Handle notification click for push
  /// and database notifications
  Future<void> onNotificationClick(
    BuildContext context, {
    required String nType,
    required String nSenderId,
    required String nMessage,
    // Call Info object
    String? nCallInfo,
  }) async {
    /// Control notification type
    switch (nType) {
      case 'like':

        /// Check user VIP account
        if (UserModel().userIsVip) {
          /// Go direct to user profile
          _goToProfileScreen(context, nSenderId);
        } else {
          /// Go Profile Likes Screen
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const ProfileLikesScreen()),
          );
        }
        break;
      case 'visit':

        /// Check user VIP account
        if (UserModel().userIsVip) {
          /// Go direct to user profile
          _goToProfileScreen(context, nSenderId);
        } else {
          /// Go Profile Visits Screen
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ProfileVisitsScreen(),
            ),
          );
        }
        break;

      // Point 5: Nouveaux types de notifications intelligentes
      case 'high_compatibility':
      case 'new_matches':
      case 'spark':
      case 'spark_like':
      case 'spark_match':
      case 'spark_declined':

        /// Aller à Matches > Discover
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const HomeScreen(initialTabIndex: 1),
          ),
        );
        break;

      case 'nearby_match':

        /// Aller à Matches > Discover avec un message spécial
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const HomeScreen(initialTabIndex: 1),
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('💡 Enable location to discover nearby matches.'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 3),
          ),
        );
        break;

      case 'alert':

        /// Show dialog info
        Future(() {
          infoDialog(context, message: nMessage);
        });

        break;
    }
  }

  /// Navigate to profile screen
  void _goToProfileScreen(BuildContext context, userSenderId) async {
    /// Get updated user info
    final User user = await UserModel().getUserObject(userSenderId);

    /// Go direct to profile
    Future(
      () => Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => ProfileScreen(user: user)),
      ),
    );
  }
}
