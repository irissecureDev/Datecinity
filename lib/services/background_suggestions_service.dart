import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cheers/datas/user.dart';
import 'package:cheers/models/user_model.dart';
import 'package:cheers/services/suggestions_service.dart';
import 'package:cheers/services/suggestions_notifications_service.dart';

/// Service en arrière-plan pour les suggestions intelligentes
///
/// Fonctionnalités:
/// - Surveillance géolocalisation en continu
/// - Mise à jour automatique des suggestions
/// - Notifications push pour nouveaux profils compatibles
/// - Optimisation batterie avec stratégies adaptatives
/// - Gestion des états de l'application (foreground/background)
class BackgroundSuggestionsService {
  static const MethodChannel _channel = MethodChannel('background_suggestions');

  // Instances des services
  static final SuggestionsService _suggestionsService = SuggestionsService();
  static final SuggestionsNotificationsService _notificationsService =
      SuggestionsNotificationsService();

  // État du service
  static bool _isRunning = false;
  static bool _isInBackground = false;
  static Timer? _updateTimer;
  static StreamSubscription<Position>? _positionStream;

  // Configuration
  static const Duration _foregroundUpdateInterval = Duration(minutes: 5);
  static const Duration _backgroundUpdateInterval = Duration(minutes: 15);
  static const double _significantLocationChange = 100.0; // mètres

  // Cache et optimisation
  static Position? _lastKnownPosition;
  static DateTime? _lastUpdateTime;
  static List<User>? _cachedSuggestions;
  static final Map<String, DateTime> _notificationCooldowns = {};

  /// Initialiser le service en arrière-plan
  static Future<bool> initialize() async {
    try {
      debugPrint('🚀 BackgroundSuggestionsService: Initialisation...');

      // Vérifier les permissions de géolocalisation
      final permission = await _checkLocationPermissions();
      if (!permission) {
        debugPrint('❌ Permissions de géolocalisation non accordées');
        return false;
      }

      // Configurer le channel natif pour iOS/Android
      await _setupNativeChannel();

      // Démarrer la surveillance de position
      await _startLocationTracking();

      // Configurer les callbacks d'état de l'app
      _setupAppStateCallbacks();

      _isRunning = true;
      debugPrint('✅ BackgroundSuggestionsService: Initialisé avec succès');

      return true;
    } catch (e) {
      debugPrint('❌ Erreur initialisation BackgroundSuggestionsService: $e');
      return false;
    }
  }

  /// Arrêter le service en arrière-plan
  static Future<void> stop() async {
    try {
      debugPrint('🛑 BackgroundSuggestionsService: Arrêt...');

      _isRunning = false;

      // Arrêter les timers
      _updateTimer?.cancel();
      _updateTimer = null;

      // Arrêter la surveillance de position
      await _positionStream?.cancel();
      _positionStream = null;

      // Nettoyer le cache
      _cachedSuggestions = null;
      _notificationCooldowns.clear();

      debugPrint('✅ BackgroundSuggestionsService: Arrêté');
    } catch (e) {
      debugPrint('❌ Erreur arrêt BackgroundSuggestionsService: $e');
    }
  }

