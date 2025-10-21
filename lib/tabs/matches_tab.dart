import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cheers/api/matches_api.dart';

import 'package:cheers/datas/user.dart';
import 'package:cheers/helpers/app_helper.dart';
import 'package:cheers/helpers/app_localizations.dart';
import 'package:cheers/models/user_model.dart';
import 'package:cheers/widgets/processing.dart';
import 'package:cheers/widgets/svg_icon.dart';

class MatchesTab extends StatefulWidget {
  const MatchesTab({super.key});

  @override
  MatchesTabState createState() => MatchesTabState();
}

class MatchesTabState extends State<MatchesTab> with TickerProviderStateMixin {
  final MatchesApi _matchesApi = MatchesApi();
  final AppHelper _appHelper = AppHelper();
  List<DocumentSnapshot<Map<String, dynamic>>>? _matches;
  List<User>? _matchUsers;
  LatLng? _currentLocation;
  late AppLocalizations _i18n;

  final Set<Marker> _markers = {};
  final Completer<GoogleMapController> _mapController = Completer();

  // Ajout d'un marqueur pour la position actuelle
  Marker? _currentLocationMarker;

  // Tab controller pour basculer entre carte et liste
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMatchesAndLocation();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showLocationDeniedDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(_i18n.translate("location_permission_denied")),
        content: Text(_i18n.translate("enable_location_permission")),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_i18n.translate("ok")),
          ),
        ],
      ),
    );
  }

  Future<void> _loadMatchesAndLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permission denied');
          _showLocationDeniedDialog();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permission denied forever');
        _showLocationDeniedDialog();
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });

      final matches = await _matchesApi.getMatches();
      if (!mounted) return;

      setState(() {
        _matches = matches;
      });

      // Charger les détails des utilisateurs matches avec pourcentages de compatibilité
      await _loadMatchUsers(matches);

      // Mettre à jour le marqueur de position actuelle avec le bon message
      String locationSnippet;
      if (matches.isEmpty) {
        locationSnippet = _i18n.translate("no_matches_in_your_area");
      } else {
        locationSnippet = _i18n.translate("current_position");
      }

      _currentLocationMarker = Marker(
        markerId: const MarkerId('current_location'),
        position: _currentLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(
          title: _i18n.translate("your_location"),
          snippet: locationSnippet,
        ),
      );

      // Ajouter le marqueur de position actuelle
      setState(() {
        _markers.clear(); // Effacer les anciens marqueurs
        _markers.add(_currentLocationMarker!);
      });

      // Charger les marqueurs des matches
      for (var match in matches) {
        final userSnapshot = await UserModel().getUser(match.id);
        if (userSnapshot.exists) {
          final data = userSnapshot.data();
          final User user = User.fromDocument(data!);
          final geo = user.userGeoPoint;
          final double compatibility = _calculateCompatibility(user);
          final int age = DateTime.now().year - user.userBirthYear;

          // Créer un marqueur personnalisé pour chaque match
          BitmapDescriptor icon;
          try {
            icon = await user.getMarkerFromUrl();
          } catch (e) {
            // Fallback vers un marqueur par défaut si l'image échoue
            icon = BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            );
          }

          final marker = Marker(
            markerId: MarkerId(match.id),
            position: LatLng(geo.latitude, geo.longitude),
            icon: icon,
            infoWindow: InfoWindow(
              title: '${user.userFullname}, $age ans',
              snippet:
                  '${compatibility.round()}% compatible • ${user.userLocality}, ${user.userCountry}',
            ),
            onTap: () {
              _showMatchDialog(user);
            },
          );

          if (mounted) {
            setState(() => _markers.add(marker));
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading matches or location: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_i18n.translate("error_loading_matches")),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Charger les détails des utilisateurs matches avec calcul de compatibilité
  Future<void> _loadMatchUsers(
    List<DocumentSnapshot<Map<String, dynamic>>> matches,
  ) async {
    List<Map<String, dynamic>> usersWithCompatibility = [];
    final currentUser = UserModel().user;
    final currentPrefs = currentUser.preferences ?? {};

    for (var match in matches) {
      try {
        final userSnapshot = await UserModel().getUser(match.id);
        if (userSnapshot.exists) {
          final data = userSnapshot.data()!;
          final User user = User.fromDocument(data);

          // Calculer le pourcentage de compatibilité
          double compatibilityPercentage = 0.0;
          if (currentPrefs.isNotEmpty && (user.preferences ?? {}).isNotEmpty) {
            int matchingAnswers = 0;
            for (final entry in currentPrefs.entries) {
              if ((user.preferences ?? {}).containsKey(entry.key) &&
                  (user.preferences ?? {})[entry.key] == entry.value) {
                matchingAnswers++;
              }
            }
            compatibilityPercentage =
                (matchingAnswers / currentPrefs.length * 100)
                    .clamp(0, 100)
                    .toDouble();
          }

          // Créer un objet avec l'utilisateur et son pourcentage
          usersWithCompatibility.add({
            'user': user,
            'compatibility': compatibilityPercentage,
          });
        }
      } catch (e) {
        debugPrint("Error loading match user ${match.id}: $e");
      }
    }

    // Trier par pourcentage de compatibilité décroissant
    usersWithCompatibility.sort(
      (a, b) => (b['compatibility'] as double).compareTo(
        a['compatibility'] as double,
      ),
    );

    if (mounted) {
      setState(() {
        _matchUsers = usersWithCompatibility
            .map((item) => item['user'] as User)
            .toList();
      });
    }
  }

  /// Calculer le pourcentage de compatibilité pour un utilisateur donné
  double _calculateCompatibility(User user) {
    final currentPrefs = UserModel().user.preferences ?? {};
    final userPrefs = user.preferences ?? {};

    if (currentPrefs.isEmpty || userPrefs.isEmpty) return 0.0;

    int matchingAnswers = 0;
    for (final entry in currentPrefs.entries) {
      if (userPrefs.containsKey(entry.key) &&
          userPrefs[entry.key] == entry.value) {
        matchingAnswers++;
      }
    }

    return (matchingAnswers / currentPrefs.length * 100)
        .clamp(0, 100)
        .toDouble();
  }

  @override
  Widget build(BuildContext context) {
    _i18n = AppLocalizations.of(context);

    return Column(
      children: [
        // Onglets pour basculer entre carte et liste
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(25),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey[600],
            labelStyle: const TextStyle(fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.map_outlined, size: 18),
                    const SizedBox(width: 8),
                    Text(_i18n.translate("map")),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.list_outlined, size: 18),
                    const SizedBox(width: 8),
                    Text(_i18n.translate("list")),
                  ],
                ),
              ),
            ],
            onTap: (index) {
              // L'utilisateur a basculé entre les onglets
            },
          ),
        ),

        // Contenu selon l'onglet sélectionné
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_buildMap(), _buildList()],
          ),
        ),
      ],
    );
  }

  Widget _buildMap() {
    if (_currentLocation == null) {
      return Processing(text: _i18n.translate("loading_location"));
    }

    if (_matches == null) {
      return Processing(text: _i18n.translate("loading"));
    }

    // Toujours afficher la carte avec au moins la position actuelle
    // même s'il n'y a pas de matches
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _currentLocation!,
        zoom: 12,
      ),
      markers: _markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      onMapCreated: (controller) {
        if (!_mapController.isCompleted) {
          _mapController.complete(controller);
        }
      },
    );
  }

  /// Construire la vue en liste des matches
  Widget _buildList() {
    if (_currentLocation == null) {
      return Processing(text: _i18n.translate("loading_location"));
    }

    if (_matches == null) {
      return Processing(text: _i18n.translate("loading"));
    }

    if (_matchUsers == null) {
      return Processing(text: _i18n.translate("loading"));
    }

    if (_matchUsers!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.favorite_outline,
                size: 60,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _i18n.translate("no_matches_found"),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Continuez à utiliser l'app pour trouver des matches !",
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _matchUsers!.length,
      itemBuilder: (context, index) {
        final User user = _matchUsers![index];
        final double compatibility = _calculateCompatibility(user);
        final int age = DateTime.now().year - user.userBirthYear;
        final int distance = _appHelper.getDistanceBetweenUsers(
          userLat: user.userGeoPoint.latitude,
          userLong: user.userGeoPoint.longitude,
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                offset: const Offset(0, 4),
                blurRadius: 15,
              ),
            ],
          ),
          child: InkWell(
            onTap: () => _showMatchDialog(user),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Photo de profil
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: user.userProfilePhoto.isNotEmpty
                          ? Image.network(
                              user.userProfilePhoto,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.grey,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Informations utilisateur
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nom et âge
                        Text(
                          '${user.userFullname}, $age ans',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Localisation
                        Row(
                          children: [
                            const SvgIcon(
                              "assets/icons/location_point_icon.svg",
                              width: 14,
                              height: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${user.userLocality}, ${user.userCountry}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Distance et Compatibilité
                        Row(
                          children: [
                            // Distance
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.blue[200]!,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                '${distance}km',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Pourcentage de compatibilité
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).primaryColor,
                                    Theme.of(
                                      context,
                                    ).primaryColor.withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${compatibility.round()}% compatible',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Flèche
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Affiche un dialog avec les détails du match
  void _showMatchDialog(User user) {
    // Calculer l'âge à partir de l'année de naissance
    int currentYear = DateTime.now().year;
    int age = currentYear - user.userBirthYear;

    // Calculer la distance et la compatibilité
    final int distance = _appHelper.getDistanceBetweenUsers(
      userLat: user.userGeoPoint.latitude,
      userLong: user.userGeoPoint.longitude,
    );
    final double compatibility = _calculateCompatibility(user);

    // Obtenir les photos depuis la galerie
    List<String> photos = [];
    if (user.userGallery != null) {
      user.userGallery!.forEach((key, value) {
        if (value is String && value.isNotEmpty) {
          photos.add(value);
        }
      });
    }
    // Ajouter la photo de profil si disponible
    if (user.userProfilePhoto.isNotEmpty &&
        !photos.contains(user.userProfilePhoto)) {
      photos.insert(0, user.userProfilePhoto);
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Photo de profil avec bordure moderne
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.8),
                    ],
                  ),
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 46,
                    backgroundImage: photos.isNotEmpty
                        ? NetworkImage(photos.first)
                        : null,
                    child: photos.isEmpty
                        ? const Icon(Icons.person, size: 50, color: Colors.grey)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Nom et âge
              Text(
                '${user.userFullname}, $age ans',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D3748),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Badges d'informations
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Distance
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.blue[200]!, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SvgIcon(
                          "assets/icons/location_point_icon.svg",
                          width: 12,
                          height: 12,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${distance}km',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Compatibilité
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.favorite,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${compatibility.round()}%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Localisation
              Text(
                '${user.userLocality}, ${user.userCountry}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Bio (si disponible)
              if (user.userBio.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey[200]!, width: 1),
                  ),
                  child: Text(
                    user.userBio,
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: Color(0xFF4A5568),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ],
          ),
          actions: [
            // Bouton Fermer
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              child: Text(
                _i18n.translate("close"),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Bouton Voir le profil
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Navigation vers le profil complet
                  // Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(user: user)));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  _i18n.translate("view_profile"),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
