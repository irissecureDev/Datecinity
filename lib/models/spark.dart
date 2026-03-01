import 'package:cheers/datas/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle pour gérer les "Sparks" - matches de proximité avec compte à rebours
class Spark {
  final String sparkId;
  final User user;
  final DateTime detectedAt;
  final DateTime expiresAt;
  final double distance;
  final double compatibility;
  final Map<String, dynamic>? compatibilityDetails;
  final SparkStatus status;

  Spark({
    required this.sparkId,
    required this.user,
    required this.detectedAt,
    required this.expiresAt,
    required this.distance,
    required this.compatibility,
    this.compatibilityDetails,
    this.status = SparkStatus.pending,
  });

  /// Vérifie si le spark a expiré
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Temps restant avant expiration
  Duration get timeRemaining {
    final remaining = expiresAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Minutes restantes
  int get minutesRemaining => timeRemaining.inMinutes;

  /// Secondes restantes (total)
  int get secondsRemaining => timeRemaining.inSeconds;

  /// Format MM:SS pour affichage
  String get timeRemainingFormatted {
    final minutes = timeRemaining.inMinutes;
    final seconds = timeRemaining.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Créer depuis Firestore
  factory Spark.fromDocument(Map<String, dynamic> doc, User user) {
    final detectedAt = (doc['detected_at'] as Timestamp).toDate();
    final expiresAt = (doc['expires_at'] as Timestamp).toDate();

    return Spark(
      sparkId: doc['spark_id'] ?? '',
      user: user,
      detectedAt: detectedAt,
      expiresAt: expiresAt,
      distance: (doc['distance'] ?? 0.0).toDouble(),
      compatibility: (doc['compatibility'] ?? 0.0).toDouble(),
      compatibilityDetails: doc['compatibility_details'],
      status: SparkStatus.fromString(doc['status'] ?? 'pending'),
    );
  }

  /// Convertir vers Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'spark_id': sparkId,
      'user_id': user.userId,
      'detected_at': Timestamp.fromDate(detectedAt),
      'expires_at': Timestamp.fromDate(expiresAt),
      'distance': distance,
      'compatibility': compatibility,
      'compatibility_details': compatibilityDetails,
      'status': status.value,
    };
  }

  /// Copier avec modifications
  Spark copyWith({
    SparkStatus? status,
    Map<String, dynamic>? compatibilityDetails,
  }) {
    return Spark(
      sparkId: sparkId,
      user: user,
      detectedAt: detectedAt,
      expiresAt: expiresAt,
      distance: distance,
      compatibility: compatibility,
      compatibilityDetails: compatibilityDetails ?? this.compatibilityDetails,
      status: status ?? this.status,
    );
  }
}

/// Statut du Spark
enum SparkStatus {
  pending('pending'), // En attente d'action
  revealed('revealed'), // Utilisateur a révélé le spark
  liked('liked'), // Utilisateur a aimé
  matched('matched'), // Les deux ont aimé = match!
  expired('expired'), // Temps écoulé
  declined('declined'); // Utilisateur a refusé

  final String value;
  const SparkStatus(this.value);

  static SparkStatus fromString(String value) {
    return SparkStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SparkStatus.pending,
    );
  }
}

/// Détails de compatibilité pour l'écran de compatibilité
class CompatibilityDetail {
  final String category;
  final String title;
  final double score;
  final String? description;
  final IconType iconType;

  CompatibilityDetail({
    required this.category,
    required this.title,
    required this.score,
    this.description,
    this.iconType = IconType.star,
  });

  factory CompatibilityDetail.fromMap(Map<String, dynamic> map) {
    return CompatibilityDetail(
      category: map['category'] ?? '',
      title: map['title'] ?? '',
      score: (map['score'] ?? 0.0).toDouble(),
      description: map['description'],
      iconType: IconType.fromString(map['icon_type'] ?? 'star'),
    );
  }
}

enum IconType {
  star('star'),
  heart('heart'),
  chat('chat'),
  energy('energy');

  final String value;
  const IconType(this.value);

  static IconType fromString(String value) {
    return IconType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => IconType.star,
    );
  }
}
