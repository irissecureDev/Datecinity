import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datecinity/datas/user.dart';

/// Type de hotspot selon le nombre d'utilisateurs
enum HotspotType {
  moderate, // 5-10 utilisateurs
  high, // 10+ utilisateurs
}

/// Extension pour obtenir les propriétés des types de hotspots
extension HotspotTypeExtension on HotspotType {
  /// Couleur associée au type de hotspot
  String get colorHex {
    switch (this) {
      case HotspotType.moderate:
        return '#FF9800'; // Orange
      case HotspotType.high:
        return '#F44336'; // Rouge
    }
  }

  /// Seuil minimum d'utilisateurs pour ce type
  int get minUsers {
    switch (this) {
      case HotspotType.moderate:
        return 5;
      case HotspotType.high:
        return 10;
    }
  }

  /// Description textuelle du niveau d'activité
  String get description {
    switch (this) {
      case HotspotType.moderate:
        return 'Zone modérément active';
      case HotspotType.high:
        return 'Zone très active';
    }
  }

  /// Icône recommandée pour ce type
  String get iconName {
    switch (this) {
      case HotspotType.moderate:
        return 'location_on';
      case HotspotType.high:
        return 'whatshot';
    }
  }
}

/// Représente une zone de concentration d'utilisateurs connectés
class Hotspot {
  /// Centre géographique du hotspot
  final GeoPoint center;

  /// Nombre d'utilisateurs connectés dans cette zone
  final int userCount;

  /// Nom du lieu (obtenu via reverse geocoding)
  final String placeName;

  /// Type de hotspot selon le nombre d'utilisateurs
  final HotspotType type;

  /// Liste des utilisateurs connectés dans cette zone
  final List<User> connectedUsers;

  /// Distance depuis la position de l'utilisateur actuel (en km)
  final double distanceFromUser;

  /// Rayon de la zone en mètres
  final double radiusMeters;

  /// Timestamp de la dernière mise à jour
  final DateTime lastUpdated;

  /// Identifiant unique du hotspot
  final String id;

  /// Adresse complète du lieu
  final String? fullAddress;

  /// Type de lieu (restaurant, bar, centre commercial, etc.)
  final String? placeType;

  /// Note ou popularité du lieu (0-5)
  final double? rating;

  const Hotspot({
    required this.center,
    required this.userCount,
    required this.placeName,
    required this.type,
    required this.connectedUsers,
    required this.distanceFromUser,
    required this.radiusMeters,
    required this.lastUpdated,
    required this.id,
    this.fullAddress,
    this.placeType,
    this.rating,
  });

