// lib/app/data/models/site.dart
class Site {
  final String id;
  final String name;
  final String? address;

  Site({required this.id, required this.name, this.address});

  factory Site.fromJson(Map<String, dynamic> j) => Site(
        id: j['id']?.toString() ?? '',
        name: (j['name'] ?? '').toString(),
        address: j['address']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
      };
}
