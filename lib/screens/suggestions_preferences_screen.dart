import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cheers/models/user_model.dart';

/// Écran de paramètres des préférences de suggestions
/// 
/// Permet à l'utilisateur de configurer:
/// - Critères de distance
/// - Tranche d'âge préférée
/// - Niveau de compatibilité minimum
/// - Types de notifications de suggestions
/// - Fréquence des suggestions
class SuggestionsPreferencesScreen extends StatefulWidget {
  const SuggestionsPreferencesScreen({super.key});

  @override
  State<SuggestionsPreferencesScreen> createState() => _SuggestionsPreferencesScreenState();
}

class _SuggestionsPreferencesScreenState extends State<SuggestionsPreferencesScreen> {
  
  // Préférences de suggestions
  double _maxDistance = 50.0;
  double _minCompatibility = 0.3;
  int _minAge = 18;
  int _maxAge = 100;
  bool _enableSmartNotifications = true;
  bool _enableHighCompatibilityAlerts = true;
  bool _enableNewUsersAlerts = false;
  bool _enableActivityAlerts = true;
  String _suggestionFrequency = 'daily'; // daily, weekly, realtime
  
  // Interface
  bool _hasChanges = false;
  
  @override
  void initState() {
    super.initState();
    _loadCurrentPreferences();
  }
  
  /// Charger les préférences actuelles de l'utilisateur
  void _loadCurrentPreferences() {
    final currentUser = UserModel().user;
    final userSettings = currentUser.userSettings ?? {};
    final suggestionsPrefs = userSettings['suggestions_preferences'] ?? {};
    
    setState(() {
      _maxDistance = (suggestionsPrefs['max_distance'] ?? 50.0).toDouble();
      _minCompatibility = (suggestionsPrefs['min_compatibility'] ?? 0.3).toDouble();
      _minAge = suggestionsPrefs['min_age'] ?? 18;
      _maxAge = suggestionsPrefs['max_age'] ?? 100;
      _enableSmartNotifications = suggestionsPrefs['enable_smart_notifications'] ?? true;
      _enableHighCompatibilityAlerts = suggestionsPrefs['enable_high_compatibility_alerts'] ?? true;
      _enableNewUsersAlerts = suggestionsPrefs['enable_new_users_alerts'] ?? false;
      _enableActivityAlerts = suggestionsPrefs['enable_activity_alerts'] ?? true;
      _suggestionFrequency = suggestionsPrefs['suggestion_frequency'] ?? 'daily';
    });
  }
  
  /// Sauvegarder les préférences
  Future<void> _savePreferences() async {
    final preferences = {
      'max_distance': _maxDistance,
      'min_compatibility': _minCompatibility,
      'min_age': _minAge,
      'max_age': _maxAge,
      'enable_smart_notifications': _enableSmartNotifications,
      'enable_high_compatibility_alerts': _enableHighCompatibilityAlerts,
      'enable_new_users_alerts': _enableNewUsersAlerts,
      'enable_activity_alerts': _enableActivityAlerts,
      'suggestion_frequency': _suggestionFrequency,
      'last_updated': DateTime.now().toIso8601String(),
    };
    
    try {
      // TODO: Sauvegarder dans Firestore
      debugPrint('💾 Sauvegarde des préférences: $preferences');
      
      // Haptic feedback pour confirmer la sauvegarde
      HapticFeedback.heavyImpact();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Préférences sauvegardées'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      setState(() {
        _hasChanges = false;
      });
      
      // Retour automatique après sauvegarde
      Future.delayed(Duration(seconds: 1), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
      
    } catch (e) {
      debugPrint('❌ Erreur sauvegarde préférences: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur lors de la sauvegarde'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
  
  /// Marquer qu'il y a des changements
  void _markAsChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _hasChanges ? _buildSaveButton() : null,
    );
  }
  
