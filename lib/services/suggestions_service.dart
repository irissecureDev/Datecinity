import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cheers/datas/user.dart';
import 'package:cheers/models/user_model.dart';
import 'package:cheers/models/proximity_profile.dart';
import 'package:flutter/foundation.dart';

/// Service pour gérer les suggestions de profils proches et compatibles
class SuggestionsService {
  static final SuggestionsService _instance = SuggestionsService._internal();
  factory SuggestionsService() => _instance;
  SuggestionsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Configuration par défaut
  static const double _defaultMaxDistance = 50.0; // km
  static const double _defaultCompatibilityThreshold = 75.0; // %
  static const int _maxSuggestions = 10;

  /// Cache pour optimiser les performances
  List<User>? _cachedSuggestions;
  DateTime? _lastCacheUpdate;
  static const Duration _cacheValidDuration = Duration(minutes: 15);

  /// Cache spécialisé pour les profils de proximité avec expiration de 10 minutes
  final ProximityCache _proximityCache = ProximityCache();

  /// Point 1: Obtenir des suggestions de profils
  Future<List<User>> getSuggestions({
    double? maxDistance,
    double? compatibilityThreshold,
    int? maxResults,
  }) async {
    try {
      debugPrint(
        '🎯 SuggestionsService: Démarrage de la recherche de suggestions',
      );

      final currentUser = UserModel().user;
      debugPrint(
        '📍 Position utilisateur: ${currentUser.userGeoPoint.latitude}, ${currentUser.userGeoPoint.longitude}',
      );

      // Utiliser le cache si valide
      if (_isCacheValid()) {
        debugPrint('📦 Utilisation du cache de suggestions');
        return _cachedSuggestions!;
      }

      final suggestions = await _findSuggestions(
        currentUser,
        maxDistance ?? _defaultMaxDistance,
        compatibilityThreshold ?? _defaultCompatibilityThreshold,
        maxResults ?? _maxSuggestions,
      );

      // Mettre à jour le cache
      _cachedSuggestions = suggestions;
      _lastCacheUpdate = DateTime.now();

      debugPrint('✅ ${suggestions.length} suggestions trouvées');
      return suggestions;
    } catch (e) {
      debugPrint('❌ Erreur lors de la recherche de suggestions: $e');
      return [];
    }
  }

  /// Méthode principale de recherche (sera étendue dans les points suivants)
  Future<List<User>> _findSuggestions(
    User currentUser,
    double maxDistance,
    double compatibilityThreshold,
    int maxResults,
  ) async {
    debugPrint(
      '🔍 Recherche avec critères: distance≤${maxDistance}km, compatibilité≥$compatibilityThreshold%',
    );

    // Point 2: Filtrage géographique
    final candidatesInRange = await _getUsersInRange(
      currentUser.userGeoPoint,
      maxDistance,
      maxResults * 2, // Récupérer plus de candidats pour filtrer ensuite
    );

    debugPrint(
      '📍 ${candidatesInRange.length} utilisateurs trouvés dans un rayon de ${maxDistance}km',
    );

    // Point 3: Appliquer les filtres de base
    final filteredCandidates = await _applyBasicFilters(
      currentUser,
      candidatesInRange,
    );

    debugPrint(
      '🔍 ${filteredCandidates.length} utilisateurs après filtrage de base',
    );

    // Point 4: Calculer la compatibilité avancée
    List<Map<String, dynamic>> candidatesWithScores = [];
    for (User candidate in filteredCandidates) {
      double distance = calculateDistance(
        currentUser.userGeoPoint,
        candidate.userGeoPoint,
      );

      double compatibilityScore = _calculateAdvancedCompatibility(
        currentUser,
        candidate,
        distance,
      );

      candidatesWithScores.add({
        'user': candidate,
        'distance': distance,
        'compatibilityScore': compatibilityScore,
      });
    }

    // Trier par score de compatibilité (décroissant)
    candidatesWithScores.sort(
      (a, b) => b['compatibilityScore'].compareTo(a['compatibilityScore']),
    );

    // Filtrer par seuil de compatibilité minimum
    candidatesWithScores = candidatesWithScores
        .where(
          (candidate) =>
              candidate['compatibilityScore'] >= compatibilityThreshold,
        )
        .toList();

    debugPrint(
      '🎯 ${candidatesWithScores.length} utilisateurs avec compatibilité ≥ ${(compatibilityThreshold * 100).toInt()}%',
    );

    return candidatesWithScores
        .take(maxResults)
        .map((item) => item['user'] as User)
        .toList();
  }

