import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vego/core/notifications/notification_store.dart';
import 'package:vego/core/storage/token_storage.dart';
import 'package:vego/data/api/api_service.dart';

/// Background/terminated FCM handler. Must be a top-level (or static) function
/// annotated with @pragma('vm:entry-point'). Notification-type messages are
/// rendered by the OS tray automatically; this hook is for any future
/// data-only handling.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Intentionally minimal.
}

/// Thin wrapper around FCM + local notifications for the daily reminder feature.
///
/// Lifecycle:
///   - [init] once at startup (channels, permission, foreground display, token-refresh).
///   - [registerToken] after login / on startup when already logged in.
///   - [removeToken] on logout.
class PushService {
  PushService._();

  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  // Must match the channel id in AndroidManifest's default_notification_channel_id.
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'daily_reminders',
    'Daily Reminders',
    description: "Tomorrow's trips and document expiry reminders",
    importance: Importance.high,
  );

  static ApiService? _api;
  static bool _initialized = false;

  /// Set up channels, permissions, foreground display and token-refresh.
  /// Safe to call multiple times — only the first call does the work.
  static Future<void> init(ApiService api) async {
    _api = api;
    // FCM web requires VAPID keys + a service worker we don't ship. Skip it so
    // the app doesn't crash on `[core/no-app]` when Firebase isn't configured.
    if (kIsWeb) return;
    if (_initialized) return;
    _initialized = true;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _local.initialize(settings: initSettings);

    final androidImpl = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(_channel);

    // Permissions: iOS prompt + Android 13+ runtime permission.
    await FirebaseMessaging.instance.requestPermission();
    await androidImpl?.requestNotificationsPermission();

    // Foreground messages don't auto-display — show them via local notifications.
    FirebaseMessaging.onMessage.listen((message) {
      final n = message.notification;
      if (n == null) return;
      _record(message);
      _local.show(
        id: n.hashCode,
        title: n.title,
        body: n.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    });

    // User tapped a tray notification that opened/resumed the app.
    FirebaseMessaging.onMessageOpenedApp.listen(_record);

    // App launched from a terminated state by tapping a notification.
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _record(initial);

    // Re-register when FCM rotates the token.
    FirebaseMessaging.instance.onTokenRefresh.listen(_sendRegister);
  }

  /// Add an incoming message to the in-app notifications history.
  static void _record(RemoteMessage message) {
    final n = message.notification;
    final title = n?.title ?? message.data['title']?.toString() ?? '';
    final body = n?.body ?? message.data['body']?.toString() ?? '';
    if (title.isEmpty && body.isEmpty) return;
    // messageId is stable across foreground/tap, so de-dupe keys off it.
    final id = message.messageId ?? '${title}_${body}'.hashCode.toString();
    NotificationStore.instance.add(
      id: id,
      title: title,
      body: body,
      type: message.data['type']?.toString(),
    );
  }

  /// Register this device's current FCM token for the logged-in admin/agency.
  static Future<void> registerToken() async {
    if (kIsWeb) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _sendRegister(token);
    } catch (_) {
      // best-effort — never block the UI on push registration
    }
  }

  static Future<void> _sendRegister(String token) async {
    try {
      final adminIdStr = await TokenStorage.getValue('admin_id');
      final agencyId = await TokenStorage.getValue('agency_id');
      await _api?.registerDeviceToken({
        'admin_id': int.tryParse(adminIdStr ?? ''),
        'agency_id': agencyId,
        'fcm_token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
      });
    } catch (_) {
      // best-effort
    }
  }

  /// Remove this device's token from the backend (call on logout, before tokens
  /// are cleared so the protected endpoint still authenticates).
  static Future<void> removeToken() async {
    if (kIsWeb) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _api?.removeDeviceToken({'fcm_token': token});
      }
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {
      // best-effort
    }
  }
}
