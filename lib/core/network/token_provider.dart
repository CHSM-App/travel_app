import 'package:flutter_riverpod/legacy.dart';
import 'package:travel_agency_app/core/storage/token_storage.dart';

class TokenState {
  final String? accessToken;
  final String? refreshToken;

  const TokenState({this.accessToken, this.refreshToken});

  bool get isLoggedIn => accessToken != null && refreshToken != null;

  TokenState copyWith({
    String? accessToken,
    String? refreshToken,
  }) {
    return TokenState(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
    );
  }
}

class TokenNotifier extends StateNotifier<TokenState> {
  TokenNotifier() : super(const TokenState());

  /// Load saved tokens at app start
  Future<void> loadTokens() async {
    final tokens = await TokenStorage.getTokens();
    if (tokens != null) {
      state = TokenState(
        accessToken: tokens['accessToken'],
        refreshToken: tokens['refreshToken'],
      );
    }
  }

  /// Save new tokens
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    state = TokenState(accessToken: accessToken, refreshToken: refreshToken);
    await TokenStorage.saveTokens(accessToken, refreshToken);
  }

  /// Clear tokens and trigger logout
  Future<void> clearTokens() async {
    state = const TokenState();
    await TokenStorage.clear();
  }
}

final tokenProvider =
    StateNotifierProvider<TokenNotifier, TokenState>((ref) => TokenNotifier());
