import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Almacenamiento seguro de tokens JWT y datos de usuario autenticado.
///
/// Solo guarda lo estrictamente necesario para reanudar sesión.
class TokenManager {
  static const _accessTokenKey = 'bm_access_token';
  static const _refreshTokenKey = 'bm_refresh_token';
  static const _userKey = 'bm_user';

  final FlutterSecureStorage _storage;

  TokenManager({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);
  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> saveUser(Map<String, dynamic> userJson) async {
    await _storage.write(key: _userKey, value: jsonEncode(userJson));
  }

  Future<Map<String, dynamic>?> getUser() async {
    final raw = await _storage.read(key: _userKey);
    if (raw == null || raw.isEmpty) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<bool> hasValidTokens() async {
    final access = await getAccessToken();
    final refresh = await getRefreshToken();
    return access != null && access.isNotEmpty && refresh != null && refresh.isNotEmpty;
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userKey);
  }
}
