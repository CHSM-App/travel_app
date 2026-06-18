import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vego/core/storage/constant.dart';
import 'package:vego/core/storage/token_storage.dart';

/// What our backend returns for a route lookup.
class DistanceResult {
  final double km; // numeric distance, used for the field + fuel calc
  final String distanceText; // pretty distance, e.g. "173 km"
  final String? durationText; // estimated time, e.g. "3 hours 46 mins"
  final int? durationMinutes; // numeric estimate, for round-trip (×2) math

  DistanceResult({
    required this.km,
    required this.distanceText,
    this.durationText,
    this.durationMinutes,
  });
}

/// Asks OUR backend for the road distance between two place names.
/// The Google API key lives on the server (.env), never in the app.
class DistanceService {
  static Future<DistanceResult?> getDistance(
    String origin,
    String destination,
  ) async {
    // baseUrl already ends with '/', so this becomes
    // https://vego.vengurlatech.com/users/distance
    final url = Uri.parse('${baseUrl}users/distance').replace(
      queryParameters: {
        'origins': origin,
        'destinations': destination,
      },
    );

    // `/users/*` is auth-protected; attach the bearer token manually (the bare
    // http package has no Dio interceptor to inject it).
    final tokens = await TokenStorage.getTokens();
    final token = tokens?['accessToken'];
    final res = await http.get(
      url,
      headers: (token != null && token.isNotEmpty)
          ? {'Authorization': 'Bearer $token'}
          : null,
    );
    if (res.statusCode != 200) return null;

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final km = data['distanceKm'];
    if (km is! num) return null;

    final durationText = data['durationText'] as String?;
    // Prefer a numeric duration from the backend (seconds) if it sends one;
    // otherwise derive minutes from the human-readable text.
    final durationValue = data['durationValue'];
    final durationMinutes = durationValue is num
        ? (durationValue / 60).round()
        : _parseDurationToMinutes(durationText);

    return DistanceResult(
      km: km.toDouble(),
      distanceText: (data['distanceText'] as String?) ?? '${km.toStringAsFixed(1)} km',
      durationText: durationText,
      durationMinutes: durationMinutes,
    );
  }

  // Turns a Google-style duration string ("1 day 3 hours 46 mins", "46 mins")
  // into total minutes. Returns null if nothing parseable is found.
  static int? _parseDurationToMinutes(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    final lower = text.toLowerCase();
    int total = 0;
    bool matched = false;

    final day = RegExp(r'(\d+)\s*day').firstMatch(lower);
    if (day != null) {
      total += int.parse(day.group(1)!) * 1440;
      matched = true;
    }
    final hour = RegExp(r'(\d+)\s*hour').firstMatch(lower);
    if (hour != null) {
      total += int.parse(hour.group(1)!) * 60;
      matched = true;
    }
    final min = RegExp(r'(\d+)\s*min').firstMatch(lower);
    if (min != null) {
      total += int.parse(min.group(1)!);
      matched = true;
    }
    return matched ? total : null;
  }
}
