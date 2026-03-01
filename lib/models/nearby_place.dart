import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';

/// Type de lieu à proximité
enum PlaceCategory {
  bar,
  restaurant,
  nightClub,
  cafe,
  shoppingMall,
  cinema,
  park,
  gym,
  spa,
  other,
}

/// Extension pour obtenir les propriétés des catégories de lieux
extension PlaceCategoryExtension on PlaceCategory {
  /// Display name of the category
  String get displayName {
    switch (this) {
      case PlaceCategory.bar:
        return 'Bar';
      case PlaceCategory.restaurant:
        return 'Restaurant';
      case PlaceCategory.nightClub:
        return 'Nightclub';
      case PlaceCategory.cafe:
        return 'Café';
      case PlaceCategory.shoppingMall:
        return 'Shopping Mall';
      case PlaceCategory.cinema:
        return 'Cinema';
      case PlaceCategory.park:
        return 'Park';
      case PlaceCategory.gym:
        return 'Gym';
      case PlaceCategory.spa:
        return 'Spa';
      case PlaceCategory.other:
        return 'Other';
    }
  }

  /// Icône associée à la catégorie
  String get iconName {
    switch (this) {
      case PlaceCategory.bar:
        return 'local_bar';
      case PlaceCategory.restaurant:
        return 'restaurant';
      case PlaceCategory.nightClub:
        return 'nightlife';
      case PlaceCategory.cafe:
        return 'coffee';
      case PlaceCategory.shoppingMall:
        return 'shopping_bag';
      case PlaceCategory.cinema:
        return 'movie';
      case PlaceCategory.park:
        return 'park';
      case PlaceCategory.gym:
        return 'fitness_center';
      case PlaceCategory.spa:
        return 'spa';
      case PlaceCategory.other:
        return 'place';
    }
  }

  /// Couleur associée à la catégorie
  String get colorHex {
    switch (this) {
      case PlaceCategory.bar:
        return '#E91E63'; // Pink
      case PlaceCategory.restaurant:
        return '#FF5722'; // Deep Orange
      case PlaceCategory.nightClub:
        return '#9C27B0'; // Purple
      case PlaceCategory.cafe:
        return '#795548'; // Brown
      case PlaceCategory.shoppingMall:
        return '#2196F3'; // Blue
      case PlaceCategory.cinema:
        return '#FF9800'; // Orange
      case PlaceCategory.park:
        return '#4CAF50'; // Green
      case PlaceCategory.gym:
        return '#F44336'; // Red
      case PlaceCategory.spa:
        return '#00BCD4'; // Cyan
      case PlaceCategory.other:
        return '#607D8B'; // Blue Grey
    }
  }

  /// Types Google Places associés à cette catégorie
  List<String> get googlePlaceTypes {
    switch (this) {
      case PlaceCategory.bar:
        return ['bar'];
      case PlaceCategory.restaurant:
        return ['restaurant'];
      case PlaceCategory.nightClub:
        return ['night_club'];
      case PlaceCategory.cafe:
        return ['cafe'];
      case PlaceCategory.shoppingMall:
        return ['shopping_mall'];
      case PlaceCategory.cinema:
        return ['movie_theater'];
      case PlaceCategory.park:
        return ['park'];
      case PlaceCategory.gym:
        return ['gym'];
      case PlaceCategory.spa:
        return ['spa'];
      case PlaceCategory.other:
        return ['establishment'];
    }
  }
}

/// Représente un lieu à proximité récupéré depuis Google Places API
class NearbyPlace {
  /// Identifiant unique du lieu (place_id de Google)
  final String id;

  /// Nom du lieu
  final String name;

  /// Adresse du lieu
  final String? address;

  /// Position géographique du lieu
  final GeoPoint location;

  /// Catégorie du lieu
  final PlaceCategory category;

  /// Types Google Places bruts
  final List<String> types;

  /// Distance depuis la position de l'utilisateur (en km)
  final double distanceKm;

  /// Note moyenne (0-5)
  final double? rating;

  /// Nombre d'avis
  final int? userRatingsTotal;

  /// Niveau de prix (0-4)
  final int? priceLevel;

  /// Indique si le lieu est ouvert actuellement
  final bool? isOpenNow;

  /// URL de la photo principale du lieu
  final String? photoUrl;

  /// Icône Google du lieu
  final String? iconUrl;

  /// Vicinity (adresse courte)
  final String? vicinity;

  /// Horaires d'ouverture
  final List<String>? openingHours;

  /// Numéro de téléphone
  final String? phoneNumber;

  /// Site web
  final String? website;

  const NearbyPlace({
    required this.id,
    required this.name,
    this.address,
    required this.location,
    required this.category,
    required this.types,
    required this.distanceKm,
    this.rating,
    this.userRatingsTotal,
    this.priceLevel,
    this.isOpenNow,
    this.photoUrl,
    this.iconUrl,
    this.vicinity,
    this.openingHours,
    this.phoneNumber,
    this.website,
  });

