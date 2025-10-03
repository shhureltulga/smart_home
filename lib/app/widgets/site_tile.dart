import 'package:flutter/material.dart';
import '../data/models/site.dart';

class SiteTile extends StatelessWidget {
  final Site site;
  final VoidCallback? onTap;
  const SiteTile({super.key, required this.site, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(site.name),
        subtitle: Text(site.address ?? 'Хаяг байхгүй'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
