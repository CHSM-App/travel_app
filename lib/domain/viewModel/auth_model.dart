import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/domain/usecase/auth_use_case.dart';

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
    AsyncValue<String>? transaction,
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

  AuthViewModel(this.ref, this.usecase)
      : super(const AuthState());

  /// Login function
  // Future<String?> login(TokenResponse mobile) async {
  //   state = state.copyWith(isLoading: true);

  //   try {
  //     // 🔹 Call API
  //     final result = await usecase.login(mobile); 
  //     // result should be TokenResponse

  //     // ✅ Save tokens to Riverpod + SecureStorage
  //     await ref
  //         .read(tokenProvider.notifier)
  //         .saveTokens(result.accessToken ?? "", result.refreshToken ?? "");

  //     state = state.copyWith(isLoading: false, data: {"message": "Login Successful"});
  //     return "sucesss"; // Return TokenResponse for UI navigation
  //   } catch (e) {
  //     state = state.copyWith(isLoading: false, error: e.toString());
  //     return null;
  //   }
  // }
  // Future<bool> logout(TokenResponse refreshToken) async {
  //   state = state.copyWith(isLoading: true);

  //   try {
  //     // 🔹 Call API
  //   await usecase.logout(refreshToken); 
  //     // result should be TokenResponse

  //     // ✅ Clear tokens from Riverpod + SecureStorage
  //     await ref
  //         .read(tokenProvider.notifier)
  //         .clearTokens();

  //     state = state.copyWith(isLoading: false, data: {"message": "Logout Successful"});
  //     return true; // Return true for successful logout
  //   } catch (e) {
  //     state = state.copyWith(isLoading: false, error: e.toString());
  //     return false;
  //   }
  // }

}

