import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:datecinity/api/notifications_api.dart';
import 'package:datecinity/constants/constants.dart';
import 'package:datecinity/models/user_model.dart';
import 'package:datecinity/datas/user.dart';
import 'package:datecinity/services/suggestions_service.dart';

/// Service de notifications intelligentes pour les suggestions de profils
///
/// Ce service gère:
/// - Notifications de nouveaux matches avec haute compatibilité
/// - Notifications personnalisées selon préférences utilisateur
/// - Système de déclencheurs intelligents (évite le spam)
/// - Intégration avec l'API de notifications existante
class SuggestionsNotificationsService {
  static final SuggestionsNotificationsService _instance =
      SuggestionsNotificationsService._internal();

  factory SuggestionsNotificationsService() => _instance;
  SuggestionsNotificationsService._internal();

  // Dependencies
  final NotificationsApi _notificationsApi = NotificationsApi();
  final SuggestionsService _suggestionsService = SuggestionsService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Configuration des notifications
  static const String NOTIFICATION_TYPE_NEW_MATCHES = 'new_matches';
  static const String NOTIFICATION_TYPE_HIGH_COMPATIBILITY =
      'high_compatibility';
  static const String NOTIFICATION_TYPE_NEARBY_MATCH = 'nearby_match';

  // Seuils et limites
  static const double HIGH_COMPATIBILITY_THRESHOLD = 0.8; // 80%
  static const double NEARBY_DISTANCE_THRESHOLD = 10.0; // 10km
  static const int MAX_NOTIFICATIONS_PER_DAY = 3;
  static const int NOTIFICATION_COOLDOWN_HOURS = 6;

  // Collection pour le tracking des notifications
  static const String COLLECTION_NOTIFICATION_TRACKING =
      'notifications_tracking';

  // ====================
  // POINT 5: SYSTÈME DE NOTIFICATIONS INTELLIGENTES
  // ====================

  /// Vérifier et envoyer des notifications pour nouveaux matches de haute compatibilité
  Future<void> checkAndNotifyHighCompatibilityMatches(String userId) async {
    try {
      debugPrint(
        '🔔 Vérification notifications haute compatibilité pour: $userId',
      );

      // 1. Vérifier si l'utilisateur peut recevoir des notifications
      if (!await _canSendNotification(
        userId,
        NOTIFICATION_TYPE_HIGH_COMPATIBILITY,
      )) {
        debugPrint('🔕 Cooldown actif ou limite atteinte pour: $userId');
        return;
      }

      // 2. Obtenir les suggestions avec haute compatibilité
      final List<User> suggestions = await _suggestionsService.getSuggestions(
        maxResults: 10,
        compatibilityThreshold: HIGH_COMPATIBILITY_THRESHOLD,
      );

      if (suggestions.isEmpty) {
        debugPrint('🔍 No high compatibility suggestions found');
        return;
      }

      // 3. Filtrer les nouveaux matches (non vus récemment)
      final List<User> newHighCompatibilityMatches = await _filterNewMatches(
        userId,
        suggestions,
      );

      if (newHighCompatibilityMatches.isEmpty) {
        debugPrint('🔍 Aucun nouveau match haute compatibilité');
        return;
      }

      // 4. Envoyer la notification
      await _sendHighCompatibilityNotification(
        userId,
        newHighCompatibilityMatches,
      );

      // 5. Tracker la notification envoyée
      await _trackNotificationSent(
        userId,
        NOTIFICATION_TYPE_HIGH_COMPATIBILITY,
      );

      debugPrint('✅ Notification haute compatibilité envoyée à: $userId');
    } catch (e) {
      debugPrint('❌ Erreur notification haute compatibilité: $e');
    }
  }

