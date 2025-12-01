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

  // Floors
  bool _loadingFloors = true;
  String? _floorsError;
  List<FloorItem> _floors = const [];
  String? _selectedFloorId;

  // Devices (энэ давхрынх)
  List<Map<String, dynamic>> _devices = [];

  // 3D PBD controller
  final PbdCardController _pbdCtrl = PbdCardController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      _siteId = await SecureStore.instance.read(SecureKeys.selectedSiteId);
      _jwt = await SecureStore.instance.read(SecureKeys.accessToken);

      if (_siteId != null && _siteId!.isNotEmpty) {
        _refetchOverview();
        _loadFloors();
      }

      if (mounted) setState(() {});
      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(seconds: 5), (_) {
        _loadDevices();
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _refetchOverview() {
    final siteId = _siteId;
    if (!mounted || siteId == null || siteId.isEmpty) return;
    setState(() {
      _futureOverview =
          Get.find<SitesService>().fetchOverview(siteId).then((ov) {
        if (mounted) {
          _siteTitle = 'Dashboard • ${ov.siteName}';
        }
        return ov;
      });
    });
  }

  Future<void> _loadFloors() async {
    final siteId = _siteId;
    if (siteId == null || siteId.isEmpty) return;
    try {
      setState(() {
        _loadingFloors = true;
        _floorsError = null;
      });

      final list = await ApiClient.I.getFloors(siteId); // [{id,name,order}]
      final items = list
          .map<FloorItem>(
            (m) => FloorItem(
              id: m['id'] as String,
              name: (m['name'] as String?)?.trim().isNotEmpty == true
                  ? m['name'] as String
                  : 'Floor',
              order: (m['order'] as num?)?.toInt() ?? 0,
            ),
          )
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));

      setState(() {
        _floors = items;
        _selectedFloorId ??=
            items.isNotEmpty ? items.first.id : null; // default floor
        _loadingFloors = false;
      });

      await _loadDevices();
    } catch (e) {
      setState(() {
        _loadingFloors = false;
        _floorsError = e.toString();
      });
      debugPrint('getFloors err: $e');
    }
  }

  Future<void> _loadDevices() async {
    final siteId = _siteId;
    final fid = _selectedFloorId;
    if (!mounted || siteId == null || siteId.isEmpty || fid == null) return;

    try {
      final list = await ApiClient.I.getDevicesByFloor(siteId, fid);
      setState(() {
        _devices = list;
      });

      // 3D дээрх pin-үүдийг шинэчилнэ
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
              _loadFloors();
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
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return _ErrorView(
                    message: '${snap.error}',
                    onRetry: () {
                      _refetchOverview();
                      _loadFloors();
                    },
                  );
                }

                final ov = snap.data!;
                return Stack(
                  children: [
                    RefreshIndicator(
                      onRefresh: () async {
                        _refetchOverview();
                        await _loadFloors();
                      },
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        children: [
                          const SizedBox(height: 12),
                          _DashboardHeader(
                            outsideTemp: ov.weather?.tempC ?? 0,
                            humidity: ov.weather?.humidity ?? 0,
                            weatherTemp: (ov.weather?.tempC ?? 0).round(),
                            windSpeed:
                                (ov.weather?.windSpeedMs ?? 0).round(),
                            rainProb:
                                (ov.weather?.rainProb ?? 0).round(),
                          ),
                          const SizedBox(height: 12),

                          if (_jwt != null) ...[
                            if (_loadingFloors) ...[
                              const LinearProgressIndicator(minHeight: 2),
                              const SizedBox(height: 8),
                            ] else if (_floorsError != null) ...[
                              Text(
                                'Алдаа: $_floorsError',
                                style: const TextStyle(
                                    color: Colors.redAccent),
                              ),
                              TextButton(
                                onPressed: _loadFloors,
                                child: const Text('Дахин ачаалах'),
                              ),
                              const SizedBox(height: 8),
                            ] else ...[
                              if (_floors.isNotEmpty)
                                PbdFloorSelector(
                                  floors: _floors,
                                  selectedFloorId: _selectedFloorId,
                                  onChanged: _onFloorChanged,
                                ),
                              const SizedBox(height: 8),

                              if (_selectedFloorId != null)
                                PbdCard(
                                  key: ValueKey(
                                      'pbd-${_selectedFloorId!}'),
                                  baseUrl: "https://api.habea.mn",
                                  siteId: _siteId!,
                                  floorId: _selectedFloorId,
                                  jwt: _jwt!,
                                  height: 400,
                                  controller: _pbdCtrl,
                                  devices: _devices,
                                )
                              else
                                const Text('Давхар олдсонгүй.'),
                              const SizedBox(height: 120),
                            ],
                          ],
                        ],
                      ),
                    ),

                    // Доод талаас дээш драглагдах төхөөрөмжийн картууд
                    if (_selectedFloorId != null)
                      _DevicesSheet(devices: _devices),
                  ],
                );
              },
            ),
    );
  }
}

