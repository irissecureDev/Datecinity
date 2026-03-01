import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cheers/models/hotspot.dart';
import 'package:cheers/models/nearby_place.dart';
import 'package:cheers/models/user_model.dart';
import 'package:cheers/services/hotspots_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// Map widget to display hotspots, nearby places and user position
class HotspotsMapWidget extends StatefulWidget {
  final List<Hotspot> hotspots;
  final List<NearbyPlace> nearbyPlaces;
  final Function(Hotspot)? onHotspotTap;
  final Function(NearbyPlace)? onPlaceTap;
  final VoidCallback? onRefresh;

  const HotspotsMapWidget({
    super.key,
    required this.hotspots,
    this.nearbyPlaces = const [],
    this.onHotspotTap,
    this.onPlaceTap,
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
  NearbyPlace? _selectedPlace;
  bool _isLoadingRoute = false;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void didUpdateWidget(HotspotsMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hotspots != widget.hotspots ||
        oldWidget.nearbyPlaces != widget.nearbyPlaces) {
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
      debugPrint('❌ Error getting position: $e');
    }
  }

  /// Update markers on the map
  void _updateMarkers() {
    final markers = <Marker>{};

    // Current user marker
    if (_userPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user_position'),
          position: LatLng(_userPosition!.latitude, _userPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: 'My location',
            snippet: UserModel().user.userFullname,
          ),
        ),
      );
    }

