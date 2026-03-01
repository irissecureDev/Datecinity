import 'dart:async';
import 'package:cheers/api/notifications_api.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cheers/datas/user.dart' as app_data;
import 'package:cheers/helpers/app_localizations.dart';
import 'package:cheers/models/proximity_profile.dart';
import 'package:cheers/models/user_model.dart';
import 'package:cheers/screens/profile_screen.dart';
import 'package:cheers/services/foreground_push_service.dart';
import 'package:cheers/services/suggestions_service.dart';
import 'package:cheers/widgets/discovery_flow_widget.dart';
import 'package:cheers/widgets/no_data.dart';
import 'package:cheers/widgets/processing.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
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
  static const bool _enableFakeSparksForTesting = true;

  final SuggestionsService _suggestionsService = SuggestionsService();

  late AppLocalizations _i18n;
  late TabController _tabController;
  late PageController _sparksPageController;
  Timer? _refreshTimer;

  List<ProximityProfile> _sparkProfiles = [];
  bool _isLoadingSparks = false;
  double _currentSparkPage = 0;
  bool _didCenterInitialSparkPage = false;
  bool _didSimulateNearbyPush = false;
  final NotificationsApi _notificationsApi = NotificationsApi();

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

      final resolvedProfiles =
          (kDebugMode && _enableFakeSparksForTesting && profiles.length < 5)
          ? _buildFakeSparkProfiles()
          : profiles;

      final usingFakeProfiles =
          kDebugMode && _enableFakeSparksForTesting && profiles.length < 5;

      if (mounted) {
        setState(() {
          _sparkProfiles = resolvedProfiles;
          _isLoadingSparks = false;
          _didCenterInitialSparkPage = false;
        });

        _centerInitialSparkCardIfNeeded();

        if (usingFakeProfiles &&
            defaultTargetPlatform == TargetPlatform.iOS &&
            !_didSimulateNearbyPush &&
            resolvedProfiles.isNotEmpty) {
          _didSimulateNearbyPush = true;
          final fake = resolvedProfiles.first;
          await ForegroundPushService.instance.showFakeNearbyMatchNotification(
            fullName: fake.user.userFullname,
            compatibility: fake.compatibility,
            distanceKm: fake.distance,
          );
        }
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

  List<ProximityProfile> _buildFakeSparkProfiles() {
    final now = DateTime.now();

    app_data.User fakeUser({
      required String id,
      required String fullName,
      required int year,
      required String photo,
      required String gender,
      required String city,
    }) {
      return app_data.User(
        userId: id,
        userProfilePhoto: photo,
        userFullname: fullName,
        userGender: gender,
        userBirthDay: 12,
        userBirthMonth: 6,
        userBirthYear: year,
        userBio: 'Profil de test pour le carousel Sparks',
        userPhoneNumber: '',
        userEmail: '$id@test.cheers',
        userGallery: const {},
        userCountry: 'France',
        userLocality: city,
        userGeoPoint: const GeoPoint(48.8566, 2.3522),
        userSettings: const {},
        userStatus: 'active',
        userLevel: 'user',
        userIsVerified: true,
        userRegDate: now,
        userLastLogin: now,
        userDeviceToken: '',
        userTotalLikes: 0,
        userTotalVisits: 0,
        userTotalDisliked: 0,
        education: 'Bachelor',
        religion: '',
        hobbies: const ['music', 'travel'],
        languages: const ['fr', 'en'],
        pets: const [],
        preferences: const {},
      );
    }

    return [
      ProximityProfile(
        user: fakeUser(
          id: 'fake_spark_1',
          fullName: 'Justin Martin',
          year: 1994,
          photo: 'https://i.pravatar.cc/900?img=12',
          gender: 'Male',
          city: 'Paris',
        ),
        detectedAt: now.subtract(const Duration(minutes: 1)),
        distance: 0.12,
        compatibility: 0.91,
      ),
      ProximityProfile(
        user: fakeUser(
          id: 'fake_spark_2',
          fullName: 'Emma Laurent',
          year: 1997,
          photo: 'https://i.pravatar.cc/900?img=47',
          gender: 'Female',
          city: 'Lyon',
        ),
        detectedAt: now.subtract(const Duration(minutes: 2)),
        distance: 0.18,
        compatibility: 0.88,
      ),
      ProximityProfile(
        user: fakeUser(
          id: 'fake_spark_3',
          fullName: 'Sara Diallo',
          year: 1998,
          photo: 'https://i.pravatar.cc/900?img=32',
          gender: 'Female',
          city: 'Marseille',
        ),
        detectedAt: now.subtract(const Duration(minutes: 3)),
        distance: 0.25,
        compatibility: 0.86,
      ),
      ProximityProfile(
        user: fakeUser(
          id: 'fake_spark_4',
          fullName: 'Nora Benali',
          year: 1996,
          photo: 'https://i.pravatar.cc/900?img=5',
          gender: 'Female',
          city: 'Bordeaux',
        ),
        detectedAt: now.subtract(const Duration(minutes: 4)),
        distance: 0.31,
        compatibility: 0.84,
      ),
      ProximityProfile(
        user: fakeUser(
          id: 'fake_spark_5',
          fullName: 'Lucas Petit',
          year: 1993,
          photo: 'https://i.pravatar.cc/900?img=14',
          gender: 'Male',
          city: 'Nantes',
        ),
        detectedAt: now.subtract(const Duration(minutes: 5)),
        distance: 0.39,
        compatibility: 0.82,
      ),
    ];
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

  Future<void> _triggerFakeNearbyPush() async {
    final profile = _sparkProfiles.isNotEmpty
        ? _sparkProfiles.first
        : _buildFakeSparkProfiles().first;

    await ForegroundPushService.instance.showFakeNearbyMatchNotification(
      fullName: profile.user.userFullname,
      compatibility: profile.compatibility,
      distanceKm: profile.distance,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification test envoyée.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _triggerSelfFcmPush() async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      for (int i = 0; i < 5; i++) {
        final apns = await messaging.getAPNSToken();
        if (apns != null && apns.isNotEmpty) {
          break;
        }
        await Future.delayed(const Duration(milliseconds: 500));
      }

      final token = await messaging.getToken();

      if (token == null || token.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Token FCM indisponible. Active les notifications iOS et relance l\'app.',
            ),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      await _notificationsApi.sendPushNotification(
        nTitle: '🧪 Test push FCM',
        nBody: 'Push réelle envoyée sur ce device iOS.',
        nType: 'nearby_match',
        nSenderId: UserModel().user.userId,
        nUserDeviceToken: token,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Push FCM envoyée. Vérifie la bannière iOS.'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur test push FCM: $e'),
          duration: const Duration(seconds: 4),
        ),
      );
    }
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

        if (kDebugMode && defaultTargetPlatform == TargetPlatform.iOS)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 6,
              children: [
                TextButton.icon(
                  onPressed: _triggerFakeNearbyPush,
                  icon: const Icon(
                    Icons.notifications_active_outlined,
                    size: 18,
                  ),
                  label: const Text('Tester notification proximité'),
                ),
                TextButton.icon(
                  onPressed: _triggerSelfFcmPush,
                  icon: const Icon(Icons.send_outlined, size: 18),
                  label: const Text('Tester push FCM (réelle)'),
                ),
              ],
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
