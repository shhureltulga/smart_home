// lib/app/modules/auth/auth_controller.dart
import 'dart:convert';
import 'package:get/get.dart';

import '../../core/storage/secure_storage.dart';
import 'auth_service.dart';

class AuthController extends GetxController {
  final AuthService _service;
  AuthController(this._service);

  /// UI төлөвүүд
  final RxBool loading = false.obs;
  final RxString error = ''.obs;

  /// Кэшлэгдсэн өгөгдөл
  final RxBool loggedIn = false.obs;
  final RxMap<String, dynamic> user = <String, dynamic>{}.obs;
  final RxList<dynamic> households = <dynamic>[].obs;

  @override
  void onInit() {
    super.onInit();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final token = await SecureStore.instance.read(SecureKeys.accessToken);
    loggedIn.value = token?.isNotEmpty == true;

    final u = await SecureStore.instance.read(SecureKeys.userJson);
    if (u != null && u.isNotEmpty) {
      user.assignAll(jsonDecode(u) as Map<String, dynamic>);
    }
    final h = await SecureStore.instance.read(SecureKeys.households);
    if (h != null && h.isNotEmpty) {
      households.assignAll(jsonDecode(h) as List<dynamic>);
    }
  }

  /// Нэвтрэх. Амжилттай бол `null`, алдаа бол мессеж буцаана.
  Future<String?> login(String phone, String password) async {
    loading.value = true;
    error.value = '';
    try {
      final err = await _service.login(phone: phone, password: password);
      if (err != null) {
        error.value = err;
        return err;
      }
      // Амжилттай → /me татаж локал кэшийг шинэчилнэ
      await _service.me();
      await _bootstrap(); // state-ээ сэргээе
      return null;
    } finally {
      loading.value = false;
    }
  }

  /// /me дахин татах (жишээ нь app resume үед)
  Future<void> refreshMe() async {
    loading.value = true;
    try {
      final ok = await _service.me();
      if (ok) {
        final u = await SecureStore.instance.read(SecureKeys.userJson);
        final h = await SecureStore.instance.read(SecureKeys.households);
        if (u != null && u.isNotEmpty) {
          user.assignAll(jsonDecode(u) as Map<String, dynamic>);
        }
        if (h != null && h.isNotEmpty) {
          households.assignAll(jsonDecode(h) as List<dynamic>);
        }
        loggedIn.value = true;
      }
    } finally {
      loading.value = false;
    }
  }

  /// Гарах
  Future<void> logout() async {
    loading.value = true;
    try {
      await _service.logout();
      loggedIn.value = false;
      user.clear();
      households.clear();
    } finally {
      loading.value = false;
    }
  }

  /// Эхний идэвхтэй household-ийн ID (Flutter талд Site жагсаалт авахад хэрэглэнэ)
  Future<String?> getHouseholdId() async {
    final raw = await SecureStore.instance.read(SecureKeys.households);
    if (raw == null || raw.isEmpty) return null;
    try {
      final List list = jsonDecode(raw) as List;
      if (list.isEmpty) return null;
      final Map first = list.first as Map;
      // backend формат 1: { role, household: { id, name } }
      if (first['household'] is Map && first['household']['id'] is String) {
        return first['household']['id'] as String;
      }
      // формат 2: [{ id, name }]
      if (first['id'] is String) return first['id'] as String;
      return null;
    } catch (_) {
      return null;
    }
  }
}
