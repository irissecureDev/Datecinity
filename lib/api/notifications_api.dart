import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:datecinity/constants/constants.dart';
import 'package:datecinity/models/user_model.dart';
import 'package:flutter/material.dart';

class NotificationsApi {
  /// FINAL VARIABLES
  ///
  /// Firestore instance
  final _firestore = FirebaseFirestore.instance;
  static final _functions = FirebaseFunctions.instance;

  /// Save notification in database
  Future<void> saveNotification({
    required String nReceiverId,
    required String nType,
    required String nMessage,
  }) async {
    _firestore
        .collection(C_NOTIFICATIONS)
        .add({
          N_SENDER_ID: UserModel().user.userId,
          N_SENDER_FULLNAME: UserModel().user.userFullname,
          N_SENDER_PHOTO_LINK: UserModel().user.userProfilePhoto,
          N_RECEIVER_ID: nReceiverId,
          N_TYPE: nType,
          N_MESSAGE: nMessage,
          N_READ: false,
          TIMESTAMP: FieldValue.serverTimestamp(),
        })
        .then((_) {
          debugPrint('saveNotification() -> success');
        });
  }

  /// Notify Current User after purchasing VIP subscription
  Future<void> onPurchaseNotification({required String nMessage}) async {
    _firestore
        .collection(C_NOTIFICATIONS)
        .add({
          N_SENDER_FULLNAME: APP_NAME,
          N_RECEIVER_ID: UserModel().user.userId,
          N_TYPE: 'alert',
          N_MESSAGE: nMessage,
          N_READ: false,
          TIMESTAMP: FieldValue.serverTimestamp(),
        })
        .then((_) {
          debugPrint('saveNotification() -> success');
        });
  }

  /// Get stream notifications for current user
  Stream<QuerySnapshot<Map<String, dynamic>>> getNotifications() {
    /// Build query
    return _firestore
        .collection(C_NOTIFICATIONS)
        .where(N_RECEIVER_ID, isEqualTo: UserModel().user.userId)
        .orderBy(TIMESTAMP, descending: true)
        .snapshots();
  }

  /// Delete current user notifications
  Future<void> deleteUserNotifications() async {
    await _firestore
        .collection(C_NOTIFICATIONS)
        .where(N_RECEIVER_ID, isEqualTo: UserModel().user.userId)
        .get()
        .then((QuerySnapshot<Map<String, dynamic>> snapshot) async {
          // Check result
          if (snapshot.docs.isEmpty) return;

          /// Loop notifications and delete one by one
          for (DocumentSnapshot<Map<String, dynamic>> doc in snapshot.docs) {
            await doc.reference.delete();
          }

          debugPrint('deleteUserNotifications() -> deleted');
        });
  }

  Future<void> deleteUserSentNotifications() async {
    _firestore
        .collection(C_NOTIFICATIONS)
        .where(N_SENDER_ID, isEqualTo: UserModel().user.userId)
        .get()
        .then((QuerySnapshot<Map<String, dynamic>> snapshot) async {
          // Check result
          if (snapshot.docs.isEmpty) return;

          /// Loop notifications
          for (DocumentSnapshot<Map<String, dynamic>> doc in snapshot.docs) {
            await doc.reference.delete();
          }
          debugPrint('deleteUserSentNotifications() -> deleted');
        });
  }

  /// Send push notification method
  Future<void> sendPushNotification({
    required String nTitle,
    required String nBody,
    required String nType,
    required String nSenderId,
    required String nUserDeviceToken,
    // Call Info Map Data
    Map<String, dynamic>? nCallInfo,
  }) async {
    try {
      await _functions.httpsCallable('sendPushNotification').call({
        'type': nType,
        'title': nTitle,
        'body': nBody,
        'deviceToken': nUserDeviceToken,
        'call': nCallInfo,
        'senderId': nSenderId,
      });
      debugPrint('sendPushNotification() -> success');
    } catch (e) {
      debugPrint('sendPushNotification() -> error: $e');
    }
  }
}