  /// Point 2: Rechercher les utilisateurs dans un rayon géographique
  Future<List<User>> _getUsersInRange(
    GeoPoint centerPoint,
    double radiusKm,
    int maxResults,
  ) async {
    try {
      // Calculer les bounds approximatifs pour optimiser la requête
      final bounds = _calculateGeoBounds(centerPoint, radiusKm);

      debugPrint(
        '🗺️ Recherche dans les bounds: lat ${bounds['minLat']}-${bounds['maxLat']}, lon ${bounds['minLon']}-${bounds['maxLon']}',
      );

      // Requête Firestore avec filtre géographique approximatif
      final querySnapshot = await _firestore
          .collection('Users')
          .where(
            'userGeoPoint.latitude',
            isGreaterThanOrEqualTo: bounds['minLat'],
          )
          .where('userGeoPoint.latitude', isLessThanOrEqualTo: bounds['maxLat'])
          .limit(maxResults)
          .get();

      final List<User> usersInRange = [];
      final currentUserId = UserModel().user.userId;

      for (final doc in querySnapshot.docs) {
        try {
          final userData = doc.data();
          final user = User.fromDocument(userData);

          // Exclure l'utilisateur actuel
          if (user.userId == currentUserId) {
            continue;
          }

          // Vérifier la distance exacte
          final distance = calculateDistance(centerPoint, user.userGeoPoint);
          if (distance <= radiusKm) {
            usersInRange.add(user);
            debugPrint(
              '✅ Utilisateur ${user.userFullname} à ${distance.toStringAsFixed(1)}km',
            );
          }
        } catch (e) {
          debugPrint('⚠️ Erreur lors du parsing de l\'utilisateur: $e');
          continue;
        }
      }

      // Trier par distance croissante
      usersInRange.sort((a, b) {
        final distanceA = calculateDistance(centerPoint, a.userGeoPoint);
        final distanceB = calculateDistance(centerPoint, b.userGeoPoint);
        return distanceA.compareTo(distanceB);
      });

      return usersInRange;
    } catch (e) {
      debugPrint('❌ Erreur lors de la recherche géographique: $e');
      return [];
    }
  }

  /// Calculer les bounds géographiques approximatifs pour un rayon donné
  Map<String, double> _calculateGeoBounds(GeoPoint center, double radiusKm) {
    // Approximation: 1 degré de latitude ≈ 111 km
    // 1 degré de longitude ≈ 111 km * cos(latitude)
    const double kmPerDegreeLat = 111.0;
    final double kmPerDegreeLon = 111.0 * cos(center.latitude * pi / 180);

    final double deltaLat = radiusKm / kmPerDegreeLat;
    final double deltaLon = radiusKm / kmPerDegreeLon;

    return {
      'minLat': center.latitude - deltaLat,
      'maxLat': center.latitude + deltaLat,
      'minLon': center.longitude - deltaLon,
      'maxLon': center.longitude + deltaLon,
    };
  }

