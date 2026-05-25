import 'dart:async';
import 'package:flutter/material.dart';
import 'package:datecinity/models/hotspot.dart';
import 'package:datecinity/models/nearby_place.dart';
import 'package:datecinity/services/hotspots_service.dart';
import 'package:datecinity/services/nearby_places_service.dart';
import 'package:datecinity/widgets/hotspots_map_widget.dart';
import 'package:datecinity/widgets/nearby_places_list_widget.dart';
import 'package:datecinity/widgets/processing.dart';
import 'package:url_launcher/url_launcher.dart';

/// Matches tab with hotspots and nearby places logic
///
/// Tab 1 - Map: Displays nearby places (bars, restaurants, etc.) on a map
/// Tab 2 - List: List of nearby places within 4km radius
class MatchesTab extends StatefulWidget {
  const MatchesTab({super.key});

  @override
  MatchesTabState createState() => MatchesTabState();
}

class MatchesTabState extends State<MatchesTab> with TickerProviderStateMixin {
  final HotspotsService _hotspotsService = HotspotsService();
  final NearbyPlacesService _nearbyPlacesService = NearbyPlacesService();

  // Hotspots state (for map users)
  List<Hotspot> _hotspots = [];
  bool _isLoadingHotspots = false;

  // Nearby places state (for list and map)
  List<NearbyPlace> _nearbyPlaces = [];
  bool _isLoadingPlaces = false;

  /// When non-null, the map shows only this place (focused mode)
  NearbyPlace? _focusedPlace;

  String? _errorMessage;

  // Tab controller to switch between map and list
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Load all data (hotspots + places)
  Future<void> _loadData() async {
    await Future.wait([_loadHotspots(), _loadNearbyPlaces()]);
  }

  /// Load hotspots (for map users)
  Future<void> _loadHotspots() async {
    if (_isLoadingHotspots) return;

    setState(() {
      _isLoadingHotspots = true;
    });

    try {
      final hotspots = await _hotspotsService.detectHotspots();

      if (mounted) {
        setState(() {
          _hotspots = hotspots;
          _isLoadingHotspots = false;
        });
      }

      debugPrint('🎯 ${hotspots.length} hotspots loaded');
    } catch (e) {
      debugPrint('❌ Error loading hotspots: $e');

      if (mounted) {
        setState(() {
          _isLoadingHotspots = false;
        });
      }
    }
  }

  /// Load nearby places (for list and map)
  Future<void> _loadNearbyPlaces() async {
    if (_isLoadingPlaces) return;

    setState(() {
      _isLoadingPlaces = true;
      _errorMessage = null;
    });

    try {
      final places = await _nearbyPlacesService.getNearbyPlaces();

      if (mounted) {
        setState(() {
          _nearbyPlaces = places;
          _isLoadingPlaces = false;
        });
      }

      debugPrint('📍 ${places.length} nearby places loaded');
    } catch (e) {
      debugPrint('❌ Error loading nearby places: $e');

      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading places';
          _isLoadingPlaces = false;
        });
      }
    }
  }

  /// Handle tap on a hotspot (map)
  void _onHotspotTap(Hotspot hotspot) {
    debugPrint('🎯 Hotspot selected: ${hotspot.placeName}');

    // Switch to map tab if we're on the list
    if (_tabController.index == 1) {
      _tabController.animateTo(0);
    }
  }

  /// Handle tap on a place (list)
  void _onPlaceTap(NearbyPlace place) {
    debugPrint('📍 Place selected: ${place.name}');

    setState(() {
      _focusedPlace = place;
    });

    // Switch to map tab
    if (_tabController.index != 0) {
      _tabController.animateTo(0);
    }
  }

  /// Clear focused place and return to all-places view
  void _onClearFocus() {
    setState(() {
      _focusedPlace = null;
    });
  }

  /// Handle request for directions to a place
  void _onGetPlaceDirections(NearbyPlace place) {
    _openDirections(
      place.location.latitude,
      place.location.longitude,
      place.name,
    );
  }

  /// Open Google Maps for directions
  Future<void> _openDirections(double lat, double lng, String placeName) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🧭 Directions to $placeName'),
            action: SnackBarAction(
              label: 'Open Maps',
              onPressed: () async {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              },
            ),
          ),
        );
      }
    }
  }

  /// Refresh nearby places
  Future<void> _refreshNearbyPlaces() async {
    await _nearbyPlacesService.forceRefresh();
    await _loadNearbyPlaces();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Modern tab bar style
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          height: 54,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(27),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
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
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey[600],
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 0.2,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 20),
                    SizedBox(width: 8),
                    Text("Map"),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.list, size: 20),
                    SizedBox(width: 8),
                    Text("List"),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Content based on selected tab
        Expanded(child: _buildContent()),
      ],
    );
  }

  /// Build content based on state
  Widget _buildContent() {
    // For Map tab, use nearby places
    // For List tab, use nearby places (Google Places)

    return TabBarView(
      controller: _tabController,
      physics:
          const NeverScrollableScrollPhysics(), // Disable swipe between tabs to avoid conflicts
      children: [_buildMapView(), _buildListView()],
    );
  }

  /// Build the map view (nearby places)
  Widget _buildMapView() {
    if (_isLoadingPlaces) {
      return const Processing(text: "Searching for nearby places...");
    }

    return HotspotsMapWidget(
      hotspots: _hotspots,
      nearbyPlaces: _nearbyPlaces,
      onHotspotTap: _onHotspotTap,
      onPlaceTap: _onPlaceTap,
      onRefresh: _refreshNearbyPlaces,
      focusedPlace: _focusedPlace,
      onClearFocus: _onClearFocus,
    );
  }

  /// Build the list view (nearby places)
  Widget _buildListView() {
    if (_isLoadingPlaces) {
      return const Processing(text: "Searching for nearby places...");
    }

    if (_errorMessage != null && _nearbyPlaces.isEmpty) {
      return _buildErrorState();
    }

    return NearbyPlacesListWidget(
      places: _nearbyPlaces,
      onPlaceTap: _onPlaceTap,
      onGetDirections: _onGetPlaceDirections,
      onRefresh: _refreshNearbyPlaces,
    );
  }

  /// Build error state
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Loading Error',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshNearbyPlaces,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
