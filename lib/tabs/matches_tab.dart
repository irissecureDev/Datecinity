import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:soulmate/api/matches_api.dart';
import 'package:soulmate/datas/user.dart';
import 'package:soulmate/helpers/app_localizations.dart';
import 'package:soulmate/models/user_model.dart';
import 'package:soulmate/screens/chat_screen.dart';
import 'package:soulmate/widgets/no_data.dart';
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

  @override
  void initState() {
    super.initState();
    _loadMatchesAndLocation();
  }

  Future<void> _loadMatchesAndLocation() async {
    try {
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
      );
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });

      final matches = await _matchesApi.getMatches();
      if (!mounted) return;

      setState(() {
        _matches = matches;
      });

      // Load marker data
      for (var match in matches) {
        final userSnapshot = await UserModel().getUser(match.id);
        if (userSnapshot.exists) {
          final data = userSnapshot.data();
          final User user = User.fromDocument(data!);
          final geo = user.userGeoPoint;
          final icon = await user.getMarkerFromUrl();

          final marker = Marker(
            markerId: MarkerId(match.id),
            position: LatLng(geo.latitude, geo.longitude),
            icon: icon,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChatScreen(user: user)),
              );
            },
          );
          setState(() => _markers.add(marker));
        }
      }
    } catch (e) {
      debugPrint("Error loading matches or location: $e");
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

    if (_matches!.isEmpty) {
      return NoData(svgName: 'heart_icon', text: _i18n.translate("no_match"));
    }

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
}
