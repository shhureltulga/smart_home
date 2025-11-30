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
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
  });

  @override
  Widget build(BuildContext context) {
    final items = [...floors]..sort((a, b) => a.order.compareTo(b.order));

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFF0F1115),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Давхар', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            ...items.map((f) => RadioListTile<String>(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: f.id,
                  groupValue: selectedFloorId,
                  onChanged: (v) => v != null ? onChanged(v) : null,
                  title: Text(f.name),
                  visualDensity: const VisualDensity(vertical: -3),
                )),
          ],
        ),
      ),
    );
  }
}
