import '../config/app_config.dart';

/// Centralized registry of all API endpoints exposed by the Cloudflare Gateway.
class ApiEndpoints {
  ApiEndpoints._();

  /// Gateway base URL resolved from [AppConfig].
  static String get baseUrl => AppConfig.gatewayBaseUrl;

  /// Current environment name.
  static String get appEnv => AppConfig.envName;

  // ── Authentication ──────────────────────────────────────────────────────────
  static const String login = '/v1/auth/login';
  static const String refresh = '/v1/auth/refresh';
  static const String logout = '/v1/auth/logout';
  static const String me = '/v1/me';

  // ── System & Telemetry ──────────────────────────────────────────────────────
  static const String appVersion = '/v1/app/version';
  static const String health = '/v1/health';

  // ── Solar EPC Domain Resources ──────────────────────────────────────────────
  static const String catalog = '/v1/catalog/bootstrap';
  static const String quotations = '/v1/quotations';
  static const String customerFiles = '/v1/customer-files';
  static const String ledger = '/v1/ledger';
}
