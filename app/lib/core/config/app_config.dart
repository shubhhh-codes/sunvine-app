/// Supported environment profiles for Sunvine EPC.
enum AppEnvironmentType {
  dev,
  staging,
  prod;

  static AppEnvironmentType fromString(String value) {
    switch (value.toLowerCase().trim()) {
      case 'prod':
      case 'production':
        return AppEnvironmentType.prod;
      case 'staging':
        return AppEnvironmentType.staging;
      case 'dev':
      case 'development':
      default:
        return AppEnvironmentType.dev;
    }
  }
}

/// Central application configuration parsed from compile-time environment variables.
///
/// Configure via `--dart-define-from-file=env/dev.json` or individual `--dart-define` flags.
class AppConfig {
  AppConfig._();

  static const String _envString = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'staging',
  );

  static const String _baseUrl = String.fromEnvironment(
    'GATEWAY_BASE_URL',
    defaultValue: 'https://sunvine-gateway-staging.sunvinerenewable.workers.dev',
  );

  /// Current active environment profile.
  static final AppEnvironmentType environment = AppEnvironmentType.fromString(_envString);

  /// Gateway API base URL.
  static String get gatewayBaseUrl => _baseUrl;

  /// Environment name string (dev, staging, prod).
  static String get envName => environment.name;

  /// Whether running in production environment.
  static bool get isProduction => environment == AppEnvironmentType.prod;

  /// Whether running in development environment.
  static bool get isDevelopment => environment == AppEnvironmentType.dev;

  /// Default HTTP connection timeout.
  static const Duration connectTimeout = Duration(seconds: 15);

  /// Default HTTP receive timeout.
  static const Duration receiveTimeout = Duration(seconds: 15);

  /// Session lock threshold for backgrounded app (5 minutes in milliseconds).
  static const int backgroundLockTimeoutMs = 5 * 60 * 1000;
}
