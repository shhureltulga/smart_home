// lib/app/core/storage/secure_storage.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Аппын дотор ашиглах түлхүүрүүд (локал аюулгүй хадгалалт)
class SecureKeys {
  static const accessToken   = 'access_token';
  static const refreshToken  = 'refresh_token';
  static const sessionId     = 'session_id';
  static const userJson      = 'user_json';
  static const households    = 'households_json';
  static const selectedSiteId= 'selected_site_id'; // ← НЭМЭЛТ
}

class SecureStore {
  SecureStore._();
  static final SecureStore instance = SecureStore._();

  static const _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );

  static const _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
  );

  final _storage = const FlutterSecureStorage(
    aOptions: _androidOptions,
    iOptions: _iosOptions,
  );

  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> delete(String key) => _storage.delete(key: key);

  /// Нэвтэрсэнтэй холбоотой бүх токен/кешийг цэвэрлэнэ
  Future<void> clearAuth() async {
    await _storage.delete(key: SecureKeys.accessToken);
    await _storage.delete(key: SecureKeys.refreshToken);
    await _storage.delete(key: SecureKeys.sessionId);
    await _storage.delete(key: SecureKeys.userJson);
    await _storage.delete(key: SecureKeys.households);
    await _storage.delete(key: SecureKeys.selectedSiteId); // ← сонгосон site-ийг ч цэвэрлэе
  }
}
