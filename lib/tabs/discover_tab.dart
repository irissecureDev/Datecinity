import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cheers/api/dislikes_api.dart';
import 'package:cheers/api/likes_api.dart';
import 'package:cheers/api/matches_api.dart';
import 'package:cheers/api/visits_api.dart';
import 'package:cheers/constants/constants.dart';
import 'package:cheers/datas/user.dart';
import 'package:cheers/dialogs/its_match_dialog.dart';
import 'package:cheers/helpers/app_localizations.dart';
import 'package:cheers/models/user_model.dart';
import 'package:cheers/models/proximity_profile.dart';
import 'package:cheers/plugins/swipe_stack/swipe_stack.dart';
import 'package:cheers/screens/disliked_profile_screen.dart';
import 'package:cheers/screens/profile_screen.dart';
import 'package:cheers/services/suggestions_service.dart';
import 'package:cheers/widgets/cicle_button.dart';
import 'package:cheers/widgets/no_data.dart';
import 'package:cheers/widgets/processing.dart';
import 'package:cheers/widgets/profile_card.dart';
import 'package:cheers/widgets/advanced_profile_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cheers/api/users_api.dart';
import 'dart:async';

class DiscoverTab extends StatefulWidget {
  const DiscoverTab({super.key});

  @override
  DiscoverTabState createState() => DiscoverTabState();
}

