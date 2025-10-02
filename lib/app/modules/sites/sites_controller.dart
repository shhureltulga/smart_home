import 'package:get/get.dart';
import 'package:smart_home/app/core/storage/secure_storage.dart';
import 'package:smart_home/app/data/models/site.dart';
import 'package:smart_home/app/modules/auth/auth_controller.dart';
import 'package:smart_home/app/modules/sites/sites_service.dart';

class SitesController extends GetxController {
  final SitesService _service;
  SitesController(this._service);

  final RxBool loading = false.obs;
  final RxString error = ''.obs;
  final RxList<Site> sites = <Site>[].obs;

  late final AuthController auth;

  @override
  void onInit() {
    super.onInit();
    auth = Get.find<AuthController>();
    loadSites();
  }

  Future<void> loadSites() async {
    loading.value = true;
    error.value = '';
    try {
      final hid = _resolveHouseholdId(); // <-- параметргүй болгов
      if (hid.isEmpty) {
        error.value = 'householdId олдсонгүй';
        sites.clear();
        return;
      }

      final list = await _service.fetchSites(householdId: hid);
      sites.assignAll(list);
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  /// AuthController-д буусан /me-ийн өгөгдлөөс эхний household ID-г гаргана.
  String _resolveHouseholdId() {
    try {
      final hs = auth.households; // энэ нь List<dynamic>
      if (hs.isEmpty) return '';

      final first = hs.first;
      if (first is Map) {
        // API: [{ role, household: { id, name } }]
        final hh = first['household'];
        if (hh is Map && hh['id'] is String) {
          return hh['id'] as String;
        }
        // fallback: [{ id, name, ... }]
        if (first['id'] is String) {
          return first['id'] as String;
        }
      }
      return '';
    } catch (_) {
      return '';
    }
  }

  /// Сонгосон site-ийг хадгалаад dashboard руу шилжинэ.
  Future<void> onSelect(Site s) async {
    await SecureStore.instance.write(SecureKeys.selectedSiteId, s.id);
    Get.offAllNamed('/dashboard');
  }
}
