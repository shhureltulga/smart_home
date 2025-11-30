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
import 'package:smart_home/app/widgets/pbd_floor_selector.dart';
import 'package:smart_home/app/data/api_client.dart'; // ApiClient.I

// 🔌 Картын widget-ууд
import 'package:smart_home/app/widgets/device_sections/climate_section.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _siteId;
  String? _jwt;
  String _siteTitle = 'Dashboard';
  Future<SiteOverview>? _futureOverview;
  Timer? _ticker;

  // -------- Floors + devices --------
  bool _loadingFloors = true;
  String? _floorsErr;
  List<FloorItem> _floors = const [];
  String? _selectedFloorId;

  /// Энэ давхрын төхөөрөмжүүд (API → getDevicesByFloor)
  List<Map<String, dynamic>> _devices = [];

  /// Device.id → LatestSensor map
  Map<String, Map<String, dynamic>> _latestByDeviceId = {};

  // 3D viewer controller
  final PbdCardController _pbdCtrl = PbdCardController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      _siteId =
          await SecureStore.instance.read(SecureKeys.selectedSiteId);
      _jwt = await SecureStore.instance.read(SecureKeys.accessToken);

      if (!mounted) return;
      setState(() {});

      _refetchOverview();
      _loadFloors();

      // ⏱ 5 сек тутам overview + devices дахин татна
      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(seconds: 5), (_) {
        _refetchOverview();
        _loadDevices();
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  // -------- Site overview --------
  void _refetchOverview() {
    if (!mounted || _siteId == null || _siteId!.isEmpty) return;
    setState(() {
      _futureOverview = Get.find<SitesService>()
          .fetchOverview(_siteId!)
          .then((ov) {
        if (mounted) {
          setState(() {
            _siteTitle = 'Dashboard • ${ov.siteName}';
          });
        }
        return ov;
      });
    });
  }

  // -------- Floors + devices --------
  Future<void> _loadFloors() async {
    if (_siteId == null) return;
    try {
      setState(() {
        _loadingFloors = true;
        _floorsErr = null;
      });

      final list = await ApiClient.I.getFloors(_siteId!);
      final items = list
          .map<FloorItem>((m) => FloorItem(
                id: m['id'] as String,
                name: (m['name'] as String?)?.trim().isNotEmpty == true
                    ? m['name'] as String
                    : 'Floor',
                order: (m['order'] as num?)?.toInt() ?? 0,
              ))
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));

      setState(() {
        _floors = items;
        _selectedFloorId ??=
            items.isNotEmpty ? items.first.id : null;
        _loadingFloors = false;
      });

      await _loadDevices();
    } catch (e) {
      setState(() {
        _loadingFloors = false;
        _floorsErr = e.toString();
      });
      debugPrint('getFloors err: $e');
    }
  }

  Future<void> _loadDevices() async {
    if (_siteId == null || _selectedFloorId == null) return;

    try {
      final list =
          await ApiClient.I.getDevicesByFloor(_siteId!, _selectedFloorId!);

      // Backend-аас device бүр дээр LatestSensor-г `latest` field-ээр
      // явуулдаг гэж үзэж байна. (хэрвээ үгүй бол backend дээрээ
      // join хийж өгөх хэрэгтэй.)
      final latestMap = <String, Map<String, dynamic>>{};
      for (final d in list) {
        final id = d['id'] as String?;
        final latest = d['latest'];
        if (id != null && latest is Map<String, dynamic>) {
          latestMap[id] = latest;
        }
      }

      setState(() {
        _devices = List<Map<String, dynamic>>.from(list);
        _latestByDeviceId = latestMap;
      });

      _pbdCtrl.setDevices?.call(_devices);
    } catch (e) {
      debugPrint('getDevicesByFloor err: $e');
    }
  }

  void _onFloorChanged(String id) {
    setState(() => _selectedFloorId = id);
    _loadDevices();
    debugPrint('Floor changed -> $id');
  }

  @override
  Widget build(BuildContext context) {
    final title = _siteId == null
        ? 'Dashboard'
        : 'Dashboard • ${_siteId!.substring(0, 8)}';

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => RootScaffold.openDrawer(context),
          ),
        ),
        title: Text(_siteTitle.isNotEmpty ? _siteTitle : title),
        actions: [
          IconButton(
            tooltip: 'Дахин татах',
            onPressed: () {
              _refetchOverview();
              _loadDevices();
            },
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
              future: _futureOverview,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting &&
                    snap.data == null) {
                  return const Center(
                      child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return _ErrorView(
                    message: '${snap.error}',
                    onRetry: () {
                      _refetchOverview();
                      _loadDevices();
                    },
                  );
                }

                final ov = snap.data!;

                // Ар талд overview + 3D, урд талд draggable devices sheet
                return Stack(
                  children: [
                    RefreshIndicator(
                      onRefresh: () async {
                        _refetchOverview();
                        await _loadDevices();
                      },
                      child: _OverviewBody(
                        ov: ov,
                        siteId: _siteId!,
                        jwt: _jwt,
                        floors: _floors,
                        selectedFloorId: _selectedFloorId,
                        loadingFloors: _loadingFloors,
                        floorsErr: _floorsErr,
                        pbdCtrl: _pbdCtrl,
                        devices: _devices,
                        onReloadFloors: _loadFloors,
                        onFloorChanged: _onFloorChanged,
                      ),
                    ),
                    _DevicesSheet(
                      devices: _devices,
                      latestByDeviceId: _latestByDeviceId,
                    ),
                  ],
                );
              },
            ),
    );
  }
}

