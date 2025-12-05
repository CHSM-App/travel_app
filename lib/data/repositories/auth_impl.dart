
import 'package:travel_agency_app/data/api/api_service.dart';
import 'package:travel_agency_app/domain/models/token_response.dart';
import 'package:travel_agency_app/domain/repository/auth_repo.dart';

class AuthImpl implements AuthRepository {
  final ApiService apiService;

  AuthImpl(this.apiService);



  // @override
  // Future<TokenResponse> createLogin(String preMob) {
  //   return apiService.createLogin(preMob);
  // }

  // @override
  // Future<TokenResponse>refreshAccessToken(String refreshToken) {
  //   return apiService.refreshAccessToken(refreshToken);
  // }
}