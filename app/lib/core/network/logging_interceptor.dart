import 'package:dio/dio.dart';
import '../utils/app_logger.dart';

/// Lightweight Dio interceptor that logs clean single-line API telemetry.
/// Replaces noisy JSON header/body dumps with concise:
/// `[API] 🌐 GET /v1/quotations?limit=100 ➔ 200 (145ms)`
class LoggingInterceptor extends Interceptor {
  static const String _startTimeKey = '_req_start_ms';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startTimeKey] = DateTime.now().millisecondsSinceEpoch;
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final startMs = response.requestOptions.extra[_startTimeKey] as int?;
    final durationMs = startMs != null ? DateTime.now().millisecondsSinceEpoch - startMs : 0;
    
    final path = response.requestOptions.uri.path +
        (response.requestOptions.uri.query.isNotEmpty ? '?${response.requestOptions.uri.query}' : '');
        
    AppLogger.api(
      response.requestOptions.method,
      path,
      response.statusCode ?? 200,
      durationMs,
    );
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final startMs = err.requestOptions.extra[_startTimeKey] as int?;
    final durationMs = startMs != null ? DateTime.now().millisecondsSinceEpoch - startMs : 0;
    
    final path = err.requestOptions.uri.path +
        (err.requestOptions.uri.query.isNotEmpty ? '?${err.requestOptions.uri.query}' : '');
        
    final statusCode = err.response?.statusCode ?? 0;
    final message = err.message ?? err.error?.toString() ?? 'Network error';

    AppLogger.api(
      err.requestOptions.method,
      path,
      statusCode,
      durationMs,
      extra: message,
    );
    super.onError(err, handler);
  }
}
