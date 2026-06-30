import 'package:dio/dio.dart';

/// Automatically retries requests that fail due to a *backend / transport*
/// problem — connection drops, timeouts, or 5xx server errors — with an
/// exponential backoff. Client errors (4xx, including 401 which the token
/// interceptor already handles) are never retried because re-sending them
/// would fail the same way.
///
/// Opt a single request out by setting `extra: {'disableRetry': true}` on it.
class RetryInterceptor extends Interceptor {
  final Dio dio;

  /// How many extra attempts after the first one fails.
  final int maxRetries;

  /// Base delay; the nth retry waits `baseDelay * 2^n` (e.g. 500ms, 1s, 2s).
  final Duration baseDelay;

  RetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
    this.baseDelay = const Duration(milliseconds: 500),
  });

  static const _attemptKey = 'retryAttempt';
  static const _disableKey = 'disableRetry';

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final attempt = (options.extra[_attemptKey] as int?) ?? 0;

    final canRetry = options.extra[_disableKey] != true &&
        attempt < maxRetries &&
        _shouldRetry(err);

    if (!canRetry) {
      return handler.next(err);
    }

    // Exponential backoff: 500ms, 1s, 2s, ...
    final delay = baseDelay * (1 << attempt);
    await Future<void>.delayed(delay);

    options.extra[_attemptKey] = attempt + 1;

    try {
      final response = await dio.fetch<dynamic>(options);
      return handler.resolve(response);
    } on DioException catch (e) {
      // Re-sending failed too; let the (possibly further-retried) error flow on.
      return handler.next(e);
    } catch (_) {
      return handler.next(err);
    }
  }

  /// Retry only on problems that a retry can plausibly fix: transport issues
  /// and transient server errors (HTTP 5xx). Everything else passes straight
  /// through.
  ///
  /// To avoid double-submitting writes, a non-idempotent request (POST/PATCH)
  /// is retried only when the failure happened *before* the server could have
  /// processed it (connection/send phase). Once a response was being received
  /// or the server returned 5xx, it may already have applied the write, so we
  /// don't resend it.
  bool _shouldRetry(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.connectionError:
        // Request almost certainly never completed — safe for any method.
        return true;
      case DioExceptionType.unknown:
        // SocketException "connection closed" / "connection reset" means the
        // server dropped the keep-alive socket before the request was sent.
        // Safe to retry any method because the server never saw the request.
        final error = err.error;
        if (error is Exception) {
          final msg = error.toString().toLowerCase();
          final closedBeforeSent = msg.contains('connection closed') ||
              msg.contains('connection reset') ||
              msg.contains('broken pipe') ||
              msg.contains('software caused connection abort');
          if (closedBeforeSent) return true;
          // Other unknown errors (no network, dns fail) — retry any method.
          return true;
        }
        return false;
      case DioExceptionType.receiveTimeout:
        return _isIdempotent(err.requestOptions.method);
      case DioExceptionType.badResponse:
        final code = err.response?.statusCode ?? 0;
        return code >= 500 && code < 600 &&
            _isIdempotent(err.requestOptions.method);
      default:
        return false;
    }
  }

  bool _isIdempotent(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
      case 'HEAD':
      case 'OPTIONS':
      case 'PUT':
      case 'DELETE':
        return true;
      default: // POST, PATCH
        return false;
    }
  }
}
