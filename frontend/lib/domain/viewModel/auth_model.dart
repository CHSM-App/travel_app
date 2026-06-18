import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vego/core/network/error_messages.dart';
import 'package:vego/core/network/token_provider.dart';
import 'package:vego/domain/models/token_response.dart';
import 'package:vego/domain/usecase/auth_use_case.dart';

@immutable
class AuthState {
  final bool isLoading;
  final Map<String, dynamic>? data;
  final String? error;

  const AuthState({
    this.isLoading = false,
    this.data,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    Map<String, dynamic>? data,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }
}

class AuthViewModel extends StateNotifier<AuthState> {
  final Ref ref;
  final AuthUseCase usecase;

  AuthViewModel(this.ref, this.usecase) : super(const AuthState());

  Future<String?> createLogin(TokenResponse mobile) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await usecase.createLogin(mobile);

      if ((result.accessToken ?? '').isEmpty ||
          (result.refreshToken ?? '').isEmpty) {
        throw Exception('Invalid token response');
      }

      await ref.read(tokenProvider.notifier).saveTokens(
            result.accessToken!,
            result.refreshToken!,
          );

      state = state.copyWith(
        isLoading: false,
        data: {'message': 'Login Successful'},
      );
      return 'success';
    } catch (e) {
      state = state.copyWith(isLoading: false, error: friendlyErrorMessage(e));
      return null;
    }
  }

  Future<bool> logout(TokenResponse refreshToken) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await usecase.logout(refreshToken);
      await ref.read(tokenProvider.notifier).clearTokens();

      state = state.copyWith(
        isLoading: false,
        data: {'message': 'Logout Successful'},
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: friendlyErrorMessage(e));
      return false;
    }
  }
}
