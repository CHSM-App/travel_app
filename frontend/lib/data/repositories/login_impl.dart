import 'dart:io';

import 'package:vego/core/storage/token_storage.dart';
import 'package:vego/data/api/api_service.dart';
import 'package:vego/domain/models/login_info.dart';
import 'package:vego/domain/models/login_response.dart';
import 'package:vego/domain/models/otp_response.dart';
import 'package:vego/domain/repository/login_repo.dart';

class LoginImpl implements LoginRepo {
  final ApiService apiService;

  LoginImpl(this.apiService);
  @override

  Future<LoginResponse> addAdmin(LoginInfo loginInfo) {
    return apiService.addAdmin(loginInfo);
  }


  @override
  Future<LoginResponse> login(LoginInfo loginInfo) async {

    final response = await apiService.login(loginInfo);
      print("LOGIN RESPONSE:");
  print("adminId: ${response.adminId}");
  print("agencyId: ${response.agencyId}");

    // LOGIN SUCCESS -> SAVE TOKEN + USER DATA
    if (response.success == 1) {

      await TokenStorage.saveValue(
          'admin_id', response.adminId?.toString() ?? "");

      await TokenStorage.saveValue(
          'name', response.name ?? "");

      await TokenStorage.saveValue(
          'email', response.email ?? "");

      await TokenStorage.saveValue(
          'mobile', response.mobile ?? "");

      await TokenStorage.saveValue(
          'agency_id', response.agencyId ?? "");
    }

    return response;
  }
@override
  Future<LoginResponse> forgotPassword(LoginInfo loginInfo) {
    return apiService.forgotPassword(loginInfo);
  }

  @override
  Future<OtpResponse> sendOtp(String mobile, String purpose) {
    return apiService.sendOtp({'mobile': mobile, 'purpose': purpose});
  }

  @override
  Future<OtpResponse> verifyOtp(String mobile, String otp, String purpose) {
    return apiService
        .verifyOtp({'mobile': mobile, 'otp': otp, 'purpose': purpose});
  }

  @override
  Future<dynamic> deleteAccount(String mobile, String otp, String? reason) {
    return apiService.deleteAccount({
      'mobile': mobile,
      'otp': otp,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    });
  }

@override
  Future<List<LoginInfo>> adminProfile(int adminId) {
    return apiService.adminProfile(adminId);
  }


  @override
  Future updateAdminProfile(File image, String adminId, String agencyId) {
     return apiService.updateAdminProfile(image,adminId, agencyId);
  }

@override
  Future deleteAdminProfile(Map<String, String> body) {
    return apiService.deleteAdminProfile(body);
  }


}

 
  
