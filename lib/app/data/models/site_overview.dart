class EdgeBrief {
  final String id;
  final String edgeId;
  final String status;      // "online" | "offline"
  final DateTime? lastSeenAt;
  EdgeBrief({required this.id, required this.edgeId, required this.status, this.lastSeenAt});

  factory EdgeBrief.fromJson(Map<String, dynamic> j) => EdgeBrief(
    id: (j['id'] ?? '') as String,
    edgeId: (j['edgeId'] ?? '') as String,
    status: (j['status'] ?? '') as String,
    lastSeenAt: j['lastSeenAt'] != null ? DateTime.tryParse(j['lastSeenAt']) : null,
  );
}

class LatestSensorItem {
  final String id;
  final String deviceKey;
  final String? type;
  final double value;
  final DateTime ts;
  LatestSensorItem({
    required this.id,
    required this.deviceKey,
    required this.type,
    required this.value,
    required this.ts,
  });

  factory LatestSensorItem.fromJson(Map<String, dynamic> j) => LatestSensorItem(
    id: (j['id'] ?? '') as String,
    deviceKey: (j['deviceKey'] ?? '') as String,
    type: j['type'] as String?,
    value: (j['value'] as num).toDouble(),
    ts: DateTime.parse(j['ts']),
  );
}

class SiteOverview {
  final String siteId;
  final String siteName;
  final String? address;

  final int rooms;
  final int devices;
  final DateTime? lastReadingAt;

  final EdgeBrief? edge;
  final List<LatestSensorItem> latest;

  SiteOverview({
    required this.siteId,
    required this.siteName,
    this.address,
    required this.rooms,
    required this.devices,
    this.lastReadingAt,
    this.edge,
    required this.latest,
  });

  factory SiteOverview.fromJson(Map<String, dynamic> j) {
    final site = (j['site'] ?? {}) as Map<String, dynamic>;
    final stats = (j['stats'] ?? {}) as Map<String, dynamic>;
    final latest = (j['latestSensors'] as List<dynamic>? ?? [])
        .map((e) => LatestSensorItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return SiteOverview(
      siteId: (site['id'] ?? '') as String,
      siteName: (site['name'] ?? '') as String,
      address: site['address'] as String?,
      rooms: (stats['rooms'] ?? 0) as int,
      devices: (stats['devices'] ?? 0) as int,
      lastReadingAt: stats['lastReadingAt'] != null
          ? DateTime.tryParse(stats['lastReadingAt'])
          : null,
      edge: j['edge'] != null ? EdgeBrief.fromJson(j['edge'] as Map<String, dynamic>) : null,
      latest: latest,
    );
  }
}
