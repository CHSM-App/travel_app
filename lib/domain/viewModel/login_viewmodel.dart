// import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/core/storage/token_storage.dart';
import 'package:travel_agency_app/domain/models/login_info.dart';
import 'package:travel_agency_app/domain/models/login_response.dart';
import 'package:travel_agency_app/domain/usecase/login_usecase.dart';

class LoginState {
  final bool isLoading;
  final String? error;

  final int adminId;
  final String? name;
  final String? email;
  final String? mobile;
  final String? agencyId;
  final double? perKmCharge;

  final AsyncValue<List<LoginInfo>> adminProfile;

  const LoginState({
    this.isLoading = false,
    this.error,
    this.adminId = 0,
    this.name,
    this.email,
    this.mobile,
    this.agencyId,
    this.perKmCharge,

    this.adminProfile = const AsyncValue.loading(),
  });

  LoginState copyWith({
    bool? isLoading,
    String? error,
    int? adminId,
    String? name,
    String? email,
    String? mobile,
    String? agencyId,
    double? perKmCharge,

    AsyncValue<List<LoginInfo>>? adminProfile,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      adminId: adminId ?? this.adminId,
      name: name ?? this.name,
      email: email ?? this.email,
      mobile: mobile ?? this.mobile,
      agencyId: agencyId ?? this.agencyId,
      perKmCharge: perKmCharge ?? this.perKmCharge,

      adminProfile: adminProfile ?? this.adminProfile,
    );
  }
}

class LoginViewModel extends StateNotifier<LoginState> {
  final LoginUseCase usecase;

  LoginViewModel(this.usecase) : super(const LoginState()) {
    loadFromStorage();
  }

  //--------------------------------------------------
  // LOAD TOKEN FROM STORAGE (AUTO LOGIN)
  //--------------------------------------------------

  Future<void> loadFromStorage() async {
    final adminIdStr = await TokenStorage.getValue('admin_id');
    final adminId = int.tryParse(adminIdStr ?? '0') ?? 0;

    final name = await TokenStorage.getValue('name');
    final email = await TokenStorage.getValue('email');
    final mobile = await TokenStorage.getValue('mobile');
    final agencyId = await TokenStorage.getValue('agency_id');
    final perKmStr = await TokenStorage.getValue('per_km_charge');
    final perKm = double.tryParse(perKmStr ?? '');

    state = state.copyWith(
      adminId: adminId,
      agencyId: agencyId,
      name: name,
      email: email,
      mobile: mobile,
      perKmCharge: perKm,
    );
  }

  // LOGIN

  Future<LoginResponse?> login(LoginInfo loginInfo) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await usecase.login(loginInfo);

      if (response.success == 1) {
        // SAVE TOKEN
        await TokenStorage.saveValue('admin_id', response.adminId.toString());

        await TokenStorage.saveValue('name', response.name ?? "");

        await TokenStorage.saveValue('email', response.email ?? "");

        await TokenStorage.saveValue('mobile', response.mobile ?? "");

        await TokenStorage.saveValue('agency_id', response.agencyId ?? "");

        await TokenStorage.saveValue(
          'per_km_charge',
          response.perKmCharge?.toString() ?? "",
        );
        // LOAD INTO STATE
        await loadFromStorage();
      }

      state = state.copyWith(isLoading: false);

      return response;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());

      return LoginResponse(success: 0, message: e.toString());
    }
  }

  // ADD ADMIN
  Future<LoginResponse?> addAdmin(LoginInfo loginInfo) async {
    try {
      state = state.copyWith(isLoading: true);

      final response = await usecase.addAdmin(loginInfo);

      state = state.copyWith(isLoading: false);

      return response;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());

      return LoginResponse(success: 0, message: e.toString());
    }
  }

  //--------------------------------------------------
  // FORGOT PASSWORD
  //--------------------------------------------------

  Future<LoginResponse?> forgotPassword(LoginInfo loginInfo) async {
    try {
      state = state.copyWith(isLoading: true);

      final response = await usecase.forgotPassword(loginInfo);

      state = state.copyWith(isLoading: false);

      return response;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());

      return LoginResponse(success: 0, message: e.toString());
    }
  }

  /// Persist a freshly-edited per-km rate to secure storage and live state so
  /// the booking form's auto-calc picks it up immediately (without re-login).
  Future<void> setPerKmCharge(double? rate) async {
    await TokenStorage.saveValue('per_km_charge', rate?.toString() ?? "");
    state = state.copyWith(perKmCharge: rate);
  }

  //--------------------------------------------------
  // ADMIN PROFILE
  //--------------------------------------------------

  Future<void> adminProfile(int adminId) async {
    state = state.copyWith(adminProfile: const AsyncValue.loading());

    try {
      final result = await usecase.adminProfile(adminId);

      state = state.copyWith(adminProfile: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(adminProfile: AsyncValue.error(e, st));
    }
  }
  //LOGOUT

  Future<void> logout() async {
    await TokenStorage.clear();
    state = const LoginState();
  }

  Future<dynamic> updateAdminProfile(
    File image,
    int adminId,
    String agencyId,
  ) async {
    try {
      state = state.copyWith(isLoading: true);
      final response = await usecase.updateAdminProfile(
        image,
        adminId.toString(),
        agencyId,
      );
      state = state.copyWith(isLoading: false);
      return response;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

Future<dynamic> deleteAdminProfile(Map<String, String> body) async {
    try {
      state = state.copyWith(isLoading: true);
      final response = await usecase.deleteAdminProfile(body);
      state = state.copyWith(isLoading: false);
      return response;
    }
catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }
}