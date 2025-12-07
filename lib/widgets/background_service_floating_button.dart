import 'package:flutter/material.dart';
import 'package:cheers/services/background_suggestions_service.dart';
import 'package:cheers/screens/background_service_screen.dart';

/// Widget de bouton flottant pour accéder rapidement au service en arrière-plan
class BackgroundServiceFloatingButton extends StatefulWidget {
  const BackgroundServiceFloatingButton({super.key});

  @override
  _BackgroundServiceFloatingButtonState createState() =>
      _BackgroundServiceFloatingButtonState();
}

class _BackgroundServiceFloatingButtonState
    extends State<BackgroundServiceFloatingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isServiceRunning = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _updateServiceStatus();

    // Animation en boucle quand le service est actif
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Mettre à jour le statut du service
  void _updateServiceStatus() {
    final stats = BackgroundSuggestionsService.getStats();
    setState(() {
      _isServiceRunning = stats['isRunning'] ?? false;
    });
  }

  /// Basculer le service
  Future<void> _toggleService() async {
    if (_isServiceRunning) {
      await BackgroundSuggestionsService.stop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🛑 Service en arrière-plan arrêté'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      final success = await BackgroundSuggestionsService.initialize();
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Service en arrière-plan démarré'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Échec du démarrage du service'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
    _updateServiceStatus();
  }

  /// Afficher les options du service
  void _showServiceOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // En-tête
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isServiceRunning ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    _isServiceRunning ? Icons.check : Icons.pause,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Service en Arrière-plan',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                Text(
                  _isServiceRunning ? 'ACTIF' : 'ARRÊTÉ',
                  style: TextStyle(
                    color: _isServiceRunning ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Description rapide
            Text(
              _isServiceRunning
                  ? 'Le service surveille votre position et met à jour vos suggestions automatiquement.'
                  : 'Démarrez le service pour recevoir des suggestions en temps réel basées sur votre position.',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),

            const SizedBox(height: 20),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _toggleService,
                    icon: Icon(
                      _isServiceRunning ? Icons.stop : Icons.play_arrow,
                    ),
                    label: Text(_isServiceRunning ? 'Arrêter' : 'Démarrer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isServiceRunning
                          ? Colors.red
                          : Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BackgroundServiceScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.settings),
                    label: const Text('Configurer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isServiceRunning ? _scaleAnimation.value : 1.0,
          child: FloatingActionButton(
            onPressed: _showServiceOptions,
            backgroundColor: _isServiceRunning
                ? Colors.green
                : Colors.grey[600],
            foregroundColor: Colors.white,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  _isServiceRunning
                      ? Icons.wifi_tethering
                      : Icons.wifi_tethering_off,
                  size: 28,
                ),
                if (_isServiceRunning)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
