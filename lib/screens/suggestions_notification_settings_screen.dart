import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cheers/models/user_model.dart';
import 'package:cheers/services/suggestions_notifications_service.dart';

/// Interface de paramètres pour les notifications intelligentes de suggestions
///
/// Permet à l'utilisateur de configurer:
/// - Types de notifications à recevoir
/// - Fréquence des notifications
/// - Seuils de compatibilité
class SuggestionsNotificationSettingsScreen extends StatefulWidget {
  const SuggestionsNotificationSettingsScreen({super.key});

  @override
  State<SuggestionsNotificationSettingsScreen> createState() =>
      _SuggestionsNotificationSettingsScreenState();
}

class _SuggestionsNotificationSettingsScreenState
    extends State<SuggestionsNotificationSettingsScreen> {
  final SuggestionsNotificationsService _notificationsService =
      SuggestionsNotificationsService();

  // État des préférences
  Map<String, bool> _preferences = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  /// Charger les préférences actuelles
  Future<void> _loadPreferences() async {
    try {
      final preferences = await _notificationsService
          .getUserNotificationPreferences(UserModel().user.userId);

      setState(() {
        _preferences = preferences;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Erreur lors du chargement des préférences');
    }
  }

  /// Sauvegarder les préférences
  Future<void> _savePreferences() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await _notificationsService.updateNotificationPreferences(
        UserModel().user.userId,
        _preferences,
      );

      _showSuccessSnackBar('Préférences sauvegardées avec succès');
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la sauvegarde');
    }

    setState(() {
      _isSaving = false;
    });
  }

  /// Afficher message de succès
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Afficher message d'erreur
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
              ],
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Notifications Intelligentes',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save, color: Colors.white),
              onPressed: _savePreferences,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête explicatif
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.smart_toy,
                                color: Theme.of(context).primaryColor,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Notifications Intelligentes',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Recevez des notifications personnalisées pour les matches '
                            'les plus pertinents selon votre compatibilité et votre localisation.',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Types de notifications
                  const Text(
                    'Types de notifications',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Matches haute compatibilité
                  _buildNotificationTile(
                    title: 'Matches haute compatibilité',
                    subtitle:
                        'Notifications pour les profils très compatibles (80%+)',
                    icon: Icons.favorite,
                    iconColor: Colors.red,
                    key: 'high_compatibility_matches',
                  ),

                  // Matches à proximité
                  _buildNotificationTile(
                    title: 'Matches à proximité',
                    subtitle:
                        'Notifications pour les profils proches géographiquement',
                    icon: Icons.location_on,
                    iconColor: Colors.blue,
                    key: 'nearby_matches',
                  ),

                  // Nouveaux matches
                  _buildNotificationTile(
                    title: 'Nouveaux matches',
                    subtitle:
                        'Notifications pour de nouveaux profils compatibles',
                    icon: Icons.new_releases,
                    iconColor: Colors.green,
                    key: 'new_matches',
                  ),

                  // Suggestions quotidiennes
                  _buildNotificationTile(
                    title: 'Résumé quotidien',
                    subtitle:
                        'Une notification par jour avec vos meilleures suggestions',
                    icon: Icons.schedule,
                    iconColor: Colors.orange,
                    key: 'daily_suggestions',
                  ),

                  const SizedBox(height: 30),

                  // Informations sur la fréquence
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Fréquence des notifications',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• Maximum 3 notifications par jour\n'
                            '• Délai minimum de 6h entre notifications\n'
                            '• Algorithme intelligent pour éviter le spam',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Bouton de test (pour développement)
                  if (kDebugMode) ...[
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text(
                      'Mode développement',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await _notificationsService.onUserLogin(
                          UserModel().user.userId,
                        );
                        _showSuccessSnackBar('Test de notification envoyé');
                      },
                      icon: const Icon(Icons.bug_report),
                      label: const Text('Tester les notifications'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade300,
                        foregroundColor: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  /// Widget pour une ligne de paramètre de notification
  Widget _buildNotificationTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required String key,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        value: _preferences[key] ?? false,
        onChanged: (bool value) {
          setState(() {
            _preferences[key] = value;
          });
        },
        activeColor: Theme.of(context).primaryColor,
      ),
    );
  }
}