  /// Create a NearbyPlace from Google Places API response
  factory NearbyPlace.fromGooglePlacesJson(
    Map<String, dynamic> json, {
    required double userLat,
    required double userLng,
    String? apiKey,
  }) {
    // Extract position
    final geometry = json['geometry'] as Map<String, dynamic>?;
    final locationData = geometry?['location'] as Map<String, dynamic>?;
    final lat = (locationData?['lat'] as num?)?.toDouble() ?? 0;
    final lng = (locationData?['lng'] as num?)?.toDouble() ?? 0;

    // Calculate distance
    final distanceKm = calculateDistanceKm(userLat, userLng, lat, lng);

    // Extract types
    final types =
        (json['types'] as List<dynamic>?)?.map((t) => t.toString()).toList() ??
        [];

    // Determine category
    final category = determineCategoryFromTypes(types);

    // Extract opening hours
    final openingHoursData = json['opening_hours'] as Map<String, dynamic>?;
    final isOpenNow = openingHoursData?['open_now'] as bool?;

    // Extract photo URL if available
    String? photoUrl;
    final photos = json['photos'] as List<dynamic>?;
    if (photos != null && photos.isNotEmpty && apiKey != null) {
      final firstPhoto = photos.first as Map<String, dynamic>;
      final photoReference = firstPhoto['photo_reference'] as String?;
      if (photoReference != null) {
        photoUrl =
            'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photo_reference=$photoReference&key=$apiKey';
      }
    }

    return NearbyPlace(
      id: json['place_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown place',
      address: json['formatted_address'] as String?,
      location: GeoPoint(lat, lng),
      category: category,
      types: types,
      distanceKm: distanceKm,
      rating: (json['rating'] as num?)?.toDouble(),
      userRatingsTotal: json['user_ratings_total'] as int?,
      priceLevel: json['price_level'] as int?,
      isOpenNow: isOpenNow,
      photoUrl: photoUrl,
      iconUrl: json['icon'] as String?,
      vicinity: json['vicinity'] as String?,
    );
  }

  /// Calculer la distance entre deux points en km (méthode publique)
  static double calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusKm = 6371;
    final double dLat = _degToRad(lat2 - lat1);
    final double dLon = _degToRad(lon2 - lon1);

    final double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusKm * c;
  }

  static double _degToRad(double deg) => deg * (math.pi / 180);

  /// Déterminer la catégorie à partir des types Google (méthode publique)
  static PlaceCategory determineCategoryFromTypes(List<String> types) {
    if (types.contains('night_club')) return PlaceCategory.nightClub;
    if (types.contains('bar')) return PlaceCategory.bar;
    if (types.contains('restaurant')) return PlaceCategory.restaurant;
    if (types.contains('cafe')) return PlaceCategory.cafe;
    if (types.contains('shopping_mall')) return PlaceCategory.shoppingMall;
    if (types.contains('movie_theater')) return PlaceCategory.cinema;
    if (types.contains('park')) return PlaceCategory.park;
    if (types.contains('gym')) return PlaceCategory.gym;
    if (types.contains('spa')) return PlaceCategory.spa;
    return PlaceCategory.other;
  }

  /// Description formatée de la distance
  String get distanceDescription {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    } else {
      return '${distanceKm.toStringAsFixed(1)} km';
    }
  }

  /// Description formatée de la note
  String get ratingDescription {
    if (rating == null) return 'Pas d\'avis';
    return '${rating!.toStringAsFixed(1)}/5 (${userRatingsTotal ?? 0} avis)';
  }

  /// Description formatée du niveau de prix
  String get priceLevelDescription {
    if (priceLevel == null) return '';
    return '\$' * (priceLevel! + 1);
  }

  /// Statut d'ouverture formaté
  String get openingStatusDescription {
    if (isOpenNow == null) return 'Horaires inconnus';
    return isOpenNow! ? 'Ouvert' : 'Fermé';
  }

  /// Convertir en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'location': location,
      'category': category.index,
      'types': types,
      'distanceKm': distanceKm,
      'rating': rating,
      'userRatingsTotal': userRatingsTotal,
      'priceLevel': priceLevel,
      'isOpenNow': isOpenNow,
      'photoUrl': photoUrl,
      'iconUrl': iconUrl,
      'vicinity': vicinity,
      'openingHours': openingHours,
      'phoneNumber': phoneNumber,
      'website': website,
    };
  }

  /// Créer une copie avec modifications
  NearbyPlace copyWith({
    String? id,
    String? name,
    String? address,
    GeoPoint? location,
    PlaceCategory? category,
    List<String>? types,
    double? distanceKm,
    double? rating,
    int? userRatingsTotal,
    int? priceLevel,
    bool? isOpenNow,
    String? photoUrl,
    String? iconUrl,
    String? vicinity,
    List<String>? openingHours,
    String? phoneNumber,
    String? website,
  }) {
    return NearbyPlace(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      location: location ?? this.location,
      category: category ?? this.category,
      types: types ?? this.types,
      distanceKm: distanceKm ?? this.distanceKm,
      rating: rating ?? this.rating,
      userRatingsTotal: userRatingsTotal ?? this.userRatingsTotal,
      priceLevel: priceLevel ?? this.priceLevel,
      isOpenNow: isOpenNow ?? this.isOpenNow,
      photoUrl: photoUrl ?? this.photoUrl,
      iconUrl: iconUrl ?? this.iconUrl,
      vicinity: vicinity ?? this.vicinity,
      openingHours: openingHours ?? this.openingHours,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      website: website ?? this.website,
    );
  }

  @override
  String toString() {
    return 'NearbyPlace{id: $id, name: $name, category: ${category.displayName}, distance: $distanceDescription}';
  }
}
