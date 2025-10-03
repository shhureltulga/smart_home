// lib/app/modules/sites/sites_controller.dart
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

  @override
  void onInit() {
    super.onInit();
    load(); // эхлэхдээ ачааллах
  }

  /// Site жагсаалт татах
  Future<void> load() async {
    loading.value = true;
    error.value = '';
    try {
      final hid = _resolveHouseholdId(Get.find<AuthController>());
      final list = await _service.fetchSites(householdId: hid);
      sites.assignAll(list);
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  /// Site сонгох
  Future<void> onSelect(Site s) async {
    await SecureStore.instance.write(SecureKeys.selectedSiteId, s.id);
    Get.offAllNamed('/main');
  }

  /// Аль household-оор дуудах вэ — одоохондоо эхний идэвхтэйг авна
  String _resolveHouseholdId(AuthController auth) {
    // Танай `me()`-ийн өгөгдөл: households = [{role, household:{id,name}}]
    final list = auth.households;
    if (list.isEmpty) throw 'household хоосон байна';
    final first = (list.first as Map)['household'] as Map;
    final hid = (first['id'] ?? '').toString();
    if (hid.isEmpty) throw 'householdId олдсонгүй';
    return hid;
  }
}