  /// Créer un hotspot à partir de données JSON
  factory Hotspot.fromJson(Map<String, dynamic> json) {
    return Hotspot(
      center: json['center'] as GeoPoint,
      userCount: json['userCount'] as int,
      placeName: json['placeName'] as String,
      type: HotspotType.values[json['type'] as int],
      connectedUsers: (json['connectedUsers'] as List<dynamic>)
          .map(
            (userData) => User.fromDocument(userData as Map<String, dynamic>),
          )
          .toList(),
      distanceFromUser: (json['distanceFromUser'] as num).toDouble(),
      radiusMeters: (json['radiusMeters'] as num).toDouble(),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      id: json['id'] as String,
      fullAddress: json['fullAddress'] as String?,
      placeType: json['placeType'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
    );
  }

  /// Convertir le hotspot en JSON
  Map<String, dynamic> toJson() {
    return {
      'center': center,
      'userCount': userCount,
      'placeName': placeName,
      'type': type.index,
      'connectedUsers': connectedUsers
          .map(
            (user) => {
              'userId': user.userId,
              'userFullname': user.userFullname,
              'userGender': user.userGender,
              'userBirthDay': user.userBirthDay,
            },
          )
          .toList(),
      'distanceFromUser': distanceFromUser,
      'radiusMeters': radiusMeters,
      'lastUpdated': lastUpdated.toIso8601String(),
      'id': id,
      'fullAddress': fullAddress,
      'placeType': placeType,
      'rating': rating,
    };
  }

  /// Créer une copie avec des modifications
  Hotspot copyWith({
    GeoPoint? center,
    int? userCount,
    String? placeName,
    HotspotType? type,
    List<User>? connectedUsers,
    double? distanceFromUser,
    double? radiusMeters,
    DateTime? lastUpdated,
    String? id,
    String? fullAddress,
    String? placeType,
    double? rating,
  }) {
    return Hotspot(
      center: center ?? this.center,
      userCount: userCount ?? this.userCount,
      placeName: placeName ?? this.placeName,
      type: type ?? this.type,
      connectedUsers: connectedUsers ?? this.connectedUsers,
      distanceFromUser: distanceFromUser ?? this.distanceFromUser,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      id: id ?? this.id,
      fullAddress: fullAddress ?? this.fullAddress,
      placeType: placeType ?? this.placeType,
      rating: rating ?? this.rating,
    );
  }

  /// Vérifier si le hotspot est récent (moins de 5 minutes)
  bool get isRecent {
    return DateTime.now().difference(lastUpdated).inMinutes <= 5;
  }

  /// Obtenir une description formatée du nombre d'utilisateurs
  String get userCountDescription {
    if (userCount == 1) {
      return '1 personne connectée';
    } else {
      return '$userCount personnes connectées';
    }
  }

  /// Obtenir une description formatée de la distance
  String get distanceDescription {
    if (distanceFromUser < 0.1) {
      return '${(distanceFromUser * 1000).round()}m';
    } else if (distanceFromUser < 1.0) {
      return '${(distanceFromUser * 1000).round()}m';
    } else {
      return '${distanceFromUser.toStringAsFixed(1)}km';
    }
  }

  /// Obtenir l'intensité du hotspot (0.0 à 1.0)
  double get intensity {
    // Basé sur le nombre d'utilisateurs, normalisé entre 0 et 1
    const maxUsers = 50; // Valeur maximale attendue
    return (userCount / maxUsers).clamp(0.0, 1.0);
  }

  /// Obtenir une couleur basée sur l'intensité
  String get intensityColorHex {
    final intensity = this.intensity;
    if (intensity < 0.3) {
      return '#4CAF50'; // Vert
    } else if (intensity < 0.6) {
      return '#FF9800'; // Orange
    } else {
      return '#F44336'; // Rouge
    }
  }

  /// Vérifier si l'utilisateur donné est dans ce hotspot
  bool containsUser(String userId) {
    return connectedUsers.any((user) => user.userId == userId);
  }

  /// Obtenir les genres représentés dans le hotspot
  Map<String, int> get genderDistribution {
    final Map<String, int> distribution = {};
    for (final user in connectedUsers) {
      final gender = user.userGender.isEmpty ? 'Unknown' : user.userGender;
      distribution[gender] = (distribution[gender] ?? 0) + 1;
    }
    return distribution;
  }

  /// Obtenir l'âge moyen des utilisateurs connectés
  double get averageAge {
    if (connectedUsers.isEmpty) return 0;

    final ages = connectedUsers
        .where((user) => user.userBirthDay > 0)
        .map((user) {
          // Calculer l'âge approximatif à partir de userBirthDay (timestamp)
          final birthYear = DateTime.fromMillisecondsSinceEpoch(
            user.userBirthDay * 1000,
          ).year;
          final currentYear = DateTime.now().year;
          return currentYear - birthYear;
        })
        .where((age) => age > 0 && age < 120); // Filtrer les âges valides

    if (ages.isEmpty) return 0;

    return ages.reduce((a, b) => a + b) / ages.length;
  }

  @override
  String toString() {
    return 'Hotspot{id: $id, placeName: $placeName, userCount: $userCount, type: $type, distance: $distanceDescription}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Hotspot && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
