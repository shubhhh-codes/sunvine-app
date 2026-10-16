import 'package:dio/dio.dart';
import '../errors/exceptions.dart';

/// Central Dio Interceptor that translates HTTP and network errors into typed [AppException]s.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;
    final statusCode = response?.statusCode;
    final data = response?.data;

    String? serverMessage;
    String? errorCode;
    int? retryAfter;

    if (data is Map<String, dynamic>) {
      serverMessage = data['message']?.toString() ?? data['error']?.toString();
      errorCode = data['code']?.toString();
      if (data['retryAfter'] is num) {
        retryAfter = (data['retryAfter'] as num).toInt();
      }
    }

    AppException appException;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        appException = const NetworkException('Connection timed out. Please check your internet connectivity.');
        break;

      case DioExceptionType.badResponse:
        switch (statusCode) {
          case 400:
            appException = ValidationException(serverMessage ?? 'Invalid request submitted.');
            break;
          case 401:
            appException = AuthException(
              serverMessage ?? 'Authentication failed. Please check your credentials.',
              statusCode: 401,
              code: errorCode ?? 'INVALID_CREDENTIALS',
            );
            break;
          case 403:
            appException = ForbiddenException(
              serverMessage ?? 'Access restricted or account suspended.',
              statusCode: 403,
              code: errorCode ?? 'ACCOUNT_SUSPENDED',
            );
            break;
          case 429:
            appException = RateLimitException(
              serverMessage ?? 'Too many requests. Please try again later.',
              retryAfter: retryAfter,
            );
            break;
          case 500:
          case 502:
          case 503:
            appException = ServerException(serverMessage ?? 'Sunvine gateway error. Please try again later.');
            break;
          default:
            appException = ServerException(serverMessage ?? 'An unexpected server error occurred ($statusCode).');
        }
        break;

      case DioExceptionType.cancel:
        return handler.next(err);

      default:
        appException = NetworkException(err.message ?? 'A network communication error occurred.');
    }

    final wrappedErr = DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: appException,
      message: appException.message,
    );

    return handler.next(wrappedErr);
  }
}
