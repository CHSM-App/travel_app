


import 'dart:io';

import 'package:vego/domain/models/login_info.dart';
import 'package:vego/domain/models/login_response.dart';
import 'package:vego/domain/models/otp_response.dart';
import 'package:vego/domain/repository/login_repo.dart';

class LoginUseCase {
  final LoginRepo loginRepo;

  LoginUseCase(this.loginRepo);
  

  Future<LoginResponse> addAdmin(LoginInfo loginInfo) {
    return loginRepo.addAdmin(loginInfo);
  }
  Future<LoginResponse> login(LoginInfo loginInfo) {
    return loginRepo.login(loginInfo);
  } 
  Future<LoginResponse> forgotPassword(LoginInfo loginInfo) {
    return loginRepo.forgotPassword(loginInfo);
  }
  Future<OtpResponse> sendOtp(String mobile, String purpose) {
    return loginRepo.sendOtp(mobile, purpose);
  }
  Future<OtpResponse> verifyOtp(String mobile, String otp, String purpose) {
    return loginRepo.verifyOtp(mobile, otp, purpose);
  }
  Future<dynamic> deleteAccount(String mobile, String otp, String? reason) {
    return loginRepo.deleteAccount(mobile, otp, reason);
  }
  Future<List<LoginInfo>> adminProfile(int adminId) {
    return loginRepo.adminProfile(adminId);
  }
    Future<dynamic> updateAdminProfile(File image, String adminId, String agencyId) {
    return loginRepo.updateAdminProfile(image, adminId, agencyId);
  }
  Future<dynamic> deleteAdminProfile(Map<String, String> body) {
    return loginRepo.deleteAdminProfile(body);
  }




}