// lib/app/modules/auth/auth_service.dart
import 'dart:convert';

import '../../core/config/endpoints.dart';
import '../../core/network/http_client.dart';
import '../../core/storage/secure_storage.dart';

class AuthService {
  final ApiClient _api;
  AuthService(this._api);

  Future<String?> login({
    required String phone,
    required String password,
  }) async {
    final data = await _api.postJson<Map<String, dynamic>>(
      ApiPaths.login,
      {'phone': phone, 'password': password},
      withAuth: false, // access токенгүй үе
    );

    if (data['ok'] != true) {
      return (data['error'] ?? 'login_failed').toString();
    }

    final access  = data['access_token'] as String?;
    final refresh = data['refresh_token'] as String?;
    final sid     = data['session_id'] as String?;
    final user    = data['user'] as Map<String, dynamic>?;

    if (access != null && access.isNotEmpty) {
      await SecureStore.instance.write(SecureKeys.accessToken, access);
    }
    if (refresh != null && refresh.isNotEmpty) {
      await SecureStore.instance.write(SecureKeys.refreshToken, refresh);
    }
    if (sid != null && sid.isNotEmpty) {
      await SecureStore.instance.write(SecureKeys.sessionId, sid);
    }
    if (user != null) {
      await SecureStore.instance.write(
        SecureKeys.userJson,
        jsonEncode(user),
      );
    }

    return null;
  }

  Future<bool> me() async {
    final data = await _api.getJson<Map<String, dynamic>>(ApiPaths.me);
    if (data['ok'] == true) {
      await SecureStore.instance.write(
        SecureKeys.userJson,
        jsonEncode(data['user']),
      );
      await SecureStore.instance.write(
        SecureKeys.households,
        jsonEncode(data['households'] ?? []),
      );
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    final sid = await SecureStore.instance.read(SecureKeys.sessionId);
    try {
      await _api.postJson(ApiPaths.logout, {'session_id': sid});
    } catch (_) {/* ignore */}
    await SecureStore.instance.clearAuth();
  }
}