    // Hotspot markers
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
            snippet: '${hotspot.userCount} people connected',
            onTap: () => _onHotspotMarkerTap(hotspot),
          ),
          onTap: () => _onHotspotMarkerTap(hotspot),
        ),
      );
    }

    // Nearby places markers
    for (final place in widget.nearbyPlaces) {
      final color = _getPlaceMarkerColor(place.category);
      final ratingStr = place.rating != null
          ? '${place.rating!.toStringAsFixed(1)}★'
          : '';

      markers.add(
        Marker(
          markerId: MarkerId('place_${place.id}'),
          position: LatLng(place.location.latitude, place.location.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(color),
          infoWindow: InfoWindow(
            title: place.name,
            snippet: '${place.category.displayName} • $ratingStr',
            onTap: () => _onPlaceMarkerTap(place),
          ),
          onTap: () => _onPlaceMarkerTap(place),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  /// Get marker color based on place category
  double _getPlaceMarkerColor(PlaceCategory category) {
    switch (category) {
      case PlaceCategory.bar:
        return BitmapDescriptor.hueMagenta;
      case PlaceCategory.restaurant:
        return BitmapDescriptor.hueOrange;
      case PlaceCategory.nightClub:
        return BitmapDescriptor.hueViolet;
      case PlaceCategory.cafe:
        return BitmapDescriptor.hueYellow;
      case PlaceCategory.shoppingMall:
        return BitmapDescriptor.hueCyan;
      case PlaceCategory.cinema:
        return BitmapDescriptor.hueRose;
      case PlaceCategory.park:
        return BitmapDescriptor.hueGreen;
      case PlaceCategory.gym:
        return BitmapDescriptor.hueRed;
      case PlaceCategory.spa:
        return BitmapDescriptor.hueAzure;
      case PlaceCategory.other:
        return BitmapDescriptor.hueBlue;
    }
  }

  /// Handle tap on a hotspot marker
  void _onHotspotMarkerTap(Hotspot hotspot) {
    setState(() {
      _selectedHotspot = hotspot;
      _selectedPlace = null;
    });

    widget.onHotspotTap?.call(hotspot);
    _showHotspotBottomSheet(hotspot);
  }

  /// Handle tap on a place marker
  void _onPlaceMarkerTap(NearbyPlace place) {
    setState(() {
      _selectedPlace = place;
      _selectedHotspot = null;
    });

    widget.onPlaceTap?.call(place);
    _showPlaceBottomSheet(place);
  }

  /// Center the map on the user's position
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

  /// Show bottom sheet with hotspot details
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
                      hotspot.type == HotspotType.high
                          ? 'VERY ACTIVE'
                          : 'ACTIVE',
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
                      '${hotspot.averageAge.round()} avg.',
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
                      label: Text(
                        _isLoadingRoute ? 'Loading...' : 'Directions',
                      ),
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
                      label: const Text('Center'),
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

  /// Build a stat chip
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

  /// Show route to hotspot
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

        // Center map to show the route
        _fitMapToShowRoute(route);
      }
    } catch (e) {
      debugPrint('❌ Error calculating route: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Unable to calculate route'),
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

  /// Center the map on a hotspot
  void _centerMapOnHotspot(Hotspot hotspot) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(hotspot.center.latitude, hotspot.center.longitude),
        16.0,
      ),
    );
  }

  /// Fit map to show all hotspots and places
  void _fitAllHotspots() {
    if (widget.hotspots.isEmpty && widget.nearbyPlaces.isEmpty) return;

    final List<LatLng> positions = [];

    // Add user position
    if (_userPosition != null) {
      positions.add(LatLng(_userPosition!.latitude, _userPosition!.longitude));
    }

    // Add hotspot positions
    for (final hotspot in widget.hotspots) {
      positions.add(LatLng(hotspot.center.latitude, hotspot.center.longitude));
    }

    // Add nearby place positions
    for (final place in widget.nearbyPlaces) {
      positions.add(LatLng(place.location.latitude, place.location.longitude));
    }

    if (positions.isNotEmpty) {
      // Calculate bounds
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

      // Add margin
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

  /// Fit map to show the route
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
    // Wait for user position before displaying the map
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
            // Center immediately on user if position is available
            if (_userPosition != null) {
              _centerMapOnUser();
            }
          },
          markers: _markers,
          polylines: _polylines,

          // Enable all user interactions
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          compassEnabled: true,
          mapToolbarEnabled: true,

          // Zoom controls - allow pinch to zoom
          zoomControlsEnabled: false, // Keep custom buttons
          zoomGesturesEnabled: true, // Pinch to zoom enabled
          // Move and rotate controls
          scrollGesturesEnabled: true, // Touch scroll enabled
          rotateGesturesEnabled: true, // Two-finger rotation enabled
          tiltGesturesEnabled: true, // Tilt enabled
          // Map type
          mapType: MapType.normal,

          // Zoom limits for better experience
          minMaxZoomPreference: const MinMaxZoomPreference(5.0, 20.0),

          // Callbacks for interactions
          onTap: (LatLng position) {
            // Hide bottom sheet when tapping on the map
            if (_selectedHotspot != null || _selectedPlace != null) {
              setState(() {
                _selectedHotspot = null;
                _selectedPlace = null;
              });
            }
          },
          onCameraMove: (CameraPosition position) {
            // React to camera movements if needed
            // Can be used to load more places when moving
          },
        ),

        // Main control buttons
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            children: [
              // Refresh button
              FloatingActionButton(
                heroTag: 'refresh_hotspots',
                mini: true,
                onPressed: widget.onRefresh,
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue,
                child: const Icon(Icons.refresh),
              ),
              const SizedBox(height: 8),

              // My location button
              FloatingActionButton(
                heroTag: 'my_location',
                mini: true,
                onPressed: _goToMyLocation,
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue,
                child: const Icon(Icons.my_location),
              ),
              const SizedBox(height: 8),

              // View all places button
              if (widget.hotspots.isNotEmpty || widget.nearbyPlaces.isNotEmpty)
                FloatingActionButton(
                  heroTag: 'fit_all_hotspots',
                  mini: true,
                  onPressed: _fitAllHotspots,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green,
                  child: const Icon(Icons.fullscreen),
                ),
              const SizedBox(height: 8),

              // Clear route button
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

        // Zoom buttons
        Positioned(
          bottom: 100,
          right: 16,
          child: Column(
            children: [
              // Zoom in button
              FloatingActionButton(
                heroTag: 'zoom_in',
                mini: true,
                onPressed: _zoomIn,
                backgroundColor: Colors.white,
                foregroundColor: Colors.grey[700],
                child: const Icon(Icons.add, size: 20),
              ),
              const SizedBox(height: 4),

              // Zoom out button
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

        // Loading indicator
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
                      Text('Calculating route...'),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Show bottom sheet with place details
  void _showPlaceBottomSheet(NearbyPlace place) {
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
              // Drag handle
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

              // Header with photo
              Row(
                children: [
                  // Place photo
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: place.photoUrl != null
                        ? Image.network(
                            place.photoUrl!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: _getPlaceCategoryColor(place.category),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _getPlaceCategoryIcon(place.category),
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          )
                        : Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: _getPlaceCategoryColor(place.category),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getPlaceCategoryIcon(place.category),
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          place.category.displayName,
                          style: TextStyle(
                            fontSize: 14,
                            color: _getPlaceCategoryColor(place.category),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (place.rating != null)
                          Row(
                            children: [
                              ...List.generate(5, (index) {
                                final rating = place.rating ?? 0;
                                return Icon(
                                  index < rating.floor()
                                      ? Icons.star
                                      : (index < rating
                                            ? Icons.star_half
                                            : Icons.star_border),
                                  color: Colors.amber,
                                  size: 16,
                                );
                              }),
                              const SizedBox(width: 4),
                              Text(
                                '${place.rating?.toStringAsFixed(1) ?? '0'} (${place.userRatingsTotal ?? 0})',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Address
              if (place.address != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          place.address!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Stats
              Row(
                children: [
                  _buildStatChip(
                    Icons.directions_walk,
                    '${place.distanceKm.toStringAsFixed(1)} km',
                  ),
                  const SizedBox(width: 8),
                  if (place.priceLevel != null)
                    _buildStatChip(
                      Icons.attach_money,
                      '\$' * place.priceLevel!,
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _openDirectionsToPlace(place),
                      icon: const Icon(Icons.directions),
                      label: const Text('Directions'),
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
                      onPressed: () => _centerMapOnPlace(place),
                      icon: const Icon(Icons.center_focus_strong),
                      label: const Text('Center'),
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

  /// Center the map on a place
  void _centerMapOnPlace(NearbyPlace place) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(place.location.latitude, place.location.longitude),
        16.0,
      ),
    );
    Navigator.pop(context);
  }

  /// Open directions to a place in Google Maps
  Future<void> _openDirectionsToPlace(NearbyPlace place) async {
    final lat = place.location.latitude;
    final lng = place.location.longitude;
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

  /// Get category icon
  IconData _getPlaceCategoryIcon(PlaceCategory category) {
    switch (category) {
      case PlaceCategory.bar:
        return Icons.local_bar;
      case PlaceCategory.restaurant:
        return Icons.restaurant;
      case PlaceCategory.nightClub:
        return Icons.nightlife;
      case PlaceCategory.cafe:
        return Icons.coffee;
      case PlaceCategory.shoppingMall:
        return Icons.shopping_bag;
      case PlaceCategory.cinema:
        return Icons.movie;
      case PlaceCategory.park:
        return Icons.park;
      case PlaceCategory.gym:
        return Icons.fitness_center;
      case PlaceCategory.spa:
        return Icons.spa;
      case PlaceCategory.other:
        return Icons.place;
    }
  }

  /// Get category color
  Color _getPlaceCategoryColor(PlaceCategory category) {
    switch (category) {
      case PlaceCategory.bar:
        return const Color(0xFFE91E63);
      case PlaceCategory.restaurant:
        return const Color(0xFFFF5722);
      case PlaceCategory.nightClub:
        return const Color(0xFF9C27B0);
      case PlaceCategory.cafe:
        return const Color(0xFF795548);
      case PlaceCategory.shoppingMall:
        return const Color(0xFF2196F3);
      case PlaceCategory.cinema:
        return const Color(0xFFFF9800);
      case PlaceCategory.park:
        return const Color(0xFF4CAF50);
      case PlaceCategory.gym:
        return const Color(0xFFF44336);
      case PlaceCategory.spa:
        return const Color(0xFF00BCD4);
      case PlaceCategory.other:
        return const Color(0xFF607D8B);
    }
  }

  /// Go to my location
  void _goToMyLocation() {
    _centerMapOnUser();
  }

  /// Zoom in
  void _zoomIn() {
    _mapController?.animateCamera(CameraUpdate.zoomIn());
  }

  /// Zoom out
  void _zoomOut() {
    _mapController?.animateCamera(CameraUpdate.zoomOut());
  }

  /// Clear route
  void _clearRoute() {
    setState(() {
      _polylines.clear();
    });
  }
}
