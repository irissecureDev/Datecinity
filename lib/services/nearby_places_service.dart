import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:datecinity/models/nearby_place.dart';
import 'package:datecinity/constants/constants.dart';

/// Service pour récupérer les lieux à proximité via Google Places API
class NearbyPlacesService {
  static final NearbyPlacesService _instance = NearbyPlacesService._internal();
  factory NearbyPlacesService() => _instance;
  NearbyPlacesService._internal();

  // Configuration
  static const double _searchRadiusKm = 4.0; // Rayon de recherche de 4km
  static const int _searchRadiusMeters = 4000; // 4km en mètres
  static const int _cacheValidityMinutes = 5; // Cache valide pendant 5 minutes
  static const int _maxResultsPerType = 20; // max résultats par type de lieu

  // Types de lieux à rechercher
  static const List<String> _placeTypes = [
    'bar',
    'restaurant',
    'night_club',
    'cafe',
    'shopping_mall',
    'movie_theater',
  ];

  // Cache
  List<NearbyPlace>? _cachedPlaces;
  DateTime? _cacheTimestamp;
  Position? _cachedPosition;

  /// Obtenir la clé API Google selon la plateforme
  String get _apiKey {
    if (Platform.isAndroid) {
      return ANDROID_MAPS_API_KEY;
    } else if (Platform.isIOS) {
      return IOS_MAPS_API_KEY;
    }
    return ANDROID_MAPS_API_KEY;
  }

  /// Récupérer tous les lieux à proximité dans un rayon de 4km
  Future<List<NearbyPlace>> getNearbyPlaces({bool forceRefresh = false}) async {
    try {
      debugPrint('📍 NearbyPlacesService: Fetching nearby places...');

      // Vérifier le cache
      if (!forceRefresh && _isCacheValid()) {
        debugPrint('📋 Using cache (${_cachedPlaces!.length} places)');
        return _cachedPlaces!;
      }

      // Obtenir la position actuelle de l'utilisateur
      final userPosition = await _getCurrentUserPosition();
      if (userPosition == null) {
        debugPrint('❌ User position not available');
        return [];
      }

      // Récupérer les lieux pour chaque type
      final allPlaces = <NearbyPlace>[];
      final seenPlaceIds = <String>{};

      for (final placeType in _placeTypes) {
        try {
          final places = await _fetchPlacesOfType(
            placeType,
            userPosition.latitude,
            userPosition.longitude,
          );

          // Ajouter les lieux non dupliqués
          for (final place in places) {
            if (!seenPlaceIds.contains(place.id)) {
              seenPlaceIds.add(place.id);
              allPlaces.add(place);
            }
          }

          debugPrint('✅ Found ${places.length} $placeType places');
        } catch (e) {
          debugPrint('⚠️ Error fetching $placeType places: $e');
        }
      }

      // Trier par distance
      allPlaces.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

      // Filtrer pour garder uniquement les lieux dans le rayon de 4km
      final filteredPlaces = allPlaces
          .where((place) => place.distanceKm <= _searchRadiusKm)
          .toList();

      // Mettre en cache
      _cachedPlaces = filteredPlaces;
      _cacheTimestamp = DateTime.now();
      _cachedPosition = userPosition;

      debugPrint('🎯 Total: ${filteredPlaces.length} places within 4km');

      return filteredPlaces;
    } catch (e) {
      debugPrint('❌ Error fetching nearby places: $e');
      return [];
    }
  }

  /// Récupérer les lieux d'un type spécifique via Google Places API
  Future<List<NearbyPlace>> _fetchPlacesOfType(
    String placeType,
    double lat,
    double lng,
  ) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
      '?location=$lat,$lng'
      '&radius=$_searchRadiusMeters'
      '&type=$placeType'
      '&key=$_apiKey',
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch places: ${response.statusCode}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final status = data['status'] as String?;

    if (status != 'OK' && status != 'ZERO_RESULTS') {
      final errorMessage = data['error_message'] as String? ?? status;
      debugPrint('⚠️ Google Places API error: $errorMessage');
      // Ne pas throw, juste retourner une liste vide
      return [];
    }

    final results = data['results'] as List<dynamic>? ?? [];

