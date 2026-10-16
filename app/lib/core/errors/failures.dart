/// Immutable failure value object surfaced to presentation controllers and UI widgets.
abstract class Failure {
  final String message;
  final String? code;
  final int? statusCode;

  const Failure(this.message, {this.code, this.statusCode});

  @override
  String toString() => '$runtimeType: $message (code: $code, status: $statusCode)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          code == other.code &&
          statusCode == other.statusCode;

  @override
  int get hashCode => Object.hash(runtimeType, message, code, statusCode);
}

/// Network failure (offline, timeout, unreachable).
class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'Unable to connect to server. Check your internet connection.',
    String code = 'NETWORK_ERROR',
  ]) : super(code: code, statusCode: 0);
}

/// Authentication failure (invalid credentials, bad token).
class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.statusCode = 401, super.code = 'INVALID_CREDENTIALS'});
}

/// Access forbidden (suspended account, unauthorized role).
class ForbiddenFailure extends Failure {
  const ForbiddenFailure(super.message, {super.statusCode = 403, super.code = 'ACCOUNT_SUSPENDED'});
}

/// Rate limit exceeded.
class RateLimitFailure extends Failure {
  final int? retryAfter;

  const RateLimitFailure(super.message, {this.retryAfter, super.statusCode = 429, super.code = 'RATE_LIMITED'});
}

/// Server error (HTTP 500, 502, 503).
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server encountered an internal error. Please try again later.'])
      : super(statusCode: 500, code: 'SERVER_ERROR');
}

/// Client-side validation failure.
class ValidationFailure extends Failure {
  const ValidationFailure(super.message) : super(statusCode: 400, code: 'VALIDATION_ERROR');
}

/// Unexpected general failure.
class UnknownFailure extends Failure {
  const UnknownFailure(super.message, {super.statusCode, super.code = 'UNKNOWN_ERROR'});
}
