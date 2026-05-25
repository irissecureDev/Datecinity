import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datecinity/api/blocked_users_api.dart';
import 'package:datecinity/constants/constants.dart';
import 'package:datecinity/models/user_model.dart';
import 'package:datecinity/plugins/geoflutterfire/geoflutterfire.dart';
import 'package:flutter/material.dart';

class UsersApi {
  /// Get firestore instance
  ///
  final _firestore = FirebaseFirestore.instance;

  /// Get all users
  Future<List<DocumentSnapshot<Map<String, dynamic>>>> getUsers({
    required List<DocumentSnapshot<Map<String, dynamic>>> dislikedUsers,
  }) async {
    /// Build Users query
    Query<Map<String, dynamic>> usersQuery = _firestore
        .collection(C_USERS)
        .where(USER_STATUS, isEqualTo: 'active')
        .where(USER_LEVEL, isEqualTo: 'user');

    // Filter by gender
    usersQuery = UserModel().filterUserGender(usersQuery);

    // Instance of Geoflutterfire
    final Geoflutterfire geo = Geoflutterfire();

    /// Get user settings
    final Map<String, dynamic>? settings = UserModel().user.userSettings;

    /// Get user geo center
    final GeoFirePoint center = geo.point(
      latitude: UserModel().user.userGeoPoint.latitude,
      longitude: UserModel().user.userGeoPoint.longitude,
    );

    final allUsers = await geo
        .collection(collectionRef: usersQuery)
        .within(
          center: center,
          radius: settings![USER_MAX_DISTANCE].toDouble(),
          field: USER_GEO_POINT,
          strictMode: true,
        )
        .first;

    // Remove current user
    allUsers.removeWhere((u) => u[USER_ID] == UserModel().user.userId);

    // Remove disliked users
    for (var dislikedUser in dislikedUsers) {
      allUsers.removeWhere((u) => u[USER_ID] == dislikedUser[DISLIKED_USER_ID]);
    }

    // Remove liked users
    final likedProfiles =
        (await _firestore
                .collection(C_LIKES)
                .where(LIKED_BY_USER_ID, isEqualTo: UserModel().user.userId)
                .get())
            .docs;

    for (var likedUser in likedProfiles) {
      allUsers.removeWhere((u) => u[USER_ID] == likedUser[LIKED_USER_ID]);
    }

    // Remove blocked users
    await BlockedUsersApi()
        .removeBlockedUsers(allUsers)
        .then((_) => debugPrint('removeBlockedUsers() -> success'))
        .catchError((e) => debugPrint('removeBlockedUsers() -> error: $e'));

    // Remove users without preferences
    allUsers.removeWhere((user) => !user.data()!.containsKey(USER_PREFERENCES));

    // Sort by registration date
    allUsers.sort((a, b) {
      final dateA = a[USER_REG_DATE].toDate();
      final dateB = b[USER_REG_DATE].toDate();
      return dateA.compareTo(dateB);
    });

    // Current user preferences
    final UserModel currentUser = UserModel();
    final Map<String, dynamic> currentPrefs =
        currentUser.user.preferences ?? {};

    // Calculate preference matches and add matching percentage
    for (var doc in allUsers) {
      final prefs =
          (doc.data()![USER_PREFERENCES] ?? {}) as Map<String, dynamic>;

      if (prefs.isEmpty || currentPrefs.isEmpty) {
        doc.data()![USER_MATCH_PERCENT] = 0;
        continue;
      }

      int matches = 0;
      for (final entry in currentPrefs.entries) {
        if (prefs.containsKey(entry.key) && prefs[entry.key] == entry.value) {
          matches++;
        }
      }

      final double matchPercent = (matches / currentPrefs.length * 100)
          .clamp(0, 100)
          .toDouble();

      // 👇 Attach matching percentage to user data (for UI)
      doc.data()![USER_MATCH_PERCENT] = matchPercent;
    }

    // Sort by highest match percentage
    allUsers.sort((a, b) {
      final double matchA = (a.data()![USER_MATCH_PERCENT] ?? 0).toDouble();
      final double matchB = (b.data()![USER_MATCH_PERCENT] ?? 0).toDouble();
      return matchB.compareTo(matchA);
    });

    // Filter by age range
    final int minAge = settings[USER_MIN_AGE];
    final int maxAge = settings[USER_MAX_AGE];

    return allUsers.where((user) {
      final birth = DateTime(
        user[USER_BIRTH_YEAR],
        user[USER_BIRTH_MONTH],
        user[USER_BIRTH_DAY],
      );
      final int age = UserModel().calculateUserAge(birth);
      return age >= minAge && age <= maxAge;
    }).toList();
  }
}
