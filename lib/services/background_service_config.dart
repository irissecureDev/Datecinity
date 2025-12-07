import 'package:flutter/foundation.dart';
import 'package:cheers/services/background_suggestions_service.dart';
import 'package:cheers/models/user_model.dart';

/// Configuration et initialisation du service de suggestions en arrière-plan
class BackgroundServiceConfig {
  static bool _isInitialized = false;

  /// Initialiser le service de suggestions en arrière-plan au démarrage de l'app
  static Future<void> initializeOnStartup() async {
    if (_isInitialized) {
      debugPrint('⚠️ BackgroundServiceConfig: Déjà initialisé');
      return;
    }

    try {
      debugPrint('🚀 BackgroundServiceConfig: Initialisation au démarrage...');

      // Vérifier que l'utilisateur est connecté
      final userModel = UserModel();
      if (userModel.user.userId.isEmpty) {
        debugPrint('⏳ Utilisateur non connecté, initialisation reportée');
        return;
      }

      // Vérifier les préférences utilisateur pour le service en arrière-plan
      final shouldAutoStart = await _checkUserPreferences();

      if (shouldAutoStart) {
        // Initialiser le service en arrière-plan
        final success = await BackgroundSuggestionsService.initialize();

        if (success) {
          debugPrint(
            '✅ Service de suggestions en arrière-plan démarré automatiquement',
          );
        } else {
          debugPrint('❌ Échec du démarrage automatique du service');
        }
      } else {
        debugPrint('📴 Service en arrière-plan désactivé par l\'utilisateur');
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('❌ Erreur initialisation BackgroundServiceConfig: $e');
    }
  }

  /// Démarrer le service manuellement (depuis les paramètres par exemple)
  static Future<bool> startManually() async {
    try {
      debugPrint('🔄 Démarrage manuel du service en arrière-plan...');

      final success = await BackgroundSuggestionsService.initialize();

      if (success) {
        // Sauvegarder la préférence utilisateur
        await _saveUserPreference(true);
        debugPrint('✅ Service démarré manuellement et préférence sauvegardée');
      }

      return success;
    } catch (e) {
      debugPrint('❌ Erreur démarrage manuel: $e');
      return false;
    }
  }

  /// Arrêter le service manuellement
  static Future<void> stopManually() async {
    try {
      debugPrint('🛑 Arrêt manuel du service en arrière-plan...');

      await BackgroundSuggestionsService.stop();

      // Sauvegarder la préférence utilisateur
      await _saveUserPreference(false);
      debugPrint('✅ Service arrêté manuellement et préférence sauvegardée');
    } catch (e) {
      debugPrint('❌ Erreur arrêt manuel: $e');
    }
  }

  /// Vérifier les préférences utilisateur pour le démarrage automatique
  static Future<bool> _checkUserPreferences() async {
    try {
      // Par défaut, on démarre le service (première installation)
      // Dans une vraie app, ceci viendrait d'une base de données ou SharedPreferences
      return true; // Pour les tests, on démarre automatiquement
    } catch (e) {
      debugPrint('❌ Erreur lecture préférences: $e');
      return false; // Par sécurité, ne pas démarrer en cas d'erreur
    }
  }

  /// Sauvegarder la préférence utilisateur
  static Future<void> _saveUserPreference(bool enabled) async {
    try {
      // Ici on sauvegarderait dans SharedPreferences ou Firestore
      // Pour l'instant, on ne fait que logger
      debugPrint('💾 Préférence service arrière-plan: $enabled');
    } catch (e) {
      debugPrint('❌ Erreur sauvegarde préférence: $e');
    }
  }

  /// Vérifier si le service est configuré pour démarrer automatiquement
  static Future<bool> isAutoStartEnabled() async {
    return await _checkUserPreferences();
  }

  /// Activer/désactiver le démarrage automatique
  static Future<void> setAutoStart(bool enabled) async {
    await _saveUserPreference(enabled);

    if (enabled && !BackgroundSuggestionsService.getStats()['isRunning']) {
      await startManually();
    } else if (!enabled &&
        BackgroundSuggestionsService.getStats()['isRunning']) {
      await stopManually();
    }
  }

  /// Réinitialiser la configuration (pour les tests)
  static void reset() {
    _isInitialized = false;
  }

  /// Obtenir le statut d'initialisation
  static bool get isInitialized => _isInitialized;
}
