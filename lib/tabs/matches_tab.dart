import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cheers/models/hotspot.dart';
import 'package:cheers/services/hotspots_service.dart';
import 'package:cheers/widgets/hotspots_map_widget.dart';
import 'package:cheers/widgets/hotspots_list_widget.dart';
import 'package:cheers/widgets/processing.dart';
import 'package:cheers/helpers/app_localizations.dart';

/// Onglet Matches transformé avec la logique des hotspots
///
/// Tab 1 - Carte : Affiche les zones de concentration d'utilisateurs avec marqueurs colorés
/// Tab 2 - Liste : Liste des lieux populaires avec détails et actions
class MatchesTab extends StatefulWidget {
  const MatchesTab({super.key});

  @override
  MatchesTabState createState() => MatchesTabState();
}

class MatchesTabState extends State<MatchesTab> with TickerProviderStateMixin {
  final HotspotsService _hotspotsService = HotspotsService();

  // État
  List<Hotspot> _hotspots = [];
  bool _isLoadingHotspots = false;
  String? _errorMessage;
  late AppLocalizations _i18n;

  // Tab controller pour basculer entre carte et liste
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHotspots();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Charger les hotspots
  Future<void> _loadHotspots() async {
    if (_isLoadingHotspots) return;

    setState(() {
      _isLoadingHotspots = true;
      _errorMessage = null;
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
          _errorMessage = 'Error loading popular places';
          _isLoadingHotspots = false;
        });
      }
    }
  }

  /// Gérer le tap sur un hotspot
  void _onHotspotTap(Hotspot hotspot) {
    debugPrint('🎯 Hotspot selected: ${hotspot.placeName}');

    // Basculer vers l'onglet carte si on est sur la liste
    if (_tabController.index == 1) {
      _tabController.animateTo(0);
    }
  }

  /// Gérer la demande d'itinéraire
  void _onGetDirections(Hotspot hotspot) {
    // TODO: Intégrer avec une app de navigation externe
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🧭 Route to ${hotspot.placeName}'),
        action: SnackBarAction(
          label: 'Open Maps',
          onPressed: () {
            // TODO: Ouvrir Google Maps ou Apple Maps
            debugPrint('🗺️ Ouverture navigation vers ${hotspot.placeName}');
          },
        ),
      ),
    );
  }

  /// Actualiser les hotspots
  Future<void> _refreshHotspots() async {
    await _hotspotsService.forceRefresh();
    await _loadHotspots();
  }

  @override
  Widget build(BuildContext context) {
    _i18n = AppLocalizations.of(context);

    return Column(
      children: [
        // Barre d'onglets style moderne
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

        // Contenu selon l'onglet sélectionné
        Expanded(child: _buildContent()),
      ],
    );
  }

  /// Construire le contenu selon l'état
  Widget _buildContent() {
    if (_isLoadingHotspots) {
      return const Processing(text: "Finding popular places...");
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return TabBarView(
      controller: _tabController,
      physics:
          const NeverScrollableScrollPhysics(), // Désactive le swipe entre tabs pour éviter les conflits
      children: [_buildMapView(), _buildListView()],
    );
  }

  /// Construire la vue carte
  Widget _buildMapView() {
    return Container(
      child: HotspotsMapWidget(
        hotspots: _hotspots,
        onHotspotTap: _onHotspotTap,
        onRefresh: _refreshHotspots,
      ),
    );
  }

  /// Construire la vue liste
  Widget _buildListView() {
    return HotspotsListWidget(
      hotspots: _hotspots,
      onHotspotTap: _onHotspotTap,
      onGetDirections: _onGetDirections,
      onRefresh: _refreshHotspots,
    );
  }

  /// Construire l'état d'erreur
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
              onPressed: _refreshHotspots,
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