/* ------------------------ Overview (ар тал) ------------------------ */

class _OverviewBody extends StatelessWidget {
  final SiteOverview ov;
  final String siteId;
  final String? jwt;
  final List<FloorItem> floors;
  final String? selectedFloorId;
  final bool loadingFloors;
  final String? floorsErr;
  final PbdCardController pbdCtrl;
  final List<Map<String, dynamic>> devices;
  final VoidCallback onReloadFloors;
  final ValueChanged<String> onFloorChanged;

  const _OverviewBody({
    required this.ov,
    required this.siteId,
    required this.jwt,
    required this.floors,
    required this.selectedFloorId,
    required this.loadingFloors,
    required this.floorsErr,
    required this.pbdCtrl,
    required this.devices,
    required this.onReloadFloors,
    required this.onFloorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 12),
        _DashboardHeader(
          outsideTemp: ov.weather?.tempC ?? 0,
          humidity: ov.weather?.humidity ?? 0,
          weatherTemp: (ov.weather?.tempC ?? 0).round(),
          windSpeed: (ov.weather?.windSpeedMs ?? 0).round(),
          rainProb: (ov.weather?.rainProb ?? 0).round(),
        ),
        const SizedBox(height: 12),

        if (jwt != null) ...[
          if (loadingFloors) ...[
            const LinearProgressIndicator(minHeight: 2),
            const SizedBox(height: 8),
          ] else if (floorsErr != null) ...[
            Text(
              'Алдаа: $floorsErr',
              style: const TextStyle(color: Colors.redAccent),
            ),
            TextButton(
              onPressed: onReloadFloors,
              child: const Text('Дахин ачаалах'),
            ),
            const SizedBox(height: 8),
          ] else ...[
            if (floors.isNotEmpty)
              PbdFloorSelector(
                floors: floors,
                selectedFloorId: selectedFloorId,
                onChanged: onFloorChanged,
              ),
            const SizedBox(height: 8),

            if (selectedFloorId != null)
              PbdCard(
                key: ValueKey('pbd-$selectedFloorId'),
                baseUrl: "https://api.habea.mn",
                siteId: siteId,
                floorId: selectedFloorId,
                jwt: jwt!,
                height: 400,
                controller: pbdCtrl,
                devices: devices,
              )
            else
              const Text('Давхар олдсонгүй.'),
            const SizedBox(height: 120),
          ],
        ],
      ],
    );
  }
}

