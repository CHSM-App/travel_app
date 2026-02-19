
import 'package:travel_agency_app/domain/models/token_response.dart';
import 'package:travel_agency_app/domain/repository/auth_repo.dart';

class AuthUseCase {
  final AuthRepository authRepository;
  AuthUseCase(this.authRepository);

  Future<TokenResponse> login(TokenResponse token) {
    return authRepository.createLogin(token);
  }
  Future<TokenResponse> refreshAccessToken(TokenResponse refreshToken) {
    return authRepository.refreshAccessToken(refreshToken);
  }
    
}