  /// Vérifier et envoyer des notifications pour nouveaux matches à proximité
  Future<void> checkAndNotifyNearbyMatches(String userId) async {
    try {
      debugPrint('🔔 Vérification notifications proximité pour: $userId');

      if (!await _canSendNotification(userId, NOTIFICATION_TYPE_NEARBY_MATCH)) {
        return;
      }

      final List<User> suggestions = await _suggestionsService.getSuggestions(
        maxResults: 15,
        compatibilityThreshold: 0.5, // Seuil plus bas pour proximité
      );

      final User currentUser = UserModel().user;

      // Filtrer par distance proche
      final List<User> nearbyMatches = suggestions.where((candidate) {
        final double distance = _suggestionsService.calculateDistance(
          currentUser.userGeoPoint,
          candidate.userGeoPoint,
        );
        return distance <= NEARBY_DISTANCE_THRESHOLD;
      }).toList();

      if (nearbyMatches.isEmpty) {
        debugPrint('🔍 No nearby matches found');
        return;
      }

      final List<User> newNearbyMatches = await _filterNewMatches(
        userId,
        nearbyMatches,
      );

      if (newNearbyMatches.isNotEmpty) {
        await _sendNearbyMatchNotification(userId, newNearbyMatches);
        await _trackNotificationSent(userId, NOTIFICATION_TYPE_NEARBY_MATCH);
        debugPrint('✅ Notification proximité envoyée à: $userId');
      }
    } catch (e) {
      debugPrint('❌ Erreur notification proximité: $e');
    }
  }

  /// Vérifier les préférences de notification de l'utilisateur
  Future<Map<String, bool>> getUserNotificationPreferences(
    String userId,
  ) async {
    try {
      final doc = await _firestore.collection(C_USERS).doc(userId).get();

      if (!doc.exists) {
        return _getDefaultNotificationPreferences();
      }

      final userData = doc.data()!;
      final settings = userData[USER_SETTINGS] as Map<String, dynamic>?;

      if (settings == null) {
        return _getDefaultNotificationPreferences();
      }

      return {
        'high_compatibility_matches':
            settings['notify_high_compatibility'] ?? true,
        'nearby_matches': settings['notify_nearby_matches'] ?? true,
        'new_matches': settings['notify_new_matches'] ?? true,
        'daily_suggestions': settings['notify_daily_suggestions'] ?? false,
      };
    } catch (e) {
      debugPrint('❌ Erreur récupération préférences notifications: $e');
      return _getDefaultNotificationPreferences();
    }
  }

  /// Mettre à jour les préférences de notification
  Future<void> updateNotificationPreferences(
    String userId,
    Map<String, bool> preferences,
  ) async {
    try {
      await _firestore.collection(C_USERS).doc(userId).update({
        '$USER_SETTINGS.notify_high_compatibility':
            preferences['high_compatibility_matches'],
        '$USER_SETTINGS.notify_nearby_matches': preferences['nearby_matches'],
        '$USER_SETTINGS.notify_new_matches': preferences['new_matches'],
        '$USER_SETTINGS.notify_daily_suggestions':
            preferences['daily_suggestions'],
      });

      debugPrint('✅ Préférences notifications mises à jour pour: $userId');
    } catch (e) {
      debugPrint('❌ Erreur mise à jour préférences: $e');
    }
  }

  // ====================
  // MÉTHODES PRIVÉES
  // ====================

