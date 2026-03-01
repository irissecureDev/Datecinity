import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:cheers/api/notifications_api.dart';
import 'package:cheers/constants/constants.dart';
import 'package:cheers/datas/user.dart';
import 'package:cheers/models/spark.dart';
import 'package:cheers/models/user_model.dart';

/// Service pour gérer les Sparks (matches de proximité)
class SparkService {
  static final SparkService _instance = SparkService._internal();
  factory SparkService() => _instance;
  SparkService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationsApi _notificationsApi = NotificationsApi();

  // Collection names
  static const String C_SPARKS = 'Sparks';
  static const String C_SPARK_HISTORY = 'SparkHistory';

  // Configuration
  static const int SPARK_DURATION_MINUTES = 10;
  static const double MIN_COMPATIBILITY_FOR_SPARK = 0.6; // 60%
  static const double MAX_DISTANCE_FOR_SPARK = 0.5; // 500m

  // Stream controllers
  final StreamController<Spark?> _activeSparkController =
      StreamController<Spark?>.broadcast();
  Stream<Spark?> get activeSparkStream => _activeSparkController.stream;

  Spark? _currentSpark;
  Spark? get currentSpark => _currentSpark;

  /// Créer un nouveau Spark quand deux utilisateurs sont proches
  Future<Spark?> createSpark({
    required User targetUser,
    required double distance,
    required double compatibility,
    Map<String, dynamic>? compatibilityDetails,
  }) async {
    try {
      final currentUser = UserModel().user;
      final sparkId =
          '${currentUser.userId}_${targetUser.userId}_${DateTime.now().millisecondsSinceEpoch}';
      final now = DateTime.now();
      final expiresAt = now.add(
        const Duration(minutes: SPARK_DURATION_MINUTES),
      );

      final sparkData = {
        'spark_id': sparkId,
        'user1_id': currentUser.userId,
        'user2_id': targetUser.userId,
        'detected_at': Timestamp.fromDate(now),
        'expires_at': Timestamp.fromDate(expiresAt),
        'distance': distance,
        'compatibility': compatibility,
        'compatibility_details':
            compatibilityDetails ??
            _generateCompatibilityDetails(currentUser, targetUser),
        'status': SparkStatus.pending.value,
        'user1_status': 'pending',
        'user2_status': 'pending',
      };

      // Sauvegarder dans Firestore
      await _firestore.collection(C_SPARKS).doc(sparkId).set(sparkData);

      // Créer l'objet Spark pour l'utilisateur actuel
      final spark = Spark(
        sparkId: sparkId,
        user: targetUser,
        detectedAt: now,
        expiresAt: expiresAt,
        distance: distance,
        compatibility: compatibility,
        compatibilityDetails:
            sparkData['compatibility_details'] as Map<String, dynamic>?,
        status: SparkStatus.pending,
      );

      _currentSpark = spark;
      _activeSparkController.add(spark);

      // Envoyer notification push à l'autre utilisateur
      await _sendSparkNotification(targetUser);

      debugPrint('✨ Spark créé: $sparkId');
      return spark;
    } catch (e) {
      debugPrint('❌ Erreur création Spark: $e');
      return null;
    }
  }

  /// Envoyer une notification push pour un nouveau Spark
  Future<void> _sendSparkNotification(User targetUser) async {
    try {
      final currentUser = UserModel().user;

      await _notificationsApi.sendPushNotification(
        nTitle: '✨ A Spark is forming!',
        nBody: 'Someone compatible is nearby. Open the app to reveal them!',
        nType: 'spark',
        nSenderId: currentUser.userId,
        nUserDeviceToken: targetUser.userDeviceToken,
      );

      // Sauvegarder la notification dans la base
      await _notificationsApi.saveNotification(
        nReceiverId: targetUser.userId,
        nType: 'spark',
        nMessage: 'Someone compatible crossed your path!',
      );

      // Notifier aussi l'utilisateur actuel (exigence: notification aux deux)
      await _notificationsApi.saveNotification(
        nReceiverId: currentUser.userId,
        nType: 'spark',
        nMessage: 'A person nearby matches with you.',
      );

      if (currentUser.userDeviceToken.isNotEmpty) {
        await _notificationsApi.sendPushNotification(
          nTitle: '✨ Proximity Spark',
          nBody: 'A person nearby matches with you.',
          nType: 'spark',
          nSenderId: targetUser.userId,
          nUserDeviceToken: currentUser.userDeviceToken,
        );
      }

      debugPrint('🔔 Notification Spark envoyée à ${targetUser.userFullname}');
    } catch (e) {
      debugPrint('❌ Erreur envoi notification Spark: $e');
    }
  }

