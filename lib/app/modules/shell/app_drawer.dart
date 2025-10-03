import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/storage/secure_storage.dart';
import '../auth/auth_controller.dart';
import 'capabilities.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final user = auth.user;
    final role = (user['role'] ?? 'member').toString(); // одоогоор mock

    Widget item({
      required String code,
      required IconData icon,
      required String text,
      VoidCallback? onTap,
    }) {
      if (!Capabilities.allow(role, code)) return const SizedBox.shrink();
      return ListTile(
        leading: Icon(icon),
        title: Text(text),
        onTap: onTap,
      );
    }

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(user['displayName']?.toString() ?? 'Миний мэдээлэл'),
              subtitle: FutureBuilder(
                future: SecureStore.instance.read(SecureKeys.selectedSiteId),
                builder: (_, snap) => Text(snap.data?.toString() ?? 'Өрөө/тоот'),
              ),
            ),
            const Divider(),

            item(code:'usage',   icon: Icons.home_work_outlined, text:'Орон сууцны ашиглалт', onTap: (){}),
            item(code:'call',    icon: Icons.support_agent_outlined, text:'Дуудлага өгөх', onTap: (){}),
            item(code:'gate',    icon: Icons.vpn_key_outlined, text:'Орон сууц руу нэвтрэх', onTap: (){}),
            item(code:'car',     icon: Icons.local_taxi_outlined, text:'Машин бүртгэх', onTap: (){}),
            item(code:'devices', icon: Icons.memory_outlined, text:'Төхөөрөмжүүд', onTap: (){}),
            item(code:'terms',   icon: Icons.description_outlined, text:'Үйлчилгээний нөхцөл', onTap: (){}),
            item(code:'settings',icon: Icons.settings_outlined, text:'Тохиргоо', onTap: (){}),

            const Spacer(),
            const Divider(),

            item(
              code:'logout',
              icon: Icons.logout,
              text:'Системээс гарах',
              onTap: () async {
                await Get.find<AuthController>().logout();
                // бүх локал сонголт арилгах
                await SecureStore.instance.clearAuth();
                if (context.mounted) {
                  Get.offAllNamed('/login');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