    return results
        .take(_maxResultsPerType)
        .map(
          (placeData) => NearbyPlace.fromGooglePlacesJson(
            placeData as Map<String, dynamic>,
            userLat: lat,
            userLng: lng,
            apiKey: _apiKey,
          ),
        )
        .toList();
  }

  /// Obtenir la position actuelle de l'utilisateur
  Future<Position?> _getCurrentUserPosition() async {
    try {
      // Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('❌ Location permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('❌ Location permission permanently denied');
        return null;
      }

      // Obtenir la position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );

      return position;
    } catch (e) {
      debugPrint('❌ Error getting position: $e');
      return null;
    }
  }

  /// Vérifier si le cache est toujours valide
  bool _isCacheValid() {
    if (_cachedPlaces == null || _cacheTimestamp == null) {
      return false;
    }

    final cacheAge = DateTime.now().difference(_cacheTimestamp!);
    return cacheAge.inMinutes < _cacheValidityMinutes;
  }

  /// Forcer le rafraîchissement des données
  Future<List<NearbyPlace>> forceRefresh() async {
    _cachedPlaces = null;
    _cacheTimestamp = null;
    _cachedPosition = null;
    return getNearbyPlaces(forceRefresh: true);
  }

  /// Obtenir les statistiques des lieux
  Map<String, dynamic> getPlacesStats() {
    return {
      'totalPlaces': _cachedPlaces?.length ?? 0,
      'lastUpdate': _cacheTimestamp?.toIso8601String(),
      'cachedPosition': _cachedPosition != null
          ? '${_cachedPosition!.latitude}, ${_cachedPosition!.longitude}'
          : null,
      'cacheValid': _isCacheValid(),
    };
  }

  /// Récupérer les détails d'un lieu spécifique
  Future<NearbyPlace?> getPlaceDetails(String placeId) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=$placeId'
        '&fields=name,formatted_address,geometry,rating,user_ratings_total,'
        'opening_hours,formatted_phone_number,website,price_level,photos,types'
        '&key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch place details: ${response.statusCode}',
        );
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final status = data['status'] as String?;

      if (status != 'OK') {
        debugPrint(
          '⚠️ Place details error: ${data['error_message'] ?? status}',
        );
        return null;
      }

      final result = data['result'] as Map<String, dynamic>?;
      if (result == null) return null;

      // Obtenir la position actuelle pour calculer la distance
      final userPosition = await _getCurrentUserPosition();
      if (userPosition == null) return null;

      // Extraire les données
      final geometry = result['geometry'] as Map<String, dynamic>?;
      final location = geometry?['location'] as Map<String, dynamic>?;
      final lat = (location?['lat'] as num?)?.toDouble() ?? 0;
      final lng = (location?['lng'] as num?)?.toDouble() ?? 0;

      final types =
          (result['types'] as List<dynamic>?)
              ?.map((t) => t.toString())
              .toList() ??
          [];

      final openingHours = result['opening_hours'] as Map<String, dynamic>?;
      final weekdayText = (openingHours?['weekday_text'] as List<dynamic>?)
          ?.map((t) => t.toString())
          .toList();

      // Construire le photoUrl si disponible
      String? photoUrl;
      final photos = result['photos'] as List<dynamic>?;
      if (photos != null && photos.isNotEmpty) {
        final firstPhoto = photos.first as Map<String, dynamic>;
        final photoReference = firstPhoto['photo_reference'] as String?;
        if (photoReference != null) {
          photoUrl =
              'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photo_reference=$photoReference&key=$_apiKey';
        }
      }

      return NearbyPlace(
        id: placeId,
        name: result['name'] as String? ?? 'Unknown',
        address: result['formatted_address'] as String?,
        location: GeoPoint(lat, lng),
        category: NearbyPlace.determineCategoryFromTypes(types),
        types: types,
        distanceKm: NearbyPlace.calculateDistanceKm(
          userPosition.latitude,
          userPosition.longitude,
          lat,
          lng,
        ),
        rating: (result['rating'] as num?)?.toDouble(),
        userRatingsTotal: result['user_ratings_total'] as int?,
        priceLevel: result['price_level'] as int?,
        isOpenNow: openingHours?['open_now'] as bool?,
        photoUrl: photoUrl,
        openingHours: weekdayText,
        phoneNumber: result['formatted_phone_number'] as String?,
        website: result['website'] as String?,
      );
    } catch (e) {
      debugPrint('❌ Error fetching place details: $e');
      return null;
    }
  }

  /// Filtrer les lieux par catégorie
  List<NearbyPlace> filterByCategory(
    List<NearbyPlace> places,
    PlaceCategory category,
  ) {
    return places.where((place) => place.category == category).toList();
  }

  /// Filtrer les lieux ouverts
  List<NearbyPlace> filterOpenNow(List<NearbyPlace> places) {
    return places.where((place) => place.isOpenNow == true).toList();
  }

  /// Obtenir les catégories disponibles avec leur nombre de lieux
  Map<PlaceCategory, int> getCategoryCounts(List<NearbyPlace> places) {
    final counts = <PlaceCategory, int>{};
    for (final place in places) {
      counts[place.category] = (counts[place.category] ?? 0) + 1;
    }
    return counts;
  }
}
