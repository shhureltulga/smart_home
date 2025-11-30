import 'package:flutter/material.dart';

/// 🔌 Залгуурын мөрийн дата
class OutletTileData {
  final String name;
  final bool isOn;
  final int? powerW;

  const OutletTileData({
    required this.name,
    required this.isOn,
    this.powerW,
  });
}

/// 🔌 Outlets хэсэг (карт)
class OutletsSection extends StatelessWidget {
  final String? subtitle;
  final List<OutletTileData> outlets;

  const OutletsSection({
    super.key,
    this.subtitle,
    required this.outlets,
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
              Icon(Icons.electric_bolt, size: 18, color: Colors.amber.shade300),
              const SizedBox(width: 8),
              Text('Outlets',
                  style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Icon(Icons.chevron_right,
                  color: Colors.white.withOpacity(.5)),
            ],
          ),
          if (subtitle?.isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.white.withOpacity(.7),
                  ),
            ),
          ],
          const SizedBox(height: 10),
          for (final o in outlets)
            _OutletTile(
              name: o.name,
              isOn: o.isOn,
              powerW: o.powerW,
            ),
        ],
      ),
    );
  }
}

/// Нэг залгуурын мөр
class _OutletTile extends StatelessWidget {
  final String name;
  final bool isOn;
  final int? powerW;

  const _OutletTile({
    required this.name,
    required this.isOn,
    this.powerW,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.power_outlined),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (powerW != null)
                  Text(
                    '$powerW W',
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: Colors.white.withOpacity(.7)),
                  ),
              ],
            ),
          ),
          Switch(
            value: isOn,
            onChanged: (_) {
              // TODO: command илгээнэ
            },
          ),
        ],
      ),
    );
  }
}
