import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cheers/models/hotspot.dart';
import 'package:cheers/models/user_model.dart';
import 'package:cheers/services/hotspots_service.dart';

/// Widget de carte pour afficher les hotspots et la position utilisateur
class HotspotsMapWidget extends StatefulWidget {
  final List<Hotspot> hotspots;
  final Function(Hotspot)? onHotspotTap;
  final VoidCallback? onRefresh;

  const HotspotsMapWidget({
    super.key,
    required this.hotspots,
    this.onHotspotTap,
    this.onRefresh,
  });

  @override
  _HotspotsMapWidgetState createState() => _HotspotsMapWidgetState();
}

class _HotspotsMapWidgetState extends State<HotspotsMapWidget> {
  GoogleMapController? _mapController;
  final HotspotsService _hotspotsService = HotspotsService();
  Position? _userPosition;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Hotspot? _selectedHotspot;
  bool _isLoadingRoute = false;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void didUpdateWidget(HotspotsMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hotspots != widget.hotspots) {
      _updateMarkers();
    }
  }

  /// Initialiser la carte
  Future<void> _initializeMap() async {
    await _getCurrentPosition();
    _updateMarkers();
  }

  /// Obtenir la position actuelle de l'utilisateur
  Future<void> _getCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      setState(() {
        _userPosition = position;
      });

      // Centrer la carte sur la position utilisateur quand elle est obtenue
      if (_mapController != null) {
        _centerMapOnUser();
      }
    } catch (e) {
      debugPrint('❌ Erreur obtention position: $e');
    }
  }

  /// Mettre à jour les marqueurs sur la carte
  void _updateMarkers() {
    final markers = <Marker>{};

    // Marqueur de l'utilisateur actuel
    if (_userPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user_position'),
          position: LatLng(_userPosition!.latitude, _userPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: 'Ma position',
            snippet: UserModel().user.userFullname,
          ),
        ),
      );
    }

    // Marqueurs des hotspots
    for (final hotspot in widget.hotspots) {
      final color = hotspot.type == HotspotType.high
          ? BitmapDescriptor.hueRed
          : BitmapDescriptor.hueOrange;

      markers.add(
        Marker(
          markerId: MarkerId(hotspot.id),
          position: LatLng(hotspot.center.latitude, hotspot.center.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(color),
          infoWindow: InfoWindow(
            title: hotspot.placeName,
            snippet: '${hotspot.userCount} personnes connectées',
            onTap: () => _onHotspotMarkerTap(hotspot),
          ),
          onTap: () => _onHotspotMarkerTap(hotspot),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  /// Gérer le tap sur un marqueur de hotspot
  void _onHotspotMarkerTap(Hotspot hotspot) {
    setState(() {
      _selectedHotspot = hotspot;
    });

    widget.onHotspotTap?.call(hotspot);
    _showHotspotBottomSheet(hotspot);
  }

  /// Centrer la carte sur la position de l'utilisateur
  void _centerMapOnUser() {
    if (_mapController != null && _userPosition != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_userPosition!.latitude, _userPosition!.longitude),
            zoom: 15.0,
          ),
        ),
      );
    }
  }

  /// Afficher la bottom sheet avec les détails du hotspot
  void _showHotspotBottomSheet(Hotspot hotspot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Poignée de drag
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // En-tête
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hotspot.placeName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (hotspot.placeType != null)
                          Text(
                            hotspot.placeType!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: hotspot.type == HotspotType.high
                          ? Colors.red
                          : Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      hotspot.type == HotspotType.high ? 'TRÈS ACTIF' : 'ACTIF',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Statistiques
              Row(
                children: [
                  _buildStatChip(Icons.people, hotspot.userCountDescription),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    Icons.location_on,
                    hotspot.distanceDescription,
                  ),
                  if (hotspot.averageAge > 0) ...[
                    const SizedBox(width: 8),
                    _buildStatChip(
                      Icons.cake,
                      '${hotspot.averageAge.round()} ans moy.',
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 16),

              // Boutons d'action
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoadingRoute
                          ? null
                          : () => _showRouteToHotspot(hotspot),
                      icon: _isLoadingRoute
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.directions),
                      label: Text(_isLoadingRoute ? 'Calcul...' : 'Itinéraire'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _centerMapOnHotspot(hotspot),
                      icon: const Icon(Icons.center_focus_strong),
                      label: const Text('Centrer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// Construire un chip de statistique
  Widget _buildStatChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.grey[600], size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Afficher l'itinéraire vers un hotspot
  Future<void> _showRouteToHotspot(Hotspot hotspot) async {
    if (_userPosition == null) return;

    setState(() {
      _isLoadingRoute = true;
    });

    try {
      final route = await _hotspotsService.getRouteToHotspot(hotspot);

      if (route.isNotEmpty) {
        final polyline = Polyline(
          polylineId: PolylineId('route_to_${hotspot.id}'),
          points: route
              .map((point) => LatLng(point['latitude']!, point['longitude']!))
              .toList(),
          color: Colors.blue,
          width: 4,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        );

        setState(() {
          _polylines = {polyline};
        });

        // Centrer la carte pour montrer tout l'itinéraire
        _fitMapToShowRoute(route);
      }
    } catch (e) {
      debugPrint('❌ Erreur calcul itinéraire: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Impossible de calculer l\'itinéraire'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingRoute = false;
      });
    }
  }

  /// Centrer la carte sur un hotspot
  void _centerMapOnHotspot(Hotspot hotspot) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(hotspot.center.latitude, hotspot.center.longitude),
        16.0,
      ),
    );
  }

  /// Ajuster la carte pour montrer tous les hotspots
  void _fitAllHotspots() {
    if (widget.hotspots.isEmpty) return;

    final List<LatLng> positions = [];

    // Ajouter la position utilisateur
    if (_userPosition != null) {
      positions.add(LatLng(_userPosition!.latitude, _userPosition!.longitude));
    }

    // Ajouter les positions des hotspots
    for (final hotspot in widget.hotspots) {
      positions.add(LatLng(hotspot.center.latitude, hotspot.center.longitude));
    }

    if (positions.isNotEmpty) {
      // Calculer les limites
      double minLat = positions.first.latitude;
      double maxLat = positions.first.latitude;
      double minLng = positions.first.longitude;
      double maxLng = positions.first.longitude;

      for (final position in positions) {
        minLat = minLat < position.latitude ? minLat : position.latitude;
        maxLat = maxLat > position.latitude ? maxLat : position.latitude;
        minLng = minLng < position.longitude ? minLng : position.longitude;
        maxLng = maxLng > position.longitude ? maxLng : position.longitude;
      }

      // Ajouter une marge
      final double margin = 0.01;
      final LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(minLat - margin, minLng - margin),
        northeast: LatLng(maxLat + margin, maxLng + margin),
      );

      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100.0),
      );
    }
  }

  /// Ajuster la carte pour montrer tout l'itinéraire
  void _fitMapToShowRoute(List<Map<String, double>> route) {
    if (route.length < 2) return;

    double minLat = route.first['latitude']!;
    double maxLat = route.first['latitude']!;
    double minLng = route.first['longitude']!;
    double maxLng = route.first['longitude']!;

    for (final point in route) {
      minLat = minLat < point['latitude']! ? minLat : point['latitude']!;
      maxLat = maxLat > point['latitude']! ? maxLat : point['latitude']!;
      minLng = minLng < point['longitude']! ? minLng : point['longitude']!;
      maxLng = maxLng > point['longitude']! ? maxLng : point['longitude']!;
    }

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100.0, // padding
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Attendre d'avoir la position utilisateur avant d'afficher la carte
    if (_userPosition == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading your location...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final initialPosition = LatLng(
      _userPosition!.latitude,
      _userPosition!.longitude,
    );

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: initialPosition,
            zoom: 13.0,
          ),
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
            // Centrer immédiatement sur l'utilisateur si la position est disponible
            if (_userPosition != null) {
              _centerMapOnUser();
            }
          },
          markers: _markers,
          polylines: _polylines,

          // Activer toutes les interactions utilisateur
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          compassEnabled: true,
          mapToolbarEnabled: true,

          // Contrôles de zoom - permettre le zoom par gestes
          zoomControlsEnabled: false, // On garde nos boutons personnalisés
          zoomGesturesEnabled: true, // Pinch to zoom activé
          // Contrôles de déplacement et rotation
          scrollGesturesEnabled: true, // Déplacement tactile activé
          rotateGesturesEnabled: true, // Rotation avec deux doigts activée
          tiltGesturesEnabled: true, // Inclinaison activée
          // Type de carte
          mapType: MapType.normal,

          // Limites de zoom pour une meilleure expérience
          minMaxZoomPreference: const MinMaxZoomPreference(5.0, 20.0),

          // Callbacks pour les interactions
          onTap: (LatLng position) {
            // Masquer la bottom sheet si elle est ouverte quand on tap sur la carte
            if (_selectedHotspot != null) {
              setState(() {
                _selectedHotspot = null;
              });
            }
          },
          onCameraMove: (CameraPosition position) {
            // Réagir aux mouvements de caméra si nécessaire
            // Peut être utilisé pour charger plus de hotspots quand on se déplace
          },
        ),

        // Boutons de contrôle principal
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            children: [
              // Bouton refresh
              FloatingActionButton(
                heroTag: 'refresh_hotspots',
                mini: true,
                onPressed: widget.onRefresh,
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue,
                child: const Icon(Icons.refresh),
              ),
              const SizedBox(height: 8),

              // Bouton ma position
              FloatingActionButton(
                heroTag: 'my_location',
                mini: true,
                onPressed: _goToMyLocation,
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue,
                child: const Icon(Icons.my_location),
              ),
              const SizedBox(height: 8),

              // Bouton voir tous les hotspots
              if (widget.hotspots.isNotEmpty)
                FloatingActionButton(
                  heroTag: 'fit_all_hotspots',
                  mini: true,
                  onPressed: _fitAllHotspots,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green,
                  child: const Icon(Icons.fullscreen),
                ),
              const SizedBox(height: 8),

              // Bouton clear route
              if (_polylines.isNotEmpty)
                FloatingActionButton(
                  heroTag: 'clear_route',
                  mini: true,
                  onPressed: _clearRoute,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red,
                  child: const Icon(Icons.clear),
                ),
            ],
          ),
        ),

        // Boutons de zoom
        Positioned(
          bottom: 100,
          right: 16,
          child: Column(
            children: [
              // Bouton zoom in
              FloatingActionButton(
                heroTag: 'zoom_in',
                mini: true,
                onPressed: _zoomIn,
                backgroundColor: Colors.white,
                foregroundColor: Colors.grey[700],
                child: const Icon(Icons.add, size: 20),
              ),
              const SizedBox(height: 4),

              // Bouton zoom out
              FloatingActionButton(
                heroTag: 'zoom_out',
                mini: true,
                onPressed: _zoomOut,
                backgroundColor: Colors.white,
                foregroundColor: Colors.grey[700],
                child: const Icon(Icons.remove, size: 20),
              ),
            ],
          ),
        ),

        // Indicateur de chargement
        if (_isLoadingRoute)
          const Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Calcul de l\'itinéraire...'),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Aller à ma position
  void _goToMyLocation() {
    _centerMapOnUser();
  }

  /// Zoomer
  void _zoomIn() {
    _mapController?.animateCamera(CameraUpdate.zoomIn());
  }

  /// Dézoomer
  void _zoomOut() {
    _mapController?.animateCamera(CameraUpdate.zoomOut());
  }

  /// Effacer l'itinéraire
  void _clearRoute() {
    setState(() {
      _polylines.clear();
    });
  }
}
