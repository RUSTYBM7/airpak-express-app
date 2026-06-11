import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../config/env.dart';

/// Top-level handler used as the entry point for background messages.
/// Must be a top-level function (not a closure) and annotated with
/// `@pragma('vm:entry-point')` so AOT compilation keeps it.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase may not be configured (no google-services.json) — the
    // local notifications plugin still takes over for foreground UX.
  }
  await PushNotificationService.instance
      .handleBackgroundMessage(message);
}

/// FCM + local notifications façade.
///
/// In a real deployment the iOS / Android app would carry a
/// `GoogleService-Info.plist` and `google-services.json`; without them
/// [init] is a safe no-op and the rest of the app continues to work.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  final _messageStreamCtrl = StreamController<RemoteMessage>.broadcast();
  FirebaseMessaging? _messaging;
  String? _token;
  bool _initialised = false;

  String? get token => _token;
  Stream<RemoteMessage> get onMessage => _messageStreamCtrl.stream;

  /// Call from `main()` before `runApp()`. Idempotent.
  Future<void> init() async {
    if (_initialised) return;
    _initialised = true;

    // Local notifications — always available, used as the foreground UX
    // even when FCM itself isn't configured.
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _local.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (resp) {
        // Tap-on-notification handler can navigate to a shipment here.
      },
    );

    if (!AppEnv.enablePush) return;

    // Firebase is optional — initialising without google-services.json
    // throws and we want to keep the app running.
    try {
      await Firebase.initializeApp();
      _messaging = FirebaseMessaging.instance;
      FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

      await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.onMessage.listen((m) {
        _showLocal(m);
        _messageStreamCtrl.add(m);
      });
      FirebaseMessaging.onMessageOpenedApp.listen(_messageStreamCtrl.add);

      _token = await _messaging!.getToken(vapidKey: AppEnv.fcmVapidKey);
      _messaging!.onTokenRefresh.listen((t) {
        _token = t;
        // In production, POST `t` to your backend to register the
        // device against the user account.
      });
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('FCM init skipped: $e');
      }
    }
  }

  /// Foreground / background message handler — renders a local
  /// notification with the title and body.
  Future<void> handleBackgroundMessage(RemoteMessage message) async {
    await _showLocal(message);
  }

  /// Used by the support / shipment-update code paths to push a
  /// notification even when FCM isn't fully configured.
  Future<void> showLocal({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'shipnow_default',
      'ShipNow updates',
      channelDescription: 'Shipment updates, support replies, and promos',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();
    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  Future<void> _showLocal(RemoteMessage m) async {
    final notif = m.notification;
    if (notif == null) return;
    await showLocal(
      title: notif.title ?? m.data['title']?.toString() ?? 'ShipNow',
      body: notif.body ?? m.data['body']?.toString() ?? '',
      payload: m.data['tracking']?.toString(),
    );
  }

  /// Subscribe the device to a shipment-tracking topic so that
  /// server-sent updates arrive as push notifications.
  Future<void> subscribeToShipment(String trackingNumber) async {
    final m = _messaging;
    if (m == null) return;
    final topic = 'shipment_${trackingNumber.toLowerCase()}';
    try {
      await m.subscribeToTopic(topic);
    } catch (_) {
      // ignore — topic subs require server-side admin SDK in prod.
    }
  }

  Future<void> unsubscribeFromShipment(String trackingNumber) async {
    final m = _messaging;
    if (m == null) return;
    try {
      await m.unsubscribeFromTopic(
          'shipment_${trackingNumber.toLowerCase()}');
    } catch (_) {}
  }
}