/* ------------------------ Draggable Devices Sheet (урд тал) ------------------------ */

class _DevicesSheet extends StatelessWidget {
  final List<Map<String, dynamic>> devices;
  final Map<String, Map<String, dynamic>> latestByDeviceId;

  const _DevicesSheet({
    super.key,
    required this.devices,
    required this.latestByDeviceId,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.12,
      minChildSize: 0.12,
      maxChildSize: 0.92,
      snap: true,
      snapSizes: const [0.12, 0.45, 0.92],
      builder: (ctx, scroll) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF141517),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(18)),
            boxShadow: [
              BoxShadow(
                blurRadius: 18,
                color: Colors.black.withOpacity(.45),
              )
            ],
            border: Border(
              top: BorderSide(
                color: cs.outlineVariant.withOpacity(.25),
              ),
            ),
          ),
          child: CustomScrollView(
            controller: scroll,
            slivers: [
              const _SheetHandle(),
              const _RoomChipsBar(),
              _DevicesListSliver(
                devices: devices,
                latestByDeviceId: latestByDeviceId,
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 28)),
            ],
          ),
        );
      },
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();
  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 10),
        child: Center(
          child: Container(
            width: 42,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.18),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoomChipsBar extends StatelessWidget {
  const _RoomChipsBar();
  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: Wrap(
          spacing: 8,
          runSpacing: -4,
          children: [
            _chip('All', selected: true),
            _chip('Зочны өрөө'),
            _chip('Гал тогоо'),
            _chip('Унтлагын'),
          ],
        ),
      ),
    );
  }

  static Widget _chip(String text, {bool selected = false}) {
    return FilterChip(
      selected: selected,
      onSelected: (_) {},
      label: Text(text),
      showCheckmark: false,
      selectedColor: const Color(0xFF0EA5A4).withOpacity(.22),
    );
  }
}

/// Нэг төхөөрөмж = нэг карт
class _DevicesListSliver extends StatelessWidget {
  final List<Map<String, dynamic>> devices;
  final Map<String, Map<String, dynamic>> latestByDeviceId;

  const _DevicesListSliver({
    required this.devices,
    required this.latestByDeviceId,
  });

  @override
  Widget build(BuildContext context) {
    if (devices.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Энэ давхарт төхөөрөмж алга байна.'),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final d = devices[index];
          final id = d['id'] as String? ?? '';
          final domain = (d['domain'] as String?) ?? '';
          final label =
              (d['label'] as String?) ??
              (d['name'] as String?) ??
              'Төхөөрөмж';
          final latest = latestByDeviceId[id];

          switch (domain) {
            case 'climate':
              // Паарны термостат
              final tData = ClimateThermostatData(
                name: label,
                currentTemp:
                    (latest?['temperature'] as num?)?.toDouble(),
                targetTemp: ((latest?['setpoint'] ??
                            latest?['occupied_heating_setpoint'] ??
                            latest?['target_temp']) as num? ??
                        22)
                    .toDouble(),
                hvacAction: latest?['hvac_action'] as String?,
              );
              return ClimateSection(
                subtitle: 'Thermostat',
                thermostats: [tData],
                sensors: _sensorItemsFromLatest(latest),
              );

            default:
              // Ердийн sensor / coordinator гэх мэт
              return _SensorDeviceCard(
                name: label,
                latest: latest,
              );
          }
        },
        childCount: devices.length,
      ),
    );
  }
}