  /// Calculer la distance entre deux points géographiques
  double calculateDistance(GeoPoint point1, GeoPoint point2) {
    const double earthRadius = 6371; // Rayon de la Terre en km

    final lat1Rad = point1.latitude * pi / 180;
    final lat2Rad = point2.latitude * pi / 180;
    final deltaLatRad = (point2.latitude - point1.latitude) * pi / 180;
    final deltaLonRad = (point2.longitude - point1.longitude) * pi / 180;

    final a =
        sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) *
            cos(lat2Rad) *
            sin(deltaLonRad / 2) *
            sin(deltaLonRad / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// Vérifier si le cache est valide
  bool _isCacheValid() {
    return _cachedSuggestions != null &&
        _lastCacheUpdate != null &&
        DateTime.now().difference(_lastCacheUpdate!) < _cacheValidDuration;
  }

  /// Invalider le cache
  void invalidateCache() {
    _cachedSuggestions = null;
    _lastCacheUpdate = null;
    debugPrint('🗑️ Cache de suggestions invalidé');
  }

  /// Obtenir les statistiques du service
  Map<String, dynamic> getServiceStats() {
    return {
      'cache_valid': _isCacheValid(),
      'cached_suggestions_count': _cachedSuggestions?.length ?? 0,
      'last_cache_update': _lastCacheUpdate?.toIso8601String(),
      'proximity_cache_stats': _proximityCache.getStats(),
    };
  }

  // ====================
  // NOUVELLES MÉTHODES POUR LA PROXIMITÉ AVEC EXPIRATION
  // ====================

  /// Détecter et ajouter les nouveaux profils de proximité
  /// Cette méthode est appelée lors des mises à jour de position
  Future<List<ProximityProfile>> detectNewProximityProfiles({
    double maxDistanceKm = 0.1, // 100 mètres par défaut
    double minCompatibility = 0.5,
  }) async {
    try {
      debugPrint(
        '🔍 Détection profils proximité: ${maxDistanceKm}km, compatibilité ≥ ${(minCompatibility * 100).round()}%',
      );

      final currentUser = UserModel().user;
      final suggestions = await _findSuggestions(
        currentUser,
        maxDistanceKm,
        minCompatibility,
        20, // Limite pour éviter la surcharge
      );

      final List<ProximityProfile> newProfiles = [];

      for (final user in suggestions) {
        final distance = calculateDistance(
          currentUser.userGeoPoint,
          user.userGeoPoint,
        );

        // Calculer la compatibilité avancée
        final compatibility = _calculateAdvancedCompatibility(
          currentUser,
          user,
          distance,
        );

        // Vérifier si le profil n'est pas déjà dans le cache
        if (!_proximityCache.containsUser(user.userId)) {
          final proximityProfile = ProximityProfile.fromUser(
            user: user,
            distance: distance,
            compatibility: compatibility,
          );

          _proximityCache.addProfile(proximityProfile);
          newProfiles.add(proximityProfile);

          debugPrint(
            '✨ Nouveau profil proximité détecté: ${user.userFullname} à ${(distance * 1000).round()}m (${(compatibility * 100).round()}% compatible)',
          );
        }
      }

      if (newProfiles.isNotEmpty) {
        debugPrint(
          '🎯 ${newProfiles.length} nouveaux profils de proximité détectés',
        );
      }

      return newProfiles;
    } catch (e) {
      debugPrint('❌ Erreur détection profils proximité: $e');
      return [];
    }
  }

  /// Obtenir tous les profils de proximité actifs (non expirés)
  List<ProximityProfile> getActiveProximityProfiles() {
    return _proximityCache.getActiveProfiles();
  }

  /// Obtenir les profils de proximité groupés par distance
  Map<String, List<ProximityProfile>> getProximityProfilesByDistance() {
    final activeProfiles = getActiveProximityProfiles();

    final Map<String, List<ProximityProfile>> grouped = {
      '5m': [],
      '10m': [],
      '25m': [],
      '50m': [],
      '100m+': [],
    };

    for (final profile in activeProfiles) {
      final distanceM = profile.distance * 1000; // Convertir en mètres

      if (distanceM <= 5) {
        grouped['5m']!.add(profile);
      } else if (distanceM <= 10) {
        grouped['10m']!.add(profile);
      } else if (distanceM <= 25) {
        grouped['25m']!.add(profile);
      } else if (distanceM <= 50) {
        grouped['50m']!.add(profile);
      } else {
        grouped['100m+']!.add(profile);
      }
    }

    return grouped;
  }

  /// Obtenir les profils très proches nécessitant une notification
  List<ProximityProfile> getProfilesRequiringNotification() {
    return _proximityCache
        .getVeryCloseProfiles()
        .where(
          (profile) => profile.compatibility >= 0.7,
        ) // 70% de compatibilité minimum
        .toList();
  }

  /// Nettoyer le cache de proximité (supprimer les profils expirés)
  void cleanProximityCache() {
    final statsBefore = _proximityCache.getStats();
    _proximityCache.getActiveProfiles(); // Déclenche le nettoyage automatique
    final statsAfter = _proximityCache.getStats();

    if (statsBefore['expired_profiles'] > 0) {
      debugPrint(
        '🧹 Cache proximité nettoyé: ${statsBefore['expired_profiles']} profils expirés supprimés',
      );
    }
  }

  /// Vider complètement le cache de proximité
  void clearProximityCache() {
    _proximityCache.clearCache();
    debugPrint('🗑️ Cache de proximité vidé complètement');
  }

  /// Point 3: Appliquer les filtres de base pour exclure les profils inappropriés
  Future<List<User>> _applyBasicFilters(
    User currentUser,
    List<User> candidates,
  ) async {
    final List<User> filteredUsers = [];

    // Obtenir les listes d'exclusion
    final likedUserIds = await _getLikedUserIds(currentUser.userId);
    final dislikedUserIds = await _getDislikedUserIds(currentUser.userId);
    final blockedUserIds = await _getBlockedUserIds(currentUser.userId);

    debugPrint(
      '🚫 Exclusions: ${likedUserIds.length} likés, ${dislikedUserIds.length} dislikés, ${blockedUserIds.length} bloqués',
    );

    for (final candidate in candidates) {
      // Filtre 1: Exclure les utilisateurs déjà likés
      if (likedUserIds.contains(candidate.userId)) {
        debugPrint('⚠️ Exclu ${candidate.userFullname}: déjà liké');
        continue;
      }

      // Filtre 2: Exclure les utilisateurs dislikés
      if (dislikedUserIds.contains(candidate.userId)) {
        debugPrint('⚠️ Exclu ${candidate.userFullname}: déjà disliké');
        continue;
      }

      // Filtre 3: Exclure les utilisateurs bloqués
      if (blockedUserIds.contains(candidate.userId)) {
        debugPrint('⚠️ Exclu ${candidate.userFullname}: bloqué');
        continue;
      }

      // Filtre 4: Vérifier les critères d'âge
      if (!_isAgeCompatible(currentUser, candidate)) {
        debugPrint('⚠️ Exclu ${candidate.userFullname}: âge incompatible');
        continue;
      }

      // Filtre 5: Vérifier les critères de genre
      if (!_isGenderCompatible(currentUser, candidate)) {
        debugPrint('⚠️ Exclu ${candidate.userFullname}: genre incompatible');
        continue;
      }

      // Filtre 6: Vérifier l'activité récente (dernière connexion < 30 jours)
      if (!_isActiveUser(candidate)) {
        debugPrint('⚠️ Exclu ${candidate.userFullname}: utilisateur inactif');
        continue;
      }

      // Si tous les filtres passent, ajouter à la liste
      filteredUsers.add(candidate);
      debugPrint('✅ ${candidate.userFullname} ajouté aux suggestions');
    }

    return filteredUsers;
  }

  /// Obtenir les IDs des utilisateurs likés
  Future<Set<String>> _getLikedUserIds(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('Likes')
          .where('likedBy', isEqualTo: userId)
          .get();

      return querySnapshot.docs
          .map((doc) => doc['likedUser'] as String)
          .toSet();
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des likes: $e');
      return <String>{};
    }
  }

