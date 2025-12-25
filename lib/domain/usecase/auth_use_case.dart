
import 'package:travel_agency_app/domain/repository/auth_repo.dart';

class AuthUseCase {
  final AuthRepository authRepository;
  AuthUseCase(this.authRepository);

  // Future<TokenResponse> login(TokenResponse token) {
  //   return authRepository.createLogin(token);
  // }
  // Future<TokenResponse> refreshAccessToken(TokenResponse refreshToken) {
  //   return authRepository.refreshAccessToken(refreshToken);
  // }
  //   Future<TokenResponse> logout(TokenResponse refreshToken) {
  //     return authRepository.logout(refreshToken);
  //   }
}