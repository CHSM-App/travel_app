import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vego/core/network/interceptor.dart';
import 'package:vego/core/network/retry_interceptor.dart';
import 'package:vego/core/network/network_state_notifier.dart';
import 'package:vego/core/storage/constant.dart';

import '../../data/api/api_service.dart';
import '../../data/repositories/auth_impl.dart';

final authRepoProvider = Provider<AuthImpl>((ref) {
  final dio = Dio(BaseOptions(baseUrl: baseUrl));
  return AuthImpl(ApiService(dio));
});

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  // The backend sits behind IIS/Node with `Keep-Alive: timeout=5`, so the
  // server drops idle keep-alive connections after 5s. Dart's HttpClient
  // defaults to a 15s idleTimeout and reuses pooled connections — reusing one
  // the server already closed surfaces as "Connection closed before full
  // header was received". Closing our idle sockets *before* the server does
  // (3s < 5s) avoids that race at the source.
  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      client.idleTimeout = const Duration(seconds: 3);
      return client;
    },
  );

  dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));

  // Add your token interceptor if needed
 
  dio.interceptors.add(
    TokenInterceptor(
      dio: dio,
      ref: ref,
      authRepository: ref.watch(authRepoProvider),
      onTransportFailure: (error) async {
        await ref
            .read(networkStateProvider.notifier)
            .handleTransportFailure('No internet connection');
      },
      onTransportRecovery: () {
        ref.read(networkStateProvider.notifier).markConnectedFromRequest();
      },
    ),
  );

  // Auto-retry transient backend failures (timeouts, connection drops, 5xx)
  // with exponential backoff. Added last so token refresh (401) is resolved
  // first; only genuine backend/transport errors reach the retry logic.
  dio.interceptors.add(RetryInterceptor(dio: dio));

  return dio;
});

final apiServiceProvider = Provider<ApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiService(dio);
});

final apiStateProvider = StateNotifierProvider<ApiStateNotifier, ApiState>((ref) {
  return ApiStateNotifier(ref.watch(apiServiceProvider));
});
