

import 'package:travel_agency_app/domain/models/login_info.dart';
import 'package:travel_agency_app/domain/models/login_response.dart';


abstract class LoginRepo {
  Future<LoginResponse> addAdmin(LoginInfo loginInfo);


  Future<LoginResponse> login(LoginInfo loginInfo);
  Future<LoginResponse> forgotPassword(LoginInfo loginInfo);
  Future<List<LoginInfo>> adminProfile(int adminId);
}