/* ------------------------ Devices Draggable Sheet ------------------------ */

class _DevicesSheet extends StatefulWidget {
  final List<Map<String, dynamic>> devices;

  const _DevicesSheet({required this.devices});

  @override
  State<_DevicesSheet> createState() => _DevicesSheetState();
}

class _DevicesSheetState extends State<_DevicesSheet> {
  /// null = All, бусад үед roomId
  String? _selectedRoomId;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final allDevices = widget.devices;

    // Тухайн давхарт device-тэй өрөөнүүд (давхардалгүй)
    final rooms = _buildRoomsFromDevices(allDevices);

    // Шүүлтүүртэй төхөөрөмжийн жагсаалт
    final filteredDevices = _selectedRoomId == null
        ? allDevices
        : allDevices
            .where(
              (d) =>
                  d['roomId'] != null && d['roomId'] == _selectedRoomId,
            )
            .toList();

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
              ),
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
              _RoomChipsBar(
                rooms: rooms,
                selectedRoomId: _selectedRoomId,
                onChanged: (roomId) {
                  setState(() {
                    _selectedRoomId = roomId;
                  });
                },
              ),
              _DevicesListSliver(devices: filteredDevices),
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

class _RoomTab {
  final String id;
  final String name;
  const _RoomTab({required this.id, required this.name});
}

// devices-ээс roomId/roomName-ийг гаргаж List<_RoomTab> болгоно
List<_RoomTab> _buildRoomsFromDevices(
    List<Map<String, dynamic>> devices) {
  final Map<String, _RoomTab> map = {};
  for (final d in devices) {
    final roomId = d['roomId'] as String?;
    if (roomId == null) continue;

    final rawName = (d['roomName'] as String?) ?? '';
    final name =
        rawName.trim().isNotEmpty ? rawName.trim() : 'Room';

    map.putIfAbsent(roomId, () => _RoomTab(id: roomId, name: name));
  }
  return map.values.toList();
}

class _RoomChipsBar extends StatelessWidget {
  final List<_RoomTab> rooms;
  final String? selectedRoomId;
  final ValueChanged<String?> onChanged;

  const _RoomChipsBar({
    required this.rooms,
    required this.selectedRoomId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: Wrap(
          spacing: 8,
          runSpacing: -4,
          children: [
            _RoomChip(
              label: 'All',
              selected: selectedRoomId == null,
              onTap: () => onChanged(null),
            ),
            for (final r in rooms)
              _RoomChip(
                label: r.name,
                selected: selectedRoomId == r.id,
                onTap: () => onChanged(r.id),
              ),
          ],
        ),
      ),
    );
  }
}

class _RoomChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RoomChip({
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: selected,
      onSelected: (_) => onTap(),
      label: Text(label),
      showCheckmark: false,
      selectedColor: const Color(0xFF0EA5A4).withOpacity(.22),
    );
  }
}


/// Нэг төхөөрөмж = нэг карт
class _DevicesListSliver extends StatelessWidget {
  final List<Map<String, dynamic>> devices;

  const _DevicesListSliver({
    required this.devices,
  });

