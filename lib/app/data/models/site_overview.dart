// ---------- EdgeBrief ----------
class EdgeBrief {
  final String id;
  final String edgeId;
  final String status; // "online" | "offline"
  final DateTime? lastSeenAt;

  const EdgeBrief({
    required this.id,
    required this.edgeId,
    required this.status,
    this.lastSeenAt,
  });

  factory EdgeBrief.fromJson(Map<String, dynamic> j) => EdgeBrief(
        id: (j['id'] ?? '') as String,
        edgeId: (j['edgeId'] ?? '') as String,
        status: (j['status'] ?? '') as String,
        lastSeenAt: j['lastSeenAt'] != null
            ? DateTime.tryParse(j['lastSeenAt'].toString())
            : null,
      );
}

// ---------- LatestSensorItem ----------
class LatestSensorItem {
  final String id;
  final String deviceKey;
  final String? type;
  final double value;
  final DateTime ts;

  const LatestSensorItem({
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
        value: (j['value'] as num?)?.toDouble() ?? 0.0,
        ts: DateTime.tryParse(j['ts']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      );
}

// ---------- WeatherNow (TOP-LEVEL!) ----------
class WeatherNow {
  final double tempC;
  final double humidity;
  final double windSpeedMs;
  final double rainProb;

  const WeatherNow({
    required this.tempC,
    required this.humidity,
    required this.windSpeedMs,
    required this.rainProb,
  });

  factory WeatherNow.fromJson(Map<String, dynamic> j) => WeatherNow(
        tempC: (j['tempC'] as num?)?.toDouble() ?? 0,
        humidity: (j['humidity'] as num?)?.toDouble() ?? 0,
        windSpeedMs: (j['windSpeedMs'] as num?)?.toDouble() ?? 0,
        rainProb: (j['rainProb'] as num?)?.toDouble() ?? 0,
      );
}

// ---------- SiteOverview ----------
class SiteOverview {
  final String siteId;
  final String siteName;
  final String? address;

  final int rooms;
  final int devices;
  final DateTime? lastReadingAt;

  final EdgeBrief? edge;
  final List<LatestSensorItem> latest;

  /// Цаг агаар (nullable)
  final WeatherNow? weather;

  const SiteOverview({
    required this.siteId,
    required this.siteName,
    this.address,
    required this.rooms,
    required this.devices,
    this.lastReadingAt,
    this.edge,
    required this.latest,
    this.weather,
  });

  factory SiteOverview.fromJson(Map<String, dynamic> j) {
    final site = (j['site'] ?? const {}) as Map<String, dynamic>;
    final stats = (j['stats'] ?? const {}) as Map<String, dynamic>;

    final latestList = (j['latestSensors'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(LatestSensorItem.fromJson)
        .toList();

    return SiteOverview(
      siteId: (site['id'] ?? '') as String,
      siteName: (site['name'] ?? '') as String,
      address: site['address'] as String?,
      rooms: (stats['rooms'] as int?) ?? 0,
      devices: (stats['devices'] as int?) ?? 0,
      lastReadingAt: stats['lastReadingAt'] != null
          ? DateTime.tryParse(stats['lastReadingAt'].toString())
          : null,
      edge: j['edge'] is Map<String, dynamic>
          ? EdgeBrief.fromJson(j['edge'] as Map<String, dynamic>)
          : null,
      latest: latestList,
      weather: j['weather'] is Map<String, dynamic>
          ? WeatherNow.fromJson(j['weather'] as Map<String, dynamic>)
          : null,
    );
  }
}
