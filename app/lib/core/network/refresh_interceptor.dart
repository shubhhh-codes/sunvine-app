import 'dart:async';
import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import 'token_storage.dart';

typedef SessionRevokedCallback = void Function(String reason);

class RefreshInterceptor extends Interceptor {
  final Dio dio;
  final TokenStorage tokenStorage;
  final SessionRevokedCallback onSessionRevoked;
  final Future<String> Function() getDeviceId;

  Completer<String?>? _refreshCompleter;

  RefreshInterceptor({
    required this.dio,
    required this.tokenStorage,
    required this.onSessionRevoked,
    required this.getDeviceId,
  });

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final response = err.response;
    final requestOptions = err.requestOptions;

    // Check if error is 401 Unauthorized and not an auth endpoint
    final isAuthRoute = requestOptions.path.contains(ApiEndpoints.login) ||
        requestOptions.path.contains(ApiEndpoints.refresh);

    if (response?.statusCode == 401 && !isAuthRoute) {
      try {
        final newAccessToken = await _performSingleFlightRefresh();

        if (newAccessToken != null) {
          // Retry original request with newly minted access token
          requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
          final cloneReq = await dio.fetch(requestOptions);
          return handler.resolve(cloneReq);
        } else {
          await _handleSessionExpired('Session expired. Please sign in again.');
          return handler.next(err);
        }
      } catch (refreshErr) {
        await _handleSessionExpired('Authentication failed during token refresh.');
        return handler.next(err);
      }
    }

    return handler.next(err);
  }

  /// Single-flight lock: Only one refresh HTTP call runs concurrently.
  Future<String?> _performSingleFlightRefresh() async {
    if (_refreshCompleter != null) {
      // Refresh already in progress; await result
      return await _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<String?>();

    try {
      final currentRefreshToken = await tokenStorage.getRefreshToken();
      if (currentRefreshToken == null) {
        _refreshCompleter!.complete(null);
        return null;
      }

      final deviceId = await getDeviceId();

      // Direct Dio call without interceptors to avoid circular refresh loops
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: dio.options.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      final response = await refreshDio.post(
        ApiEndpoints.refresh,
        data: {
          'refreshToken': currentRefreshToken,
          'deviceId': deviceId,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final newAccessToken = data['accessToken'] as String;
        final accessExpiresAt = data['accessExpiresAt'] as int;
        final newRefreshToken = data['refreshToken'] as String;
        final user = data['user'] as Map<String, dynamic>?;

        await tokenStorage.saveSession(
          accessToken: newAccessToken,
          accessExpiresAt: accessExpiresAt,
          refreshToken: newRefreshToken,
        );

        if (user != null) {
          await tokenStorage.saveDealerUser(user);
        }

        _refreshCompleter!.complete(newAccessToken);
        return newAccessToken;
      } else {
        _refreshCompleter!.complete(null);
        return null;
      }
    } catch (e) {
      if (e is DioException) {
        final status = e.response?.statusCode;
        if (status == 403) {
          onSessionRevoked('Account suspended. Contact Sunvine support.');
        } else if (status == 401) {
          onSessionRevoked('Session expired or revoked. Please sign in again.');
        }
      }
      _refreshCompleter!.complete(null);
      return null;
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<void> _handleSessionExpired(String reason) async {
    await tokenStorage.clearSession();
    onSessionRevoked(reason);
  }
}
