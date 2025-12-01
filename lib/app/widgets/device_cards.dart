// lib/app/widgets/device_cards.dart
import 'package:flutter/material.dart';

/// Нэг төхөөрөмжийн картын суурь wrapper
class DeviceCardShell extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const DeviceCardShell({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF17181B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant.withOpacity(.15)),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

/// 💡 LIGHT card
class LightDeviceCard extends StatelessWidget {
  final String name;
  final bool isOn;
  final int brightness; // 0–100

  const LightDeviceCard({
    super.key,
    required this.name,
    required this.isOn,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    return DeviceCardShell(
      title: name,
      trailing: Switch(
        value: isOn,
        onChanged: (_) {
          // TODO: light on/off команд
        },
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Brightness',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Text('$brightness%'),
            ],
          ),
          Slider(
            value: brightness.toDouble().clamp(0, 100),
            onChanged: (_) {
              // TODO: brightness команд
            },
            min: 0,
            max: 100,
          ),
        ],
      ),
    );
  }
}

/// 🔌 OUTLET / SWITCH card
class OutletDeviceCard extends StatelessWidget {
  final String name;
  final bool isOn;
  final int? powerW;

  const OutletDeviceCard({
    super.key,
    required this.name,
    required this.isOn,
    this.powerW,
  });

  @override
  Widget build(BuildContext context) {
    return DeviceCardShell(
      title: name,
      trailing: Switch(
        value: isOn,
        onChanged: (_) {
          // TODO: outlet on/off команд
        },
      ),
      child: Row(
        children: [
          const Icon(Icons.power_outlined),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (powerW != null)
                  Text(
                    '$powerW W',
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: Colors.white.withOpacity(.7)),
                  )
                else
                  Text(
                    'Power info not available',
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: Colors.white.withOpacity(.7)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 🌡 CLIMATE / SENSOR card
class ClimateDeviceCard extends StatelessWidget {
  final String name;
  final num? temperature;
  final num? humidity;
  final num? co2;
  final num? setpoint;
  final bool heatingOn;

  const ClimateDeviceCard({
    super.key,
    required this.name,
    this.temperature,
    this.humidity,
    this.co2,
    this.setpoint,
    required this.heatingOn,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chips = <Widget>[];

    if (temperature != null) {
      chips.add(
        ClimateChip(
          icon: Icons.thermostat_outlined,
          label: '${temperature!.toStringAsFixed(1)}°C',
        ),
      );
    }
    if (humidity != null) {
      chips.add(
        ClimateChip(
          icon: Icons.water_drop_outlined,
          label: '${humidity!.toStringAsFixed(0)}%',
        ),
      );
    }
    if (co2 != null) {
      chips.add(
        ClimateChip(
          icon: Icons.co2,
          label: '${co2!.toStringAsFixed(0)} ppm',
        ),
      );
    }

    final sp = setpoint ?? temperature;

    return DeviceCardShell(
      title: name,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            heatingOn ? Icons.local_fire_department : Icons.ac_unit,
            size: 20,
            color: heatingOn ? Colors.orangeAccent : Colors.lightBlueAccent,
          ),
          const SizedBox(width: 8),
          Switch(
            value: heatingOn,
            onChanged: (_) {
              // TODO: heating on/off команд
            },
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (sp != null) ...[
            Text(
              'Setpoint',
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: Colors.white.withOpacity(.7)),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '${sp.toStringAsFixed(1)}°C',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.tune),
                  onPressed: () {
                    // TODO: thermostat тохиргооны bottom sheet
                  },
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: chips,
          ),
        ],
      ),
    );
  }
}

class ClimateChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const ClimateChip({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

/// 🧩 Бусад төрөл (domain танигдаагүй) – generic card
class GenericDeviceCard extends StatelessWidget {
  final String name;
  final String domain;
  final bool isOn;

  const GenericDeviceCard({
    super.key,
    required this.name,
    required this.domain,
    required this.isOn,
  });

  @override
  Widget build(BuildContext context) {
    return DeviceCardShell(
      title: name,
      trailing: Switch(
        value: isOn,
        onChanged: (_) {},
      ),
      child: Row(
        children: [
          const Icon(Icons.devices_other),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Төрөл: $domain',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
