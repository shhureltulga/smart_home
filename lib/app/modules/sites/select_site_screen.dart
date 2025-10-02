// lib/app/modules/sites/select_site_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_home/app/data/models/site.dart';
import 'package:smart_home/app/modules/sites/sites_controller.dart';

class SelectSiteScreen extends StatelessWidget {
  const SelectSiteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<SitesController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Site сонгох')),
      body: Obx(() {
        if (c.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (c.error.value.isNotEmpty) {
          return Center(child: Text('Алдаа: ${c.error.value}'));
        }
        if (c.sites.isEmpty) {
          return const Center(child: Text('Танд харагдах Site алга.'));
        }

        // Жагсаалтаа tile-уудаар харуулна
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: c.sites.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final Site s = c.sites[i];
            return _SiteTile(
              site: s,
              onTap: () => c.onSelect(s),
            );
          },
        );
      }),
    );
  }
}

class _SiteTile extends StatelessWidget {
  final Site site;
  final VoidCallback onTap;
  const _SiteTile({required this.site, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.home_outlined, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(site.name,
                        style: Theme.of(context).textTheme.titleMedium),
                    if (site.address != null && site.address!.isNotEmpty)
                      Text(site.address!,
                          style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