  /// Vérifier si on peut envoyer une notification à l'utilisateur
  Future<bool> _canSendNotification(
    String userId,
    String notificationType,
  ) async {
    try {
      // Vérifier les préférences utilisateur
      final preferences = await getUserNotificationPreferences(userId);

      bool canSend = false;
      switch (notificationType) {
        case NOTIFICATION_TYPE_HIGH_COMPATIBILITY:
          canSend = preferences['high_compatibility_matches'] ?? true;
          break;
        case NOTIFICATION_TYPE_NEARBY_MATCH:
          canSend = preferences['nearby_matches'] ?? true;
          break;
        case NOTIFICATION_TYPE_NEW_MATCHES:
          canSend = preferences['new_matches'] ?? true;
          break;
      }

      if (!canSend) {
        debugPrint('🔕 Notifications désactivées pour $notificationType');
        return false;
      }

      // Vérifier le cooldown et la limite quotidienne
      final tracking = await _getNotificationTracking(userId);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Vérifier limite quotidienne
      final todayNotifications = tracking.where((notification) {
        final notificationDate = notification['timestamp'].toDate();
        final notificationDay = DateTime(
          notificationDate.year,
          notificationDate.month,
          notificationDate.day,
        );
        return notificationDay == today;
      }).length;

      if (todayNotifications >= MAX_NOTIFICATIONS_PER_DAY) {
        debugPrint(
          '🔕 Limite quotidienne atteinte: $todayNotifications/$MAX_NOTIFICATIONS_PER_DAY',
        );
        return false;
      }

      // Vérifier cooldown pour ce type de notification
      final lastNotificationOfType = tracking
          .where((n) => n['type'] == notificationType)
          .map((n) => n['timestamp'].toDate())
          .fold<DateTime?>(null, (latest, current) {
            if (latest == null) return current;
            return current.isAfter(latest) ? current : latest;
          });

      if (lastNotificationOfType != null) {
        final timeSinceLastNotification = now.difference(
          lastNotificationOfType,
        );
        if (timeSinceLastNotification.inHours < NOTIFICATION_COOLDOWN_HOURS) {
          debugPrint(
            '🔕 Cooldown actif: ${timeSinceLastNotification.inHours}h < ${NOTIFICATION_COOLDOWN_HOURS}h',
          );
          return false;
        }
      }

      return true;
    } catch (e) {
      debugPrint('❌ Erreur vérification notification: $e');
      return false;
    }
  }

  /// Filtrer les nouveaux matches (pas vus récemment)
  Future<List<User>> _filterNewMatches(
    String userId,
    List<User> candidates,
  ) async {
    try {
      // Récupérer les interactions récentes (likes, visites) pour éviter les doublons
      final recentInteractions = await _getRecentInteractions(userId);

      return candidates.where((candidate) {
        return !recentInteractions.contains(candidate.userId);
      }).toList();
    } catch (e) {
      debugPrint('❌ Erreur filtrage nouveaux matches: $e');
      return candidates;
    }
  }

  /// Envoyer notification pour matches haute compatibilité
  Future<void> _sendHighCompatibilityNotification(
    String userId,
    List<User> matches,
  ) async {
    final int matchCount = matches.length;
    final String title =
        '🎯 Nouveau${matchCount > 1 ? 's' : ''} match${matchCount > 1 ? 's' : ''} compatible${matchCount > 1 ? 's' : ''}!';

    String message;
    if (matchCount == 1) {
      message =
          '${matches.first.userFullname} a une compatibilité élevée avec vous!';
    } else {
      message =
          '$matchCount nouvelles personnes très compatibles vous attendent!';
    }

    // Sauvegarder notification en base
    await _notificationsApi.saveNotification(
      nReceiverId: userId,
      nType: NOTIFICATION_TYPE_HIGH_COMPATIBILITY,
      nMessage: message,
    );

    // Envoyer push notification si l'utilisateur a un token
    final userDoc = await _firestore.collection(C_USERS).doc(userId).get();
    final deviceToken = userDoc.data()?[USER_DEVICE_TOKEN];

    if (deviceToken != null && deviceToken.isNotEmpty) {
      await _notificationsApi.sendPushNotification(
        nTitle: title,
        nBody: message,
        nType: NOTIFICATION_TYPE_HIGH_COMPATIBILITY,
        nSenderId: 'system',
        nUserDeviceToken: deviceToken,
      );
    }
  }

  /// Envoyer notification pour matches à proximité
  Future<void> _sendNearbyMatchNotification(
    String userId,
    List<User> matches,
  ) async {
    final int matchCount = matches.length;
    final String title = '📍 Match${matchCount > 1 ? 's' : ''} à proximité!';

    String message;
    if (matchCount == 1) {
      message = '${matches.first.userFullname} se trouve près de vous!';
    } else {
      message = '$matchCount personnes intéressantes dans votre région!';
    }

    await _notificationsApi.saveNotification(
      nReceiverId: userId,
      nType: NOTIFICATION_TYPE_NEARBY_MATCH,
      nMessage: message,
    );

    final userDoc = await _firestore.collection(C_USERS).doc(userId).get();
    final deviceToken = userDoc.data()?[USER_DEVICE_TOKEN];

    if (deviceToken != null && deviceToken.isNotEmpty) {
      await _notificationsApi.sendPushNotification(
        nTitle: title,
        nBody: message,
        nType: NOTIFICATION_TYPE_NEARBY_MATCH,
        nSenderId: 'system',
        nUserDeviceToken: deviceToken,
      );
    }
  }

