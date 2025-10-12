// lib/app/modules/sites/select_site_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:smart_home/app/modules/sites/sites_controller.dart';

import 'package:smart_home/app/widgets/app_scaffold.dart';
import 'package:smart_home/app/widgets/async_view.dart';
import 'package:smart_home/app/widgets/site_tile.dart';

class SelectSiteScreen extends StatelessWidget {
  const SelectSiteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<SitesController>();

    return Obx(() {
      final isLoading = c.loading.value;
      final hasError  = c.error.value.isNotEmpty;

   return AppScaffold(
  title: 'Site сонгох',
  actions: [
    IconButton(
      tooltip: 'Сэргээх',
      onPressed: isLoading ? null : c.load,
      icon: isLoading
          ? const SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.refresh),
    ),
  ],
  child: AsyncView(
    loading: isLoading,
    error: hasError ? c.error.value : null,
    isEmpty: !isLoading && !hasError && c.sites.isEmpty,
    emptyText: 'Танд харагдах Site алга.',
    // onRetry: c.load,  <-- УСТГАСАН
    child: RefreshIndicator(
      onRefresh: () async => c.load(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        itemCount: c.sites.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final s = c.sites[i];
          return SiteTile(
            site: s,
            onTap: () => c.onSelect(s),
          );
        },
      ),
    ),
  ),
);
    });
  }
}