  @override
  Widget build(BuildContext context) {
    if (devices.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Энэ давхарт төхөөрөмж алга байна.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (ctx, index) {
          final d = devices[index];
          final name = (d['label'] as String?)?.trim().isNotEmpty == true
              ? d['label'] as String
              : (d['name'] as String?) ?? 'Device';
          final domain = (d['domain'] as String?) ?? '';
          final isOn = (d['isOn'] as bool?) ?? false;
          final sensors = (d['sensors'] as List<dynamic>?)
                  ?.cast<Map<String, dynamic>>() ??
              const <Map<String, dynamic>>[];

          switch (domain) {
            case 'light':
              return _LightDeviceCard(
                name: name,
                isOn: isOn,
                brightness: _findBrightness(sensors),
              );

            case 'switch':
            case 'outlet':
              return _SwitchDeviceCard(
                name: name,
                isOn: isOn,
              );

            case 'climate':
              return _ClimateThermostatCard(
                name: name,
                isOn: isOn,
                setpoint: _findSetpoint(sensors),
                temperature: _findTemperature(sensors),
                humidity: _findHumidity(sensors),
                battery: _findBattery(sensors),
              );

            case 'sensor':
            default:
              return _SensorDeviceCard(
                name: name,
                metrics: _buildSensorMetrics(sensors),
              );
          }
        },
        childCount: devices.length,
      ),
    );
  }

  /* ---------- helper функцууд (latestSensor-оос утга авах) ---------- */

  static double? _findTemperature(List<Map<String, dynamic>> sensors) {
    final s = sensors.firstWhere(
      (e) =>
          (e['entityKey'] as String?)?.contains('current_temperature') ==
              true ||
          (e['entityKey'] as String?)?.contains('temperature') == true ||
          (e['haEntityId'] as String?)?.contains('temperature') == true,
      orElse: () => {},
    );
    final v = s['value'];
    return v is num ? v.toDouble() : null;
  }

  static double? _findHumidity(List<Map<String, dynamic>> sensors) {
    final s = sensors.firstWhere(
      (e) =>
          (e['entityKey'] as String?)?.contains('humidity') == true ||
          (e['haEntityId'] as String?)?.contains('humidity') == true,
      orElse: () => {},
    );
    final v = s['value'];
    return v is num ? v.toDouble() : null;
  }

  static double? _findBattery(List<Map<String, dynamic>> sensors) {
    final s = sensors.firstWhere(
      (e) =>
          (e['entityKey'] as String?)?.contains('battery') == true ||
          (e['haEntityId'] as String?)?.contains('battery') == true,
      orElse: () => {},
    );
    final v = s['value'];
    return v is num ? v.toDouble() : null;
  }

  static double? _findSetpoint(List<Map<String, dynamic>> sensors) {
    // setpoint / target / Heat_Temperature г.м түлхүүрүүдийг шалгана
    final s = sensors.firstWhere(
      (e) {
        final key = (e['entityKey'] as String?) ?? '';
        if (key.contains('setpoint')) return true;
        if (key.contains('target_temperature')) return true;
        if (key.toLowerCase().contains('heat_temperature')) return true;
        return false;
      },
      orElse: () => {},
    );
    final v = s['value'];
    return v is num ? v.toDouble() : null;
  }

  static double _findBrightness(List<Map<String, dynamic>> sensors) {
    final s = sensors.firstWhere(
      (e) =>
          (e['entityKey'] as String?)?.contains('brightness') == true ||
          (e['haEntityId'] as String?)?.contains('brightness') == true,
      orElse: () => {},
    );
    final v = s['value'];
    if (v is num) return v.toDouble().clamp(0, 100);
    return 0;
  }

  static List<_SensorMetric> _buildSensorMetrics(
      List<Map<String, dynamic>> sensors) {
    final List<_SensorMetric> out = [];
    for (final s in sensors) {
      final key = (s['entityKey'] as String?) ?? '';
      final unit = (s['unit'] as String?) ?? '';
      final value = s['value'];

      if (value is! num) continue;

      IconData icon;
      String label;

      if (key.contains('temperature')) {
        icon = Icons.thermostat_outlined;
        label = 'Температур';
      } else if (key.contains('humidity')) {
        icon = Icons.water_drop_outlined;
        label = 'Чийгшил';
      } else if (key.contains('battery')) {
        icon = Icons.battery_std;
        label = 'Battery';
      } else if (key.toLowerCase().contains('pressure')) {
        icon = Icons.speed;
        label = 'Даралт';
      } else if (key.toLowerCase().contains('lqi')) {
        icon = Icons.network_check;
        label = 'LQI';
      } else {
        icon = Icons.sensors;
        label = key;
      }

      out.add(
        _SensorMetric(
          icon: icon,
          label: label,
          value: '${value.toStringAsFixed(1)} $unit',
        ),
      );
    }
    return out;
  }
}


/* ------------------------ 1) LIGHT CARD ------------------------ */

class _LightDeviceCard extends StatelessWidget {
  final String name;
  final bool isOn;
  final double brightness;

