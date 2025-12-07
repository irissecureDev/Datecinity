import 'dart:async';
import 'dart:io';

import 'package:cheers/api/dislikes_api.dart';
import 'package:cheers/api/likes_api.dart';
import 'package:cheers/api/users_api.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cheers/api/conversations_api.dart';
import 'package:cheers/api/notifications_api.dart';
import 'package:cheers/helpers/app_helper.dart';
import 'package:cheers/helpers/app_localizations.dart';
import 'package:cheers/helpers/app_notifications.dart';
import 'package:cheers/models/user_model.dart';
import 'package:cheers/services/suggestions_service.dart';
import 'package:cheers/services/suggestions_notifications_service.dart';
import 'package:cheers/models/proximity_profile.dart';
import 'package:cheers/screens/notifications_screen.dart';
import 'package:cheers/tabs/conversations_tab.dart';
import 'package:cheers/tabs/discover_tab.dart';
import 'package:cheers/tabs/matches_tab.dart';
import 'package:cheers/tabs/profile_tab.dart';
import 'package:cheers/widgets/notification_counter.dart';
import 'package:cheers/widgets/svg_icon.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cheers/constants/constants.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  /// Variables
  final _conversationsApi = ConversationsApi();
  final _notificationsApi = NotificationsApi();
  final _appNotifications = AppNotifications();
  final _suggestionsService = SuggestionsService();
  final _suggestionsNotificationsService = SuggestionsNotificationsService();
  int _selectedIndex = 0;
  late AppLocalizations _i18n;
  late Stream<DocumentSnapshot<Map<String, dynamic>>> _userStream;
  // in_app_purchase stream
  late StreamSubscription<List<PurchaseDetails>> _inAppPurchaseStream;
  final AppHelper _appHelper = AppHelper();

  StreamSubscription<Position>? _positionStream;
  Timer? _proximityCheckTimer;

  /// Tab navigation
  Widget _showCurrentNavBar() {
    List<Widget> options = <Widget>[
      const MatchesTab(), // Index 0: Discover affiche le contenu Matches (cartes swipe)
      const DiscoverTab(), // Index 1: Matches affiche le contenu Discover (carte utilisateurs)
      const ConversationsTab(), // Index 2: Conversations
      const ProfileTab(), // Index 3: Profile
    ];

    return options.elementAt(_selectedIndex);
  }

  /// Update selected tab
  void _onTappedNavBar(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// Get current User Real Time updates
  void _getCurrentUserUpdates() {
    /// Get user stream
    _userStream = UserModel().getUserStream();

    /// Subscribe to user updates
    _userStream.listen((userEvent) {
      // Update user
      UserModel().updateUserObject(userEvent.data()!);
    });
  }

  ///
  /// Handle in-app purchases upates
  ///
  void _handlePurchaseUpdates() {
    // Listen purchase updates
    _inAppPurchaseStream = InAppPurchase.instance.purchaseStream.listen((
      purchases,
    ) async {
      // Loop incoming purchases
      for (var purchase in purchases) {
        // Control purchase status
        switch (purchase.status) {
          case PurchaseStatus.pending:
            // Handle this case.
            break;
          case PurchaseStatus.purchased:

            /// **** Deliver product to user **** ///
            ///
            /// Update User VIP Status to true
            UserModel().setUserVip();
            // Set Vip Subscription Id
            UserModel().setActiveVipId(purchase.productID);

            /// Update user verified status
            await UserModel().updateUserData(
              userId: UserModel().user.userId,
              data: {USER_IS_VERIFIED: true},
            );

            // User first name
            final String userFirstname = UserModel().user.userFullname.split(
              ' ',
            )[0];

            /// Save notification in database for user
            _notificationsApi.onPurchaseNotification(
              nMessage:
                  '${_i18n.translate("hello")} $userFirstname, '
                  '${_i18n.translate("your_vip_account_is_active")}\n '
                  '${_i18n.translate("thanks_for_buying")}',
            );

            if (purchase.pendingCompletePurchase) {
              /// Complete pending purchase
              InAppPurchase.instance.completePurchase(purchase);
              debugPrint('Success pending purchase completed!');
            }
            break;
          case PurchaseStatus.error:
            // Handle this case.
            debugPrint('purchase error-> ${purchase.error?.message}');
            break;
          case PurchaseStatus.restored:

            ///
            /// <--- Restore VIP Subscription --->
            ///
            UserModel().setUserVip();
            // Set Vip Subscription Id
            UserModel().setActiveVipId(purchase.productID);
            // Debug
            debugPrint('Active VIP SKU: ${purchase.productID}');
            // Check
            if (UserModel().showRestoreVipMsg) {
              // Show toast message
              Fluttertoast.showToast(
                msg: _i18n.translate('VIP_subscription_successfully_restored'),
                gravity: ToastGravity.BOTTOM,
                backgroundColor: APP_PRIMARY_COLOR,
                textColor: Colors.white,
              );
            }
            break;
          case PurchaseStatus.canceled:
            // Show canceled feedback
            Fluttertoast.showToast(
              msg: _i18n.translate(
                'you_canceled_the_purchase_please_try_again',
              ),
              gravity: ToastGravity.BOTTOM,
              backgroundColor: APP_PRIMARY_COLOR,
              textColor: Colors.white,
            );
            break;
        }
      }
    });
  }

  Future<void> _handleNotificationClick(Map<String, dynamic>? data) async {
    /// Handle notification click
    await _appNotifications.onNotificationClick(
      context,
      nType: data?[N_TYPE] ?? '',
      nSenderId: data?[N_SENDER_ID] ?? '',
      nMessage: data?[N_MESSAGE] ?? '',
    );
  }

  /// Request push notifications permission.
  static Future<void> _requestNotificationsPermission() async {
    // Request permission for iOS devices
    if (Platform.isIOS) {
      final settings = await FirebaseMessaging.instance.requestPermission();
      final AuthorizationStatus status = settings.authorizationStatus;
      // Debug
      debugPrint('requestNotificationsPermission() for iOS -> $status');
    } else {
      // <-- Android permissions -->
      final PermissionStatus status = await Permission.notification.request();
      if (status.isPermanentlyDenied) {
        // Permission permanently denied, you can open the app settings to allow permissions
        await openAppSettings();
      }
      // Debug
      debugPrint('requestNotificationsPermission() for Android -> $status');
    }
  }

  ///
  /// Handle incoming notifications while the app is in the Foreground
  ///
  Future<void> _initFirebaseMessage() async {
    /// Request permission for IOS
    await _requestNotificationsPermission();

    // Get inicial message if the application
    // has been opened from a terminated state.
    final message = await FirebaseMessaging.instance.getInitialMessage();
    // Check notification data
    if (message != null) {
      // Debug
      debugPrint('getInitialMessage() -> data: ${message.data}');
      // Handle notification data
      await _handleNotificationClick(message.data);
    }

    // Returns a [Stream] that is called when a user
    // presses a notification message displayed via FCM.
    // Note: A Stream event will be sent if the app has
    // opened from a background state (not terminated).
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      // Debug
      debugPrint('onMessageOpenedApp() -> data: ${message.data}');
      // Handle notification data
      await _handleNotificationClick(message.data);
    });

    // Listen for incoming push notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage? message) async {
      // Debug
      debugPrint('onMessage() -> data: ${message?.data}');
      // Handle notification data
      await _handleNotificationClick(message?.data);
    });
  }

  @override
  void initState() {
    super.initState();

    /// Restore VIP Subscription
    _appHelper.restoreVipAccount();

    /// Init streams
    _getCurrentUserUpdates();
    _handlePurchaseUpdates();
    _initFirebaseMessage();
    _initLocationListener();
  }

  @override
  void dispose() {
    super.dispose();
    // Close streams
    _userStream.drain();
    _inAppPurchaseStream.cancel();
    _positionStream?.cancel();
    _proximityCheckTimer?.cancel();
  }

  Future<void> _initLocationListener() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Fluttertoast.showToast(
        msg: "Location services are disabled.",
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }

    // Check permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Fluttertoast.showToast(msg: "Location permission denied.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Fluttertoast.showToast(
        msg:
            "Location permission permanently denied. Please enable it from settings.",
      );
      return;
    }

    // Get initial position
    var currentPosition = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(accuracy: LocationAccuracy.best),
    );

    _appHelper.updateUserLocation(
      userId: UserModel().getFirebaseUser!.uid, // widget.userId
      latitude: currentPosition.latitude,
      longitude: currentPosition.longitude,
    );

    // Listen to continuous location updates
    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
            distanceFilter: 10, // meters
          ),
        ).listen((Position position) async {
          // Mettre à jour la position de l'utilisateur
          await _appHelper.updateUserLocation(
            userId: UserModel().getFirebaseUser!.uid,
            latitude: position.latitude,
            longitude: position.longitude,
          );

          // Détecter les nouveaux profils de proximité
          await _detectProximityProfiles();

          // Logique existante pour les matches automatiques (optionnel)
          await _handleAutomaticMatching();
        });

    // Timer pour nettoyer le cache et vérifier les expirations toutes les minutes
    _proximityCheckTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      _suggestionsService.cleanProximityCache();
      debugPrint('🧹 Cache de proximité nettoyé automatiquement');
    });
  }

  @override
  Widget build(BuildContext context) {
    /// Initialization
    _i18n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
              ],
            ),
          ),
        ),
        title: Row(
          children: [
            Image.asset("assets/images/app_logo.png", width: 40, height: 40),
            const SizedBox(width: 5),
            const Text(
              APP_NAME,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: _getNotificationCounter(),
            onPressed: () async {
              // Go to Notifications Screen
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => NotificationsScreen()),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        elevation: Platform.isIOS ? 0 : 8,
        currentIndex: _selectedIndex,
        onTap: _onTappedNavBar,
        items: [
          /// Discover Tab (index 0 - affiche le contenu Matches: cartes swipe)
          BottomNavigationBarItem(
            icon: SvgIcon(
              "assets/icons/discover_icon.svg",
              width: 27,
              height: 27,
              color: _selectedIndex == 0
                  ? Theme.of(context).primaryColor
                  : null,
            ),
            label: _i18n.translate("discover"),
          ),

          /// Matches Tab (index 1 - affiche le contenu Discover: carte utilisateurs)
          BottomNavigationBarItem(
            icon: SvgIcon(
              _selectedIndex == 1
                  ? "assets/icons/heart_2_icon.svg"
                  : "assets/icons/heart_icon.svg",
              color: _selectedIndex == 1
                  ? Theme.of(context).primaryColor
                  : null,
            ),
            label: _i18n.translate("matches"),
          ),

          /// Conversations Tab
          BottomNavigationBarItem(
            icon: _getConversationCounter(),
            label: _i18n.translate("chats"),
          ),

          /// Profile Tab
          BottomNavigationBarItem(
            icon: SvgIcon(
              _selectedIndex == 3
                  ? "assets/icons/user_2_icon.svg"
                  : "assets/icons/user_icon.svg",
              color: _selectedIndex == 3
                  ? Theme.of(context).primaryColor
                  : null,
            ),
            label: _i18n.translate("profile"),
          ),
        ],
      ),
      body: _showCurrentNavBar(),
    );
  }

  /// Count unread notifications
  Widget _getNotificationCounter() {
    // Set icon
    const icon = SvgIcon(
      "assets/icons/bell_icon.svg",
      width: 33,
      height: 33,
      color: Colors.white,
    );

    /// Handle stream
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _notificationsApi.getNotifications(),
      builder: (context, snapshot) {
        // Check result
        if (!snapshot.hasData) {
          return icon;
        } else {
          /// Get total counter to alert user
          final total = snapshot.data!.docs
              .where((doc) => doc.data()[N_READ] == false)
              .toList()
              .length;
          if (total == 0) return icon;
          return NotificationCounter(icon: icon, counter: total);
        }
      },
    );
  }

  /// Count unread chats
  Widget _getConversationCounter() {
    // Set icon
    final icon = SvgIcon(
      _selectedIndex == 2
          ? "assets/icons/message_2_icon.svg"
          : "assets/icons/message_icon.svg",
      width: 30,
      height: 30,
      color: _selectedIndex == 2 ? Theme.of(context).primaryColor : null,
    );

    /// Handle stream
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _conversationsApi.getConversations(),
      builder: (context, snapshot) {
        // Check result
        if (!snapshot.hasData) {
          return icon;
        } else {
          /// Get total counter to alert user
          final total = snapshot.data!.docs
              .where((doc) => doc.data()[MESSAGE_READ] == false)
              .toList()
              .length;
          if (total == 0) return icon;
          return NotificationCounter(icon: icon, counter: total);
        }
      },
    );
  }

  /// Détecter les nouveaux profils de proximité et envoyer des notifications
  Future<void> _detectProximityProfiles() async {
    try {
      debugPrint('🔍 Détection profils de proximité...');

      // Détecter les nouveaux profils dans un rayon de 100m avec 50% de compatibilité minimum
      final newProfiles = await _suggestionsService.detectNewProximityProfiles(
        maxDistanceKm: 0.1, // 100 mètres
        minCompatibility: 0.5, // 50% de compatibilité
      );

      if (newProfiles.isNotEmpty) {
        debugPrint(
          '✨ ${newProfiles.length} nouveaux profils détectés à proximité',
        );

        // Filtrer les profils nécessitant une notification (très compatibles)
        final notificationProfiles = newProfiles
            .where((profile) => profile.compatibility >= 0.7) // 70% minimum
            .toList();

        if (notificationProfiles.isNotEmpty) {
          debugPrint(
            '🔔 Envoi de notifications pour ${notificationProfiles.length} profils hautement compatibles',
          );

          // Déclencher les notifications via le service
          await _suggestionsNotificationsService.checkAndNotifyNearbyMatches(
            UserModel().user.userId,
          );

          // Afficher une notification locale
          _showLocalProximityNotification(notificationProfiles);
        }
      }
    } catch (e) {
      debugPrint('❌ Erreur détection proximité: $e');
    }
  }

  /// Afficher une notification locale pour les profils de proximité
  void _showLocalProximityNotification(List<ProximityProfile> profiles) {
    if (profiles.isEmpty) return;

    String message;
    if (profiles.length == 1) {
      final profile = profiles.first;
      final distanceM = (profile.distance * 1000).round();
      message =
          '📍 ${profile.user.userFullname} est à ${distanceM}m de vous ! (${(profile.compatibility * 100).round()}% compatible)';
    } else {
      message =
          '📍 ${profiles.length} personnes hautement compatibles sont près de vous !';
    }

    // Afficher un toast
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: Theme.of(context).primaryColor,
      textColor: Colors.white,
      fontSize: 14.0,
    );

    // Afficher aussi un SnackBar si possible
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.location_on, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(message, style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).primaryColor,
          duration: Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Voir',
            textColor: Colors.white,
            onPressed: () {
              // Aller à l'onglet Discover
              setState(() {
                _selectedIndex = 1; // Index pour Discover
              });
            },
          ),
        ),
      );
    }
  }

  /// Gérer les matches automatiques (logique existante optionnelle)
  Future<void> _handleAutomaticMatching() async {
    try {
      /// First: Load All Disliked Users to be filtered
      final dislikedUsers = await DislikesApi().getDislikedUsers(
        withLimit: false,
      );

      /// Validate user max distance
      await UserModel().checkUserMaxDistance();

      /// Load all users
      final users = await UsersApi().getUsers(dislikedUsers: dislikedUsers);

      for (var user in users) {
        // Get the matching percentage from user data with safe access
        final userData = user.data();
        final double matchPercent = (userData?[USER_MATCH_PERCENT] ?? 0)
            .toDouble();

        if (matchPercent >= 70) {
          LikesApi().likeUser(
            likedUserId: user[USER_ID],
            userDeviceToken: user[USER_DEVICE_TOKEN],
            nMessage:
                "You have a ${matchPercent.toInt()}% match with ${UserModel().user.userFullname.split(' ')[0]}",
            onLikeResult: (result) {
              debugPrint('likeResult: $result');
            },
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Erreur automatic matching: $e');
    }
  }
}
