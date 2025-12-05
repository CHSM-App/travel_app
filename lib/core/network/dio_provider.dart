import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:travel_agency_app/core/network/interceptor.dart';
import 'package:travel_agency_app/core/storage/constant.dart';
import 'package:travel_agency_app/data/api/api_service.dart';
import 'package:travel_agency_app/domain/viewModel/network_model.dart';

import '../../data/repositories/auth_impl.dart';


final authRepoProvider = Provider<AuthImpl>((ref) {
  final dio = Dio(BaseOptions(baseUrl: baseUrl));
  return AuthImpl(ApiService(dio));
});

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    sendTimeout: const Duration(seconds: 15),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  ));

  dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  
  // Add Network Interceptor
  // dio.interceptors.add(NetworkInterceptor(ref));
  
  // Add your token interceptor if needed
  dio.interceptors.add(TokenInterceptor(dio:dio, ref:ref,authRepository: ref.watch(authRepoProvider))); // Create this file if needed

  return dio;
});

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(ref.watch(dioProvider));
});

final apiStateProvider = StateNotifierProvider<ApiStateNotifier, ApiState>((ref) {
  return ApiStateNotifier(ref.watch(apiServiceProvider));
});
