// lib/app/widgets/pbd_floor_selector.dart
import 'package:flutter/material.dart';

class FloorItem {
  final String id;
  final String name;
  final int order;
  FloorItem({required this.id, required this.name, this.order = 0});
}

class PbdFloorSelector extends StatelessWidget {
  final List<FloorItem> floors;
  final String? selectedFloorId;
  final ValueChanged<String> onChanged;
  final EdgeInsets padding;

  const PbdFloorSelector({
    super.key,
    required this.floors,
    required this.selectedFloorId,
    required this.onChanged,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
  });

  @override
  Widget build(BuildContext context) {
    if (floors.isEmpty) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final items = [...floors]..sort((a, b) => a.order.compareTo(b.order));

    // Card background танай dashboard dark theme-тэй тааруулсан
    final cardBg = const Color(0xFF0F1115);
    final barBg = const Color(0xFF0B2230).withOpacity(.65);
    final border = cs.outlineVariant.withOpacity(.22);

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: cardBg,
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // const Text(
            //   'Давхар',
            //   style: TextStyle(fontWeight: FontWeight.w700),
            // ),
            const SizedBox(height: 10),

            // ✅ 1–4 button хэв маяг (4-өөс олон бол scroll хийнэ)
            Container(
              decoration: BoxDecoration(
                color: barBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border, width: 1),
              ),
              padding: const EdgeInsets.all(6),
              child: SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (ctx, i) {
                    final f = items[i];
                    final selected = f.id == selectedFloorId;

                    return _FloorSegmentButton(
                      text: _labelForFloor(i, f.name),
                      selected: selected,
                      onTap: () => onChanged(f.id),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// name нь "1 давхар" гэх мэт байвал шууд ашиглана.
  /// Үгүй бол 1-ээр дугаарлаад "1 Давхар" гэж харуулна.
  String _labelForFloor(int index, String name) {
    final n = name.trim();
    if (n.isEmpty) return '${index + 1} Давхар';
    if (RegExp(r'\d').hasMatch(n)) return n; // "1 давхар" гэх мэт
    return '${index + 1} Давхар';
  }
}

class _FloorSegmentButton extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _FloorSegmentButton({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final bgSelected = const Color(0xFF0EA5A4).withOpacity(.22);
    final bgNormal = Colors.white.withOpacity(.04);

    final borderSelected = const Color(0xFF0EA5A4).withOpacity(.55);
    final borderNormal = cs.outlineVariant.withOpacity(.20);

    final fgSelected = Colors.white;
    final fgNormal = Colors.white.withOpacity(.85);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minWidth: 92), // 4 товч багтана
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? bgSelected : bgNormal,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? borderSelected : borderNormal,
              width: 1,
            ),
          ),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? fgSelected : fgNormal,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              letterSpacing: .2,
            ),
          ),
        ),
      ),
    );
  }
}
