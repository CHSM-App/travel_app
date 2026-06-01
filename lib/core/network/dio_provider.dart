import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/core/network/interceptor.dart';
import 'package:travel_agency_app/core/network/retry_interceptor.dart';
import 'package:travel_agency_app/core/network/network_state_notifier.dart';
import 'package:travel_agency_app/core/storage/constant.dart';

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
