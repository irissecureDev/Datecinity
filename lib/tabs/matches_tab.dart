import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:soulmate/api/matches_api.dart';
import 'package:soulmate/datas/user.dart';
import 'package:soulmate/helpers/app_localizations.dart';
import 'package:soulmate/models/user_model.dart';
import 'package:soulmate/widgets/processing.dart';

class MatchesTab extends StatefulWidget {
  const MatchesTab({super.key});

  @override
  MatchesTabState createState() => MatchesTabState();
}

class MatchesTabState extends State<MatchesTab> {
  final MatchesApi _matchesApi = MatchesApi();
  List<DocumentSnapshot<Map<String, dynamic>>>? _matches;
  LatLng? _currentLocation;
  late AppLocalizations _i18n;

  final Set<Marker> _markers = {};
  final Completer<GoogleMapController> _mapController = Completer();

  // Ajout d'un marqueur pour la position actuelle
  Marker? _currentLocationMarker;

  @override
  void initState() {
    super.initState();
    _loadMatchesAndLocation();
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
              title: user.userFullname,
              snippet: '${user.userLocality}, ${user.userCountry}',
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

  @override
  Widget build(BuildContext context) {
    _i18n = AppLocalizations.of(context);

    return Column(children: [Expanded(child: _buildMap())]);
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
      onMapCreated: (controller) => _mapController.complete(controller),
    );
  }

  /// Affiche un dialog avec les détails du match
  void _showMatchDialog(User user) {
    // Calculer l'âge à partir de l'année de naissance
    int currentYear = DateTime.now().year;
    int age = currentYear - user.userBirthYear;

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
            borderRadius: BorderRadius.circular(15),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Photo de profil
              CircleAvatar(
                radius: 50,
                backgroundImage: photos.isNotEmpty
                    ? NetworkImage(photos.first)
                    : null,
                child: photos.isEmpty
                    ? const Icon(Icons.person, size: 50)
                    : null,
              ),
              const SizedBox(height: 16),

              // Nom et âge
              Text(
                '${user.userFullname}, $age ans',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Localisation
              Text(
                '${user.userLocality}, ${user.userCountry}',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),

              // Bio (si disponible)
              if (user.userBio.isNotEmpty) ...[
                Text(
                  user.userBio,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(_i18n.translate("close")),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Vous pouvez ajouter ici la navigation vers le chat ou le profil complet
                // Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(user: user)));
              },
              child: Text(_i18n.translate("view_profile")),
            ),
          ],
        );
      },
    );
  }
}