  /// Tracker une notification envoyée
  Future<void> _trackNotificationSent(
    String userId,
    String notificationType,
  ) async {
    await _firestore.collection(COLLECTION_NOTIFICATION_TRACKING).add({
      'user_id': userId,
      'type': notificationType,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Récupérer l'historique des notifications
  Future<List<Map<String, dynamic>>> _getNotificationTracking(
    String userId,
  ) async {
    final snapshot = await _firestore
        .collection(COLLECTION_NOTIFICATION_TRACKING)
        .where('user_id', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  /// Récupérer les interactions récentes pour éviter les doublons
  Future<List<String>> _getRecentInteractions(String userId) async {
    final List<String> interactions = [];

    try {
      // Récupérer les likes récents (30 derniers jours)
      final likesSnapshot = await _firestore
          .collection(C_LIKES)
          .where(LIKED_BY_USER_ID, isEqualTo: userId)
          .where(
            TIMESTAMP,
            isGreaterThan: Timestamp.fromDate(
              DateTime.now().subtract(Duration(days: 30)),
            ),
          )
          .get();

      interactions.addAll(
        likesSnapshot.docs.map((doc) => doc.data()[LIKED_USER_ID] as String),
      );

      // Récupérer les visites récentes (7 derniers jours)
      final visitsSnapshot = await _firestore
          .collection(C_VISITS)
          .where(VISITED_BY_USER_ID, isEqualTo: userId)
          .where(
            TIMESTAMP,
            isGreaterThan: Timestamp.fromDate(
              DateTime.now().subtract(Duration(days: 7)),
            ),
          )
          .get();

      interactions.addAll(
        visitsSnapshot.docs.map((doc) => doc.data()[VISITED_USER_ID] as String),
      );
    } catch (e) {
      debugPrint('❌ Erreur récupération interactions: $e');
    }

    return interactions;
  }

  /// Préférences par défaut
  Map<String, bool> _getDefaultNotificationPreferences() {
    return {
      'high_compatibility_matches': true,
      'nearby_matches': true,
      'new_matches': true,
      'daily_suggestions': false,
    };
  }

  // ====================
  // MÉTHODES PUBLIQUES POUR TRIGGERS
  // ====================

  /// Déclencheur à appeler quand un utilisateur se connecte
  Future<void> onUserLogin(String userId) async {
    debugPrint('🔔 Déclencheur connexion utilisateur: $userId');

    // Vérifier les matches haute compatibilité
    await checkAndNotifyHighCompatibilityMatches(userId);

    // Petit délai pour éviter de surcharger
    await Future.delayed(Duration(seconds: 2));

    // Vérifier les matches à proximité
    await checkAndNotifyNearbyMatches(userId);
  }

  /// Déclencheur à appeler quand la position de l'utilisateur change
  Future<void> onLocationUpdate(String userId) async {
    debugPrint('🔔 Déclencheur mise à jour position: $userId');

    // Attendre un peu pour que la position soit mise à jour en base
    await Future.delayed(Duration(seconds: 5));

    // Vérifier les nouveaux matches à proximité
    await checkAndNotifyNearbyMatches(userId);
  }

  /// Déclencheur pour notification quotidienne (à appeler via cron job)
  Future<void> onDailyCheck(String userId) async {
    debugPrint('🔔 Déclencheur vérification quotidienne: $userId');

    final preferences = await getUserNotificationPreferences(userId);

    if (preferences['daily_suggestions'] == true) {
      await checkAndNotifyHighCompatibilityMatches(userId);
    }
  }
}
