import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../constants/api_endpoints.dart';
import 'token_storage.dart';
import 'auth_interceptor.dart';
import 'refresh_interceptor.dart';
import 'error_interceptor.dart';

/// Central HTTP Client wrapper configured with timeouts, auth headers, token rotation, and error translation.
class ApiClient {
  late final Dio dio;
  final TokenStorage tokenStorage;

  ApiClient({
    required this.tokenStorage,
    required SessionRevokedCallback onSessionRevoked,
    required Future<String> Function() getDeviceId,
    String? baseUrl,
  }) {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? ApiEndpoints.baseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Client-App': 'Sunvine-Dealer-Mobile',
          'X-Client-Env': AppConfig.envName,
        },
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(tokenStorage: tokenStorage),
      RefreshInterceptor(
        dio: dio,
        tokenStorage: tokenStorage,
        onSessionRevoked: onSessionRevoked,
        getDeviceId: getDeviceId,
      ),
      ErrorInterceptor(),
    ]);
  }
}
