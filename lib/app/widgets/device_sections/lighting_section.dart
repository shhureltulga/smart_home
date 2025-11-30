import 'package:flutter/material.dart';

/// 💡 Гэрлийн плитний дата
class LightTileData {
  final String name;
  final bool isOn;
  final int brightness; // 0..100

  const LightTileData({
    required this.name,
    required this.isOn,
    required this.brightness,
  });
}

/// 💡 Lighting System хэсэг (карт)
class LightingSection extends StatelessWidget {
  final String? subtitle;
  final List<LightTileData> lights;

  const LightingSection({
    super.key,
    this.subtitle,
    required this.lights,
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
              Text('Lighting System',
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
          for (final l in lights)
            _LightTile(
              name: l.name,
              isOn: l.isOn,
              brightness: l.brightness,
            ),
        ],
      ),
    );
  }
}

/// Гэрлийн нэг мөр
class _LightTile extends StatelessWidget {
  final String name;
  final bool isOn;
  final int brightness;

  const _LightTile({
    required this.name,
    required this.isOn,
    required this.brightness,
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
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.titleSmall,
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
          Row(
            children: [
              const SizedBox(width: 4),
              const Text('Brightness'),
              Expanded(
                child: Slider(
                  value: brightness.toDouble(),
                  min: 0,
                  max: 100,
                  onChanged: (_) {
                    // TODO: command илгээнэ
                  },
                ),
              ),
              Text('$brightness%'),
            ],
          ),
        ],
      ),
    );
  }
}
