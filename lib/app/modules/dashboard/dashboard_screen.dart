// lib/app/modules/dashboard/dashboard_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:smart_home/app/core/storage/secure_storage.dart';
import 'package:smart_home/app/modules/sites/sites_service.dart';
import 'package:smart_home/app/data/models/site_overview.dart';
import 'package:smart_home/app/theme.dart';
import 'package:smart_home/app/modules/shell/root_scaffold.dart';
import 'package:smart_home/app/widgets/pbd_card.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _siteId;
  String? _jwt;
  String _siteTitle = 'Dashboard'; 
  Future<SiteOverview>? _future;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      _siteId = await SecureStore.instance.read(SecureKeys.selectedSiteId);
      _jwt    = await SecureStore.instance.read(SecureKeys.accessToken);

      if (mounted) setState(() {});
      _refetch();

      // ⏱ 5 сек тутам автоматаар шинэчилнэ
      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(seconds: 5), (_) => _refetch());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _refetch() {
    if (!mounted || _siteId == null || _siteId!.isEmpty) return;
    setState(() {
      _future = Get.find<SitesService>()
          .fetchOverview(_siteId!)
          .then((ov) {
            // Overview ирмэгц гарчгийг site.name болгоно
            if (mounted) {
              setState(() {
                _siteTitle = 'Dashboard • ${ov.siteName}';
              });
            }
            return ov;
          });
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final title = _siteId == null ? 'Dashboard' : 'Dashboard • ${_siteId!.substring(0, 8)}';

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => RootScaffold.openDrawer(context),
          ),
        ),
        title: Text(_siteTitle),
        actions: [
          IconButton(
            tooltip: 'Дахин татах',
            onPressed: _refetch,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Site солих',
            onPressed: () => Get.offAllNamed('/select-site'),
            icon: const Icon(Icons.swap_horiz),
          ),
        ],
      ),

      body: _siteId == null
          ? const Center(child: Text('Site сонгогдоогүй байна.'))
          : FutureBuilder<SiteOverview>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting && snap.data == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return _ErrorView(message: '${snap.error}', onRetry: _refetch);
                }

                final ov = snap.data!;

                return RefreshIndicator(
                  onRefresh: () async => _refetch(),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      // --- Edge / Site карт
                      Container(
                        decoration: BoxDecoration(
                          color: tokens.surfaceCard,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: tokens.accent.withOpacity(.18),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(Icons.home_outlined),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(ov.siteName, style: Theme.of(context).textTheme.titleMedium),
                                  Text(
                                    ov.address?.isNotEmpty == true ? ov.address! : 'Хаяг байхгүй',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Edge: ${ov.edge?.edgeId ?? '—'}',
                                    style: Theme.of(context).textTheme.labelSmall),
                                const SizedBox(height: 6),
                                _StatusChip(text: ov.edge?.status ?? '—', ok: ov.edge?.status == 'online'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      _DashboardHeader(
                        outsideTemp: ov.weather?.tempC ?? 0,
                        humidity: ov.weather?.humidity ?? 0,
                        weatherTemp: (ov.weather?.tempC ?? 0).round(),
                        windSpeed: (ov.weather?.windSpeedMs ?? 0).round(),
                        rainProb: (ov.weather?.rainProb ?? 0).round(),
                        ),

                      const SizedBox(height: 12),
                    
                        // ListView children дотор (Latest sensors-оос дээш):
                       if (_siteId != null && _jwt != null) ...[
                          const SizedBox(height: 12),
                       PbdCard(
                                baseUrl: "https://api.habea.mn",
                                siteId: _siteId!,
                                jwt: _jwt!,
                                height: 300,
                              ),

                        ],

                      // --- Хураангуй статистик (Rooms/Devices)
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'Rooms',
                              value: ov.rooms.toString(),
                              icon: Icons.meeting_room_outlined,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              label: 'Devices',
                              value: ov.devices.toString(),
                              icon: Icons.devices_other_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                   
                      // --- Сүүлийн мэдрэгчүүд
                      Container(
                        decoration: BoxDecoration(
                          color: tokens.surfaceCard,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Latest sensors', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            if (ov.latest.isEmpty)
                              const Text('Мэдрэгчийн өгөгдөл алга.')
                            else
                              ...ov.latest.map(
                                (e) => ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text('${e.deviceKey} • ${e.type ?? 'custom'}'),
                                  subtitle: Text(e.ts.toLocal().toString().split('.').first),
                                  trailing: Text(
                                    e.value.toString(),
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

/* ------------------------ Widgets ------------------------ */

class _DashboardHeader extends StatelessWidget {
  final double outsideTemp;
  final double humidity;
  final int weatherTemp;
  final int windSpeed; // м/с
  final int rainProb;  // %

  const _DashboardHeader({
    required this.outsideTemp,
    required this.humidity,
    required this.weatherTemp,
    required this.windSpeed,
    required this.rainProb,
  });
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = cs.surfaceContainerHighest.withOpacity(0.15);

    return Column(
      children: [
        // 2 том KPI
        Row(
          children: [
            Expanded(
              child: _KpiCard.big(
                label: 'Гадна температур',
                value: '${outsideTemp.toStringAsFixed(1)}°C',
                icon: Icons.thermostat_outlined,
                iconColor: const Color(0xFFFFA24C),
                background: bg,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard.big(
                label: 'Чийгшил',
                value: '${humidity.toStringAsFixed(1)}%',
                icon: Icons.water_drop_outlined,
                iconColor: const Color(0xFFFF8A3D),
                background: bg,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 3 жижиг KPI-ийг нэг strip дотор
        _InlineInfoCard(items: [
          _InlineItem(icon: Icons.cloud_outlined,    label: 'Цаг агаар',       value: '$weatherTemp°C'),
          _InlineItem(icon: Icons.air_outlined,      label: 'Салхины хурд',    value: '$windSpeedм/с'),
          _InlineItem(icon: Icons.umbrella_outlined, label: 'Тунадас магадлал', value: '$rainProb%'),
        ]),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool compact;
  final Color? iconColor;
  final Color? background;

  const _KpiCard._({
    required this.label,
    required this.value,
    required this.icon,
    required this.compact,
    this.iconColor,
    this.background,
  });

  factory _KpiCard.big({
    required String label,
    required String value,
    required IconData icon,
    Color? iconColor,
    Color? background,
  }) =>
      _KpiCard._(
        label: label,
        value: value,
        icon: icon,
        compact: false,
        iconColor: iconColor,
        background: background,
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: background ?? cs.surfaceContainerHighest.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(.25), width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: (iconColor ?? cs.secondary).withOpacity(.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: iconColor ?? cs.secondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: cs.onSurface.withOpacity(.75),
                    letterSpacing: .2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: .3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Inline strip карт (3 багц нэг контейнерт) ────────────────────────────────

class _InlineItem {
  final IconData icon;
  final String label;
  final String value;
  const _InlineItem({required this.icon, required this.label, required this.value});
}

class _InlineInfoCard extends StatelessWidget {
  final List<_InlineItem> items;
  const _InlineInfoCard({required this.items});

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final divider = Container(
      width: 1,
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.white.withOpacity(.06),
    );

    return Container(
      decoration: BoxDecoration(
        color: tokens.surfaceCard,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            Expanded(child: _InlineInfoItem(item: items[i])),
            if (i != items.length - 1) divider,
          ],
        ],
      ),
    );
  }
}

class _InlineInfoItem extends StatelessWidget {
  final _InlineItem item;
  const _InlineInfoItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white.withOpacity(.7),
        );
    final valueStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: tokens.accent.withOpacity(.18),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Icon(item.icon, size: 18),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: labelStyle),
              const SizedBox(height: 2),
              Text(item.value, style: valueStyle),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Бусад жижиг widget-үүд ───────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return Container(
      decoration: BoxDecoration(
        color: tokens.surfaceCard,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: tokens.accent.withOpacity(.18),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              Text(value, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String text;
  final bool ok;
  const _StatusChip({required this.text, required this.ok});

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final bg = ok ? tokens.success.withOpacity(.18) : Colors.red.withOpacity(.18);
    final fg = ok ? tokens.success : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Өгөгдөл авахад алдаа гарлаа.'),
        const SizedBox(height: 8),
        Text(message, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: onRetry, child: const Text('Дахин оролдох')),
      ]),
    );
  }
}