  /// Récupérer les Sparks actifs pour l'utilisateur actuel
  Future<List<Spark>> getActiveSparks() async {
    try {
      final currentUserId = UserModel().user.userId;
      final now = Timestamp.now();

      // Chercher les sparks où l'utilisateur est impliqué et non expirés
      final query1 = await _firestore
          .collection(C_SPARKS)
          .where('user1_id', isEqualTo: currentUserId)
          .where('expires_at', isGreaterThan: now)
          .get();

      final query2 = await _firestore
          .collection(C_SPARKS)
          .where('user2_id', isEqualTo: currentUserId)
          .where('expires_at', isGreaterThan: now)
          .get();

      final List<Spark> sparks = [];
      final allDocs = [...query1.docs, ...query2.docs];

      for (final doc in allDocs) {
        final data = doc.data();
        final otherUserId = data['user1_id'] == currentUserId
            ? data['user2_id']
            : data['user1_id'];

        // Charger l'utilisateur
        final userDoc = await _firestore
            .collection(C_USERS)
            .doc(otherUserId)
            .get();
        if (userDoc.exists) {
          final user = User.fromDocument(userDoc.data()!);
          sparks.add(Spark.fromDocument(data, user));
        }
      }

      if (sparks.isNotEmpty) {
        _currentSpark = sparks.first;
        _activeSparkController.add(_currentSpark);
      }

      return sparks;
    } catch (e) {
      debugPrint('❌ Erreur récupération Sparks: $e');
      return [];
    }
  }

  /// Révéler un Spark (l'utilisateur a cliqué sur "Reveal Spark")
  Future<bool> revealSpark(String sparkId) async {
    try {
      final currentUserId = UserModel().user.userId;
      final sparkDoc = await _firestore.collection(C_SPARKS).doc(sparkId).get();

      if (!sparkDoc.exists) return false;

      final data = sparkDoc.data()!;
      final statusField = data['user1_id'] == currentUserId
          ? 'user1_status'
          : 'user2_status';

      await _firestore.collection(C_SPARKS).doc(sparkId).update({
        statusField: 'revealed',
      });

      if (_currentSpark?.sparkId == sparkId) {
        _currentSpark = _currentSpark!.copyWith(status: SparkStatus.revealed);
        _activeSparkController.add(_currentSpark);
      }

      debugPrint('👁️ Spark révélé: $sparkId');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur révélation Spark: $e');
      return false;
    }
  }

  /// Aimer un Spark
  Future<bool> likeSpark(String sparkId) async {
    try {
      final currentUserId = UserModel().user.userId;
      final sparkDoc = await _firestore.collection(C_SPARKS).doc(sparkId).get();

      if (!sparkDoc.exists) return false;

      final data = sparkDoc.data()!;
      final isUser1 = data['user1_id'] == currentUserId;
      final statusField = isUser1 ? 'user1_status' : 'user2_status';
      final otherStatusField = isUser1 ? 'user2_status' : 'user1_status';
      final otherUserId = isUser1 ? data['user2_id'] : data['user1_id'];

      // Mettre à jour le statut
      await _firestore.collection(C_SPARKS).doc(sparkId).update({
        statusField: 'liked',
      });

      // Vérifier si l'autre a aussi aimé → Match!
      final otherStatus = data[otherStatusField];
      if (otherStatus == 'liked') {
        await _createMatch(sparkId, currentUserId, otherUserId);
      } else {
        // Notifier l'autre utilisateur
        final otherUserDoc = await _firestore
            .collection(C_USERS)
            .doc(otherUserId)
            .get();
        if (otherUserDoc.exists) {
          final otherUser = User.fromDocument(otherUserDoc.data()!);
          await _notificationsApi.sendPushNotification(
            nTitle: '💫 Your Spark liked you!',
            nBody:
                'Someone you crossed paths with is interested. Like them back to match!',
            nType: 'spark_like',
            nSenderId: currentUserId,
            nUserDeviceToken: otherUser.userDeviceToken,
          );
        }
      }

      if (_currentSpark?.sparkId == sparkId) {
        _currentSpark = _currentSpark!.copyWith(status: SparkStatus.liked);
        _activeSparkController.add(_currentSpark);
      }

      debugPrint('❤️ Spark aimé: $sparkId');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur like Spark: $e');
      return false;
    }
  }

