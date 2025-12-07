import 'package:flutter/material.dart';
import 'package:cheers/services/background_suggestions_service.dart';
import 'package:cheers/services/background_service_config.dart';
import 'package:cheers/screens/background_service_screen.dart';
import 'package:cheers/widgets/background_service_floating_button.dart';

/// Écran de test et démonstration du service en arrière-plan
///
/// Cet écran permet de :
/// - Tester toutes les fonctionnalités du service
/// - Voir les logs en temps réel
/// - Simuler différents scénarios
class BackgroundServiceTestScreen extends StatefulWidget {
  const BackgroundServiceTestScreen({super.key});

  @override
  _BackgroundServiceTestScreenState createState() =>
      _BackgroundServiceTestScreenState();
}

class _BackgroundServiceTestScreenState
    extends State<BackgroundServiceTestScreen> {
  final List<String> _logs = [];
  bool _isAutoScrollEnabled = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _addLog('📱 Écran de test du service en arrière-plan initialisé');
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Ajouter un log
  void _addLog(String message) {
    setState(() {
      _logs.add(
        '${DateTime.now().toIso8601String().substring(11, 19)} $message',
      );
    });

    // Auto-scroll vers le bas
    if (_isAutoScrollEnabled && _scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  /// Test d'initialisation
  Future<void> _testInitialization() async {
    _addLog('🧪 Test d\'initialisation...');

    try {
      await BackgroundServiceConfig.initializeOnStartup();
      _addLog('✅ Initialisation terminée');

      final stats = BackgroundSuggestionsService.getStats();
      _addLog('📊 Statut: ${stats['isRunning'] ? 'Actif' : 'Inactif'}');
    } catch (e) {
      _addLog('❌ Erreur initialisation: $e');
    }
  }

  /// Test de démarrage/arrêt
  Future<void> _testStartStop() async {
    final stats = BackgroundSuggestionsService.getStats();
    final isRunning = stats['isRunning'] ?? false;

    if (isRunning) {
      _addLog('🛑 Test arrêt du service...');
      await BackgroundSuggestionsService.stop();
      _addLog('✅ Service arrêté');
    } else {
      _addLog('🚀 Test démarrage du service...');
      final success = await BackgroundSuggestionsService.initialize();
      _addLog(success ? '✅ Service démarré' : '❌ Échec démarrage');
    }
  }

  /// Test de mise à jour forcée
  Future<void> _testForceUpdate() async {
    _addLog('🔄 Test mise à jour forcée...');

    try {
      await BackgroundSuggestionsService.forceUpdate();
      _addLog('✅ Mise à jour forcée terminée');
    } catch (e) {
      _addLog('❌ Erreur mise à jour: $e');
    }
  }

  /// Test de nettoyage cache
  void _testClearCache() {
    _addLog('🗑️ Test nettoyage cache...');
    BackgroundSuggestionsService.clearCache();
    _addLog('✅ Cache nettoyé');
  }

  /// Simuler un changement de mode (foreground/background)
  void _simulateAppStateChange() {
    final stats = BackgroundSuggestionsService.getStats();
    final isInBackground = stats['isInBackground'] ?? false;

    if (isInBackground) {
      _addLog('☀️ Simulation: App en premier plan');
      BackgroundSuggestionsService.onAppForeground();
    } else {
      _addLog('🌙 Simulation: App en arrière-plan');
      BackgroundSuggestionsService.onAppBackground();
    }
  }

  /// Afficher les statistiques détaillées
  void _showDetailedStats() {
    final stats = BackgroundSuggestionsService.getStats();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Statistiques Détaillées'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatRow('État', stats['isRunning'] ? 'Actif' : 'Inactif'),
              _buildStatRow(
                'Mode',
                stats['isInBackground'] ? 'Background' : 'Foreground',
              ),
              _buildStatRow(
                'Suggestions',
                '${stats['cachedSuggestionsCount'] ?? 0}',
              ),
              _buildStatRow('Cooldowns', '${stats['activeCooldowns'] ?? 0}'),
              _buildStatRow(
                'Dernière MAJ',
                stats['lastUpdateTime'] ?? 'Jamais',
              ),
              if (stats['lastKnownPosition'] != null) ...[
                const SizedBox(height: 8),
                const Text(
                  'Position:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                _buildStatRow(
                  'Latitude',
                  '${stats['lastKnownPosition']['latitude']?.toStringAsFixed(6) ?? 'N/A'}',
                ),
                _buildStatRow(
                  'Longitude',
                  '${stats['lastKnownPosition']['longitude']?.toStringAsFixed(6) ?? 'N/A'}',
                ),
                _buildStatRow(
                  'Timestamp',
                  '${stats['lastKnownPosition']['timestamp'] ?? 'N/A'}',
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  /// Construire une ligne de statistique
  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontFamily: 'monospace')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Service Background'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BackgroundServiceScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Panel de contrôles de test
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              children: [
                // Ligne 1
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _testInitialization,
                        child: const Text('Init'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _testStartStop,
                        child: const Text('Start/Stop'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _testForceUpdate,
                        child: const Text('Update'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Ligne 2
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _testClearCache,
                        child: const Text('Clear Cache'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _simulateAppStateChange,
                        child: const Text('Toggle State'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _showDetailedStats,
                        child: const Text('Stats'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // En-tête des logs
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              border: Border(bottom: BorderSide(color: Colors.blue[200]!)),
            ),
            child: Row(
              children: [
                const Icon(Icons.terminal, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Logs en temps réel',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Switch(
                  value: _isAutoScrollEnabled,
                  onChanged: (value) {
                    setState(() => _isAutoScrollEnabled = value);
                  },
                ),
                const Text('Auto-scroll'),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() => _logs.clear());
                    _addLog('🧹 Logs effacés');
                  },
                ),
              ],
            ),
          ),

          // Zone des logs
          Expanded(
            child: Container(
              color: Colors.black,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(8),
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    child: Text(
                      _logs[index],
                      style: const TextStyle(
                        color: Colors.green,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: const BackgroundServiceFloatingButton(),
    );
  }
}
