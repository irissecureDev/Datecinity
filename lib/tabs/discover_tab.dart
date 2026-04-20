import 'dart:async';
import 'package:cheers/helpers/app_localizations.dart';
import 'package:cheers/models/proximity_profile.dart';
import 'package:cheers/screens/profile_screen.dart';
import 'package:cheers/services/suggestions_service.dart';
import 'package:cheers/widgets/discovery_flow_widget.dart';
import 'package:cheers/widgets/no_data.dart';
import 'package:cheers/widgets/processing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DiscoverTab extends StatefulWidget {
  const DiscoverTab({super.key});

  @override
  DiscoverTabState createState() => DiscoverTabState();
}

class DiscoverTabState extends State<DiscoverTab>
    with TickerProviderStateMixin {
  static const double _sparkMaxDistanceKm = 0.5;
  static const double _sparkMinCompatibility = 0.6;
  static const double _sparkHighCompatibility = 0.75;

  final SuggestionsService _suggestionsService = SuggestionsService();

  late AppLocalizations _i18n;
  late TabController _tabController;
  late PageController _sparksPageController;
  Timer? _refreshTimer;

  List<ProximityProfile> _sparkProfiles = [];
  bool _isLoadingSparks = false;
  double _currentSparkPage = 0;
  bool _didCenterInitialSparkPage = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _sparksPageController = PageController(viewportFraction: 0.72)
      ..addListener(() {
        if (!_sparksPageController.hasClients) return;
        final page = _sparksPageController.page;
        if (page == null) return;
        if ((page - _currentSparkPage).abs() < 0.001) return;
        setState(() {
          _currentSparkPage = page;
        });
      });
    _loadSparkProfiles(detectNearby: true);

    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadSparkProfiles(detectNearby: true);
    });
  }

  @override
  void dispose() {
    _sparksPageController.dispose();
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSparkProfiles({required bool detectNearby}) async {
    if (_isLoadingSparks) return;

    setState(() {
      _isLoadingSparks = true;
    });

    try {
      _suggestionsService.cleanProximityCache();

      if (detectNearby) {
        await _suggestionsService.detectNewProximityProfiles(
          maxDistanceKm: _sparkMaxDistanceKm,
          minCompatibility: _sparkMinCompatibility,
        );
      }

      final profiles = _suggestionsService
          .getActiveProximityProfiles()
          .where(
            (profile) =>
                !profile.isExpired &&
                profile.distance <= _sparkMaxDistanceKm &&
                profile.compatibility >= _sparkHighCompatibility,
          )
          .toList();

      profiles.sort((a, b) {
        final comp = b.compatibility.compareTo(a.compatibility);
        if (comp != 0) return comp;
        return a.distance.compareTo(b.distance);
      });

      if (mounted) {
        setState(() {
          _sparkProfiles = profiles;
          _isLoadingSparks = false;
          _didCenterInitialSparkPage = false;
        });

        _centerInitialSparkCardIfNeeded();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _sparkProfiles = [];
          _isLoadingSparks = false;
        });
      }
      debugPrint('❌ Sparks load error: $e');
    }
  }

  void _centerInitialSparkCardIfNeeded() {
    if (_didCenterInitialSparkPage || _sparkProfiles.length < 3) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_sparksPageController.hasClients) return;
      if (_didCenterInitialSparkPage) return;

      _sparksPageController.jumpToPage(1);
      setState(() {
        _currentSparkPage = 1;
        _didCenterInitialSparkPage = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    _i18n = AppLocalizations.of(context);
    return Column(
      children: [
        // Barre d'onglets
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          height: 54,
          decoration: BoxDecoration(
            color: const Color(0xFFECE1FF),
            borderRadius: BorderRadius.circular(27),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6E43B7).withOpacity(0.15),
                blurRadius: 16,
                offset: const Offset(0, 3),
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
                    const Icon(Icons.local_fire_department, size: 20),
                    const SizedBox(width: 8),
                    Text("Sparks"),
                  ],
                ),
              ),
            ],
            onTap: (index) {
              HapticFeedback.lightImpact();
              if (index == 1) {
                _loadSparkProfiles(detectNearby: true);
              }
            },
          ),
        ),

        // Contenu selon l'onglet sélectionné
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_buildDiscoverView(), _buildSparksView()],
          ),
        ),
      ],
    );
  }

  /// Discover tab - New Discovery flow with animations
  Widget _buildDiscoverView() {
    return const DiscoveryFlowWidget();
  }

  /// Sparks tab - TODO: implement new functionality
  Widget _buildSparksView() {
    if (_isLoadingSparks && _sparkProfiles.isEmpty) {
      return const Processing(text: 'Searching nearby profiles...');
    }

    if (_sparkProfiles.isEmpty) {
      return const NoData(
        svgName: 'search_icon',
        text:
            'No high-compatibility profile nearby for now. Move around and try again.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadSparkProfiles(detectNearby: true),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardHeight = constraints.maxHeight * 0.8;
          final cardWidth = constraints.maxWidth * 0.66;

          if (_sparkProfiles.length == 1) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 16),
                Center(
                  child: SizedBox(
                    width: cardWidth,
                    height: cardHeight,
                    child: _buildSparkProfileCard(_sparkProfiles.first),
                  ),
                ),
              ],
            );
          }

          _centerInitialSparkCardIfNeeded();

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 16),
              SizedBox(
                height: cardHeight,
                child: ClipRect(
                  child: PageView.builder(
                    controller: _sparksPageController,
                    itemCount: _sparkProfiles.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final delta = index - _currentSparkPage;
                      final distance = delta.abs().clamp(0.0, 1.0);

                      final scale = 1 - (distance * 0.1);
                      final verticalOffset = distance * 10;
                      final rotation = delta.clamp(-1.0, 1.0) * 0.06;

                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..translate(0.0, verticalOffset)
                          ..scale(scale)
                          ..rotateZ(rotation),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: _buildSparkProfileCard(_sparkProfiles[index]),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSparkProfileCard(ProximityProfile profile) {
    final user = profile.user;
    final fullName = user.userFullname.trim();
    final firstName = fullName.isEmpty ? 'Private' : fullName.split(' ').first;
    final age = (DateTime.now().year - user.userBirthYear).clamp(18, 99);
    final compatibilityPercent = (profile.compatibility * 100).round();

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProfileScreen(
              user: user,
              showButtons: true,
              respectVisibilitySettings: true,
              isPreviewMode: true,
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            user.userProfilePhoto.isNotEmpty
                ? Image.network(
                    user.userProfilePhoto,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildImageFallback(),
                  )
                : _buildImageFallback(),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF2D1B4E).withOpacity(0.88),
                  ],
                  stops: const [0.45, 1.0],
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$firstName, $age',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        size: 16,
                        color: Color(0xFFFFD54F),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$compatibilityPercent% Compatibility',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageFallback() {
    return Container(
      color: const Color(0xFFE6E1ED),
      child: const Center(
        child: Icon(Icons.person, size: 44, color: Color(0xFF9E9E9E)),
      ),
    );
  }
}
