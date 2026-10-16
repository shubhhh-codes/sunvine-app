import 'package:flutter/foundation.dart';

/// Clean, production-grade telemetry logger.
/// Formats structured single-line events:
///   [NAV]    📱 Screen/tab transitions
///   [ACTION] 👆 User touch/button interactions
///   [API]    🌐 HTTP requests & responses with latency
///   [AUTH]   🔑 Session lifecycle & security events
///   [ERROR]  ❌ Application exceptions
class AppLogger {
  AppLogger._();

  static String _timeNow() {
    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    final s = now.second.toString().padLeft(2, '0');
    final ms = now.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }

  /// Logs screen and view transitions.
  static void nav(String screenOrTab) {
    debugPrint('${_timeNow()} [NAV]    📱 $screenOrTab');
  }

  /// Logs user click/tap interactions.
  static void action(String description) {
    debugPrint('${_timeNow()} [ACTION] 👆 $description');
  }

  /// Logs clean HTTP API telemetry.
  static void api(String method, String path, int statusCode, int durationMs, {String? extra}) {
    final icon = statusCode >= 200 && statusCode < 300 ? '🌐' : '⚠️';
    final extraText = extra != null && extra.isNotEmpty ? ' | $extra' : '';
    debugPrint('${_timeNow()} [API]    $icon $method $path ➔ $statusCode (${durationMs}ms)$extraText');
  }

  /// Logs auth and session transitions.
  static void auth(String event) {
    debugPrint('${_timeNow()} [AUTH]   🔑 $event');
  }

  /// Logs application state updates.
  static void state(String update) {
    debugPrint('${_timeNow()} [STATE]  ⚡ $update');
  }

  /// Logs errors with concise message.
  static void error(String message, [Object? error]) {
    final errStr = error != null ? ' ($error)' : '';
    debugPrint('${_timeNow()} [ERROR]  ❌ $message$errStr');
  }
}
