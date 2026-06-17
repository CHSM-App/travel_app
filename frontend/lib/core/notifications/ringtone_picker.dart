import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

/// A sound the user picked from the device's ringtone picker.
class RingtoneChoice {
  /// content:// URI of the chosen sound, used as the notification sound.
  final String uri;

  /// Human-readable name (e.g. "Beep Beep", "Over the Horizon").
  final String title;

  const RingtoneChoice({required this.uri, required this.title});
}

/// Thin wrapper over the native `RingtoneManager` picker (see MainActivity.kt).
///
/// Opens the system ringtone/alarm picker so the user can choose any sound on
/// their device for trip reminders. Returns null when the user cancels.
class RingtonePicker {
  RingtonePicker._();

  static const _channel = MethodChannel('trip_alarm/ringtone');

  /// Launch the picker. [current] pre-selects the user's existing choice.
  /// Returns null if cancelled or unsupported (e.g. web).
  static Future<RingtoneChoice?> pick({String? current}) async {
    if (kIsWeb) return null;
    try {
      final res = await _channel.invokeMapMethod<String, dynamic>(
        'pickRingtone',
        {'current': current},
      );
      if (res == null) return null;
      final uri = res['uri']?.toString();
      if (uri == null || uri.isEmpty) return null;
      return RingtoneChoice(
        uri: uri,
        title: res['title']?.toString() ?? 'Custom sound',
      );
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
