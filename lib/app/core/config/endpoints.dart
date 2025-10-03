// lib/core/config/endpoints.dart
// Backend endpoint-уудын мөрүүдийг нэг газар төвлөрүүлэв.

class ApiPaths {
  // Auth
  static const login = '/auth/login';
  static const refresh = '/auth/refresh';
  static const logout = '/auth/logout';
  static const me = '/me';

  // Domain
  static const sites = '/api/sites';
  static const devices = '/api/devices';
  static const sensorsLatest = '/api/sensors/latest';
  static const sensorsReadings = '/api/sensors/readings';

  static String siteOverview(String siteId) => '/api/sites/$siteId/overview';
  // (сонголт) admin команд
  static const edgeCommands = '/api/edge/commands';
}