class DiscoverTabState extends State<DiscoverTab>
    with TickerProviderStateMixin {
  // Variables
  final GlobalKey<SwipeStackState> _swipeKey = GlobalKey<SwipeStackState>();
  final LikesApi _likesApi = LikesApi();
  final DislikesApi _dislikesApi = DislikesApi();
  final MatchesApi _matchesApi = MatchesApi();
  final VisitsApi _visitsApi = VisitsApi();
  final UsersApi _usersApi = UsersApi();
  final SuggestionsService _suggestionsService = SuggestionsService();

  List<DocumentSnapshot<Map<String, dynamic>>>? _users;
  List<ProximityProfile>? _proximityProfiles;
  late AppLocalizations _i18n;

  // Tab controller pour basculer entre découverte normale et suggestions intelligentes
  late TabController _tabController;

  // Timer pour rafraîchir l'interface et supprimer les profils expirés
  Timer? _refreshTimer;

  // Filtres pour les suggestions
  final double _maxDistance = 50.0;
  final double _minCompatibility = 0.3;
  bool _isLoadingSuggestions = false;

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  /// Calculer le pourcentage de compatibilité pour un utilisateur donné
  double _calculateCompatibility(User user) {
    final currentPrefs = UserModel().user.preferences ?? {};
    final userPrefs = user.preferences ?? {};

    debugPrint('🔍 Calculating compatibility for: ${user.userFullname}');
    debugPrint('📊 Current user preferences: ${currentPrefs.length} items');
    debugPrint('👤 Other user preferences: ${userPrefs.length} items');

    if (currentPrefs.isEmpty || userPrefs.isEmpty) {
      debugPrint('❌ No preferences found, returning 0% compatibility');
      return 0.0;
    }

    int matchingAnswers = 0;
    for (final entry in currentPrefs.entries) {
      if (userPrefs.containsKey(entry.key) &&
          userPrefs[entry.key] == entry.value) {
        matchingAnswers++;
      }
    }

    final double result = (matchingAnswers / currentPrefs.length * 100)
        .clamp(0, 100)
        .toDouble();

    debugPrint(
      '✅ Compatibility result: ${result.round()}% ($matchingAnswers/${currentPrefs.length} matches)',
    );

    return result;
  }

  /// Get all Users
  Future<void> _loadUsers(
    List<DocumentSnapshot<Map<String, dynamic>>> dislikedUsers,
  ) async {
    _usersApi.getUsers(dislikedUsers: dislikedUsers).then((users) {
      // Check result
      if (users.isNotEmpty) {
        if (mounted) {
          setState(() => _users = users);
        }
      } else {
        if (mounted) {
          setState(() => _users = []);
        }
      }
      // Debug
      debugPrint('getUsers() -> ${users.length}');
      debugPrint('getDislikedUsers() -> ${dislikedUsers.length}');
    });
  }

  /// Charger les profils de proximité depuis le cache
  Future<void> _loadProximityProfiles() async {
    if (_isLoadingSuggestions) return;

    setState(() {
      _isLoadingSuggestions = true;
    });

    try {
      // Obtenir les profils de proximité depuis le service
      final proximityProfiles = _suggestionsService
          .getActiveProximityProfiles();

      debugPrint(
        '📍 ${proximityProfiles.length} profils de proximité actifs récupérés',
      );

      if (mounted) {
        setState(() {
          _proximityProfiles = proximityProfiles;
          _isLoadingSuggestions = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement profils proximité: $e');
      if (mounted) {
        setState(() {
          _proximityProfiles = [];
          _isLoadingSuggestions = false;
        });
      }
    }
  }

  /// Rafraîchir les profils de proximité et supprimer les expirés
  void _refreshProximityProfiles() {
    if (!mounted) return;

    // Nettoyer le cache automatiquement
    _suggestionsService.cleanProximityCache();

    // Recharger les profils actifs
    _loadProximityProfiles();

    debugPrint('🔄 Proximity profiles refreshed');
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    /// First: Load All Disliked Users to be filtered
    _dislikesApi.getDislikedUsers(withLimit: false).then((
      List<DocumentSnapshot<Map<String, dynamic>>> dislikedUsers,
    ) async {
      /// Validate user max distance
      await UserModel().checkUserMaxDistance();

      /// Load all users
      await _loadUsers(dislikedUsers);
    });

    // Charger les suggestions de proximité
    _loadProximityProfiles();

    // Timer pour rafraîchir l'interface toutes les 30 secondes et supprimer les profils expirés
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      _refreshProximityProfiles();
    });
  }

  @override
  Widget build(BuildContext context) {
    /// Initialization
    _i18n = AppLocalizations.of(context);
    return Column(
      children: [
        // Barre d'onglets style Matches
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          height: 54,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(27),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey[600],
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              letterSpacing: 0.2,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
            dividerColor: Colors.transparent,
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.swipe, size: 20),
                    const SizedBox(width: 8),
                    Text(_i18n.translate("discover")),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.psychology, size: 20),
                    const SizedBox(width: 8),
                    Text("Suggestions"),
                  ],
                ),
              ),
            ],
            onTap: (index) {
              HapticFeedback.lightImpact();
              if (index == 1) {
                // Load/refresh proximity profiles when switching to Suggestions tab
                _loadProximityProfiles();
              }
            },
          ),
        ),

        // Contenu selon l'onglet sélectionné
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_buildDiscoverView(), _buildSuggestionsView()],
          ),
        ),
      ],
    );
  }

  /// Vue de découverte normale (Onglet 1)
  Widget _buildDiscoverView() {
    /// Check result
    if (_users == null) {
      return Processing(text: _i18n.translate("loading"));
    } else if (_users!.isEmpty) {
      /// No user found
      return NoData(
        svgName: 'search_icon',
        text: _i18n.translate(
          "no_user_found_around_you_please_try_again_later",
        ),
      );
    } else {
      return Stack(
        fit: StackFit.expand,
        children: [
          /// User card list
          SwipeStack(
            key: _swipeKey,
            children: _users!.map((userDoc) {
              // Get User object
              final User user = User.fromDocument(userDoc.data()!);
              // Calculate compatibility
              final double compatibility = _calculateCompatibility(user);
              // Return user profile
              return SwiperItem(
                builder: (SwiperPosition position, double progress) {
                  /// Return User Card with compatibility
                  return ProfileCard(
                    page: 'discover',
                    position: position,
                    user: user,
                    compatibility: compatibility,
                  );
                },
              );
            }).toList(),
            padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
            translationInterval: 6,
            scaleInterval: 0.03,
            stackFrom: StackFrom.None,
            onEnd: () => debugPrint("onEnd"),
            onSwipe: (int index, SwiperPosition position) {
              /// Control swipe position
              switch (position) {
                case SwiperPosition.None:
                  break;
                case SwiperPosition.Left:

                  /// Swipe Left Dislike profile
                  _dislikesApi.dislikeUser(
                    dislikedUserId: _users![index][USER_ID],
                    onDislikeResult: (r) => debugPrint('onDislikeResult: $r'),
                  );

                  break;

                case SwiperPosition.Right:

                  /// Swipe right and Like profile
                  _likeUser(context, clickedUserDoc: _users![index]);

                  break;
              }
            },
          ),

          /// Swipe buttons
          Positioned(
            bottom: 15,
            left: 0,
            right: 0,
            child: swipeButtons(context),
          ),
        ],
      );
    }
  }

  /// Vue des suggestions par proximité avec expiration automatique (Onglet 2)
  Widget _buildSuggestionsView() {
    if (_isLoadingSuggestions) {
      return Processing(text: "Searching for compatible profiles...");
    }

    if (_proximityProfiles == null || _proximityProfiles!.isEmpty) {
      return NoData(
        svgName: 'search_icon',
        text:
            'No temporary suggestions available.\nMove around to discover new profiles.',
      );
    }

    // Grouper par distance en utilisant ProximityProfile
    Map<String, List<ProximityProfile>> groupedByDistance = {
      '5m': [],
      '10m': [],
      '25m': [],
      '50m': [],
      '100m+': [],
    };

    for (final profile in _proximityProfiles!) {
      final distanceM = profile.distance * 1000; // Convertir en mètres

      if (distanceM <= 5) {
        groupedByDistance['5m']!.add(profile);
      } else if (distanceM <= 10) {
        groupedByDistance['10m']!.add(profile);
      } else if (distanceM <= 25) {
        groupedByDistance['25m']!.add(profile);
      } else if (distanceM <= 50) {
        groupedByDistance['50m']!.add(profile);
      } else {
        groupedByDistance['100m+']!.add(profile);
      }
    }

    return RefreshIndicator(
      onRefresh: _loadProximityProfiles,
      child: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // En-tête avec statistiques et timer
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.1),
                  Theme.of(context).primaryColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: Theme.of(context).primaryColor,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Temporary Suggestions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  '${_proximityProfiles!.length} compatible profile${_proximityProfiles!.length > 1 ? 's' : ''} detected nearby',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                SizedBox(height: 4),
                Text(
                  '⏰ Profiles disappear automatically after 10 minutes',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Groupes par distance avec informations de temps restant
          ...groupedByDistance.entries.map((entry) {
            if (entry.value.isEmpty) return SizedBox.shrink();

            return _buildProximityDistanceGroup(entry.key, entry.value);
          }),
        ],
      ),
    );
  }

  /// Construire un groupe de profils de proximité par distance avec timer d'expiration
  Widget _buildProximityDistanceGroup(
    String distance,
    List<ProximityProfile> profiles,
  ) {
    if (profiles.isEmpty) return SizedBox.shrink();

    String title;
    IconData icon;
    Color color;

    switch (distance) {
      case '5m':
        title = 'Very close (≤ 5m)';
        icon = Icons.location_on;
        color = Colors.red;
        break;
      case '10m':
        title = 'Close (≤ 10m)';
        icon = Icons.near_me;
        color = Colors.orange;
        break;
      case '25m':
        title = 'Nearby (≤ 25m)';
        icon = Icons.my_location;
        color = Colors.blue;
        break;
      case '50m':
        title = 'In the area (≤ 50m)';
        icon = Icons.location_city;
        color = Colors.green;
        break;
      default:
        title = 'In the region (100m+)';
        icon = Icons.location_city;
        color = Colors.green;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${profiles.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Liste des profils avec informations d'expiration
        ...profiles.map((profile) {
          final exactDistanceM = (profile.distance * 1000).round();
          final timeRemaining = profile.minutesUntilExpiry;

          return Container(
            margin: EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: timeRemaining <= 2
                  ? Border.all(color: Colors.red, width: 2)
                  : timeRemaining <= 5
                  ? Border.all(color: Colors.orange, width: 1)
                  : null,
            ),
            child: Column(
              children: [
                // Barre de temps restant en haut
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: timeRemaining <= 2
                        ? Colors.red.withOpacity(0.1)
                        : timeRemaining <= 5
                        ? Colors.orange.withOpacity(0.1)
                        : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.timer,
                        size: 16,
                        color: timeRemaining <= 2
                            ? Colors.red
                            : timeRemaining <= 5
                            ? Colors.orange
                            : Colors.blue,
                      ),
                      SizedBox(width: 8),
                      Text(
                        profile.timeUntilExpiryFormatted,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: timeRemaining <= 2
                              ? Colors.red
                              : timeRemaining <= 5
                              ? Colors.orange
                              : Colors.blue,
                        ),
                      ),
                      Spacer(),
                      Icon(Icons.location_on, size: 14, color: color),
                      SizedBox(width: 4),
                      Text(
                        '${exactDistanceM}m',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),

                // Carte de profil principale
                AdvancedProfileCard(
                  user: profile.user,
                  compatibility: profile.compatibility,
                  distance: profile.distance,
                  isListView: true,
                  onLike: () => _handleLike(profile.user),
                  onSuperLike: () => _handleSuperLike(profile.user),
                  onViewProfile: () => _handleViewProfile(profile.user),
                ),
              ],
            ),
          );
        }),

        SizedBox(height: 16),
      ],
    );
  }

  /// Gérer le like
  void _handleLike(User user) {
    HapticFeedback.heavyImpact();
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProfileScreen(user: user, showButtons: false),
      ),
    );
  }

  /// Build swipe buttons
  Widget swipeButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          /// Rewind profiles - Go to Disliked Profiles
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: cicleButton(
              bgColor: Colors.transparent,
              padding: 10,
              icon: const Icon(Icons.restore, size: 20, color: Colors.grey),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const DislikedProfilesScreen(),
                  ),
                );
              },
            ),
          ),

          /// Swipe left and reject user
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: cicleButton(
              bgColor: Colors.transparent,
              padding: 12,
              icon: const Icon(Icons.close, size: 24, color: Colors.red),
              onTap: () {
                final cardIndex = _swipeKey.currentState!.currentIndex;
                if (cardIndex != -1) {
                  _swipeKey.currentState!.swipeLeft();
                }
              },
            ),
          ),

          /// Swipe right and like user
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: cicleButton(
              bgColor: Colors.transparent,
              padding: 12,
              icon: Icon(
                Icons.favorite,
                size: 24,
                color: Theme.of(context).primaryColor,
              ),
              onTap: () async {
                final cardIndex = _swipeKey.currentState!.currentIndex;
                if (cardIndex != -1) {
                  _swipeKey.currentState!.swipeRight();
                }
              },
            ),
          ),

          /// Go to user profile
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: cicleButton(
              bgColor: Colors.transparent,
              padding: 10,
              icon: const Icon(
                Icons.remove_red_eye,
                size: 20,
                color: Colors.grey,
              ),
              onTap: () {
                final cardIndex = _swipeKey.currentState!.currentIndex;
                if (cardIndex != -1) {
                  final User user = User.fromDocument(
                    _users![cardIndex].data()!,
                  );

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          ProfileScreen(user: user, showButtons: false),
                    ),
                  );

                  _visitsApi.visitUserProfile(
                    visitedUserId: user.userId,
                    userDeviceToken: user.userDeviceToken,
                    nMessage:
                        "${UserModel().user.userFullname.split(' ')[0]}, "
                        "${_i18n.translate("visited_your_profile_click_and_see")}",
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Like user function
  Future<void> _likeUser(
    BuildContext context, {
    required DocumentSnapshot<Map<String, dynamic>> clickedUserDoc,
  }) async {
    /// Check match first
    await _matchesApi.checkMatch(
      userId: clickedUserDoc[USER_ID],
      onMatchResult: (result) {
        if (result) {
          /// It`s match - show dialog to ask user to chat or continue playing
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return ItsMatchDialog(
                swipeKey: _swipeKey,
                matchedUser: User.fromDocument(clickedUserDoc.data()!),
              );
            },
          );
        }
      },
    );

    /// like profile
    await _likesApi.likeUser(
      likedUserId: clickedUserDoc[USER_ID],
      userDeviceToken: clickedUserDoc[USER_DEVICE_TOKEN],
      nMessage:
          "${UserModel().user.userFullname.split(' ')[0]}, "
          "${_i18n.translate("liked_your_profile_click_and_see")}",
      onLikeResult: (result) {
        debugPrint('likeResult: $result');
      },
    );
  }
}
