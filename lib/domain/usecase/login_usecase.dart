


import 'dart:io';

import 'package:travel_agency_app/domain/models/login_info.dart';
import 'package:travel_agency_app/domain/models/login_response.dart';
import 'package:travel_agency_app/domain/repository/login_repo.dart';

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
  Future<List<LoginInfo>> adminProfile(int adminId) {
    return loginRepo.adminProfile(adminId);
  }
    Future<dynamic> updateAdminProfile(File image, String adminId, String agencyId) {
    return loginRepo.updateAdminProfile(image, adminId, agencyId);
  }

}