  /// Vérifier et demander les permissions de géolocalisation
  static Future<bool> _checkLocationPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('❌ Service de géolocalisation désactivé');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('❌ Permission de géolocalisation refusée');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('❌ Permission de géolocalisation refusée définitivement');
      return false;
    }

    // Demander la permission "Always" pour le background (iOS)
    if (permission == LocationPermission.whileInUse) {
      debugPrint(
        '⚠️ Permission "While in Use" - recommander "Always" pour le background',
      );
    }

    return true;
  }

  /// Configurer le channel natif pour le background
  static Future<void> _setupNativeChannel() async {
    try {
      _channel.setMethodCallHandler((call) async {
        switch (call.method) {
          case 'updateSuggestions':
            await _performBackgroundUpdate();
            break;
          case 'locationChanged':
            final lat = call.arguments['latitude'] as double;
            final lon = call.arguments['longitude'] as double;
            await _handleLocationChange(
              Position(
                latitude: lat,
                longitude: lon,
                timestamp: DateTime.now(),
                accuracy: 0,
                altitude: 0,
                heading: 0,
                speed: 0,
                speedAccuracy: 0,
                altitudeAccuracy: 0,
                headingAccuracy: 0,
              ),
            );
            break;
        }
      });

      // Enregistrer le service pour le background (iOS/Android)
      await _channel.invokeMethod('registerBackgroundService');
    } catch (e) {
      debugPrint('❌ Erreur configuration channel natif: $e');
    }
  }

  /// Démarrer la surveillance de géolocalisation
  static Future<void> _startLocationTracking() async {
    try {
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.medium, // Équilibre précision/batterie
        distanceFilter: 50, // Mise à jour tous les 50 mètres
      );

      _positionStream =
          Geolocator.getPositionStream(
            locationSettings: locationSettings,
          ).listen(
            _handleLocationChange,
            onError: (error) {
              debugPrint('❌ Erreur stream géolocalisation: $error');
            },
          );

      // Obtenir la position initiale
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        );
        await _handleLocationChange(position);
      } catch (e) {
        debugPrint('⚠️ Impossible d\'obtenir la position initiale: $e');
      }
    } catch (e) {
      debugPrint('❌ Erreur démarrage tracking géolocalisation: $e');
    }
  }

  /// Gérer les changements de position
  static Future<void> _handleLocationChange(Position newPosition) async {
    if (!_isRunning) return;

    try {
      debugPrint(
        '📍 Nouvelle position: ${newPosition.latitude}, ${newPosition.longitude}',
      );

      // Vérifier si le changement est significatif
      bool significantChange = false;
      if (_lastKnownPosition != null) {
        final distance = Geolocator.distanceBetween(
          _lastKnownPosition!.latitude,
          _lastKnownPosition!.longitude,
          newPosition.latitude,
          newPosition.longitude,
        );

        significantChange = distance >= _significantLocationChange;
        debugPrint(
          '📏 Distance depuis dernière position: ${distance.round()}m',
        );
      } else {
        significantChange = true; // Premier changement
      }

      _lastKnownPosition = newPosition;

      // Mettre à jour les suggestions si changement significatif
      if (significantChange) {
        await _scheduleUpdateSuggestions(immediate: true);
      }

      // Mettre à jour la position de l'utilisateur dans Firestore
      await _updateUserPosition(newPosition);
    } catch (e) {
      debugPrint('❌ Erreur gestion changement position: $e');
    }
  }

  /// Configurer les callbacks d'état de l'application
  static void _setupAppStateCallbacks() {
    // Utiliser WidgetsBinding pour détecter les changements d'état
    WidgetsBinding.instance.addObserver(_AppLifecycleObserver());
  }

  /// Planifier une mise à jour des suggestions
  static Future<void> _scheduleUpdateSuggestions({
    bool immediate = false,
  }) async {
    if (!_isRunning) return;

    try {
      // Annuler le timer précédent
      _updateTimer?.cancel();

      Duration interval;
      if (immediate) {
        interval = Duration.zero;
      } else if (_isInBackground) {
        interval = _backgroundUpdateInterval;
      } else {
        // En foreground, ajuster selon l'activité utilisateur
        interval = _foregroundUpdateInterval;
      }

      debugPrint(
        '⏰ Planification mise à jour suggestions dans ${interval.inMinutes}min',
      );

      _updateTimer = Timer(interval, () async {
        await _performBackgroundUpdate();

        // Re-planifier la prochaine mise à jour si en arrière-plan
        if (_isInBackground && _isRunning) {
          await _scheduleUpdateSuggestions();
        }
      });
    } catch (e) {
      debugPrint('❌ Erreur planification mise à jour: $e');
    }
  }

  /// Effectuer une mise à jour en arrière-plan
  static Future<void> _performBackgroundUpdate() async {
    if (!_isRunning || _lastKnownPosition == null) return;

    try {
      debugPrint('🔄 BackgroundSuggestionsService: Mise à jour en cours...');
      final startTime = DateTime.now();

      // Vérifier le cooldown global
      if (_lastUpdateTime != null) {
        final timeSinceLastUpdate = DateTime.now().difference(_lastUpdateTime!);
        if (timeSinceLastUpdate < Duration(minutes: 1)) {
          debugPrint('⏰ Cooldown actif, mise à jour ignorée');
          return;
        }
      }

      // Obtenir de nouvelles suggestions
      final suggestions = await _suggestionsService.getSuggestions(
        maxDistance: 50.0,
        compatibilityThreshold: 0.5, // Seuil plus élevé pour le background
        maxResults: 20, // Limite pour optimiser les performances
      );

      // Comparer avec le cache pour détecter les nouveaux profils
      final newSuggestions = _findNewSuggestions(suggestions);

      if (newSuggestions.isNotEmpty) {
        debugPrint(
          '🎯 ${newSuggestions.length} nouvelles suggestions trouvées',
        );

        // Déclencher les notifications pour les nouveaux profils hautement compatibles
        for (final user in newSuggestions) {
          await _handleNewSuggestion(user);
        }

        // Mettre à jour le cache
        _cachedSuggestions = suggestions;
      } else {
        debugPrint('📝 Aucune nouvelle suggestion');
      }

      _lastUpdateTime = DateTime.now();

      final duration = DateTime.now().difference(startTime);
      debugPrint('✅ Mise à jour terminée en ${duration.inMilliseconds}ms');
    } catch (e) {
      debugPrint('❌ Erreur mise à jour background: $e');
    }
  }

  /// Trouver les nouvelles suggestions par rapport au cache
  static List<User> _findNewSuggestions(List<User> currentSuggestions) {
    if (_cachedSuggestions == null) {
      return currentSuggestions;
    }

    final cachedIds = _cachedSuggestions!.map((u) => u.userId).toSet();
    return currentSuggestions
        .where((user) => !cachedIds.contains(user.userId))
        .toList();
  }

  /// Gérer une nouvelle suggestion
  static Future<void> _handleNewSuggestion(User newUser) async {
    try {
      final currentUser = UserModel().user;

      // Calculer la distance
      final distance = _suggestionsService.calculateDistance(
        currentUser.userGeoPoint,
        newUser.userGeoPoint,
      );

      debugPrint(
        '🎯 Nouvelle suggestion: ${newUser.userFullname} (${(distance * 1000).round()}m)',
      );

      // Vérifier le cooldown de notification pour cet utilisateur
      final cooldownKey = newUser.userId;
      if (_notificationCooldowns.containsKey(cooldownKey)) {
        final timeSinceLastNotification = DateTime.now().difference(
          _notificationCooldowns[cooldownKey]!,
        );
        if (timeSinceLastNotification < Duration(hours: 1)) {
          debugPrint('🔕 Cooldown actif pour ${newUser.userFullname}');
          return;
        }
      }

      // Déclencher une notification si très proche
      bool shouldNotify = false;

      if (distance * 1000 <= 10) {
        // 10 mètres
        shouldNotify = true;
      }

      if (shouldNotify) {
        // Utiliser la méthode checkAndNotifyNearbyMatches pour les profils proches
        await _notificationsService.checkAndNotifyNearbyMatches(
          currentUser.userId,
        );

        // Enregistrer le cooldown
        _notificationCooldowns[cooldownKey] = DateTime.now();

        debugPrint('🔔 Notification envoyée pour ${newUser.userFullname}');
      }
    } catch (e) {
      debugPrint('❌ Erreur gestion nouvelle suggestion: $e');
    }
  }

  /// Mettre à jour la position de l'utilisateur dans Firestore
  static Future<void> _updateUserPosition(Position position) async {
    try {
      final currentUser = UserModel().user;
      final geoPoint = GeoPoint(position.latitude, position.longitude);

      await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser.userId)
          .update({
            'user_geo_point': {'geopoint': geoPoint},
            'last_location_update': FieldValue.serverTimestamp(),
          });

      debugPrint('📍 Position utilisateur mise à jour dans Firestore');
    } catch (e) {
      debugPrint('❌ Erreur mise à jour position Firestore: $e');
    }
  }

  /// Passer en mode arrière-plan
  static void onAppBackground() {
    debugPrint('🌙 App en arrière-plan - activation mode économie');
    _isInBackground = true;

    // Réduire la fréquence de mise à jour
    _scheduleUpdateSuggestions();
  }

  /// Revenir en mode premier plan
  static void onAppForeground() {
    debugPrint('☀️ App en premier plan - activation mode normal');
    _isInBackground = false;

    // Effectuer une mise à jour immédiate
    _scheduleUpdateSuggestions(immediate: true);
  }

  /// Obtenir les statistiques du service
  static Map<String, dynamic> getStats() {
    return {
      'isRunning': _isRunning,
      'isInBackground': _isInBackground,
      'lastUpdateTime': _lastUpdateTime?.toIso8601String(),
      'lastKnownPosition': _lastKnownPosition != null
          ? {
              'latitude': _lastKnownPosition!.latitude,
              'longitude': _lastKnownPosition!.longitude,
              'timestamp': _lastKnownPosition!.timestamp.toIso8601String(),
            }
          : null,
      'cachedSuggestionsCount': _cachedSuggestions?.length ?? 0,
      'activeCooldowns': _notificationCooldowns.length,
    };
  }

  /// Forcer une mise à jour manuelle
  static Future<void> forceUpdate() async {
    debugPrint('🔄 Mise à jour forcée demandée');
    await _performBackgroundUpdate();
  }

  /// Vider le cache
  static void clearCache() {
    debugPrint('🗑️ Nettoyage du cache');
    _cachedSuggestions = null;
    _notificationCooldowns.clear();
    _lastUpdateTime = null;
  }
}

/// Observer pour surveiller le cycle de vie de l'application
class _AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        BackgroundSuggestionsService.onAppBackground();
        break;
      case AppLifecycleState.resumed:
        BackgroundSuggestionsService.onAppForeground();
        break;
      case AppLifecycleState.inactive:
        // État transitoire, ne pas changer le mode
        break;
      case AppLifecycleState.hidden:
        // Nouvel état en Flutter 3.13+
        BackgroundSuggestionsService.onAppBackground();
        break;
    }
  }
}
