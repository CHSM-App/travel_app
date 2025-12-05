import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_impl.dart';
import 'token_provider.dart';

class TokenInterceptor extends Interceptor {
  final Dio dio;
  final Ref ref;
  final AuthImpl authRepository;

  TokenInterceptor({
    required this.dio,
    required this.ref,
    required this.authRepository,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = ref.read(tokenProvider).accessToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    super.onRequest(options, handler);
  }

  // @override
  // void onError(DioException err, ErrorInterceptorHandler handler) async {
  //   if (err.response?.statusCode == 401) {
  //     final refreshToken = ref.read(tokenProvider).refreshToken;
  //     if (refreshToken != null) {
  //       try {
  //         final tokenResponse =
  //             await authRepository.refreshAccessToken(refreshToken);

  //         await ref.read(tokenProvider.notifier).saveTokens(
  //               tokenResponse.accessToken,
  //               tokenResponse.refreshToken,
  //             );

  //         final opts = err.requestOptions;
  //         opts.headers['Authorization'] = 'Bearer ${tokenResponse.accessToken}';
  //         final cloneReq = await dio.fetch(opts);
  //         return handler.resolve(cloneReq);
  //       } catch (e) {
  //         await ref.read(tokenProvider.notifier).clearTokens();
  //       }
  //     }
  //   }
  //   return handler.next(err);
  // }
}
