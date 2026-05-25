import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:datecinity/datas/user.dart';
import 'package:datecinity/models/user_model.dart';
import 'package:datecinity/services/suggestions_service.dart';
import 'package:datecinity/widgets/advanced_profile_card.dart';
import 'package:datecinity/widgets/no_data.dart';
import 'package:datecinity/widgets/processing.dart';

/// Interface utilisateur avancée pour afficher les suggestions de profils
///
/// Fonctionnalités:
/// - Affichage en liste avec scores de compatibilité détaillés
/// - Filtres avancés (distance, âge, compatibilité minimale)
/// - Système de feedback utilisateur
/// - Mode grille/liste
/// - Tri par compatibilité, distance, activité
/// - Actions rapides (like, super like, voir profil)
class AdvancedSuggestionsScreen extends StatefulWidget {
  const AdvancedSuggestionsScreen({super.key});

  @override
  State<AdvancedSuggestionsScreen> createState() =>
      _AdvancedSuggestionsScreenState();
}

class _AdvancedSuggestionsScreenState extends State<AdvancedSuggestionsScreen>
    with TickerProviderStateMixin {
  // Services
  final SuggestionsService _suggestionsService = SuggestionsService();

  // État de l'interface
  List<User> _suggestions = [];
  bool _isLoading = true;
  bool _isGridView = false;
  String _sortBy = 'compatibility'; // compatibility, distance, activity

  // Filtres
  double _maxDistance = 50.0;
  double _minCompatibility = 0.3;
  int _minAge = 18;
  int _maxAge = 100;

  // Animations
  late AnimationController _filterAnimationController;
  late AnimationController _listAnimationController;
  late Animation<double> _filterAnimation;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSuggestions();
  }

  @override
  void dispose() {
    _filterAnimationController.dispose();
    _listAnimationController.dispose();
    super.dispose();
  }

  /// Initialiser les animations
  void _initializeAnimations() {
    _filterAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _listAnimationController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _filterAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _filterAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _listAnimationController.forward();
  }

  /// Charger les suggestions avec les filtres actuels
  Future<void> _loadSuggestions() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final suggestions = await _suggestionsService.getSuggestions(
        maxDistance: _maxDistance,
        compatibilityThreshold: _minCompatibility,
        maxResults: 50,
      );

      // Filtrer par âge
      final filteredSuggestions = suggestions.where((user) {
        final age = _calculateAge(
          user.userBirthDay,
          user.userBirthMonth,
          user.userBirthYear,
        );
        return age >= _minAge && age <= _maxAge;
      }).toList();

      // Trier selon le critère sélectionné
      _sortSuggestions(filteredSuggestions);

      if (mounted) {
        setState(() {
          _suggestions = filteredSuggestions;
          _isLoading = false;
        });

        // Haptic feedback pour confirmer le chargement
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement suggestions: $e');
      if (mounted) {
        setState(() {
          _suggestions = [];
          _isLoading = false;
        });
      }
    }
  }

  /// Calculer l'âge à partir des composants de date
  int _calculateAge(int day, int month, int year) {
    final birthDate = DateTime(year, month, day);
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  /// Trier les suggestions selon le critère sélectionné
  void _sortSuggestions(List<User> suggestions) {
    final currentUser = UserModel().user;

    switch (_sortBy) {
      case 'compatibility':
        suggestions.sort((a, b) {
          final compatA = _calculateBasicCompatibility(currentUser, a);
          final compatB = _calculateBasicCompatibility(currentUser, b);
          return compatB.compareTo(compatA);
        });
        break;
      case 'distance':
        suggestions.sort((a, b) {
          final distA = _suggestionsService.calculateDistance(
            currentUser.userGeoPoint,
            a.userGeoPoint,
          );
          final distB = _suggestionsService.calculateDistance(
            currentUser.userGeoPoint,
            b.userGeoPoint,
          );
          return distA.compareTo(distB);
        });
        break;
      case 'activity':
        suggestions.sort((a, b) {
          return b.userLastLogin.compareTo(a.userLastLogin);
        });
        break;
    }
  }

  /// Calcul basique de compatibilité pour le tri
  double _calculateBasicCompatibility(User currentUser, User candidate) {
    final currentPrefs = currentUser.preferences ?? {};
    final candidatePrefs = candidate.preferences ?? {};

    if (currentPrefs.isEmpty || candidatePrefs.isEmpty) return 0.0;

    int matches = 0;
    for (final entry in currentPrefs.entries) {
      if (candidatePrefs.containsKey(entry.key) &&
          candidatePrefs[entry.key] == entry.value) {
        matches++;
      }
    }

    return matches / currentPrefs.length;
  }

  /// Basculer l'affichage des filtres
  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });

    if (_showFilters) {
      _filterAnimationController.forward();
    } else {
      _filterAnimationController.reverse();
    }

    HapticFeedback.selectionClick();
  }

  /// Appliquer les filtres
  void _applyFilters() {
    _toggleFilters();
    _loadSuggestions();
  }

  /// Réinitialiser les filtres
  void _resetFilters() {
    setState(() {
      _maxDistance = 50.0;
      _minCompatibility = 0.3;
      _minAge = 18;
      _maxAge = 100;
      _sortBy = 'compatibility';
    });
    _loadSuggestions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Filtres animés
          AnimatedBuilder(
            animation: _filterAnimation,
            builder: (context, child) {
              return SizedBox(
                height: _filterAnimation.value * 200,
                child: _filterAnimation.value > 0
                    ? _buildFiltersSection()
                    : null,
              );
            },
          ),

          // Corps principal
          Expanded(child: _buildMainContent()),
        ],
      ),
    );
  }

  /// Construire l'AppBar avec actions
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
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suggestions Intelligentes',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_suggestions.isNotEmpty)
            Text(
              '${_suggestions.length} profil${_suggestions.length > 1 ? 's' : ''} trouvé${_suggestions.length > 1 ? 's' : ''}',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
        ],
      ),
      actions: [
        // Bouton filtres
        IconButton(
          icon: Icon(
            _showFilters ? Icons.filter_list_off : Icons.filter_list,
            color: Colors.white,
          ),
          onPressed: _toggleFilters,
        ),

        // Bouton vue grille/liste
        IconButton(
          icon: Icon(
            _isGridView ? Icons.view_list : Icons.view_module,
            color: Colors.white,
          ),
          onPressed: () {
            setState(() {
              _isGridView = !_isGridView;
            });
            HapticFeedback.selectionClick();
          },
        ),

        // Bouton actualiser
        IconButton(
          icon: Icon(Icons.refresh, color: Colors.white),
          onPressed: _loadSuggestions,
        ),
      ],
    );
  }

  /// Construire la section des filtres
  Widget _buildFiltersSection() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, color: Theme.of(context).primaryColor),
              SizedBox(width: 8),
              Text(
                'Filtres Avancés',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Spacer(),
              TextButton(
                onPressed: _resetFilters,
                child: Text('Réinitialiser'),
              ),
            ],
          ),

          SizedBox(height: 16),

          Row(
            children: [
              // Distance
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Distance max: ${_maxDistance.round()}km'),
                    Slider(
                      value: _maxDistance,
                      min: 5,
                      max: 100,
                      divisions: 19,
                      onChanged: (value) {
                        setState(() {
                          _maxDistance = value;
                        });
                      },
                    ),
                  ],
                ),
              ),

              SizedBox(width: 16),

              // Compatibilité
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Compatibilité min: ${(_minCompatibility * 100).round()}%',
                    ),
                    Slider(
                      value: _minCompatibility,
                      min: 0.0,
                      max: 1.0,
                      divisions: 10,
                      onChanged: (value) {
                        setState(() {
                          _minCompatibility = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 8),

          Row(
            children: [
              // Tri
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _sortBy,
                  decoration: InputDecoration(
                    labelText: 'Trier par',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'compatibility',
                      child: Text('Compatibilité'),
                    ),
                    DropdownMenuItem(
                      value: 'distance',
                      child: Text('Distance'),
                    ),
                    DropdownMenuItem(
                      value: 'activity',
                      child: Text('Activité récente'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _sortBy = value!;
                    });
                  },
                ),
              ),

              SizedBox(width: 16),

              // Bouton appliquer
              ElevatedButton.icon(
                onPressed: _applyFilters,
                icon: Icon(Icons.search),
                label: Text('Appliquer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construire le contenu principal
  Widget _buildMainContent() {
    if (_isLoading) {
      return Processing(text: "Recherche de profils compatibles...");
    }

    if (_suggestions.isEmpty) {
      return NoData(
        svgName: 'search_icon',
        text:
            'Aucune suggestion trouvée avec ces critères.\nEssayez d\'ajuster vos filtres.',
      );
    }

    return AnimatedBuilder(
      animation: _listAnimationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _listAnimationController,
          child: SlideTransition(
            position: Tween<Offset>(begin: Offset(0, 0.1), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: _listAnimationController,
                    curve: Curves.easeOut,
                  ),
                ),
            child: _isGridView ? _buildGridView() : _buildListView(),
          ),
        );
      },
    );
  }

  /// Construire la vue en liste
  Widget _buildListView() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _suggestions.length,
      itemBuilder: (context, index) {
        final user = _suggestions[index];
        final compatibility = _calculateBasicCompatibility(
          UserModel().user,
          user,
        );
        final distance = _suggestionsService.calculateDistance(
          UserModel().user.userGeoPoint,
          user.userGeoPoint,
        );

        return AdvancedProfileCard(
          user: user,
          compatibility: compatibility,
          distance: distance,
          isListView: true,
          onLike: () => _handleLike(user),
          onSuperLike: () => _handleSuperLike(user),
          onViewProfile: () => _handleViewProfile(user),
        );
      },
    );
  }

  /// Construire la vue en grille
  Widget _buildGridView() {
    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _suggestions.length,
      itemBuilder: (context, index) {
        final user = _suggestions[index];
        final compatibility = _calculateBasicCompatibility(
          UserModel().user,
          user,
        );
        final distance = _suggestionsService.calculateDistance(
          UserModel().user.userGeoPoint,
          user.userGeoPoint,
        );

        return AdvancedProfileCard(
          user: user,
          compatibility: compatibility,
          distance: distance,
          isListView: false,
          onLike: () => _handleLike(user),
          onSuperLike: () => _handleSuperLike(user),
          onViewProfile: () => _handleViewProfile(user),
        );
      },
    );
  }

  /// Gérer le like
  void _handleLike(User user) {
    HapticFeedback.heavyImpact();
    // TODO: Implémenter la logique de like
    debugPrint('❤️ Like pour ${user.userFullname}');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❤️ ${user.userFullname} ajouté(e) à vos likes'),
        backgroundColor: Colors.pink,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Gérer le super like
  void _handleSuperLike(User user) {
    HapticFeedback.heavyImpact();
    // TODO: Implémenter la logique de super like
    debugPrint('⭐ Super Like pour ${user.userFullname}');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⭐ Super Like envoyé à ${user.userFullname}'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Gérer la vue du profil
  void _handleViewProfile(User user) {
    HapticFeedback.lightImpact();
    // TODO: Navigation vers le profil détaillé
    debugPrint('👀 Voir profil de ${user.userFullname}');
  }
}
