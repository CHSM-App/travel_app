import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:travel_agency_app/core/storage/constant.dart';

/// What our backend returns for a route lookup.
class DistanceResult {
  final double km; // numeric distance, used for the field + fuel calc
  final String distanceText; // pretty distance, e.g. "173 km"
  final String? durationText; // estimated time, e.g. "3 hours 46 mins"

  DistanceResult({
    required this.km,
    required this.distanceText,
    this.durationText,
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
    // https://travels.vengurlatech.com/users/distance
    final url = Uri.parse('${baseUrl}users/distance').replace(
      queryParameters: {
        'origins': origin,
        'destinations': destination,
      },
    );

    final res = await http.get(url);
    if (res.statusCode != 200) return null;

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final km = data['distanceKm'];
    if (km is! num) return null;

    return DistanceResult(
      km: km.toDouble(),
      distanceText: (data['distanceText'] as String?) ?? '${km.toStringAsFixed(1)} km',
      durationText: data['durationText'] as String?,
    );
  }
}
