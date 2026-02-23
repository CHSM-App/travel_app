import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/core/network/interceptor.dart';
import 'package:travel_agency_app/core/storage/constant.dart';
import 'package:travel_agency_app/domain/viewModel/network_model.dart';

import '../../data/api/api_service.dart';
import '../../data/repositories/auth_impl.dart';

final authRepoProvider = Provider<AuthImpl>((ref) {
  final dio = Dio(BaseOptions(baseUrl: baseUrl));
  return AuthImpl(ApiService(dio));
});

final dioProvider = FutureProvider<Dio>((ref) {
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

  dio.interceptors.add(
    TokenInterceptor(
      dio: dio,
      ref: ref,
      authRepository: ref.watch(authRepoProvider),
    ),
  );

  return dio;
});

final apiServiceProvider = Provider<ApiService>((ref) {
  final dio = ref.watch(dioProvider).value;
  return ApiService(dio!);
});

final apiStateProvider =
    StateNotifierProvider<ApiStateNotifier, ApiState>((ref) {
  return ApiStateNotifier(ref.watch(apiServiceProvider));
});
