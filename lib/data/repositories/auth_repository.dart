import '../api/api_client.dart';
import '../models/auth_models.dart';
import '../storage/token_manager.dart';

/// Acceso a los endpoints `/api/v1/authentication/*`.
class AuthRepository {
  final ApiClient _api;
  final TokenManager _tokens;

  AuthRepository({required ApiClient api, required TokenManager tokens})
      : _api = api,
        _tokens = tokens;

  /// Registra un atleta. Devuelve el resumen del usuario creado.
  Future<UserSummary> signUpAthlete(SignUpRequest request) async {
    final json = await _api.post(
      '/authentication/sign-up/athlete',
      body: request.toJson(),
      auth: false,
    ) as Map<String, dynamic>;
    return UserSummary.fromJson(json);
  }

  /// Registra un coach. Devuelve el resumen del usuario creado.
  Future<UserSummary> signUpCoach(SignUpRequest request) async {
    final json = await _api.post(
      '/authentication/sign-up/coach',
      body: request.toJson(),
      auth: false,
    ) as Map<String, dynamic>;
    return UserSummary.fromJson(json);
  }

  /// Inicia sesión. Persiste tokens y datos básicos del usuario.
  Future<AuthenticatedUser> signIn(SignInRequest request) async {
    final json = await _api.post(
      '/authentication/sign-in',
      body: request.toJson(),
      auth: false,
    ) as Map<String, dynamic>;
    final user = AuthenticatedUser.fromJson(json);
    await _tokens.saveTokens(
      accessToken: user.accessToken,
      refreshToken: user.refreshToken,
    );
    await _tokens.saveUser(user.toJson());
    return user;
  }

  /// Cierra sesión revocando el refresh-token y limpiando storage.
  Future<void> signOut() async {
    final refresh = await _tokens.getRefreshToken();
    if (refresh != null && refresh.isNotEmpty) {
      try {
        await _api.post(
          '/authentication/sign-out',
          body: {'refreshToken': refresh},
          auth: false,
        );
      } catch (_) {
        // Aun si el backend rechaza la revocación, limpiamos local.
      }
    }
    await _tokens.clear();
  }

  /// Restaura sesión desde storage seguro al iniciar la app.
  Future<AuthenticatedUser?> restoreSession() async {
    final has = await _tokens.hasValidTokens();
    if (!has) return null;
    final stored = await _tokens.getUser();
    if (stored == null) return null;
    try {
      return AuthenticatedUser.fromJson(stored);
    } catch (_) {
      await _tokens.clear();
      return null;
    }
  }
}
