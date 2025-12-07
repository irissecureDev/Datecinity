import 'package:flutter/material.dart';
import 'package:cheers/screens/advanced_suggestions_screen.dart';

/// Widget bouton pour accéder aux suggestions avancées
///
/// À intégrer dans l'écran principal de découverte
class AdvancedSuggestionsButton extends StatelessWidget {
  const AdvancedSuggestionsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: () => _navigateToAdvancedSuggestions(context),
        icon: Icon(Icons.psychology),
        label: Text('Suggestions Intelligentes'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 4,
        ),
      ),
    );
  }

  /// Navigation vers l'écran de suggestions avancées
  void _navigateToAdvancedSuggestions(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => AdvancedSuggestionsScreen()),
    );
  }
}

/// Widget bouton flottant pour suggestions rapides
class SuggestionsFloatingButton extends StatelessWidget {
  const SuggestionsFloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _showQuickSuggestions(context),
      icon: Icon(Icons.lightbulb),
      label: Text('Suggestions'),
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
    );
  }

  /// Afficher un modal de suggestions rapides (méthode statique)
  static void showQuickSuggestions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.psychology,
                        color: Theme.of(context).primaryColor,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Suggestions Rapides',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Spacer(),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AdvancedSuggestionsScreen(),
                            ),
                          );
                        },
                        child: Text('Voir tout'),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildQuickSuggestionCard(
                        context,
                        'Profils hautement compatibles',
                        'Découvrez les profils avec +80% de compatibilité',
                        Icons.favorite,
                        Colors.pink,
                      ),
                      _buildQuickSuggestionCard(
                        context,
                        'Nouveaux près de vous',
                        'Profils récemment inscrits dans votre zone',
                        Icons.location_on,
                        Colors.blue,
                      ),
                      _buildQuickSuggestionCard(
                        context,
                        'Centres d\'intérêt similaires',
                        'Personnes qui partagent vos passions',
                        Icons.interests,
                        Colors.green,
                      ),
                      _buildQuickSuggestionCard(
                        context,
                        'Actifs récemment',
                        'Profils connectés ces dernières heures',
                        Icons.access_time,
                        Colors.orange,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Afficher un modal de suggestions rapides
  void _showQuickSuggestions(BuildContext context) {
    SuggestionsFloatingButton.showQuickSuggestions(context);
  }

  /// Construire une carte de suggestion rapide
  static Widget _buildQuickSuggestionCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(description),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.pop(context);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AdvancedSuggestionsScreen(),
            ),
          );
        },
      ),
    );
  }
}
