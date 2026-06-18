import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vego/Screens/login.dart';
import 'package:vego/domain/models/token_response.dart';
import 'package:vego/main.dart';

import '../../data/repositories/auth_impl.dart';
import 'token_provider.dart';

class TokenInterceptor extends Interceptor {
  final Dio dio;
  final Ref ref;
  final AuthImpl authRepository;
  final Future<void> Function(DioException error)? onTransportFailure;
  final VoidCallback? onTransportRecovery;

  bool _isRefreshing = false;
  Future? _refreshFuture;

  TokenInterceptor({
    required this.dio,
    required this.ref,
    required this.authRepository,
    this.onTransportFailure,
    this.onTransportRecovery,
  });

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final token = ref.read(tokenProvider).accessToken;

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    onTransportRecovery?.call();
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_isTransportFailure(err)) {
      await onTransportFailure?.call(err);
    }

    // No response? Network issue, not a token problem.
    if (err.response == null) {
      return handler.next(err);
    }

    // Only handle unauthorized for token refresh.
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    final refreshToken = ref.read(tokenProvider).refreshToken;

    if (refreshToken == null || refreshToken.isEmpty) {
      return handler.next(err);
    }

    try {
      if (_isRefreshing) {
        await _refreshFuture;
        return _retryRequest(err, handler);
      }

      _isRefreshing = true;
      _refreshFuture = authRepository.refreshAccessToken(
        TokenResponse(refreshToken: refreshToken),
      );
      final tokenResponse = await _refreshFuture;
      _isRefreshing = false;

      if (tokenResponse.accessToken == null ||
          tokenResponse.accessToken!.isEmpty ||
          tokenResponse.refreshToken == null ||
          tokenResponse.refreshToken!.isEmpty) {
        await ref.read(tokenProvider.notifier).clearTokens();
        _goToLogin();
        return handler.next(err);
      }

      await ref.read(tokenProvider.notifier).saveTokens(
            tokenResponse.accessToken!,
            tokenResponse.refreshToken!,
          );

      return _retryRequest(err, handler);
    } catch (_) {
      _isRefreshing = false;
      await ref.read(tokenProvider.notifier).clearTokens();
      _goToLogin();
      return handler.next(err);
    }
  }

  Future<void> _retryRequest(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final reqOptions = err.requestOptions;

    final newToken = ref.read(tokenProvider).accessToken;
    reqOptions.headers['Authorization'] = 'Bearer $newToken';

    try {
      final response = await dio.fetch(reqOptions);
      handler.resolve(response);
    } catch (_) {
      handler.next(err);
    }
  }

  void _goToLogin() {
    Future.microtask(() {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    });
  }

  bool _isTransportFailure(DioException err) {
    return err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout;
  }
}