  /// Créer un match quand les deux utilisateurs se sont aimés
  Future<void> _createMatch(
    String sparkId,
    String user1Id,
    String user2Id,
  ) async {
    try {
      // Mettre à jour le spark
      await _firestore.collection(C_SPARKS).doc(sparkId).update({
        'status': SparkStatus.matched.value,
      });

      // Créer le match dans la collection Matches
      await _firestore
          .collection(C_CONNECTIONS)
          .doc(user1Id)
          .collection(C_MATCHES)
          .doc(user2Id)
          .set({
            TIMESTAMP: FieldValue.serverTimestamp(),
            'spark_id': sparkId,
            'match_type': 'spark',
          });

      await _firestore
          .collection(C_CONNECTIONS)
          .doc(user2Id)
          .collection(C_MATCHES)
          .doc(user1Id)
          .set({
            TIMESTAMP: FieldValue.serverTimestamp(),
            'spark_id': sparkId,
            'match_type': 'spark',
          });

      // Notifier les deux utilisateurs
      final user1Doc = await _firestore.collection(C_USERS).doc(user1Id).get();
      final user2Doc = await _firestore.collection(C_USERS).doc(user2Id).get();

      if (user1Doc.exists && user2Doc.exists) {
        final user1 = User.fromDocument(user1Doc.data()!);
        final user2 = User.fromDocument(user2Doc.data()!);

        await _notificationsApi.sendPushNotification(
          nTitle: '🎉 It\'s a Match!',
          nBody:
              'You and ${user2.userFullname.split(' ')[0]} both sparked! Start the conversation.',
          nType: 'spark_match',
          nSenderId: user2Id,
          nUserDeviceToken: user1.userDeviceToken,
        );

        await _notificationsApi.sendPushNotification(
          nTitle: '🎉 It\'s a Match!',
          nBody:
              'You and ${user1.userFullname.split(' ')[0]} both sparked! Start the conversation.',
          nType: 'spark_match',
          nSenderId: user1Id,
          nUserDeviceToken: user2.userDeviceToken,
        );
      }

      if (_currentSpark?.sparkId == sparkId) {
        _currentSpark = _currentSpark!.copyWith(status: SparkStatus.matched);
        _activeSparkController.add(_currentSpark);
      }

      debugPrint('🎉 Match créé depuis Spark: $sparkId');
    } catch (e) {
      debugPrint('❌ Erreur création match: $e');
    }
  }

  /// Refuser un Spark
  Future<bool> declineSpark(String sparkId) async {
    try {
      final currentUserId = UserModel().user.userId;
      final sparkDoc = await _firestore.collection(C_SPARKS).doc(sparkId).get();

      if (!sparkDoc.exists) return false;

      final data = sparkDoc.data()!;
      final statusField = data['user1_id'] == currentUserId
          ? 'user1_status'
          : 'user2_status';

      await _firestore.collection(C_SPARKS).doc(sparkId).update({
        statusField: 'declined',
      });

      if (_currentSpark?.sparkId == sparkId) {
        _currentSpark = null;
        _activeSparkController.add(null);
      }

      debugPrint('❌ Spark refusé: $sparkId');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur refus Spark: $e');
      return false;
    }
  }