/// LatestSensor → ClimateItem list (темп, чийг, CO₂, даралт, LQI, батерей)
List<ClimateItem> _sensorItemsFromLatest(
    Map<String, dynamic>? latest) {
  if (latest == null) return const [];

  final List<ClimateItem> out = [];

  void addIfPresent(
    String key,
    IconData icon,
    String label,
    String suffix,
  ) {
    final v = latest[key];
    if (v == null) return;
    num? n;
    if (v is num) {
      n = v;
    } else if (v is String) {
      n = num.tryParse(v);
    }
    final valueStr =
        n != null ? '${n.toString()}$suffix' : '$v$suffix';
    out.add(ClimateItem(icon: icon, label: label, value: valueStr));
  }

  addIfPresent('temperature', Icons.thermostat_outlined, 'Темп.', '°C');
  addIfPresent('humidity', Icons.water_drop_outlined, 'Чийгшил', '%');
  addIfPresent('co2', Icons.co2, 'CO₂', ' ppm');
  addIfPresent('pressure', Icons.speed, 'Даралт', ' hPa');
  addIfPresent('battery', Icons.battery_full, 'Батерей', '%');
  addIfPresent('lqi', Icons.network_wifi, 'LQI', '');

  return out;
}

/// Энгийн sensor төхөөрөмжийн карт
class _SensorDeviceCard extends StatelessWidget {
  final String name;
  final Map<String, dynamic>? latest;

  const _SensorDeviceCard({
    required this.name,
    this.latest,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = _sensorItemsFromLatest(latest);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF17181B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withOpacity(.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sensors, size: 18, color: Colors.amber),
              const SizedBox(width: 8),
              Text(
                name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Icon(Icons.chevron_right,
                  color: Colors.white.withOpacity(.5)),
            ],
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Text(
              'Мэдрэгчийн дата алга байна.',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: Colors.white70),
            )
          else
            for (final it in items) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(it.icon, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      it.label,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  Text(
                    it.value,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
        ],
      ),
    );
  }
}

/* ------------------------ Header/KPI/Stat ------------------------ */

class _DashboardHeader extends StatelessWidget {
  final double outsideTemp;
  final double humidity;
  final int weatherTemp;
  final int windSpeed; // м/с
  final int rainProb; // %

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
        _InlineInfoCard(items: [
          _InlineItem(
              icon: Icons.cloud_outlined,
              label: 'Цаг агаар',
              value: '$weatherTemp°C'),
          _InlineItem(
              icon: Icons.air_outlined,
              label: 'Салхины хурд',
              value: '$windSpeedм/с'),
        _InlineItem(
              icon: Icons.umbrella_outlined,
              label: 'Тунадас магадлал',
              value: '$rainProb%'),
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
        border:
            Border.all(color: cs.outlineVariant.withOpacity(.25), width: 1),
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

class _InlineItem {
  final IconData icon;
  final String label;
  final String value;
  const _InlineItem(
      {required this.icon, required this.label, required this.value});
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
    final valueStyle =
        Theme.of(context).textTheme.titleMedium?.copyWith(
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
              Text(item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: labelStyle),
              const SizedBox(height: 2),
              Text(item.value, style: valueStyle),
            ],
          ),
        ),
      ],
    );
  }
}

/* ------------------------ Site/Edge card + Error view ------------------------ */

class _SiteEdgeCard extends StatelessWidget {
  final SiteOverview ov;
  const _SiteEdgeCard({required this.ov});
  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return Container(
      decoration: BoxDecoration(
        color: tokens.surfaceCard,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
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
              Text(ov.siteName,
                  style: Theme.of(context).textTheme.titleMedium),
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
            _StatusChip(
              text: ov.edge?.status ?? '—',
              ok: ov.edge?.status == 'online',
            ),
          ],
        ),
      ]),
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
    final bg =
        ok ? tokens.success.withOpacity(.18) : Colors.red.withOpacity(.18);
    final fg = ok ? tokens.success : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontWeight: FontWeight.w600),
      ),
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
        OutlinedButton(
          onPressed: onRetry,
          child: const Text('Дахин оролдох'),
        ),
      ]),
    );
  }
}
