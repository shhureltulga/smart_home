// lib/core/config/env.dart
// Flavor/орчны тохиргоо (dev/stg/prod) + нэг мөр тохируулга

class AppEnv {
  final String baseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Duration pollingInterval;

  const AppEnv({
    required this.baseUrl,
    this.connectTimeout = const Duration(seconds: 10),
    this.receiveTimeout = const Duration(seconds: 20),
    this.pollingInterval = const Duration(seconds: 12),
  });

  /// FLAVOR-ыг --dart-define=FLAVOR=dev|stg|prod хэлбэрээр өгч болно.
  static const String _flavor =
      String.fromEnvironment('FLAVOR', defaultValue: 'prod');

  static AppEnv get current {
    switch (_flavor) {
      case 'dev':
        return const AppEnv(
          baseUrl: 'https://api.habea.mn', // dev backend-ээ оруулж болно
        );
      case 'stg':
        return const AppEnv(
          baseUrl: 'https://api.habea.mn', // staging
        );
      case 'prod':
      default:
        return const AppEnv(
          baseUrl: 'https://api.habea.mn',
        );
    }
  }

  static String get flavor => _flavor;
}
