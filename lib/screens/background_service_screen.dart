import 'package:flutter/material.dart';
import 'package:datecinity/widgets/background_service_control_widget.dart';

/// Écran de configuration et gestion du service de suggestions en arrière-plan
class BackgroundServiceScreen extends StatefulWidget {
  const BackgroundServiceScreen({super.key});

  @override
  _BackgroundServiceScreenState createState() =>
      _BackgroundServiceScreenState();
}

class _BackgroundServiceScreenState extends State<BackgroundServiceScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service en Arrière-plan'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Description du service
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Suggestions Intelligentes',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Le service en arrière-plan surveille votre position et met à jour automatiquement vos suggestions de profils compatibles. Il envoie des notifications lorsque des personnes hautement compatibles sont à proximité.',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Widget de contrôle principal
            const BackgroundServiceControlWidget(),

            const SizedBox(height: 20),

            // Fonctionnalités
            Text(
              'Fonctionnalités',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),

            _buildFeatureCard(
              icon: Icons.location_on,
              title: 'Géolocalisation Continue',
              description:
                  'Surveille votre position pour détecter les profils à proximité',
              color: Colors.green,
            ),

            _buildFeatureCard(
              icon: Icons.refresh,
              title: 'Mises à jour Automatiques',
              description: 'Actualise les suggestions selon votre déplacement',
              color: Colors.blue,
            ),

            _buildFeatureCard(
              icon: Icons.notifications_active,
              title: 'Notifications Intelligentes',
              description: 'Alerte pour les profils hautement compatibles',
              color: Colors.orange,
            ),

            _buildFeatureCard(
              icon: Icons.battery_saver,
              title: 'Optimisation Batterie',
              description: 'Gestion intelligente selon l\'état de l\'app',
              color: Colors.purple,
            ),

            const SizedBox(height: 20),

            // Conseils et avertissements
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tips_and_updates, color: Colors.amber[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Conseils d\'utilisation',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Accordez la permission "Toujours" pour la géolocalisation\n'
                    '• Le service s\'adapte automatiquement au mode arrière-plan\n'
                    '• Les notifications respectent vos préférences\n'
                    '• Le cache se vide automatiquement pour optimiser la mémoire',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// Construire une carte de fonctionnalité
  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
      ),
    );
  }

  /// Afficher la boîte de dialogue d'information
  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info, color: Colors.blue),
            SizedBox(width: 8),
            Text('Service en Arrière-plan'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Le service de suggestions en arrière-plan est une fonctionnalité avancée qui améliore votre expérience de découverte :',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                '🎯 Détection automatique de profils compatibles à proximité',
              ),
              SizedBox(height: 6),
              Text('📍 Mise à jour continue selon vos déplacements'),
              SizedBox(height: 6),
              Text('🔔 Notifications push pour les meilleures opportunités'),
              SizedBox(height: 6),
              Text('🔋 Optimisation intelligente de la batterie'),
              SizedBox(height: 12),
              Text(
                'Permissions requises :',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 6),
              Text('• Géolocalisation (recommandé: "Toujours")'),
              Text('• Notifications push'),
              SizedBox(height: 12),
              Text(
                'Le service respecte votre vie privée et n\'utilise la géolocalisation que pour améliorer les suggestions.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }
}
