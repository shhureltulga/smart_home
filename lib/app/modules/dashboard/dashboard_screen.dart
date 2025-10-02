// lib/app/modules/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_home/app/core/storage/secure_storage.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? siteId;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final sid = await SecureStore.instance.read(SecureKeys.selectedSiteId);
      setState(() => siteId = sid);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(siteId == null ? 'Dashboard' : 'Dashboard • $siteId'),
        actions: [
          IconButton(
            tooltip: 'Site солих',
            onPressed: () => Get.offAllNamed('/select-site'),
            icon: const Icon(Icons.swap_horiz),
          )
        ],
      ),
      body: const Center(child: Text('Edge статус, сүүлийн уншилтуудыг энд харуулна.')),
    );
  }
}
