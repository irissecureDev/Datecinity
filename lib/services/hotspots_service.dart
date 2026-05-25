import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:datecinity/datas/user.dart';
import 'package:datecinity/models/user_model.dart';
import 'package:datecinity/models/hotspot.dart';

/// Service pour détecter et gérer les zones de concentration d'utilisateurs (hotspots)
class HotspotsService {
  static final HotspotsService _instance = HotspotsService._internal();
  factory HotspotsService() => _instance;
  HotspotsService._internal();

  // Configuration
  static const double _clusterRadiusKm =
      0.2; // 200 mètres pour grouper les utilisateurs
  static const int _minUsersForHotspot =
      5; // Minimum 5 utilisateurs pour former un hotspot
  static const int _onlineThresholdMinutes =
      30; // Utilisateurs actifs dans les 30 dernières minutes
  static const int _cacheValidityMinutes = 2; // Cache valide pendant 2 minutes

  // Cache
  List<Hotspot>? _cachedHotspots;
  DateTime? _cacheTimestamp;

  /// Détecter tous les hotspots actuels
  Future<List<Hotspot>> detectHotspots() async {
    try {
      debugPrint('🔍 HotspotsService: Detecting hotspots...');

      // Vérifier le cache
      if (_isCacheValid()) {
        debugPrint(
          '📋 Utilisation du cache (${_cachedHotspots!.length} hotspots)',
        );
        return _cachedHotspots!;
      }

      // Obtenir la position actuelle de l'utilisateur
      final userPosition = await _getCurrentUserPosition();
      if (userPosition == null) {
        debugPrint('❌ Position utilisateur non disponible');
        return [];
      }

      // Obtenir tous les utilisateurs connectés dans un rayon de 50km
      final connectedUsers = await _getConnectedUsersNearby(userPosition);
      debugPrint('👥 ${connectedUsers.length} connected users found');

      if (connectedUsers.length < _minUsersForHotspot) {
        debugPrint('⚠️ Not enough users to form hotspots');
        return [];
      }

      // Grouper les utilisateurs par clusters géographiques
      final clusters = _createGeographicClusters(connectedUsers);
      debugPrint('📍 ${clusters.length} clusters géographiques créés');

      // Convertir les clusters en hotspots
      final hotspots = await _convertClustersToHotspots(clusters, userPosition);
      debugPrint('🎯 ${hotspots.length} hotspots detected');

      // Mettre en cache
      _cachedHotspots = hotspots;
      _cacheTimestamp = DateTime.now();

      return hotspots;
    } catch (e) {
      debugPrint('❌ Erreur détection hotspots: $e');
      return [];
    }
  }

