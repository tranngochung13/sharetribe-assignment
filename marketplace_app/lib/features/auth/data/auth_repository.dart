import '../../../core/storage/token_storage.dart';
import 'auth_service.dart';

class AuthRepository {
  final AuthService authService;
  final TokenStorage tokenStorage;

  AuthRepository({required this.authService, required this.tokenStorage});

  Future<void> login({required String email, required String password}) async {
    final token = await authService.login(email: email, password: password);

    await tokenStorage.saveTokens(
      accessToken: token.accessToken,
      refreshToken: token.refreshToken,
    );
  }

  Future<bool> isAuthenticated() async {
    final token = await tokenStorage.getAccessToken();

    return token != null && token.isNotEmpty;
  }

  Future<void> logout() {
    return tokenStorage.clear();
  }
}
