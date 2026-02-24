import 'dart:io';

import 'package:travel_agency_app/core/storage/token_storage.dart';
import 'package:travel_agency_app/data/api/api_service.dart';
import 'package:travel_agency_app/domain/models/login_info.dart';
import 'package:travel_agency_app/domain/models/login_response.dart';
import 'package:travel_agency_app/domain/repository/login_repo.dart';

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
  Future<List<LoginInfo>> adminProfile(int adminId) {
    return apiService.adminProfile(adminId);
  }


  @override
  Future updateAdminProfile(File image, String adminId, String agencyId) {
     return apiService.updateAdminProfile(image,adminId, agencyId);
  }




}

 
  
