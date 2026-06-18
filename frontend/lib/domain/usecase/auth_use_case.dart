
import 'package:vego/domain/models/token_response.dart';
import 'package:vego/domain/repository/auth_repo.dart';

class AuthUseCase {
  final AuthRepository authRepository;
  AuthUseCase(this.authRepository);

  Future<TokenResponse> createLogin(TokenResponse token) {
    return authRepository.createLogin(token);
  }

  Future<TokenResponse> refreshAccessToken(TokenResponse refreshToken) {
    return authRepository.refreshAccessToken(refreshToken);
  }

   Future<TokenResponse> logout(TokenResponse refreshToken) {
      return authRepository.logout(refreshToken);
 }
    
}