

import 'dart:io';

import 'package:travel_agency_app/domain/models/login_info.dart';
import 'package:travel_agency_app/domain/models/login_response.dart';
import 'package:travel_agency_app/domain/models/otp_response.dart';


abstract class LoginRepo {
  Future<LoginResponse> addAdmin(LoginInfo loginInfo);


  Future<LoginResponse> login(LoginInfo loginInfo);
  Future<LoginResponse> forgotPassword(LoginInfo loginInfo);
  Future<OtpResponse> sendOtp(String mobile, String purpose);
  Future<OtpResponse> verifyOtp(String mobile, String otp, String purpose);
  Future<dynamic> deleteAccount(String mobile, String otp, String? reason);
  Future<List<LoginInfo>> adminProfile(int adminId);
    Future<dynamic> updateAdminProfile(File image, String adminId, String agencyId);
    Future<dynamic> deleteAdminProfile(Map<String, String> body);

}