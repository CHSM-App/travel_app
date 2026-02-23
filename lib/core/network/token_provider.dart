import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/core/storage/token_storage.dart';

class TokenState {
  final String? accessToken;
  final String? refreshToken;
  final bool isLoading;

  const TokenState({this.accessToken, this.refreshToken, this.isLoading = true});

  bool get isLoggedIn =>
      accessToken != null &&
      accessToken!.isNotEmpty &&
      refreshToken != null &&
      refreshToken!.isNotEmpty;

  TokenState copyWith({
    String? accessToken,
    String? refreshToken,
    bool? isLoading,
  }) {
    return TokenState(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class TokenNotifier extends StateNotifier<TokenState> {
  TokenNotifier() : super(const TokenState());

  Future<void> loadTokens() async {
    final tokens = await TokenStorage.getTokens();

    if (tokens != null &&
        (tokens['accessToken'] ?? '').isNotEmpty &&
        (tokens['refreshToken'] ?? '').isNotEmpty) {
      state = TokenState(
        accessToken: tokens['accessToken'],
        refreshToken: tokens['refreshToken'],
        isLoading: false,
      );
      return;
    }

    state = const TokenState(isLoading: false);
  }

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    state = TokenState(
      accessToken: accessToken,
      refreshToken: refreshToken,
      isLoading: false,
    );
    await TokenStorage.saveTokens(accessToken, refreshToken);
  }

  Future<void> clearTokens() async {
    state = const TokenState(isLoading: false);
    await TokenStorage.clear();
  }
}

final tokenProvider =
    StateNotifierProvider<TokenNotifier, TokenState>((ref) => TokenNotifier());
