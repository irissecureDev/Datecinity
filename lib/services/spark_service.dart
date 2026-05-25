import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:datecinity/api/notifications_api.dart';
import 'package:datecinity/constants/constants.dart';
import 'package:datecinity/datas/user.dart';
import 'package:datecinity/models/spark.dart';
import 'package:datecinity/models/user_model.dart';

enum SparkActionResult { waitingOther, mutualMatch, declined, timeout, failed }

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
  static const String C_SPARK_EVENTS = 'SparkEvents';

  // Configuration
  static const int SPARK_DURATION_MINUTES = 10;
  static const double MIN_COMPATIBILITY_FOR_SPARK = 0.6; // 60%
  static const double MAX_DISTANCE_FOR_SPARK = 0.5; // 500m

  // State machine values
  static const String STATE_DETECTED = 'detected';
  static const String STATE_REVEALED = 'revealed';
  static const String STATE_USER_INTERESTED = 'user_interested';
  static const String STATE_WAITING_OTHER = 'waiting_other';
  static const String STATE_MUTUAL_MATCH = 'mutual_match';
  static const String STATE_DECLINED = 'declined';
  static const String STATE_TIMEOUT = 'timeout';
  static const String STATE_RESET = 'reset';

  // Stream controllers
  final StreamController<Spark?> _activeSparkController =
      StreamController<Spark?>.broadcast();
  Stream<Spark?> get activeSparkStream => _activeSparkController.stream;

  Spark? _currentSpark;
  Spark? get currentSpark => _currentSpark;

  String _buildPairKey(String userA, String userB) {
    final pair = [userA, userB]..sort();
    return '${pair[0]}_${pair[1]}';
  }

  String _sparkIdForUsers(String userA, String userB) {
    return 'spark_${_buildPairKey(userA, userB)}';
  }

  bool _isTerminalState(String? state) {
    return state == STATE_MUTUAL_MATCH ||
        state == STATE_DECLINED ||
        state == STATE_TIMEOUT ||
        state == STATE_RESET;
  }

  DateTime? _extractExpiryAt(Map<String, dynamic> data) {
    final ts = data['expires_at'] as Timestamp?;
    if (ts != null) {
      return ts.toDate();
    }

    final legacyTs = data['expiryAt'] as Timestamp?;
    return legacyTs?.toDate();
  }

  String _myStatusField(Map<String, dynamic> data, String currentUserId) {
    return data['user1_id'] == currentUserId ? 'user1_status' : 'user2_status';
  }

  String _otherStatusField(Map<String, dynamic> data, String currentUserId) {
    return data['user1_id'] == currentUserId ? 'user2_status' : 'user1_status';
  }

  String _otherUserId(Map<String, dynamic> data, String currentUserId) {
    return data['user1_id'] == currentUserId
        ? data['user2_id']
        : data['user1_id'];
  }

  /// Créer un nouveau Spark quand deux utilisateurs sont proches
  Future<Spark?> createSpark({
    required User targetUser,
    required double distance,
    required double compatibility,
    Map<String, dynamic>? compatibilityDetails,
  }) async {
    try {
      final currentUser = UserModel().user;
      final sparkId = _sparkIdForUsers(currentUser.userId, targetUser.userId);
      final now = DateTime.now();
      final expiresAt = now.add(
        const Duration(minutes: SPARK_DURATION_MINUTES),
      );
      final sparkRef = _firestore.collection(C_SPARKS).doc(sparkId);

      bool created = false;

      await _firestore.runTransaction((tx) async {
        final snapshot = await tx.get(sparkRef);

        if (snapshot.exists) {
          final existing = snapshot.data()!;
          final currentState =
              (existing['flow_state'] as String?) ??
              (existing['status'] as String?) ??
              STATE_DETECTED;
          final expiresAtTs = existing['expires_at'] as Timestamp?;
          final isExpired = expiresAtTs == null
              ? true
              : expiresAtTs.toDate().isBefore(now);

          if (!isExpired && !_isTerminalState(currentState)) {
            tx.update(sparkRef, {
              'distance':
                  (existing['distance'] as num?)?.toDouble() ?? distance,
              'compatibility':
                  ((existing['compatibility'] as num?)?.toDouble() ??
                          compatibility)
                      .clamp(compatibility, 1.0),
              'updated_at': FieldValue.serverTimestamp(),
            });
            return;
          }
        }

        created = true;
        tx.set(sparkRef, {
          'spark_id': sparkId,
          'pair_key': _buildPairKey(currentUser.userId, targetUser.userId),
          'user1_id': currentUser.userId,
          'user2_id': targetUser.userId,
          'detected_at': Timestamp.fromDate(now),
          'expires_at': Timestamp.fromDate(expiresAt),
          'expiryAt': Timestamp.fromDate(expiresAt),
          'distance': distance,
          'compatibility': compatibility,
          'compatibility_details':
              compatibilityDetails ??
              _generateCompatibilityDetails(currentUser, targetUser),
          'status': SparkStatus.pending.value,
          'flow_state': STATE_DETECTED,
          'user1_status': STATE_DETECTED,
          'user2_status': STATE_DETECTED,
          'match_notification_sent': false,
          'decline_notification_sent': false,
          'detected_at_server': FieldValue.serverTimestamp(),
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });

      final saved = await sparkRef.get();
      if (!saved.exists) {
        debugPrint('❌ Spark not found after transaction: $sparkId');
        return null;
      }

      final sparkData = saved.data()!;

      // Créer l'objet Spark pour l'utilisateur actuel
      final spark = Spark(
        sparkId: sparkId,
        user: targetUser,
        detectedAt: (sparkData['detected_at'] as Timestamp?)?.toDate() ?? now,
        expiresAt:
            (sparkData['expires_at'] as Timestamp?)?.toDate() ?? expiresAt,
        distance: ((sparkData['distance'] as num?)?.toDouble() ?? distance),
        compatibility:
            ((sparkData['compatibility'] as num?)?.toDouble() ?? compatibility),
        compatibilityDetails:
            sparkData['compatibility_details'] as Map<String, dynamic>?,
        status: SparkStatus.pending,
      );

      _currentSpark = spark;
      _activeSparkController.add(spark);

      // Envoyer notification push à l'autre utilisateur uniquement à la création
      if (created) {
        await _sendSparkNotification(targetUser);
        await trackStateEvent(
          sparkId: sparkId,
          eventName: 'spark_created',
          metadata: {
            'distance': spark.distance,
            'compatibility': spark.compatibility,
          },
        );
      }

      debugPrint('✨ Spark créé: $sparkId');
      return spark;
    } catch (e) {
      debugPrint('❌ Erreur création Spark: $e');
      return null;
    }
  }

  Future<void> trackStateEvent({
    required String sparkId,
    required String eventName,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _firestore.collection(C_SPARK_EVENTS).add({
        'spark_id': sparkId,
        'event_name': eventName,
        'user_id': UserModel().user.userId,
        'metadata': metadata ?? <String, dynamic>{},
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('⚠️ Spark event tracking failed: $e');
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
      final sparkRef = _firestore.collection(C_SPARKS).doc(sparkId);

      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(sparkRef);
        if (!snap.exists) return;

        final data = snap.data()!;
        final statusField = _myStatusField(data, currentUserId);
        final currentState = (data['flow_state'] as String?) ?? STATE_DETECTED;

        if (_isTerminalState(currentState)) {
          return;
        }

        tx.update(sparkRef, {
          statusField: STATE_REVEALED,
          'flow_state': STATE_REVEALED,
          'updated_at': FieldValue.serverTimestamp(),
        });
      });

      if (_currentSpark?.sparkId == sparkId) {
        _currentSpark = _currentSpark!.copyWith(status: SparkStatus.revealed);
        _activeSparkController.add(_currentSpark);
      }

      await trackStateEvent(sparkId: sparkId, eventName: 'spark_revealed');

      debugPrint('👁️ Spark révélé: $sparkId');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur révélation Spark: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getSparkDocument(String sparkId) async {
    try {
      final doc = await _firestore.collection(C_SPARKS).doc(sparkId).get();
      return doc.data();
    } catch (e) {
      debugPrint('❌ Error loading spark document: $e');
      return null;
    }
  }

  Stream<Map<String, dynamic>?> watchSparkDocument(String sparkId) {
    return _firestore.collection(C_SPARKS).doc(sparkId).snapshots().map((doc) {
      return doc.data();
    });
  }

  /// Aimer un Spark
  Future<bool> likeSpark(String sparkId) async {
    final result = await submitInterest(sparkId);
    return result != SparkActionResult.failed;
  }

  Future<SparkActionResult> submitInterest(String sparkId) async {
    try {
      final currentUserId = UserModel().user.userId;
      final sparkRef = _firestore.collection(C_SPARKS).doc(sparkId);

      SparkActionResult actionResult = SparkActionResult.failed;
      String? otherUserId;
      bool shouldNotifyOtherUser = false;

      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(sparkRef);
        if (!snap.exists) {
          actionResult = SparkActionResult.failed;
          return;
        }

        final data = snap.data()!;
        otherUserId = _otherUserId(data, currentUserId);
        final statusField = _myStatusField(data, currentUserId);
        final otherStatusField = _otherStatusField(data, currentUserId);
        final myStatus = (data[statusField] as String?) ?? STATE_DETECTED;
        final otherStatus =
            (data[otherStatusField] as String?) ?? STATE_DETECTED;

        final expiresAt = _extractExpiryAt(data);
        final isTimedOut =
            expiresAt == null || expiresAt.isBefore(DateTime.now());

        if (isTimedOut) {
          tx.update(sparkRef, {
            'status': SparkStatus.expired.value,
            'flow_state': STATE_TIMEOUT,
            'updated_at': FieldValue.serverTimestamp(),
          });
          actionResult = SparkActionResult.timeout;
          return;
        }

        if (otherStatus == STATE_DECLINED) {
          tx.update(sparkRef, {
            'flow_state': STATE_DECLINED,
            'updated_at': FieldValue.serverTimestamp(),
          });
          actionResult = SparkActionResult.declined;
          return;
        }

        if (myStatus == STATE_USER_INTERESTED &&
            otherStatus != STATE_USER_INTERESTED) {
          actionResult = SparkActionResult.waitingOther;
          return;
        }

        if (otherStatus == STATE_USER_INTERESTED) {
          tx.update(sparkRef, {
            statusField: STATE_USER_INTERESTED,
            'status': SparkStatus.matched.value,
            'flow_state': STATE_MUTUAL_MATCH,
            'updated_at': FieldValue.serverTimestamp(),
          });
          actionResult = SparkActionResult.mutualMatch;
          return;
        }

        tx.update(sparkRef, {
          statusField: STATE_USER_INTERESTED,
          'status': SparkStatus.liked.value,
          'flow_state': STATE_USER_INTERESTED,
          '${statusField}_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
        shouldNotifyOtherUser = true;
        actionResult = SparkActionResult.waitingOther;
      });

      if (actionResult == SparkActionResult.mutualMatch &&
          otherUserId != null) {
        await _createMatch(sparkId, currentUserId, otherUserId!);
        await trackStateEvent(sparkId: sparkId, eventName: 'mutual_match');
      }

      if (actionResult == SparkActionResult.waitingOther &&
          otherUserId != null &&
          shouldNotifyOtherUser) {
        final otherUserDoc = await _firestore
            .collection(C_USERS)
            .doc(otherUserId)
            .get();

        if (otherUserDoc.exists) {
          final otherUser = User.fromDocument(otherUserDoc.data()!);
          await _notificationsApi.sendPushNotification(
            nTitle: '💫 Someone is interested',
            nBody: 'A nearby spark is waiting for your response.',
            nType: 'spark_like',
            nSenderId: currentUserId,
            nUserDeviceToken: otherUser.userDeviceToken,
          );
        }

        await _markWaitingOtherState(sparkId);
        await trackStateEvent(sparkId: sparkId, eventName: 'waiting_other');
      }

      if (_currentSpark?.sparkId == sparkId) {
        if (actionResult == SparkActionResult.mutualMatch) {
          _currentSpark = _currentSpark!.copyWith(status: SparkStatus.matched);
        } else if (actionResult == SparkActionResult.waitingOther) {
          _currentSpark = _currentSpark!.copyWith(status: SparkStatus.liked);
        }
        _activeSparkController.add(_currentSpark);
      }

      debugPrint('❤️ Spark interest processed: $sparkId => $actionResult');
      return actionResult;
    } catch (e) {
      debugPrint('❌ Erreur like Spark: $e');
      return SparkActionResult.failed;
    }
  }

  Future<void> _markWaitingOtherState(String sparkId) async {
    final sparkRef = _firestore.collection(C_SPARKS).doc(sparkId);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(sparkRef);
      if (!snap.exists) {
        return;
      }

      final data = snap.data()!;
      final currentState = (data['flow_state'] as String?) ?? STATE_DETECTED;
      if (_isTerminalState(currentState)) {
        return;
      }

      if (currentState == STATE_USER_INTERESTED) {
        tx.update(sparkRef, {
          'flow_state': STATE_WAITING_OTHER,
          'updated_at': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  /// Créer un match quand les deux utilisateurs se sont aimés
  Future<void> _createMatch(
    String sparkId,
    String user1Id,
    String user2Id,
  ) async {
    try {
      final sparkRef = _firestore.collection(C_SPARKS).doc(sparkId);
      final sparkSnapshot = await sparkRef.get();
      if (!sparkSnapshot.exists) return;

      final data = sparkSnapshot.data()!;
      final alreadyNotified = data['match_notification_sent'] == true;

      await sparkRef.set({
        'status': SparkStatus.matched.value,
        'flow_state': STATE_MUTUAL_MATCH,
        'match_notification_sent': true,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

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
          }, SetOptions(merge: true));

      await _firestore
          .collection(C_CONNECTIONS)
          .doc(user2Id)
          .collection(C_MATCHES)
          .doc(user1Id)
          .set({
            TIMESTAMP: FieldValue.serverTimestamp(),
            'spark_id': sparkId,
            'match_type': 'spark',
          }, SetOptions(merge: true));

      // Notifier les deux utilisateurs
      if (!alreadyNotified) {
        final user1Doc = await _firestore
            .collection(C_USERS)
            .doc(user1Id)
            .get();
        final user2Doc = await _firestore
            .collection(C_USERS)
            .doc(user2Id)
            .get();

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
      final sparkRef = _firestore.collection(C_SPARKS).doc(sparkId);

      String? otherUserId;
      bool shouldSendDeclineNotification = false;

      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(sparkRef);
        if (!snap.exists) return;

        final data = snap.data()!;
        final flowState = (data['flow_state'] as String?) ?? STATE_DETECTED;
        if (_isTerminalState(flowState)) {
          return;
        }

        final statusField = _myStatusField(data, currentUserId);
        otherUserId = _otherUserId(data, currentUserId);
        final alreadySent = data['decline_notification_sent'] == true;

        tx.update(sparkRef, {
          statusField: STATE_DECLINED,
          'status': SparkStatus.declined.value,
          'flow_state': STATE_DECLINED,
          'decline_notification_sent': true,
          'updated_at': FieldValue.serverTimestamp(),
        });

        shouldSendDeclineNotification = !alreadySent;
      });

      if (otherUserId != null && shouldSendDeclineNotification) {
        final otherUserDoc = await _firestore
            .collection(C_USERS)
            .doc(otherUserId)
            .get();

        if (otherUserDoc.exists) {
          final otherUser = User.fromDocument(otherUserDoc.data()!);
          await _notificationsApi.sendPushNotification(
            nTitle: 'Spark update',
            nBody: 'The other user declined this spark.',
            nType: 'spark_declined',
            nSenderId: currentUserId,
            nUserDeviceToken: otherUser.userDeviceToken,
          );

          await _notificationsApi.saveNotification(
            nReceiverId: otherUser.userId,
            nType: 'spark_declined',
            nMessage: 'The other user declined this spark.',
          );
        }
      }

      await trackStateEvent(sparkId: sparkId, eventName: 'declined');

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

  Future<bool> checkAndHandleTimeout(String sparkId) async {
    try {
      final sparkRef = _firestore.collection(C_SPARKS).doc(sparkId);
      bool didTimeout = false;

      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(sparkRef);
        if (!snap.exists) return;

        final data = snap.data()!;
        final state = (data['flow_state'] as String?) ?? STATE_DETECTED;
        if (_isTerminalState(state)) {
          return;
        }

        final expiresAt = _extractExpiryAt(data);
        final timedOut =
            expiresAt == null || expiresAt.isBefore(DateTime.now());
        if (!timedOut) {
          return;
        }

        tx.update(sparkRef, {
          'status': SparkStatus.expired.value,
          'flow_state': STATE_TIMEOUT,
          'updated_at': FieldValue.serverTimestamp(),
        });

        didTimeout = true;
      });

      if (didTimeout) {
        await trackStateEvent(sparkId: sparkId, eventName: 'timed_out');
      }

      return didTimeout;
    } catch (e) {
      debugPrint('❌ Erreur timeout Spark: $e');
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

  bool _looksLikeLegacyTestUserId(String userId) {
    final normalized = userId.toLowerCase();
    return normalized.startsWith('fake_') ||
        normalized.startsWith('debug_') ||
        normalized.contains('fake_proximity') ||
        normalized.contains('debug_user_');
  }

  bool _isLegacyTestSparkDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final docId = doc.id.toLowerCase();
    final sparkId = (data['spark_id'] ?? '').toString().toLowerCase();
    final user1Id = (data['user1_id'] ?? '').toString();
    final user2Id = (data['user2_id'] ?? '').toString();
    final pairKey = (data['pair_key'] ?? '').toString().toLowerCase();
    final isDebug = data['is_debug'] == true;

    return isDebug ||
        docId.startsWith('spark_debug_') ||
        sparkId.startsWith('spark_debug_') ||
        _looksLikeLegacyTestUserId(user1Id) ||
        _looksLikeLegacyTestUserId(user2Id) ||
        pairKey.contains('fake_') ||
        pairKey.contains('debug_');
  }

  Future<void> _deleteDocsBySparkIds({
    required String collection,
    required List<String> sparkIds,
  }) async {
    if (sparkIds.isEmpty) return;

    const chunkSize = 10;
    for (var index = 0; index < sparkIds.length; index += chunkSize) {
      final end = (index + chunkSize) > sparkIds.length
          ? sparkIds.length
          : (index + chunkSize);
      final chunk = sparkIds.sublist(index, end);

      final snapshot = await _firestore
          .collection(collection)
          .where('spark_id', whereIn: chunk)
          .get();

      if (snapshot.docs.isEmpty) continue;

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  Future<int> cleanupLegacyTestSparksForCurrentUser() async {
    try {
      final currentUserId = UserModel().user.userId;

      final q1 = await _firestore
          .collection(C_SPARKS)
          .where('user1_id', isEqualTo: currentUserId)
          .get();
      final q2 = await _firestore
          .collection(C_SPARKS)
          .where('user2_id', isEqualTo: currentUserId)
          .get();

      final mergedById = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{
        for (final doc in q1.docs) doc.id: doc,
        for (final doc in q2.docs) doc.id: doc,
      };

      final docsToDelete = mergedById.values
          .where(_isLegacyTestSparkDoc)
          .toList();

      if (docsToDelete.isEmpty) {
        return 0;
      }

      final sparkIds = docsToDelete
          .map((doc) => (doc.data()['spark_id'] ?? doc.id).toString())
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      final batch = _firestore.batch();
      for (final doc in docsToDelete) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      await _deleteDocsBySparkIds(
        collection: C_SPARK_HISTORY,
        sparkIds: sparkIds,
      );
      await _deleteDocsBySparkIds(
        collection: C_SPARK_EVENTS,
        sparkIds: sparkIds,
      );

      if (_currentSpark != null && sparkIds.contains(_currentSpark!.sparkId)) {
        _currentSpark = null;
        _activeSparkController.add(null);
      }

      debugPrint(
        '🧹 ${docsToDelete.length} legacy fake/debug sparks supprimés',
      );
      return docsToDelete.length;
    } catch (e) {
      debugPrint('❌ Erreur nettoyage legacy fake/debug sparks: $e');
      return 0;
    }
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
