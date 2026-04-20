import 'package:cheers/screens/home_screen.dart';
import 'package:cheers/services/foreground_push_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PushNavigationService {
  PushNavigationService._();

  static final PushNavigationService instance = PushNavigationService._();

  GlobalKey<NavigatorState>? _navigatorKey;
  bool _initialized = false;

  bool _isDiscoverSparkType(String nType) {
    const supportedTypes = <String>{
      'nearby_match',
      'spark',
      'spark_like',
      'spark_match',
      'spark_declined',
      'high_compatibility',
      'new_matches',
    };

    return supportedTypes.contains(nType);
  }

  Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    if (_initialized) {
      _navigatorKey = navigatorKey;
      return;
    }

    _navigatorKey = navigatorKey;

    await ForegroundPushService.instance.initialize(
      onNotificationTap: _handleLocalNotificationTap,
    );

    FirebaseMessaging.onMessage.listen((message) {
      ForegroundPushService.instance.showForegroundMatchNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteMessageTap);

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleRemoteMessageTap(initialMessage);
    }

    _initialized = true;
  }

  void _handleRemoteMessageTap(RemoteMessage message) {
    final nType = (message.data['n_type'] ?? message.data['type'] ?? '')
        .toString();

    if (!_isDiscoverSparkType(nType)) {
      return;
    }

    openDiscoverSparkEntry();
  }

  void _handleLocalNotificationTap(String nType) {
    if (!_isDiscoverSparkType(nType)) {
      return;
    }

    openDiscoverSparkEntry();
  }

  void openDiscoverSparkEntry() {
    final navigator = _navigatorKey?.currentState;
    if (navigator == null) {
      debugPrint('⚠️ Navigator not ready for push deep-link');
      return;
    }

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen(initialTabIndex: 1)),
      (route) => false,
    );
  }
}
