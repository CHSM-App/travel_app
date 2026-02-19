
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/Screens/login.dart';
import 'package:travel_agency_app/domain/models/token_response.dart';
import 'package:travel_agency_app/main.dart';

 
import '../../data/repositories/auth_impl.dart';
import 'token_provider.dart';
 
class TokenInterceptor extends Interceptor {
  final Dio dio;
  final Ref ref;
  final AuthImpl authRepository;
 
  bool _isRefreshing = false;
  Future? _refreshFuture;
 
  TokenInterceptor({
    required this.dio,
    required this.ref,
    required this.authRepository,
  });
 
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final token = ref.read(tokenProvider).accessToken;
 
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = "Bearer $token";
    }
 
    handler.next(options);
  }
 
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // No response? Network issue → not a token problem
    if (err.response == null) {
      return handler.next(err);
    }
 
    // Only handle unauthorized
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }
 
    final refreshToken = ref.read(tokenProvider).refreshToken;
 
    // If no refresh token exists → logout
    if (refreshToken == null || refreshToken.isEmpty) {
      // await ref.read(tokenProvider.notifier).clearTokens();
      return handler.next(err);
    }
 
    try {
      // If refresh already running → wait for it
      if (_isRefreshing) {
        await _refreshFuture;
        return _retryRequest(err, handler);
      }
 
      // Begin refresh logic
      _isRefreshing = true;
 
      // Delay protects against slow IIS shared hosting race conditions
     // await Future.delayed(const Duration(milliseconds: 200));
 
      _refreshFuture = authRepository.refreshAccessToken(
        TokenResponse(refreshToken: refreshToken),
      );
      final tokenResponse = await _refreshFuture;
 
      _isRefreshing = false;
 
      // Validate new tokens
      if (tokenResponse.accessToken == null ||
          tokenResponse.accessToken!.isEmpty ||
          tokenResponse.refreshToken == null ||
          tokenResponse.refreshToken!.isEmpty) {
        await ref.read(tokenProvider.notifier).clearTokens();
        _goToLogin();
        return handler.next(err);
      }
 
      // Save new tokens
      await ref.read(tokenProvider.notifier).saveTokens(
            tokenResponse.accessToken!,
            tokenResponse.refreshToken!,
          );
 
      // Retry failed request
      return _retryRequest(err, handler);
 
    } catch (e) {
      _isRefreshing = false;
      await ref.read(tokenProvider.notifier).clearTokens();
      _goToLogin();
      return handler.next(err);
    }
  }
 
  Future<void> _retryRequest(
      DioException err, ErrorInterceptorHandler handler) async {
    final reqOptions = err.requestOptions;
 
    // Update header with the new access token
    final newToken = ref.read(tokenProvider).accessToken;
    reqOptions.headers['Authorization'] = "Bearer $newToken";
 
    try {
      final response = await dio.fetch(reqOptions);
      handler.resolve(response);
    } catch (e) { 
      handler.next(err);
    }
  }
void _goToLogin() {
  Future.microtask(() {
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginPage()),
      (route) => false, // remove all previous screens
    );
  });
}
}