  const _LightDeviceCard({
    required this.name,
    required this.isOn,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    return _DeviceBaseCard(
      title: name,
      trailing: Switch(
        value: isOn,
        onChanged: (_) {}, // TODO: команд илгээх
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.lightbulb_outline),
              const SizedBox(width: 8),
              const Text('Brightness'),
              const SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: brightness,
                  min: 0,
                  max: 100,
                  onChanged: (_) {}, // TODO
                ),
              ),
              Text('${brightness.toStringAsFixed(0)}%'),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

/* ------------------------ 2) SWITCH / OUTLET CARD ------------------------ */

class _SwitchDeviceCard extends StatelessWidget {
  final String name;
  final bool isOn;

  const _SwitchDeviceCard({
    required this.name,
    required this.isOn,
  });

  @override
  Widget build(BuildContext context) {
    return _DeviceBaseCard(
      title: name,
      trailing: Switch(
        value: isOn,
        onChanged: (_) {}, // TODO
      ),
    );
  }
}

/* ------------------------ 3) CLIMATE (THERMOSTAT) CARD ------------------------ */

class _ClimateThermostatCard extends StatelessWidget {
  final String name;
  final bool isOn;
  final double? setpoint;
  final double? temperature;
  final double? humidity;
  final double? battery;

  const _ClimateThermostatCard({
    required this.name,
    required this.isOn,
    this.setpoint,
    this.temperature,
    this.humidity,
    this.battery,
  });

  @override
  Widget build(BuildContext context) {
    final sp = setpoint ?? 22.0;

    return _DeviceBaseCard(
      title: name,
      subtitle: 'Thermostat',
      trailing: Switch(
        value: isOn,
        onChanged: (_) {}, // TODO
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          const Text(
            'Setpoint',
            style: TextStyle(fontSize: 12, color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: sp,
                  min: 5,
                  max: 35,
                  onChanged: (_) {}, // TODO
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${sp.toStringAsFixed(1)}°C',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (temperature != null) ...[
                const Icon(Icons.thermostat_outlined, size: 16),
                const SizedBox(width: 4),
                Text('${temperature!.toStringAsFixed(1)}°C',
                    style: const TextStyle(fontSize: 12)),
              ],
              if (humidity != null) ...[
                const SizedBox(width: 16),
                const Icon(Icons.water_drop_outlined, size: 16),
                const SizedBox(width: 4),
                Text('${humidity!.toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 12)),
              ],
              if (battery != null) ...[
                const SizedBox(width: 16),
                const Icon(Icons.battery_std, size: 16),
                const SizedBox(width: 4),
                Text('${battery!.toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 12)),
              ],
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

/* ------------------------ 4) SENSOR CARD ------------------------ */

class _SensorMetric {
  final IconData icon;
  final String label;
  final String value;

  const _SensorMetric({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _SensorDeviceCard extends StatelessWidget {
  final String name;
  final List<_SensorMetric> metrics;

  const _SensorDeviceCard({
    required this.name,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    return _DeviceBaseCard(
      title: name,
      subtitle: metrics.isEmpty ? 'Мэдрэгчийн дата алга байна.' : null,
      trailing: const Icon(Icons.chevron_right),
      child: Column(
        children: [
          for (final m in metrics) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(m.icon, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    m.label,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                Text(
                  m.value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

/* ------------------------ Суурь картын wrapper ------------------------ */

class _DeviceBaseCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? child;

  const _DeviceBaseCard({
    required this.title,
    this.subtitle,
    this.trailing,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF17181B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withOpacity(.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt, size: 18, color: Colors.amber.shade300),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: Colors.white70),
            ),
          ],
          if (child != null) ...[
            const SizedBox(height: 8),
            child!,
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
  final int windSpeed;
  final int rainProb;

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
        _InlineInfoCard(
          items: [
            _InlineItem(
              icon: Icons.cloud_outlined,
              label: 'Цаг агаар',
              value: '$weatherTemp°C',
            ),
            _InlineItem(
              icon: Icons.air_outlined,
              label: 'Салхины хурд',
              value: '$windSpeedм/с',
            ),
            _InlineItem(
              icon: Icons.umbrella_outlined,
              label: 'Тунадас магадлал',
              value: '$rainProb%',
            ),
          ],
        ),
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
  const _InlineItem({
    required this.icon,
    required this.label,
    required this.value,
  });
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
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: labelStyle,
              ),
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