  /// Obtenir les IDs des utilisateurs dislikés
  Future<Set<String>> _getDislikedUserIds(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('Dislikes')
          .where('dislikedBy', isEqualTo: userId)
          .get();

      return querySnapshot.docs
          .map((doc) => doc['dislikedUser'] as String)
          .toSet();
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des dislikes: $e');
      return <String>{};
    }
  }

  /// Obtenir les IDs des utilisateurs bloqués
  Future<Set<String>> _getBlockedUserIds(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('BlockedUsers')
          .where('blockedBy', isEqualTo: userId)
          .get();

      return querySnapshot.docs
          .map((doc) => doc['blockedUser'] as String)
          .toSet();
    } catch (e) {
      debugPrint(
        '❌ Erreur lors de la récupération des utilisateurs bloqués: $e',
      );
      return <String>{};
    }
  }

  /// Vérifier la compatibilité d'âge
  bool _isAgeCompatible(User currentUser, User candidate) {
    final currentUserAge = UserModel().calculateUserAge(
      DateTime(
        currentUser.userBirthYear,
        currentUser.userBirthMonth,
        currentUser.userBirthDay,
      ),
    );

    final candidateAge = UserModel().calculateUserAge(
      DateTime(
        candidate.userBirthYear,
        candidate.userBirthMonth,
        candidate.userBirthDay,
      ),
    );

    // Règle simple: différence d'âge maximum de 15 ans
    // TODO: Utiliser les préférences utilisateur pour des critères plus précis
    final ageDifference = (currentUserAge - candidateAge).abs();
    return ageDifference <= 15;
  }

  /// Vérifier la compatibilité de genre
  bool _isGenderCompatible(User currentUser, User candidate) {
    // Règle simple pour l'instant
    // TODO: Implémenter selon les préférences de genre de l'utilisateur
    return currentUser.userGender != candidate.userGender;
  }

  /// Vérifier si l'utilisateur est actif
  bool _isActiveUser(User candidate) {
    final now = DateTime.now();
    final lastLogin = candidate.userLastLogin;
    final daysSinceLastLogin = now.difference(lastLogin).inDays;

    // Considérer comme actif si connecté dans les 30 derniers jours
    return daysSinceLastLogin <= 30;
  }

  // ====================
  // POINT 4: ALGORITHME DE COMPATIBILITÉ AVANCÉE
  // ====================

  /// Calculer la compatibilité avancée entre deux utilisateurs
  ///
  /// Pondération des critères:
  /// - Compatibilité du quiz: 40%
  /// - Intérêts communs: 25%
  /// - Compatibilité démographique: 20%
  /// - Niveau d'activité: 10%
  /// - Bonus géographique: 5%
  double _calculateAdvancedCompatibility(
    User currentUser,
    User candidate,
    double distance,
  ) {
    try {
      // Calcul des différents scores de compatibilité
      double quizScore = _calculateQuizCompatibility(currentUser, candidate);
      double interestsScore = _calculateInterestsCompatibility(
        currentUser,
        candidate,
      );
      double demographicsScore = _calculateDemographicsCompatibility(
        currentUser,
        candidate,
      );
      double activityScore = _calculateActivityCompatibility(
        currentUser,
        candidate,
      );
      double geographicBonus = _calculateGeographicBonus(distance);

      // Application de la pondération
      double totalScore =
          (quizScore * 0.40) +
          (interestsScore * 0.25) +
          (demographicsScore * 0.20) +
          (activityScore * 0.10) +
          (geographicBonus * 0.05);

      return totalScore.clamp(0.0, 1.0);
    } catch (e) {
      debugPrint('Erreur calcul compatibilité: $e');
      return 0.5; // Score neutre en cas d'erreur
    }
  }

  /// Calculer la compatibilité basée sur les réponses au quiz
  /// TEMPORAIRE: utilise les préférences disponibles en attendant l'implémentation du quiz
  double _calculateQuizCompatibility(User currentUser, User candidate) {
    try {
      // Pour l'instant, utilisons les préférences utilisateur disponibles
      final currentUserPrefs = currentUser.preferences;
      final candidatePrefs = candidate.preferences;

      if (currentUserPrefs == null || candidatePrefs == null) {
        return 0.5; // Score neutre si pas de préférences
      }

      // Calculer une compatibilité basique basée sur les préférences disponibles
      double score = 0.5; // Score de base

      // Bonus si les utilisateurs ont des préférences complètes
      if (currentUserPrefs.isNotEmpty && candidatePrefs.isNotEmpty) {
        score += 0.2;
      }

      return score.clamp(0.0, 1.0);
    } catch (e) {
      debugPrint('Erreur calcul compatibilité quiz: $e');
      return 0.5;
    }
  }

  /// Calculer la compatibilité basée sur les intérêts communs
  double _calculateInterestsCompatibility(User currentUser, User candidate) {
    try {
      // Utiliser les hobbies au lieu de userInterests
      final currentInterests = currentUser.hobbies;
      final candidateInterests = candidate.hobbies;

      if (currentInterests.isEmpty && candidateInterests.isEmpty) {
        return 0.7; // Score neutre-positif si aucun intérêt renseigné
      }

      if (currentInterests.isEmpty || candidateInterests.isEmpty) {
        return 0.3; // Score faible si un seul a des intérêts
      }

      // Calculer la similarité Jaccard
      Set<String> currentSet = currentInterests.toSet();
      Set<String> candidateSet = candidateInterests.toSet();

      int intersection = currentSet.intersection(candidateSet).length;
      int union = currentSet.union(candidateSet).length;

      double jaccardSimilarity = union > 0 ? intersection / union : 0.0;

      // Bonus pour un nombre élevé d'intérêts communs
      double bonus = intersection >= 3 ? 0.1 : 0.0;

      return (jaccardSimilarity + bonus).clamp(0.0, 1.0);
    } catch (e) {
      debugPrint('Erreur calcul compatibilité intérêts: $e');
      return 0.5;
    }
  }

  /// Calculer la compatibilité démographique
  double _calculateDemographicsCompatibility(User currentUser, User candidate) {
    try {
      double ageScore = _calculateAgeCompatibility(currentUser, candidate);
      double educationScore = _calculateEducationCompatibility(
        currentUser,
        candidate,
      );
      double professionScore = _calculateProfessionCompatibility(
        currentUser,
        candidate,
      );

      // Pondération: âge 50%, éducation 30%, profession 20%
      return (ageScore * 0.5) +
          (educationScore * 0.3) +
          (professionScore * 0.2);
    } catch (e) {
      debugPrint('Erreur calcul compatibilité démographique: $e');
      return 0.5;
    }
  }

  /// Calculer l'âge à partir des composants de date de naissance
  int _calculateAge(int birthDay, int birthMonth, int birthYear) {
    DateTime birthDate = DateTime(birthYear, birthMonth, birthDay);
    DateTime currentDate = DateTime.now();

    int age = currentDate.year - birthDate.year;

    if (currentDate.month < birthDate.month ||
        (currentDate.month == birthDate.month &&
            currentDate.day < birthDate.day)) {
      age--;
    }

    return age;
  }

  /// Calculer la compatibilité d'âge
  double _calculateAgeCompatibility(User currentUser, User candidate) {
    try {
      int currentAge = _calculateAge(
        currentUser.userBirthDay,
        currentUser.userBirthMonth,
        currentUser.userBirthYear,
      );
      int candidateAge = _calculateAge(
        candidate.userBirthDay,
        candidate.userBirthMonth,
        candidate.userBirthYear,
      );

      int ageDifference = (currentAge - candidateAge).abs();

      // Score optimal pour différence de 0-3 ans
      if (ageDifference <= 3) return 1.0;
      // Score bon pour différence de 4-7 ans
      if (ageDifference <= 7) return 0.8;
      // Score acceptable pour différence de 8-12 ans
      if (ageDifference <= 12) return 0.6;
      // Score faible pour différence de 13-20 ans
      if (ageDifference <= 20) return 0.3;
      // Score très faible au-delà
      return 0.1;
    } catch (e) {
      return 0.5;
    }
  }

  /// Calculer la compatibilité d'éducation
  double _calculateEducationCompatibility(User currentUser, User candidate) {
    final currentEducation = currentUser.education.toLowerCase();
    final candidateEducation = candidate.education.toLowerCase();

    if (currentEducation.isEmpty || candidateEducation.isEmpty) {
      return 0.6; // Score neutre si information manquante
    }

    // Groupes d'éducation compatibles
    final educationGroups = {
      'high school': ['high school', 'bachelor'],
      'bachelor': ['high school', 'bachelor', 'master'],
      'master': ['bachelor', 'master', 'doctorate'],
      'doctorate': ['master', 'doctorate'],
      'none': ['none', 'other'],
      'other': ['none', 'other'],
    };

    if (currentEducation == candidateEducation) return 1.0;

    if (educationGroups[currentEducation]?.contains(candidateEducation) ==
        true) {
      return 0.8;
    }

    return 0.4;
  }

  /// Calculer la compatibilité professionnelle (basée sur la religion pour l'instant)
  double _calculateProfessionCompatibility(User currentUser, User candidate) {
    // Utilisons la religion comme proxy pour la compatibilité de valeurs
    final currentReligion = currentUser.religion.toLowerCase();
    final candidateReligion = candidate.religion.toLowerCase();

    if (currentReligion.isEmpty || candidateReligion.isEmpty) {
      return 0.6; // Score neutre si information manquante
    }

    if (currentReligion == candidateReligion) return 1.0;

    // Religions compatibles
    final compatibleReligions = {
      'none': ['none', 'spiritual'],
      'spiritual': ['none', 'spiritual'],
      'other': ['none', 'spiritual', 'other'],
    };

    if (compatibleReligions[currentReligion]?.contains(candidateReligion) ==
        true) {
      return 0.7;
    }

    return 0.4;
  }

  /// Calculer la compatibilité basée sur l'activité
  double _calculateActivityCompatibility(User currentUser, User candidate) {
    try {
      double currentActivity = _calculateUserActivityLevel(currentUser);
      double candidateActivity = _calculateUserActivityLevel(candidate);

      // Score basé sur la proximité des niveaux d'activité
      double difference = (currentActivity - candidateActivity).abs();

      if (difference <= 0.2) return 1.0;
      if (difference <= 0.4) return 0.8;
      if (difference <= 0.6) return 0.6;
      return 0.3;
    } catch (e) {
      debugPrint('Erreur calcul compatibilité activité: $e');
      return 0.5;
    }
  }

  /// Calculer le niveau d'activité d'un utilisateur
  double _calculateUserActivityLevel(User user) {
    double score = 0.0;
    int factors = 0;

    // Facteur 1: Fréquence de connexion
    final now = DateTime.now();
    final daysSinceLastLogin = now.difference(user.userLastLogin).inDays;
    if (daysSinceLastLogin <= 1) {
      score += 1.0;
    } else if (daysSinceLastLogin <= 7) {
      score += 0.8;
    } else if (daysSinceLastLogin <= 30) {
      score += 0.4;
    } else {
      score += 0.1;
    }
    factors++;

    // Facteur 2: Complétude du profil
    double profileCompleteness = _calculateProfileCompleteness(user);
    score += profileCompleteness;
    factors++;

    // Facteur 3: Nombre d'intérêts (utiliser hobbies)
    int interestsCount = user.hobbies.length;
    if (interestsCount >= 5) {
      score += 1.0;
    } else if (interestsCount >= 3) {
      score += 0.7;
    } else if (interestsCount >= 1) {
      score += 0.4;
    } else {
      score += 0.0;
    }
    factors++;

    return factors > 0 ? score / factors : 0.0;
  }

  /// Calculer la complétude du profil
  double _calculateProfileCompleteness(User user) {
    int completedFields = 0;
    int totalFields = 8;

    if (user.userFullname.isNotEmpty) completedFields++;
    if (user.userBirthYear > 1900) completedFields++; // Vérifier année valide
    if (user.userProfilePhoto.isNotEmpty) completedFields++;
    if (user.userBio.isNotEmpty) completedFields++;
    if (user.education.isNotEmpty) completedFields++;
    if (user.religion.isNotEmpty) completedFields++;
    if (user.hobbies.isNotEmpty) completedFields++;
    if (user.preferences != null && user.preferences!.isNotEmpty) {
      completedFields++;
    }

    return completedFields / totalFields;
  }

  /// Calculer le bonus géographique
  double _calculateGeographicBonus(double distance) {
    // Bonus basé sur la proximité géographique
    if (distance <= 5) return 1.0; // Très proche: bonus maximum
    if (distance <= 15) return 0.8; // Proche: bon bonus
    if (distance <= 30) return 0.6; // Modéré: bonus moyen
    if (distance <= 50) return 0.4; // Distant: petit bonus
    return 0.2; // Très distant: bonus minimal
  }
}
