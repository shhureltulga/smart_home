// lib/app/widgets/device_sections/climate_section.dart
import 'package:flutter/material.dart';

/// Энгийн мэдрэгчийн мөр
class ClimateItem {
  final IconData icon;
  final String label;
  final String value;
  const ClimateItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}

/// Паарны термостатын өгөгдөл
class ClimateThermostatData {
  final String name;
  final double? currentTemp;
  final double targetTemp;
  final String? hvacAction; // heating / idle / off гэх мэт

  const ClimateThermostatData({
    required this.name,
    this.currentTemp,
    required this.targetTemp,
    this.hvacAction,
  });
}

/// Нэг том "Climate • Sensors" карт дотор
///  - эхэнд нь Thermostat control-ууд
///  - доор нь мэдрэгчийн жагсаалт
class ClimateSection extends StatelessWidget {
  final String subtitle;
  final List<ClimateThermostatData> thermostats;
  final List<ClimateItem> sensors;

  const ClimateSection({
    super.key,
    required this.subtitle,
    this.thermostats = const [],
    this.sensors = const [],
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
              Icon(Icons.electric_bolt,
                  size: 18, color: Colors.amber.shade300),
            const SizedBox(width: 8),
              Text('Climate • Sensors',
                  style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Icon(Icons.chevron_right, color: Colors.white.withOpacity(.5)),
            ],
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.white.withOpacity(.7),
                  ),
            ),
          ],
          const SizedBox(height: 10),

          // ---- Thermostat control tiles ----
          for (final t in thermostats) ...[
            _ThermostatTile(data: t),
            const SizedBox(height: 8),
          ],

          // ---- Sensor rows ----
          for (final s in sensors) ...[
            _SensorRow(item: s),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}

class _ThermostatTile extends StatefulWidget {
  final ClimateThermostatData data;
  const _ThermostatTile({required this.data});

  @override
  State<_ThermostatTile> createState() => _ThermostatTileState();
}

class _ThermostatTileState extends State<_ThermostatTile> {
  late double _targetTemp;

  @override
  void initState() {
    super.initState();
    _targetTemp = widget.data.targetTemp;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // ⛔ radiator байхгүй тул device_thermostat ашиглая
              const Icon(Icons.device_thermostat, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.data.name,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Text(
                widget.data.currentTemp != null
                    ? '${widget.data.currentTemp!.toStringAsFixed(1)}°C'
                    : '—',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('Setpoint',
                  style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(width: 8),
              Text(
                '${_targetTemp.toStringAsFixed(1)}°C',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const Spacer(),
              if (widget.data.hvacAction != null)
                Text(
                  widget.data.hvacAction!,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: Colors.white70),
                ),
            ],
          ),
          Slider(
            value: _targetTemp,
            onChanged: (v) {
              setState(() => _targetTemp = v);
              // TODO: энд паарны setpoint-ыг өөрчлөх команд явуулна
            },
            min: 15,
            max: 30,
          ),
        ],
      ),
    );
  }
}

class _SensorRow extends StatelessWidget {
  final ClimateItem item;
  const _SensorRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(item.icon),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.label,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          Text(
            item.value,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
