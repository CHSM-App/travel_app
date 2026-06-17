import 'package:dio/dio.dart';

/// Shown whenever the failure is a transport/network problem. Matches the
/// offline wording used on the Trips page so the whole app reads consistently.
const String kOfflineMessage =
    'You appear to be offline. Check your connection and try again.';

/// Shown when the server dropped the connection mid-response — typically a
/// backend restart or crash, NOT the user's device being offline. "Connection
/// closed before full header was received" arrives this way, and showing the
/// offline copy would be misleading, so we use a neutral retry message.
const String kSomethingWentWrongMessage =
    'Something went wrong. Please try again.';

/// True when [e]'s raw text looks like the server accepted the socket and then
/// closed it before replying (server restart/crash), as opposed to the device
/// having no network at all.
bool _isServerDroppedConnection(Object e) {
  if (e is! DioException) return false;
  // The descriptive text can live on `message` OR on the wrapped `error`
  // (e.g. the underlying HttpException "Connection closed before full header
  // was received"), so check both.
  final lower =
      '${e.message ?? ''} ${e.error ?? ''}'.toLowerCase();
  return lower.contains('connection closed') ||
      lower.contains('connection reset') ||
      lower.contains('connection refused');
}

/// True when [e] is a transport-level failure (no connection, timeout, or a
/// device socket error wrapped as `unknown`). Use this in full-screen error
/// states that want to show a wifi-off icon + offline copy, like the Trips page.
bool isNetworkError(Object e) {
  if (e is! DioException) return false;
  switch (e.type) {
    case DioExceptionType.connectionError:
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return true;
    case DioExceptionType.unknown:
      final lower = (e.message ?? '').toLowerCase();
      return lower.contains('socket') ||
          lower.contains('failed host lookup') ||
          lower.contains('connection') ||
          lower.contains('network');
    default:
      return false;
  }
}

/// Thrown by viewmodels when the server returned HTTP 200 but the body
/// signalled a domain-level failure (e.g. a stored procedure rejecting the
/// request with `success = 0`). Carries the message verbatim so the UI can
/// surface it instead of a generic fallback.
class AppException implements Exception {
  final String message;
  AppException(this.message);
  @override
  String toString() => message;
}

/// Maps an exception thrown from the API/Dio layer into a short, user-safe
/// message. Hides raw `DioException` stack-style text and turns every
/// transport-level failure into "No internet connection" — which is what the
/// user actually wants to see when their device is offline.
///
/// Use this everywhere a caught error is shown to the user (snackbars, error
/// states in `AsyncValue.when`, etc.) instead of `e.toString()`.
String friendlyErrorMessage(Object e) {
  // App-level rejection raised by a viewmodel — already has a human message.
  if (e is AppException) {
    final msg = e.message.trim();
    if (msg.isNotEmpty) return msg;
  }
  if (e is DioException) {
    // Server dropped the connection mid-response (restart/crash). Catch this
    // before the transport branch so the user doesn't see misleading
    // "you're offline" copy when their network is fine.
    if (_isServerDroppedConnection(e)) return kSomethingWentWrongMessage;
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return kOfflineMessage;
      case DioExceptionType.badCertificate:
        return 'Secure connection failed';
      case DioExceptionType.badResponse:
        // Prefer the server's own message. Different backend routes use
        // different keys: most use `message`, the upload routes use `error`.
        // Try both before falling back.
        final fromBody = _messageFromBody(e.response?.data);
        if (fromBody != null) return fromBody;
        final code = e.response?.statusCode;
        return code != null ? 'Server error ($code)' : 'Server error';
      case DioExceptionType.cancel:
        return 'Request cancelled';
      case DioExceptionType.unknown:
        // Device-level socket failures ("Failed host lookup", "Connection
        // closed", "Network is unreachable") arrive wrapped as `unknown` —
        // treat anything that smells like a transport failure as offline.
        final raw = (e.message ?? '').trim();
        final lower = raw.toLowerCase();
        if (lower.contains('socket') ||
            lower.contains('failed host lookup') ||
            lower.contains('connection') ||
            lower.contains('network')) {
          return kOfflineMessage;
        }
        // Anything that looks like a real, short, human-readable reason
        // gets surfaced verbatim so the user sees *why* — instead of the
        // useless "Something went wrong".
        if (raw.isNotEmpty && raw.length < 160) return raw;
        return 'Something went wrong';
    }
  }
  // Generic / unknown exception type: try to recover a useful sentence.
  final raw = e.toString().trim();
  final stripped =
      raw.startsWith('Exception: ') ? raw.substring(11).trim() : raw;
  final looksLikeStack = stripped.contains('#0 ') ||
      stripped.contains('<asynchronous suspension>') ||
      stripped.contains('DioException');
  if (stripped.isNotEmpty && stripped.length < 160 && !looksLikeStack) {
    return stripped;
  }
  return 'Something went wrong';
}

/// Pulls a human-readable message out of a parsed JSON error body. Accepts
/// the common `message` / `error` keys our backend uses, and falls back to a
/// nested `data.message` (the shape `sp_*` procs return).
String? _messageFromBody(dynamic data) {
  if (data is! Map) return null;
  for (final key in const ['message', 'error']) {
    final v = data[key];
    if (v is String) {
      final s = v.trim();
      if (s.isNotEmpty) return s;
    }
  }
  final nested = data['data'];
  if (nested is Map) {
    for (final key in const ['message', 'error']) {
      final v = nested[key];
      if (v is String) {
        final s = v.trim();
        if (s.isNotEmpty) return s;
      }
    }
  }
  return null;
}