  /// Générer les détails de compatibilité entre deux utilisateurs
  Map<String, dynamic> _generateCompatibilityDetails(User user1, User user2) {
    final details = <String, dynamic>{};

    // Valeurs alignées
    double valuesScore = 0.0;
    if (user1.religion == user2.religion && user1.religion.isNotEmpty) {
      valuesScore += 0.5;
    }
    if (user1.education == user2.education && user1.education.isNotEmpty) {
      valuesScore += 0.5;
    }
    details['values_alignment'] = {
      'score': valuesScore,
      'title': 'Values Alignment',
      'icon_type': 'star',
    };

    // Style de communication (basé sur les hobbies communs)
    final commonHobbies = user1.hobbies
        .where((h) => user2.hobbies.contains(h))
        .toList();
    final communicationScore =
        commonHobbies.length / (user1.hobbies.length.clamp(1, 10));
    details['communication_style'] = {
      'score': communicationScore.clamp(0.0, 1.0),
      'title': 'Communication Style',
      'icon_type': 'chat',
      'common_interests': commonHobbies,
    };

    // Rythme & Énergie (basé sur les langues communes et animaux)
    final commonLanguages = user1.languages
        .where((l) => user2.languages.contains(l))
        .toList();
    final commonPets = user1.pets.where((p) => user2.pets.contains(p)).toList();
    final paceScore = (commonLanguages.length + commonPets.length) / 4.0;
    details['pace_energy'] = {
      'score': paceScore.clamp(0.0, 1.0),
      'title': 'Pace & Energy',
      'icon_type': 'energy',
    };

    // Raisons du Spark
    final reasons = <String>[];
    if (commonHobbies.isNotEmpty) {
      reasons.add('You both enjoy ${commonHobbies.take(2).join(' and ')}');
    }
    if (commonLanguages.isNotEmpty) {
      reasons.add('You both speak ${commonLanguages.first}');
    }
    if (user1.religion == user2.religion && user1.religion.isNotEmpty) {
      reasons.add('Shared spiritual values');
    }
    details['spark_reasons'] = reasons;

    return details;
  }

  /// Générer des suggestions de messages pour démarrer la conversation
  List<String> generateConversationStarters(Spark spark) {
    final starters = <String>[];
    final details = spark.compatibilityDetails;

    if (details != null) {
      final commonInterests =
          details['communication_style']?['common_interests'] as List<dynamic>?;
      if (commonInterests != null && commonInterests.isNotEmpty) {
        starters.add(
          'You both love ${commonInterests.first}. What\'s your favorite way to enjoy it?',
        );
      }

      final reasons = details['spark_reasons'] as List<dynamic>?;
      if (reasons != null && reasons.isNotEmpty) {
        starters.add(
          'I noticed we ${reasons.first.toString().toLowerCase()}. Tell me more about that!',
        );
      }
    }

    starters.add('We crossed paths at a cozy spot. What brought you there?');
    starters.add('The spark brought us together. What are you hoping to find?');

    return starters;
  }

  /// Nettoyer les sparks expirés
  Future<void> cleanupExpiredSparks() async {
    try {
      final now = Timestamp.now();
      final expiredSparks = await _firestore
          .collection(C_SPARKS)
          .where('expires_at', isLessThan: now)
          .where('status', isEqualTo: SparkStatus.pending.value)
          .get();

      for (final doc in expiredSparks.docs) {
        await doc.reference.update({'status': SparkStatus.expired.value});
      }

      debugPrint('🧹 ${expiredSparks.docs.length} sparks expirés nettoyés');
    } catch (e) {
      debugPrint('❌ Erreur nettoyage sparks: $e');
    }
  }

  /// Écouter les sparks en temps réel
  Stream<List<Spark>> watchActiveSparks() {
    final currentUserId = UserModel().user.userId;

    return _firestore
        .collection(C_SPARKS)
        .where('expires_at', isGreaterThan: Timestamp.now())
        .snapshots()
        .asyncMap((snapshot) async {
          final sparks = <Spark>[];

          for (final doc in snapshot.docs) {
            final data = doc.data();

            // Vérifier si l'utilisateur est impliqué
            if (data['user1_id'] != currentUserId &&
                data['user2_id'] != currentUserId) {
              continue;
            }

            final otherUserId = data['user1_id'] == currentUserId
                ? data['user2_id']
                : data['user1_id'];

            final userDoc = await _firestore
                .collection(C_USERS)
                .doc(otherUserId)
                .get();
            if (userDoc.exists) {
              final user = User.fromDocument(userDoc.data()!);
              sparks.add(Spark.fromDocument(data, user));
            }
          }

          if (sparks.isNotEmpty && _currentSpark == null) {
            _currentSpark = sparks.first;
            _activeSparkController.add(_currentSpark);
          }

          return sparks;
        });
  }

  void dispose() {
    _activeSparkController.close();
  }
}
