import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class ForegroundPushService {
  ForegroundPushService._();

  static final ForegroundPushService instance = ForegroundPushService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
        'cheers_matches_nearby',
        'Matches & Nearby',
        description: 'Foreground notifications for nearby high-match users',
        importance: Importance.max,
      );

  bool _initialized = false;
  void Function(String nType)? _onNotificationTap;

  Future<void> _showNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    if (title.isEmpty && body.isEmpty) {
      return;
    }

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'cheers',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  Future<void> initialize({
    void Function(String nType)? onNotificationTap,
  }) async {
    _onNotificationTap = onNotificationTap;

    if (_initialized || kIsWeb) return;

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/launcher_icon'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        defaultPresentAlert: true,
        defaultPresentBadge: true,
        defaultPresentSound: true,
      ),
    );

    await _plugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) {
          return;
        }
        _onNotificationTap?.call(payload);
      },
    );

    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_androidChannel);
    } else if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    _initialized = true;
  }

  Future<void> showForegroundMatchNotification(RemoteMessage message) async {
    if (kIsWeb) return;
    if (!_initialized) {
      await initialize();
    }

    final nType = (message.data['n_type'] ?? message.data['type'] ?? '')
        .toString();

    final isNearbyOrSpark =
        nType == 'nearby_match' ||
        nType == 'spark' ||
        nType == 'spark_like' ||
        nType == 'spark_match' ||
        nType == 'spark_declined';

    if (!isNearbyOrSpark) {
      return;
    }

    final title =
        message.notification?.title ??
        (message.data['title'] ?? '✨ Match nearby').toString();

    final body =
        message.notification?.body ??
        (message.data['n_message'] ??
                message.data['body'] ??
                'A compatible person is nearby.')
            .toString();

    await _showNotification(title: title, body: body, payload: nType);
  }
}
