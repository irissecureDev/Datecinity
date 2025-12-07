import 'package:flutter/material.dart';
import 'package:cheers/services/background_suggestions_service.dart';

/// Widget de contrôle pour le service de suggestions en arrière-plan
///
/// Permet de :
/// - Démarrer/arrêter le service
/// - Visualiser les statistiques en temps réel
/// - Tester les fonctionnalités manuellement
/// - Configurer les paramètres du service
class BackgroundServiceControlWidget extends StatefulWidget {
  const BackgroundServiceControlWidget({super.key});

  @override
  _BackgroundServiceControlWidgetState createState() =>
      _BackgroundServiceControlWidgetState();
}

class _BackgroundServiceControlWidgetState
    extends State<BackgroundServiceControlWidget> {
  bool _isServiceRunning = false;
  Map<String, dynamic> _stats = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _updateStats();
  }

  /// Mettre à jour les statistiques du service
  void _updateStats() {
    setState(() {
      _stats = BackgroundSuggestionsService.getStats();
      _isServiceRunning = _stats['isRunning'] ?? false;
    });
  }

  /// Démarrer le service
  Future<void> _startService() async {
    setState(() => _isLoading = true);

    try {
      final success = await BackgroundSuggestionsService.initialize();
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Service démarré avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Échec du démarrage du service'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Erreur: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
      _updateStats();
    }
  }

  /// Arrêter le service
  Future<void> _stopService() async {
    setState(() => _isLoading = true);

    try {
      await BackgroundSuggestionsService.stop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🛑 Service arrêté'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur arrêt: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
      _updateStats();
    }
  }

  /// Forcer une mise à jour manuelle
  Future<void> _forceUpdate() async {
    setState(() => _isLoading = true);

    try {
      await BackgroundSuggestionsService.forceUpdate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔄 Mise à jour forcée effectuée'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur mise à jour: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
      _updateStats();
    }
  }

  /// Vider le cache
  void _clearCache() {
    BackgroundSuggestionsService.clearCache();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🗑️ Cache vidé'),
        backgroundColor: Colors.blue,
      ),
    );
    _updateStats();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                Icon(
                  Icons.settings_backup_restore,
                  color: _isServiceRunning ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'Service Suggestions Background',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _isServiceRunning ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _isServiceRunning ? 'ACTIF' : 'ARRÊTÉ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Boutons de contrôle
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading || _isServiceRunning
                      ? null
                      : _startService,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Démarrer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading || !_isServiceRunning
                      ? null
                      : _stopService,
                  icon: const Icon(Icons.stop),
                  label: const Text('Arrêter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading || !_isServiceRunning
                      ? null
                      : _forceUpdate,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Mise à jour'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _clearCache,
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Vider cache'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Statistiques
            Text(
              'Statistiques',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

            _buildStatsGrid(),

            const SizedBox(height: 16),

            // Position actuelle
            if (_stats['lastKnownPosition'] != null) _buildPositionInfo(),

            // Indicateur de chargement
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Construire la grille des statistiques
  Widget _buildStatsGrid() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'État',
                  _stats['isRunning'] == true ? 'Actif' : 'Inactif',
                  _stats['isRunning'] == true ? Colors.green : Colors.red,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Mode',
                  _stats['isInBackground'] == true
                      ? 'Background'
                      : 'Foreground',
                  _stats['isInBackground'] == true ? Colors.blue : Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Suggestions',
                  '${_stats['cachedSuggestionsCount'] ?? 0}',
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Cooldowns',
                  '${_stats['activeCooldowns'] ?? 0}',
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildStatItem(
            'Dernière mise à jour',
            _formatLastUpdate(_stats['lastUpdateTime']),
            Colors.grey,
          ),
        ],
      ),
    );
  }

  /// Construire un élément de statistique
  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Construire les informations de position
  Widget _buildPositionInfo() {
    final position = _stats['lastKnownPosition'] as Map<String, dynamic>;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Position actuelle',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Lat: ${position['latitude']?.toStringAsFixed(6) ?? 'N/A'}',
            style: const TextStyle(fontFamily: 'monospace'),
          ),
          Text(
            'Lon: ${position['longitude']?.toStringAsFixed(6) ?? 'N/A'}',
            style: const TextStyle(fontFamily: 'monospace'),
          ),
          if (position['timestamp'] != null)
            Text(
              'Maj: ${_formatTimestamp(position['timestamp'])}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
        ],
      ),
    );
  }

  /// Formater la dernière mise à jour
  String _formatLastUpdate(String? timestamp) {
    if (timestamp == null) return 'Jamais';

    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'À l\'instant';
      } else if (difference.inMinutes < 60) {
        return 'Il y a ${difference.inMinutes}min';
      } else if (difference.inHours < 24) {
        return 'Il y a ${difference.inHours}h';
      } else {
        return 'Il y a ${difference.inDays}j';
      }
    } catch (e) {
      return 'Erreur';
    }
  }

  /// Formater un timestamp
  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }
}
