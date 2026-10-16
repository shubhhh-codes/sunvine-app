import 'package:dio/dio.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/token_storage.dart';
import '../../../core/services/device_info_service.dart';
import '../domain/auth_models.dart';
import '../domain/i_auth_repository.dart';

/// Concrete implementation of [IAuthRepository] using Dio and [TokenStorage].
class AuthRepository implements IAuthRepository {
  final Dio dio;
  final TokenStorage tokenStorage;
  final DeviceInfoService _deviceInfoService;

  AuthRepository({
    required this.dio,
    required this.tokenStorage,
    DeviceInfoService? deviceInfoService,
  }) : _deviceInfoService = deviceInfoService ?? DeviceInfoService();

  @override
  Future<Map<String, String>> getDeviceMetadata() async {
    final meta = await _deviceInfoService.getMetadata();
    return meta.toMap();
  }

  @override
  Future<Result<AuthSession>> loginResult({
    required String identifier,
    required String password,
  }) async {
    try {
      final meta = await getDeviceMetadata();
      final cleanIdentifier = identifier.trim().replaceAll(RegExp(r'\D'), '');

      final response = await dio.post(
        ApiEndpoints.login,
        data: {
          'identifier': cleanIdentifier.length == 10 ? cleanIdentifier : identifier.trim(),
          'password': password,
          'role': 'dealer',
          'deviceId': meta['deviceId'],
          'deviceName': meta['deviceName'],
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final session = AuthSession.fromJson(response.data as Map<String, dynamic>);
        await tokenStorage.saveSession(
          accessToken: session.accessToken,
          accessExpiresAt: session.accessExpiresAt,
          refreshToken: session.refreshToken,
        );
        await tokenStorage.saveDealerUser(session.user.toJson());
        return Result.success(session);
      }

      return Result.failure(
        AuthFailure('Authentication failed with status ${response.statusCode}', statusCode: response.statusCode),
      );
    } on DioException catch (e) {
      if (e.error is AppException) {
        final appEx = e.error as AppException;
        if (appEx is RateLimitException) {
          return Result.failure(RateLimitFailure(appEx.message, retryAfter: appEx.retryAfter));
        } else if (appEx is ForbiddenException) {
          return Result.failure(ForbiddenFailure(appEx.message));
        } else if (appEx is AuthException) {
          return Result.failure(AuthFailure(appEx.message, statusCode: appEx.statusCode));
        } else if (appEx is NetworkException) {
          return Result.failure(NetworkFailure(appEx.message));
        }
      }

      final statusCode = e.response?.statusCode;
      final errorData = e.response?.data;
      String message = 'Unable to connect to gateway.';

      if (errorData is Map && errorData['message'] != null) {
        message = errorData['message'].toString();
      } else if (errorData is Map && errorData['error'] != null) {
        message = errorData['error'].toString();
      } else if (statusCode == 401) {
        message = 'Invalid credentials. Please verify your mobile number and password.';
      } else if (statusCode == 403) {
        message = 'Account suspended or inactive. Contact Sunvine support.';
      }

      return Result.failure(AuthFailure(message, statusCode: statusCode));
    } catch (e) {
      return Result.failure(UnknownFailure('An unexpected error occurred: ${e.toString()}'));
    }
  }

  @override
  Future<AuthResult> login({
    required String identifier,
    required String password,
  }) async {
    final result = await loginResult(identifier: identifier, password: password);
    return switch (result) {
      Success(data: final session) => AuthResult.success(session),
      FailureResult(failure: final failure) => AuthResult.failure(
          failure.message,
          statusCode: failure.statusCode,
        ),
    };
  }

  @override
  Future<void> logout() async {
    try {
      final refreshToken = await tokenStorage.getRefreshToken();
      final data = <String, dynamic>{};
      if (refreshToken != null) {
        data['refreshToken'] = refreshToken;
      }
      await dio.post(
        ApiEndpoints.logout,
        data: data,
      );
    } catch (_) {
      // Best-effort logout upstream
    } finally {
      await tokenStorage.clearSession();
    }
  }

  @override
  Future<AuthSession?> getStoredSession() async {
    final token = await tokenStorage.getAccessToken();
    final refreshToken = await tokenStorage.getRefreshToken();
    final expiresAt = await tokenStorage.getAccessExpiresAt();
    final userMap = await tokenStorage.getDealerUser();

    if (token != null && refreshToken != null && expiresAt != null && userMap != null) {
      return AuthSession(
        accessToken: token,
        accessExpiresAt: expiresAt,
        refreshToken: refreshToken,
        user: DealerUser.fromJson(userMap),
      );
    }
    return null;
  }
}
