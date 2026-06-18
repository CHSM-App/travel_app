import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vego/core/storage/constant.dart';
import 'package:vego/core/storage/token_storage.dart';

/// Google Places autocomplete, proxied through OUR backend so the Google API
/// key stays on the server (.env) — never shipped in the app. Mirrors
/// [DistanceService]'s contract: backend at `${baseUrl}users/placeAutocomplete`.
///
/// Backend is expected to return either:
///   ["Panaji, Goa, India", "Pune, Maharashtra, India"]
/// or Google's own shape:
///   { "predictions": [ { "description": "Panaji, Goa, India" }, ... ] }
class PlacesService {
  /// Builds the Authorization header from the stored access token, mirroring
  /// the Dio interceptor. Returns an empty map when no token is stored.
  static Future<Map<String, String>> _authHeaders() async {
    final tokens = await TokenStorage.getTokens();
    final token = tokens?['accessToken'];
    if (token == null || token.isEmpty) return const {};
    return {'Authorization': 'Bearer $token'};
  }

  /// Returns place-description suggestions for [input]. Empty list for short
  /// queries, network errors, or non-200 responses — callers fall back to their
  /// own (e.g. recent-location) suggestions so the field never breaks.
  static Future<List<String>> autocomplete(String input) async {
    final q = input.trim();
    if (q.length < 3) return const [];

    try {
      final url = Uri.parse('${baseUrl}users/placeAutocomplete').replace(
        queryParameters: {'input': q},
      );
      // `/users/*` is auth-protected on the backend, so the bearer token must be
      // attached manually here — unlike the Dio client, the bare http package
      // has no interceptor to inject it.
      final res = await http.get(url, headers: await _authHeaders());
      if (res.statusCode != 200) return const [];

      final decoded = jsonDecode(res.body);
      final List<dynamic> raw;
      if (decoded is List) {
        raw = decoded;
      } else if (decoded is Map && decoded['predictions'] is List) {
        raw = decoded['predictions'] as List<dynamic>;
      } else {
        return const [];
      }

      final out = <String>[];
      for (final item in raw) {
        String? desc;
        if (item is String) {
          desc = item;
        } else if (item is Map) {
          desc = (item['description'] ?? item['name'] ?? item['text'])
              ?.toString();
        }
        desc = desc?.trim();
        if (desc != null && desc.isNotEmpty) out.add(desc);
      }
      return out;
    } catch (_) {
      return const [];
    }
  }
}
