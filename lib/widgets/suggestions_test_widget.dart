import 'package:datecinity/services/suggestions_service.dart';
import 'package:flutter/material.dart';

/// Widget de test pour le service de suggestions
class SuggestionsTestWidget extends StatefulWidget {
  const SuggestionsTestWidget({super.key});

  @override
  State<SuggestionsTestWidget> createState() => _SuggestionsTestWidgetState();
}

class _SuggestionsTestWidgetState extends State<SuggestionsTestWidget> {
  final SuggestionsService _suggestionsService = SuggestionsService();
  bool _isLoading = false;
  Map<String, dynamic>? _serviceStats;

  @override
  void initState() {
    super.initState();
    _loadServiceStats();
  }

  void _loadServiceStats() {
    setState(() {
      _serviceStats = _suggestionsService.getServiceStats();
    });
  }

  Future<void> _testSuggestions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final suggestions = await _suggestionsService.getSuggestions();
      debugPrint('✅ Test réussi: ${suggestions.length} suggestions trouvées');

      _loadServiceStats();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Test réussi: ${suggestions.length} suggestions trouvées',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Erreur lors du test: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Suggestions Service'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Service de Suggestions - Point 1',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Service de base avec cache et calcul de distance géographique.',
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _testSuggestions,
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : const Text('Tester le Service'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_serviceStats != null) ...[
              const Text(
                'Statistiques du Service:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🎯 Test Point 4 - Compatibilité Avancée',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        '✅ Algorithme de compatibilité multi-facteurs:\n'
                        '• Quiz & Préférences: 40%\n'
                        '• Intérêts communs (hobbies): 25%\n'
                        '• Démographie (âge, éducation, religion): 20%\n'
                        '• Niveau d\'activité: 10%\n'
                        '• Bonus géographique: 5%',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green[700],
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        '🔔 Point 5 - Notifications Intelligentes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        '✅ Système de notifications avancé:\n'
                        '• Notifications haute compatibilité (80%+)\n'
                        '• Notifications matches à proximité (<10km)\n'
                        '• Système anti-spam intelligent (max 3/jour)\n'
                        '• Préférences utilisateur personnalisables\n'
                        '• Déclencheurs automatiques (connexion, localisation)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green[700],
                        ),
                      ),
                      SizedBox(height: 20),
                      Text('Cache valide: ${_serviceStats!['cache_valid']}'),
                      Text(
                        'Suggestions en cache: ${_serviceStats!['cached_suggestions_count']}',
                      ),
                      Text(
                        'Dernière mise à jour: ${_serviceStats!['last_cache_update'] ?? 'Jamais'}',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
