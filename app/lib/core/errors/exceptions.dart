/// Base exception for all application-level errors.
abstract class AppException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;

  const AppException(this.message, {this.statusCode, this.code});

  @override
  String toString() => 'AppException(code: $code, statusCode: $statusCode, message: $message)';
}

/// Thrown when network connection fails or timeouts occur.
class NetworkException extends AppException {
  const NetworkException([super.message = 'Unable to connect to Sunvine gateway. Please check your network connection.'])
      : super(code: 'NETWORK_ERROR');
}

/// Thrown when authentication credentials are invalid or missing.
class AuthException extends AppException {
  const AuthException(super.message, {super.statusCode, super.code = 'INVALID_CREDENTIALS'});
}

/// Thrown when access is forbidden, e.g. account suspended or inactive.
class ForbiddenException extends AppException {
  const ForbiddenException(super.message, {super.statusCode = 403, super.code = 'ACCOUNT_SUSPENDED'});
}

/// Thrown when API rate limit is exceeded.
class RateLimitException extends AppException {
  final int? retryAfter;

  const RateLimitException(super.message, {this.retryAfter, super.statusCode = 429, super.code = 'RATE_LIMITED'});
}

/// Thrown when remote server responds with a 5xx error.
class ServerException extends AppException {
  const ServerException([super.message = 'Sunvine gateway encountered an internal error. Please try again later.'])
      : super(statusCode: 500, code: 'SERVER_ERROR');
}

/// Thrown when client validation fails locally.
class ValidationException extends AppException {
  const ValidationException(super.message, {super.code = 'VALIDATION_ERROR'});
}

/// Thrown when session has expired and cannot be refreshed.
class SessionExpiredException extends AppException {
  const SessionExpiredException([super.message = 'Your session has expired. Please sign in again.'])
      : super(statusCode: 401, code: 'REAUTH_REQUIRED');
}
