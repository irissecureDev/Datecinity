import 'package:cheers/datas/user.dart';

/// Modèle pour gérer les profils détectés à proximité avec expiration automatique
class ProximityProfile {
  final User user;
  final DateTime detectedAt;
  final double distance; // Distance en kilomètres
  final double compatibility; // Pourcentage de compatibilité (0.0 à 1.0)

  ProximityProfile({
    required this.user,
    required this.detectedAt,
    required this.distance,
    required this.compatibility,
  });

  /// Vérifie si le profil a expiré (plus de 10 minutes)
  bool get isExpired {
    final now = DateTime.now();
    final minutesSinceDetection = now.difference(detectedAt).inMinutes;
    return minutesSinceDetection >= 10;
  }

  /// Temps restant avant expiration en minutes
  int get minutesUntilExpiry {
    final now = DateTime.now();
    final minutesSinceDetection = now.difference(detectedAt).inMinutes;
    final remaining = 10 - minutesSinceDetection;
    return remaining < 0 ? 0 : remaining;
  }

  /// Time remaining before expiry in readable format
  String get timeUntilExpiryFormatted {
    final minutes = minutesUntilExpiry;
    if (minutes <= 0) return 'Expired';
    if (minutes == 1) return '1 minute left';
    return '$minutes minutes left';
  }

  /// Créer depuis un User avec timestamp actuel
  factory ProximityProfile.fromUser({
    required User user,
    required double distance,
    required double compatibility,
  }) {
    return ProximityProfile(
      user: user,
      detectedAt: DateTime.now(),
      distance: distance,
      compatibility: compatibility,
    );
  }

  /// Créer depuis JSON (pour la persistance si nécessaire)
  factory ProximityProfile.fromJson(Map<String, dynamic> json) {
    // Simplifié pour éviter les problèmes de sérialisation
    // Dans une vraie implémentation, il faudrait sérialiser User correctement
    throw UnimplementedError('fromJson not implemented - use fromUser instead');
  }

  /// Convertir vers JSON
  Map<String, dynamic> toJson() {
    // Simplifié pour éviter les problèmes de sérialisation
    // Dans une vraie implémentation, il faudrait sérialiser User correctement
    return {
      'userId': user.userId,
      'userFullname': user.userFullname,
      'detectedAt': detectedAt.toIso8601String(),
      'distance': distance,
      'compatibility': compatibility,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProximityProfile && other.user.userId == user.userId;
  }

  @override
  int get hashCode => user.userId.hashCode;

  @override
  String toString() {
    return 'ProximityProfile(user: ${user.userFullname}, distance: ${distance}km, detected: $detectedAt, expired: $isExpired)';
  }
}

/// Gestionnaire de cache pour les profils de proximité
class ProximityCache {
  static final ProximityCache _instance = ProximityCache._internal();
  factory ProximityCache() => _instance;
  ProximityCache._internal();

  final List<ProximityProfile> _profiles = [];

  /// Ajouter un profil détecté
  void addProfile(ProximityProfile profile) {
    // Éviter les doublons
    _profiles.removeWhere((p) => p.user.userId == profile.user.userId);
    _profiles.add(profile);
    _cleanExpiredProfiles();
  }

  /// Récupérer tous les profils actifs (non expirés)
  List<ProximityProfile> getActiveProfiles() {
    _cleanExpiredProfiles();
    return List.unmodifiable(_profiles);
  }

  /// Récupérer les profils dans une zone de distance spécifique
  List<ProximityProfile> getProfilesInRange(double maxDistanceKm) {
    return getActiveProfiles()
        .where((profile) => profile.distance <= maxDistanceKm)
        .toList();
  }

  /// Récupérer les profils très proches (≤ 0.1 km = 100m)
  List<ProximityProfile> getVeryCloseProfiles() {
    return getProfilesInRange(0.1);
  }

  /// Nettoyer les profils expirés
  void _cleanExpiredProfiles() {
    _profiles.removeWhere((profile) => profile.isExpired);
  }

  /// Vider complètement le cache
  void clearCache() {
    _profiles.clear();
  }

  /// Vérifier si un utilisateur est déjà dans le cache
  bool containsUser(String userId) {
    return _profiles.any((profile) => profile.user.userId == userId);
  }

  /// Obtenir le profil d'un utilisateur spécifique
  ProximityProfile? getProfile(String userId) {
    try {
      return _profiles.firstWhere((profile) => profile.user.userId == userId);
    } catch (e) {
      return null;
    }
  }

  /// Obtenir les statistiques du cache
  Map<String, dynamic> getStats() {
    final active = getActiveProfiles();
    return {
      'total_profiles': _profiles.length,
      'active_profiles': active.length,
      'expired_profiles': _profiles.length - active.length,
      'very_close_profiles': getVeryCloseProfiles().length,
      'cache_age_minutes': _profiles.isEmpty
          ? 0
          : DateTime.now().difference(_profiles.first.detectedAt).inMinutes,
    };
  }
}
