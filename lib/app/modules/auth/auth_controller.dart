import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/api_client.dart';

class AuthController extends GetxController {
  final ApiClient api;
  AuthController(this.api);

  final phone = ''.obs;
  final password = ''.obs;
  final isLoading = false.obs;
  final _storage = const FlutterSecureStorage();

  Future<bool> login() async {
    isLoading.value = true;
    try {
      final res = await api.post('/auth/login', {
        'phone': phone.value,
        'password': password.value,
      });
      await _storage.write(key: 'access', value: res['access_token']);
      await _storage.write(key: 'refresh', value: res['refresh_token']);
      await _storage.write(key: 'session_id', value: res['session_id']);
      return true;
    } catch (_) {
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    final sid = await _storage.read(key: 'session_id');
    try {
      if (sid != null) {
        await api.post('/auth/logout', {'session_id': sid}, withAuth: true);
      }
    } catch (_) {}
    await _storage.deleteAll();
  }
}