  /// Obtenir la position actuelle de l'utilisateur
  Future<Position?> _getCurrentUserPosition() async {
    try {
      // Vérifier les permissions
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }

      // Obtenir la position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      return position;
    } catch (e) {
      debugPrint('❌ Erreur obtention position: $e');
      return null;
    }
  }

  /// Obtenir tous les utilisateurs connectés dans un rayon donné
  Future<List<User>> _getConnectedUsersNearby(Position userPosition) async {
    try {
      // Calculer les bornes géographiques (carré de ~50km autour de l'utilisateur)
      const radiusKm = 50.0;
      final bounds = _calculateGeographicBounds(userPosition, radiusKm);

      // Requête Firestore avec filtre géographique
      final query = FirebaseFirestore.instance
          .collection('Users')
          .where('user_geo_point.geopoint', isGreaterThan: bounds['southwest'])
          .where('user_geo_point.geopoint', isLessThan: bounds['northeast'])
          .where('user_is_online', isEqualTo: true)
          .where('last_activity', isGreaterThan: _getOnlineThreshold())
          .limit(200); // Limite pour éviter les requêtes trop lourdes

      final snapshot = await query.get();

      final users = <User>[];
      for (final doc in snapshot.docs) {
        try {
          final user = User.fromDocument(doc.data());

          // Vérifier que l'utilisateur n'est pas l'utilisateur actuel
          if (user.userId != UserModel().user.userId) {
            // Calculer la distance exacte
            final distance = Geolocator.distanceBetween(
              userPosition.latitude,
              userPosition.longitude,
              user.userGeoPoint.latitude,
              user.userGeoPoint.longitude,
            );

            // Garder seulement les utilisateurs dans le rayon
            if (distance <= radiusKm * 1000) {
              users.add(user);
            }
          }
        } catch (e) {
          debugPrint('⚠️ Erreur parsing utilisateur: $e');
        }
      }

      return users;
    } catch (e) {
      debugPrint('❌ Erreur requête utilisateurs connectés: $e');
      return [];
    }
  }

  /// Calculer les bornes géographiques pour une requête Firestore
  Map<String, GeoPoint> _calculateGeographicBounds(
    Position center,
    double radiusKm,
  ) {
    // Approximation simple pour un carré (pas parfait mais suffisant pour Firestore)
    const double kmPerDegree = 111.32; // Approximation à l'équateur
    final double deltaLat = radiusKm / kmPerDegree;
    final double deltaLon =
        radiusKm / (kmPerDegree * cos(center.latitude * pi / 180));

    return {
      'southwest': GeoPoint(
        center.latitude - deltaLat,
        center.longitude - deltaLon,
      ),
      'northeast': GeoPoint(
        center.latitude + deltaLat,
        center.longitude + deltaLon,
      ),
    };
  }

  /// Obtenir le seuil de temps pour considérer un utilisateur comme "en ligne"
  Timestamp _getOnlineThreshold() {
    final threshold = DateTime.now().subtract(
      Duration(minutes: _onlineThresholdMinutes),
    );
    return Timestamp.fromDate(threshold);
  }

  /// Créer des clusters géographiques d'utilisateurs
  List<List<User>> _createGeographicClusters(List<User> users) {
    final clusters = <List<User>>[];
    final processedUsers = <String>{};

    for (final user in users) {
      if (processedUsers.contains(user.userId)) continue;

      // Créer un nouveau cluster avec cet utilisateur
      final cluster = <User>[user];
      processedUsers.add(user.userId);

      // Trouver tous les utilisateurs à proximité
      for (final otherUser in users) {
        if (processedUsers.contains(otherUser.userId)) continue;

        final distance = Geolocator.distanceBetween(
          user.userGeoPoint.latitude,
          user.userGeoPoint.longitude,
          otherUser.userGeoPoint.latitude,
          otherUser.userGeoPoint.longitude,
        );

        // Si l'utilisateur est dans le rayon de cluster
        if (distance <= _clusterRadiusKm * 1000) {
          cluster.add(otherUser);
          processedUsers.add(otherUser.userId);
        }
      }

      // Garder seulement les clusters avec assez d'utilisateurs
      if (cluster.length >= _minUsersForHotspot) {
        clusters.add(cluster);
      }
    }

    return clusters;
  }

  /// Convertir les clusters en hotspots avec informations de lieu
  Future<List<Hotspot>> _convertClustersToHotspots(
    List<List<User>> clusters,
    Position userPosition,
  ) async {
    final hotspots = <Hotspot>[];

    for (int i = 0; i < clusters.length; i++) {
      final cluster = clusters[i];

      // Calculer le centre géographique du cluster
      final center = _calculateClusterCenter(cluster);

      // Calculer la distance depuis l'utilisateur
      final distanceFromUser =
          Geolocator.distanceBetween(
            userPosition.latitude,
            userPosition.longitude,
            center.latitude,
            center.longitude,
          ) /
          1000; // Convertir en km

      // Déterminer le type de hotspot
      final type = cluster.length >= 10
          ? HotspotType.high
          : HotspotType.moderate;

      // Obtenir le nom du lieu (version simplifiée sans API externe)
      final placeName = await _getPlaceNameForLocation(center, cluster.length);

      // Créer le hotspot
      final hotspot = Hotspot(
        id: 'hotspot_${DateTime.now().millisecondsSinceEpoch}_$i',
        center: center,
        userCount: cluster.length,
        placeName: placeName,
        type: type,
        connectedUsers: cluster,
        distanceFromUser: distanceFromUser,
        radiusMeters: _clusterRadiusKm * 1000,
        lastUpdated: DateTime.now(),
        placeType: _guessPlaceType(cluster.length),
      );

      hotspots.add(hotspot);
    }

    // Trier par distance
    hotspots.sort((a, b) => a.distanceFromUser.compareTo(b.distanceFromUser));

    return hotspots;
  }

  /// Calculer le centre géographique d'un cluster
  GeoPoint _calculateClusterCenter(List<User> cluster) {
    double totalLat = 0;
    double totalLon = 0;

    for (final user in cluster) {
      totalLat += user.userGeoPoint.latitude;
      totalLon += user.userGeoPoint.longitude;
    }

    return GeoPoint(totalLat / cluster.length, totalLon / cluster.length);
  }

  /// Obtenir un nom de lieu (version simplifiée sans API externe)
  Future<String> _getPlaceNameForLocation(
    GeoPoint location,
    int userCount,
  ) async {
    // Pour l'instant, génération de noms génériques
    // Dans une vraie app, on utiliserait Google Places API ou similar

    final placeTypes = [
      'Restaurant',
      'Bar',
      'Café',
      'Centre Commercial',
      'Parc',
      'Place',
      'Gare',
      'Université',
      'Cinéma',
      'Salle de Sport',
    ];

    final adjectives = [
      'Central',
      'Grand',
      'Nouveau',
      'Principal',
      'Moderne',
      'Populaire',
      'Branché',
      'Animé',
    ];

    final random = Random();
    final placeType = placeTypes[random.nextInt(placeTypes.length)];
    final adjective = adjectives[random.nextInt(adjectives.length)];

    // Ajouter les coordonnées pour l'unicité
    final latStr = location.latitude.toStringAsFixed(3);
    final lonStr = location.longitude.toStringAsFixed(3);

    return '$adjective $placeType ($latStr, $lonStr)';
  }

  /// Deviner le type de lieu selon le nombre d'utilisateurs
  String _guessPlaceType(int userCount) {
    if (userCount >= 15) {
      return 'Centre Commercial';
    } else if (userCount >= 10) {
      return 'Restaurant';
    } else if (userCount >= 7) {
      return 'Bar';
    } else {
      return 'Lieu Public';
    }
  }

  /// Vérifier si le cache est encore valide
  bool _isCacheValid() {
    if (_cachedHotspots == null || _cacheTimestamp == null) {
      return false;
    }

    final cacheAge = DateTime.now().difference(_cacheTimestamp!);
    return cacheAge.inMinutes < _cacheValidityMinutes;
  }

  /// Obtenir un hotspot par son ID
  Hotspot? getHotspotById(String id) {
    return _cachedHotspots?.firstWhere(
      (hotspot) => hotspot.id == id,
      orElse: () => throw StateError('Hotspot not found'),
    );
  }

  /// Calculer l'itinéraire vers un hotspot (version simplifiée)
  Future<List<Map<String, double>>> getRouteToHotspot(Hotspot hotspot) async {
    try {
      final userPosition = await _getCurrentUserPosition();
      if (userPosition == null) return [];

      // Pour l'instant, retourner une ligne droite
      // Dans une vraie app, on utiliserait Google Directions API
      return [
        {
          'latitude': userPosition.latitude,
          'longitude': userPosition.longitude,
        },
        {
          'latitude': hotspot.center.latitude,
          'longitude': hotspot.center.longitude,
        },
      ];
    } catch (e) {
      debugPrint('❌ Erreur calcul itinéraire: $e');
      return [];
    }
  }

  /// Forcer une actualisation du cache
  Future<List<Hotspot>> forceRefresh() async {
    _cachedHotspots = null;
    _cacheTimestamp = null;
    return detectHotspots();
  }

  /// Obtenir des statistiques sur les hotspots
  Map<String, dynamic> getHotspotsStats() {
    if (_cachedHotspots == null) {
      return {
        'totalHotspots': 0,
        'totalUsers': 0,
        'averageUsersPerHotspot': 0.0,
        'cacheAge': -1,
      };
    }

    final totalUsers = _cachedHotspots!.fold<int>(
      0,
      (sum, hotspot) => sum + hotspot.userCount,
    );

    final cacheAge = _cacheTimestamp != null
        ? DateTime.now().difference(_cacheTimestamp!).inSeconds
        : -1;

    return {
      'totalHotspots': _cachedHotspots!.length,
      'totalUsers': totalUsers,
      'averageUsersPerHotspot': _cachedHotspots!.isNotEmpty
          ? totalUsers / _cachedHotspots!.length
          : 0.0,
      'cacheAge': cacheAge,
      'lastUpdate': _cacheTimestamp?.toIso8601String(),
    };
  }

  /// Nettoyer le cache
  void clearCache() {
    _cachedHotspots = null;
    _cacheTimestamp = null;
    debugPrint('🗑️ Cache hotspots nettoyé');
  }
}
