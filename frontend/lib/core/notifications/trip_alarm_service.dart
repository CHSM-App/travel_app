import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:travel_agency_app/core/notifications/ringtone_picker.dart';
import 'package:travel_agency_app/core/storage/token_storage.dart';

/// On-device, **offline** trip reminder alarms.
///
/// Unlike [PushService] (FCM, server-pushed, needs internet), this schedules
/// notifications straight to the OS AlarmManager via
/// flutter_local_notifications' `zonedSchedule`. Once set, a reminder fires
/// around the chosen time with no network, the app closed, even in airplane
/// mode. The manifest's boot receiver re-schedules pending alarms after a
/// reboot.
///
/// Scheduling is **inexact** (`inexactAllowWhileIdle`): a day-before reminder
/// doesn't need to-the-minute precision, and this keeps the app off the
/// restricted exact-alarm permissions that Google Play reserves for clock /
/// calendar apps.
///
/// One alarm per trip: the notification id IS the `tripId`, so re-scheduling a
/// trip overwrites its previous alarm and cancelling is a single call.
class TripAlarmService {
  TripAlarmService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // Channel id is versioned (…_v2) because Android freezes a channel's
  // sound/importance the first time it's created — bumping the id forces the
  // new alarm-audio settings to take effect on devices that saw an earlier build.
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'trip_alarms_v2',
    'Trip Alarms',
    description: 'Reminders you set for upcoming trips',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    // Route through the ALARM stream so it plays at alarm volume and is audible
    // even when the phone is on silent/vibrate (like a clock alarm).
    audioAttributesUsage: AudioAttributesUsage.alarm,
  );

  // Persisted map: tripId -> { fireAt (ISO), body }. Lets the bell icon show
  // whether a trip already has a reminder, and at what time, across restarts.
  static const _storageKey = 'trip_alarms';

  // Persisted user-chosen alarm sound (a device ringtone URI + its title).
  // Null = the channel's default alarm tone. Applied to alarms scheduled after
  // the choice is made.
  static const _soundKey = 'trip_alarm_sound';
  static String? _soundUri;
  static String? _soundTitle;

  static final Map<int, _AlarmInfo> _alarms = {};
  static bool _ready = false;

  /// URI of the user's chosen reminder sound, or null for the default tone.
  static String? get currentSoundUri => _soundUri;

  /// Display name of the chosen sound, or null when using the default tone.
  static String? get currentSoundTitle => _soundTitle;

  /// Detected/assumed local timezone. This is an India-only agency app (the
  /// backend stamps IST), so we anchor alarms to Asia/Kolkata rather than pull
  /// in another plugin just to read the device zone.
  static const _localZone = 'Asia/Kolkata';

  /// Idempotent setup: timezone DB, plugin init, channel, notification
  /// permission, and loading the persisted alarm map. Safe to call repeatedly.
  static Future<void> ensureReady() async {
    if (_ready || kIsWeb) return;

    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation(_localZone));
    } catch (_) {
      // Falls back to UTC if the zone name is ever unavailable.
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(settings: initSettings);

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(_channel);
    await androidImpl?.requestNotificationsPermission();

    await _load();
    await _loadSound();
    _ready = true;
  }

  /// Set (or clear, with null) the alarm sound the user picked from the device
  /// ringtone picker. Takes effect on alarms scheduled afterwards.
  static Future<void> setSound(RingtoneChoice? choice) async {
    await ensureReady();
    _soundUri = choice?.uri;
    _soundTitle = choice?.title;
    try {
      if (choice == null) {
        await TokenStorage.deleteValue(_soundKey);
      } else {
        await TokenStorage.saveValue(
          _soundKey,
          jsonEncode({'uri': choice.uri, 'title': choice.title}),
        );
      }
    } catch (_) {
      // best-effort
    }
  }

  // Build the Android channel + details for the current sound choice. A custom
  // sound needs its OWN channel (Android binds sound to a channel and freezes
  // it at creation), so we derive a stable per-URI channel id and create it on
  // demand. No choice → the default alarm channel.
  static Future<AndroidNotificationDetails> _androidDetails() async {
    final uri = _soundUri;
    if (uri == null || uri.isEmpty) {
      return AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
      );
    }

    final sound = UriAndroidNotificationSound(uri);
    final channelId = 'trip_alarm_${uri.hashCode}';
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(
      AndroidNotificationChannel(
        channelId,
        'Trip Alarms',
        description: _channel.description,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        sound: sound,
      ),
    );

    return AndroidNotificationDetails(
      channelId,
      'Trip Alarms',
      channelDescription: _channel.description,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      sound: sound,
      enableVibration: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
    );
  }

  /// Default reminder time: **7:00 PM on the day before the trip starts**.
  static DateTime defaultReminderFor(DateTime tripStart) {
    final dayBefore = DateTime(tripStart.year, tripStart.month, tripStart.day)
        .subtract(const Duration(days: 1));
    return DateTime(dayBefore.year, dayBefore.month, dayBefore.day, 19, 0);
  }

  static bool hasAlarm(int? tripId) =>
      tripId != null && _alarms.containsKey(tripId);

  static DateTime? alarmTime(int? tripId) =>
      tripId == null ? null : _alarms[tripId]?.fireAt;

  /// Schedule (or replace) a trip's reminder. Returns false without scheduling
  /// when [fireAt] is already in the past — the caller should tell the user.
  static Future<bool> schedule({
    required int tripId,
    required DateTime fireAt,
    required String title,
    required String body,
  }) async {
    await ensureReady();
    if (kIsWeb) return false;
    if (!fireAt.isAfter(DateTime.now())) return false;

    final scheduled = tz.TZDateTime.from(fireAt, tz.local);

    await _plugin.zonedSchedule(
      id: tripId,
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: NotificationDetails(android: await _androidDetails()),
      // Inexact + allow-while-idle: fires around the set time even under Doze,
      // without needing the restricted exact-alarm permission.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'trip:$tripId',
    );

    _alarms[tripId] = _AlarmInfo(fireAt, body);
    await _persist();
    return true;
  }

  /// Cancel a trip's reminder (no-op if none set or [tripId] is null).
  static Future<void> cancel(int? tripId) async {
    if (tripId == null) return;
    await ensureReady();
    await _plugin.cancel(id: tripId);
    _alarms.remove(tripId);
    await _persist();
  }

  static Future<void> _load() async {
    try {
      final raw = await TokenStorage.getValue(_storageKey);
      if (raw == null || raw.isEmpty) return;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _alarms.clear();
      map.forEach((k, v) {
        final id = int.tryParse(k);
        final info = _AlarmInfo.fromJson(v as Map<String, dynamic>);
        if (id != null && info != null) _alarms[id] = info;
      });
    } catch (_) {
      // Corrupt data — start clean rather than crash.
    }
  }

  static Future<void> _loadSound() async {
    try {
      final raw = await TokenStorage.getValue(_soundKey);
      if (raw == null || raw.isEmpty) return;
      final j = jsonDecode(raw) as Map<String, dynamic>;
      _soundUri = j['uri']?.toString();
      _soundTitle = j['title']?.toString();
    } catch (_) {
      // Corrupt data — fall back to default tone.
    }
  }

  static Future<void> _persist() async {
    try {
      final map = _alarms.map((k, v) => MapEntry(k.toString(), v.toJson()));
      await TokenStorage.saveValue(_storageKey, jsonEncode(map));
    } catch (_) {
      // best-effort
    }
  }
}

class _AlarmInfo {
  final DateTime fireAt;
  final String body;
  _AlarmInfo(this.fireAt, this.body);

  Map<String, dynamic> toJson() =>
      {'fireAt': fireAt.toIso8601String(), 'body': body};

  static _AlarmInfo? fromJson(Map<String, dynamic> j) {
    final t = DateTime.tryParse(j['fireAt']?.toString() ?? '');
    if (t == null) return null;
    return _AlarmInfo(t, j['body']?.toString() ?? '');
  }
}