  /// Construire l'AppBar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
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
        icon: Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () {
          if (_hasChanges) {
            _showDiscardDialog();
          } else {
            Navigator.of(context).pop();
          }
        },
      ),
      title: Text(
        'Préférences de Suggestions',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        if (_hasChanges)
          IconButton(
            icon: Icon(Icons.save, color: Colors.white),
            onPressed: _savePreferences,
          ),
      ],
    );
  }
  
  /// Construire le corps de la page
  Widget _buildBody() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCriteriaSection(),
          SizedBox(height: 24),
          _buildNotificationsSection(),
          SizedBox(height: 24),
          _buildFrequencySection(),
          SizedBox(height: 80), // Espace pour le bouton flottant
        ],
      ),
    );
  }
  
  /// Section des critères de recherche
  Widget _buildCriteriaSection() {
    return _buildSection(
      title: 'Critères de Recherche',
      icon: Icons.tune,
      children: [
        // Distance maximale
        _buildSliderTile(
          title: 'Distance maximale',
          subtitle: '${_maxDistance.round()} km',
          value: _maxDistance,
          min: 5,
          max: 100,
          divisions: 19,
          onChanged: (value) {
            setState(() {
              _maxDistance = value;
            });
            _markAsChanged();
          },
        ),
        
        // Compatibilité minimale
        _buildSliderTile(
          title: 'Compatibilité minimale',
          subtitle: '${(_minCompatibility * 100).round()}%',
          value: _minCompatibility,
          min: 0.0,
          max: 1.0,
          divisions: 10,
          onChanged: (value) {
            setState(() {
              _minCompatibility = value;
            });
            _markAsChanged();
          },
        ),
        
        // Tranche d'âge
        _buildAgeRangeSection(),
      ],
    );
  }
  
  /// Section tranche d'âge
  Widget _buildAgeRangeSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tranche d\'âge',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'De $_minAge à $_maxAge ans',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 16),
          
          Row(
            children: [
              // Âge minimum
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Minimum: $_minAge ans',
                      style: TextStyle(fontSize: 12),
                    ),
                    Slider(
                      value: _minAge.toDouble(),
                      min: 18,
                      max: _maxAge.toDouble() - 1,
                      divisions: (_maxAge - 19).clamp(1, 50),
                      onChanged: (value) {
                        setState(() {
                          _minAge = value.round();
                        });
                        _markAsChanged();
                      },
                    ),
                  ],
                ),
              ),
              
              SizedBox(width: 16),
              
              // Âge maximum
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Maximum: $_maxAge ans',
                      style: TextStyle(fontSize: 12),
                    ),
                    Slider(
                      value: _maxAge.toDouble(),
                      min: (_minAge + 1).toDouble(),
                      max: 100,
                      divisions: (100 - _minAge - 1).clamp(1, 50),
                      onChanged: (value) {
                        setState(() {
                          _maxAge = value.round();
                        });
                        _markAsChanged();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// Section des notifications
  Widget _buildNotificationsSection() {
    return _buildSection(
      title: 'Notifications Intelligentes',
      icon: Icons.notifications,
      children: [
        _buildSwitchTile(
          title: 'Notifications intelligentes',
          subtitle: 'Recevoir des notifications personnalisées',
          value: _enableSmartNotifications,
          onChanged: (value) {
            setState(() {
              _enableSmartNotifications = value;
            });
            _markAsChanged();
          },
        ),
        
        if (_enableSmartNotifications) ...[
          _buildSwitchTile(
            title: 'Haute compatibilité',
            subtitle: 'Alertes pour profils très compatibles (80%+)',
            value: _enableHighCompatibilityAlerts,
            onChanged: (value) {
              setState(() {
                _enableHighCompatibilityAlerts = value;
              });
              _markAsChanged();
            },
          ),
          
          _buildSwitchTile(
            title: 'Nouveaux utilisateurs',
            subtitle: 'Alertes pour nouveaux profils dans votre zone',
            value: _enableNewUsersAlerts,
            onChanged: (value) {
              setState(() {
                _enableNewUsersAlerts = value;
              });
              _markAsChanged();
            },
          ),
          
          _buildSwitchTile(
            title: 'Activité récente',
            subtitle: 'Alertes pour profils récemment actifs',
            value: _enableActivityAlerts,
            onChanged: (value) {
              setState(() {
                _enableActivityAlerts = value;
              });
              _markAsChanged();
            },
          ),
        ],
      ],
    );
  }
  
  /// Section de la fréquence
  Widget _buildFrequencySection() {
    return _buildSection(
      title: 'Fréquence des Suggestions',
      icon: Icons.schedule,
      children: [
        _buildRadioTile(
          title: 'Temps réel',
          subtitle: 'Suggestions immédiates dès qu\'un profil correspond',
          value: 'realtime',
          groupValue: _suggestionFrequency,
          onChanged: (value) {
            setState(() {
              _suggestionFrequency = value!;
            });
            _markAsChanged();
          },
        ),
        
        _buildRadioTile(
          title: 'Quotidienne',
          subtitle: 'Résumé quotidien des meilleures suggestions',
          value: 'daily',
          groupValue: _suggestionFrequency,
          onChanged: (value) {
            setState(() {
              _suggestionFrequency = value!;
            });
            _markAsChanged();
          },
        ),
        
        _buildRadioTile(
          title: 'Hebdomadaire',
          subtitle: 'Digest hebdomadaire des suggestions',
          value: 'weekly',
          groupValue: _suggestionFrequency,
          onChanged: (value) {
            setState(() {
              _suggestionFrequency = value!;
            });
            _markAsChanged();
          },
        ),
      ],
    );
  }
  
  /// Construire une section
  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        ...children,
      ],
    );
  }
  
  /// Construire un slider tile
  Widget _buildSliderTile({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
  
  /// Construire un switch tile
  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).primaryColor,
      ),
    );
  }
  
  /// Construire un radio tile
  Widget _buildRadioTile({
    required String title,
    required String subtitle,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: RadioListTile<String>(
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
        activeColor: Theme.of(context).primaryColor,
      ),
    );
  }
  
  /// Construire le bouton de sauvegarde
  Widget _buildSaveButton() {
    return FloatingActionButton.extended(
      onPressed: _savePreferences,
      icon: Icon(Icons.save),
      label: Text('Sauvegarder'),
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
    );
  }
  
  /// Afficher le dialogue de confirmation pour annuler les changements
  void _showDiscardDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Annuler les modifications ?'),
        content: Text('Vous avez des modifications non sauvegardées. Voulez-vous les perdre ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Continuer l\'édition'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Fermer le dialogue
              Navigator.of(context).pop(); // Retour à l'écran précédent
            },
            child: Text(
              'Annuler',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}