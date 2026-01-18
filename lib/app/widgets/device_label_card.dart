// lib/app/widgets/device_label_card.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smart_home/app/core/network/http_client.dart';
import 'package:smart_home/app/core/storage/secure_storage.dart';
import 'package:smart_home/app/widgets/camera_device_card.dart';

import 'async_view.dart';


typedef DeviceActionCallback = Future<void> Function(
  Map<String, dynamic> device,
  String action,
  dynamic value,
);

class DeviceLabelCard extends StatelessWidget {
  final Map<String, dynamic> device;
  final DeviceActionCallback? onAction;

  const DeviceLabelCard({
    super.key,
    required this.device,
    this.onAction,
  });

  String _resolveEdgeBaseUrl(Map<String, dynamic> d) {
    final direct = (d['edgeBaseUrl'] as String?)?.trim();
    if (direct != null && direct.isNotEmpty) return direct;

    final ip = (d['edgeIp'] as String?)?.trim();
    if (ip != null && ip.isNotEmpty) return 'http://$ip:4000';

    return 'http://192.168.24.128:4000';
  }

  @override
  Widget build(BuildContext context) {
    final labelRaw = (device['label'] as String?) ?? '';
    final label = labelRaw.trim().toLowerCase();

    final domain = ((device['domain'] as String?) ?? '').trim().toLowerCase();

    final name = ((device['name'] as String?) ?? '').trim().isNotEmpty
        ? ((device['name'] as String?) ?? '').trim()
        : (labelRaw.trim().isNotEmpty ? labelRaw.trim() : 'Device');

    final isOn = (device['isOn'] as bool?) ?? false;
    final sensors = (device['sensors'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>() ??
        const <Map<String, dynamic>>[];

    final edgeBaseUrl = _resolveEdgeBaseUrl(device);

    switch (label) {
      case 'thermometer':
        return ThermometerDeviceCard(name: name, sensors: sensors);

      case 'thermostate':
        return ThermostatDeviceCard(
          name: name,
          isOn: isOn,
          sensors: sensors,
          onToggle: (value) => onAction?.call(device, 'set_power', value),
          onSetpointChanged: (value) =>
              onAction?.call(device, 'set_setpoint', value),
        );

      case 'motion':
        return MotionDeviceCard(name: name, sensors: sensors);

      case 'door':
        return DoorDeviceCard(name: name, sensors: sensors);

      case 'camera': {
        final camId = DeviceMetrics.findCameraEntityId(device);
        if (camId != null) {
          return CameraDeviceCard(
            title: name,     // ✅ title
            entityId: camId, // ✅ camera.xxx
            // edgeBaseUrl: edgeBaseUrl, // хүсвэл нэмж болно
          );
        }
        return GenericDomainDeviceCard(
          name: name,
          domain: domain,
          isOn: isOn,
          sensors: sensors,
        );
      }


      case 'climate':
        return ThermostatDeviceCard(name: name, isOn: isOn, sensors: sensors);

      case 'coordinator':
        return CoordinatorDeviceCard(name: name);

      default:
        if (domain == 'camera') {
          final camId = DeviceMetrics.findCameraEntityId(device);
          if (camId != null) {
            return CameraDeviceCard(
              title: name,
              entityId: camId,
              // edgeBaseUrl: edgeBaseUrl,
              // preloadLive: false, // хүсвэл true
            );

          }
        }
        return GenericDomainDeviceCard(
          name: name,
          domain: domain,
          isOn: isOn,
          sensors: sensors,
        );
    }
  }
}



/* -------------------- Нийтэд ашиглах суурь карт -------------------- */

class DeviceBaseCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? child;

  const DeviceBaseCard({
    super.key,
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

/* -------------------- Thermometer карт -------------------- */

class ThermometerDeviceCard extends StatelessWidget {
  final String name;
  final List<Map<String, dynamic>> sensors;

  const ThermometerDeviceCard({
    super.key,
    required this.name,
    required this.sensors,
  });

  @override
  Widget build(BuildContext context) {
    final temp = DeviceMetrics.findTemperature(sensors);
    final hum = DeviceMetrics.findHumidity(sensors);
    final pressure = DeviceMetrics.findPressure(sensors);
    final battery = DeviceMetrics.findBattery(sensors);
    final voltage = DeviceMetrics.findVoltage(sensors);

    Widget row(String label, String? value, {IconData? icon}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: Colors.white70),
              const SizedBox(width: 6),
            ],
            Text(label,
                style:
                    const TextStyle(color: Colors.white70, fontSize: 13)),
            const Spacer(),
            Text(
              value ?? '--',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return DeviceBaseCard(
      title: name,
      trailing: const Icon(Icons.chevron_right),
      child: Column(
        children: [
          row(
            'Battery',
            battery != null ? '${battery.toStringAsFixed(0)} %' : null,
            icon: Icons.battery_full,
          ),
          row(
            'Температур',
            temp != null ? '${temp.toStringAsFixed(1)} °C' : null,
            icon: Icons.thermostat_outlined,
          ),
          row(
            'Чийгшил',
            hum != null ? '${hum.toStringAsFixed(1)} %' : null,
            icon: Icons.water_drop_outlined,
          ),
          row(
            'Даралт',
            pressure != null ? '${pressure.toStringAsFixed(1)} hPa' : null,
            icon: Icons.speed,
          ),
          row(
            'voltage',
            voltage != null ? '${voltage.toStringAsFixed(0)} mV' : null,
            icon: Icons.swap_vert,
          ),
        ],
      ),
    );
  }
}

/* -------------------- Thermostat карт (thermostate label) -------------------- */

class ThermostatDeviceCard extends StatefulWidget {
  final String name;
  final bool isOn; // эхний ON/OFF төлөв
  final List<Map<String, dynamic>> sensors;

  // main / Dashboard руу команд дамжуулах callback-ууд
  final ValueChanged<bool>? onToggle;             // ON/OFF
  final ValueChanged<double>? onSetpointChanged;  // Setpoint

  const ThermostatDeviceCard({
    super.key,
    required this.name,
    required this.isOn,
    required this.sensors,
    this.onToggle,
    this.onSetpointChanged,
  });

  @override
  State<ThermostatDeviceCard> createState() => _ThermostatDeviceCardState();
}

class _ThermostatDeviceCardState extends State<ThermostatDeviceCard> {
  late bool _isOn;
  late double _setpoint;
  double? _temp;
  double? _hum;
  double? _battery;

  bool _dragging = false; // ✅ NEW

  @override
  void initState() {
    super.initState();
    _isOn = widget.isOn;
    _setpoint = DeviceMetrics.findSetpoint(widget.sensors) ?? 22.0;
    _temp = DeviceMetrics.findTemperature(widget.sensors);
    _hum = DeviceMetrics.findHumidity(widget.sensors);
    _battery = DeviceMetrics.findBattery(widget.sensors);
  }

  // ✅ NEW: parent (_devices) шинэчлэгдэхэд энэ картын state-ийг дагуулж шинэчилнэ
@override
void didUpdateWidget(covariant ThermostatDeviceCard oldWidget) {
  super.didUpdateWidget(oldWidget);

  bool changed = false;

  if (widget.isOn != oldWidget.isOn) {
    _isOn = widget.isOn;
    changed = true;
  }

  if (!identical(widget.sensors, oldWidget.sensors)) {
    _temp = DeviceMetrics.findTemperature(widget.sensors);
    _hum = DeviceMetrics.findHumidity(widget.sensors);
    _battery = DeviceMetrics.findBattery(widget.sensors);

    if (!_dragging) {
      final sp = DeviceMetrics.findSetpoint(widget.sensors);
      if (sp != null) _setpoint = sp;
    }
    changed = true;
  }

  if (changed && mounted) setState(() {});
}


  @override
  Widget build(BuildContext context) {
    return DeviceBaseCard(
      title: widget.name,
      subtitle: 'Thermostat',
      trailing: Switch(
        value: _isOn,
        onChanged: (value) {
          setState(() => _isOn = value);
          widget.onToggle?.call(value);
        },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Setpoint', style: TextStyle(fontSize: 12, color: Colors.white70)),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _setpoint,
                  min: 5,
                  max: 35,
                  onChanged: (value) {
                    _dragging = true;          // ✅ NEW
                    setState(() => _setpoint = value);
                  },
                  onChangeEnd: (value) {
                    _dragging = false;         // ✅ NEW
                    widget.onSetpointChanged?.call(value);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Text('${_setpoint.toStringAsFixed(1)}°C',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (_temp != null) ...[
                const Icon(Icons.thermostat_outlined, size: 16),
                const SizedBox(width: 4),
                Text('${_temp!.toStringAsFixed(1)}°C', style: const TextStyle(fontSize: 12)),
              ],
              if (_hum != null) ...[
                const SizedBox(width: 16),
                const Icon(Icons.water_drop_outlined, size: 16),
                const SizedBox(width: 4),
                Text('${_hum!.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12)),
              ],
              if (_battery != null) ...[
                const SizedBox(width: 16),
                const Icon(Icons.battery_std, size: 16),
                const SizedBox(width: 4),
                Text('${_battery!.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}


/* -------------------- Motion / Door / Coordinator картууд -------------------- */

class MotionDeviceCard extends StatelessWidget {
  final String name;
  final List<Map<String, dynamic>> sensors;

  const MotionDeviceCard({
    super.key,
    required this.name,
    required this.sensors,
  });

  @override
  Widget build(BuildContext context) {
    final state = DeviceMetrics.findBinaryState(sensors) ?? 'off';
    final active =
        state.toLowerCase() == 'on' || state.toLowerCase() == 'motion';

    return DeviceBaseCard(
      title: name,
      subtitle: 'Хөдөлгөөн мэдрэгч',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Хөдөлгөөн',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          Icon(
            active ? Icons.circle : Icons.circle_outlined,
            color: active ? Colors.greenAccent : Colors.white24,
          ),
        ],
      ),
    );
  }
}

class DoorDeviceCard extends StatelessWidget {
  final String name;
  final List<Map<String, dynamic>> sensors;

  const DoorDeviceCard({
    super.key,
    required this.name,
    required this.sensors,
  });

  @override
  Widget build(BuildContext context) {
    final state = DeviceMetrics.findBinaryState(sensors) ?? 'closed';
    final open = state.toLowerCase() == 'open';

    return DeviceBaseCard(
      title: name,
      subtitle: 'Хаалга мэдрэгч',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Төлөв',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: open ? Colors.redAccent : Colors.green,
            ),
            child: Text(
              open ? 'Нээлттэй' : 'Хаалттай',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class CoordinatorDeviceCard extends StatelessWidget {
  final String name;

  const CoordinatorDeviceCard({super.key, required this.name});


  @override
  Widget build(BuildContext context) {
    return DeviceBaseCard(
      title: name,
      subtitle: 'Zigbee coordinator',
      child: const Text(
        'Сүлжээний адаптер. Ихэвчлэн статус / firmware мэдээлэл харах зориулалттай.',
        style: TextStyle(color: Colors.white70, fontSize: 12),
      ),
    );
  }


}


/* -------------------- Domain-д суурилсан ерөнхий fallback -------------------- */

class GenericDomainDeviceCard extends StatelessWidget {
  final String name;
  final String domain;
  final bool isOn;
  final List<Map<String, dynamic>> sensors;

  const GenericDomainDeviceCard({
    super.key,
    required this.name,
    required this.domain,
    required this.isOn,
    required this.sensors,
  });

  @override
  Widget build(BuildContext context) {
    switch (domain) {
      case 'light':
        final brightness = DeviceMetrics.findBrightness(sensors) ?? 0;
        return DeviceBaseCard(
          title: name,
          trailing: Switch(
            value: isOn,
            onChanged: (_) {},
          ),
          child: Row(
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
                  onChanged: (_) {},
                ),
              ),
              Text('${brightness.toStringAsFixed(0)}%'),
            ],
          ),
        );

      case 'switch':
      case 'outlet':
        return DeviceBaseCard(
          title: name,
          trailing: Switch(
            value: isOn,
            onChanged: (_) {},
          ),
        );

      case 'climate':
        return ThermostatDeviceCard(
          name: name,
          isOn: isOn,
          sensors: sensors,
        );

      case 'sensor':
      default:
        final metrics = DeviceMetrics.buildMetricsList(sensors);
        return DeviceBaseCard(
          title: name,
          subtitle:
              metrics.isEmpty ? 'Мэдрэгчийн дата алга байна.' : null,
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
}

/* -------------------- Metrics helper класс -------------------- */

class SensorMetric {
  final IconData icon;
  final String label;
  final String value;

  const SensorMetric({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class DeviceMetrics {
  static double? findTemperature(List<Map<String, dynamic>> sensors) {
    final s = sensors.firstWhere(
      (e) {
        final key = (e['entityKey'] as String?) ?? '';
        final id = (e['haEntityId'] as String?) ?? '';
        return key.contains('current_temperature') ||
            key.contains('temperature') ||
            id.contains('temperature');
      },
      orElse: () => const {},
    );
    final v = s['value'];
    return v is num ? v.toDouble() : null;
  }

  static double? findHumidity(List<Map<String, dynamic>> sensors) {
    final s = sensors.firstWhere(
      (e) {
        final key = (e['entityKey'] as String?) ?? '';
        final id = (e['haEntityId'] as String?) ?? '';
        return key.contains('humidity') || id.contains('humidity');
      },
      orElse: () => const {},
    );
    final v = s['value'];
    return v is num ? v.toDouble() : null;
  }

  static double? findBattery(List<Map<String, dynamic>> sensors) {
    final s = sensors.firstWhere(
      (e) {
        final key = (e['entityKey'] as String?) ?? '';
        final id = (e['haEntityId'] as String?) ?? '';
        return key.contains('battery') || id.contains('battery');
      },
      orElse: () => const {},
    );
    final v = s['value'];
    return v is num ? v.toDouble() : null;
  }

  static double? findPressure(List<Map<String, dynamic>> sensors) {
    final s = sensors.firstWhere(
      (e) {
        final key = (e['entityKey'] as String?)?.toLowerCase() ?? '';
        return key.contains('pressure');
      },
      orElse: () => const {},
    );
    final v = s['value'];
    return v is num ? v.toDouble() : null;
  }

  static double? findVoltage(List<Map<String, dynamic>> sensors) {
    final s = sensors.firstWhere(
      (e) {
        final key = (e['entityKey'] as String?)?.toLowerCase() ?? '';
        return key.contains('voltage');
      },
      orElse: () => const {},
    );
    final v = s['value'];
    return v is num ? v.toDouble() : null;
  }

  static double? findSetpoint(List<Map<String, dynamic>> sensors) {
    final s = sensors.firstWhere(
      (e) {
        final key = (e['entityKey'] as String?) ?? '';
        final lower = key.toLowerCase();
        if (lower.contains('setpoint')) return true;
        if (lower.contains('target_temperature')) return true;
        if (lower.contains('heat_temperature')) return true;
        return false;
      },
      orElse: () => const {},
    );
    final v = s['value'];
    return v is num ? v.toDouble() : null;
  }

  static double? findBrightness(List<Map<String, dynamic>> sensors) {
    final s = sensors.firstWhere(
      (e) {
        final key = (e['entityKey'] as String?) ?? '';
        final id = (e['haEntityId'] as String?) ?? '';
        return key.contains('brightness') || id.contains('brightness');
      },
      orElse: () => const {},
    );
    final v = s['value'];
    return v is num ? v.toDouble().clamp(0, 100) : null;
  }

  static String? findBinaryState(List<Map<String, dynamic>> sensors) {
    final s = sensors.firstWhere(
      (e) {
        final key = (e['entityKey'] as String?)?.toLowerCase() ?? '';
        final id = (e['haEntityId'] as String?)?.toLowerCase() ?? '';
        return key.contains('state') || id.contains('binary') || id.contains('motion');
      },
      orElse: () => const {},
    );
    final v = s['value'];
    return v?.toString();
  }

  static List<SensorMetric> buildMetricsList(
      List<Map<String, dynamic>> sensors) {
    final List<SensorMetric> out = [];
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
        SensorMetric(
          icon: icon,
          label: label,
          value: '${value.toStringAsFixed(1)} $unit',
        ),
      );
    }
    return out;
  }
  static String? findCameraEntityId(Map<String, dynamic> device) {
    // ✅ backend-ээс шууд ирдэг шинэ талбар
    final cid = device['cameraEntityId'] as String?;
    if (cid != null && cid.startsWith('camera.')) return cid;

    // хуучин fallback-ууд байж болно
    final direct = (device['haEntityId'] as String?) ?? (device['entityId'] as String?);
    if (direct != null && direct.startsWith('camera.')) return direct;

    final sensors = (device['sensors'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? const [];
    for (final s in sensors) {
      final id = (s['haEntityId'] as String?) ?? '';
      if (id.startsWith('camera.')) return id;
    }
    return null;
  }


}
