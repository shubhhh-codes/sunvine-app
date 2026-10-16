import '../errors/failures.dart';

/// A functional Result type that encapsulates either a [Success] containing data [T]
/// or a [FailureResult] containing a [Failure].
sealed class Result<T> {
  const Result();

  /// Creates a successful result holding [data].
  const factory Result.success(T data) = Success<T>;

  /// Creates a failed result holding [failure].
  const factory Result.failure(Failure failure) = FailureResult<T>;

  /// Returns true if this is a [Success].
  bool get isSuccess => this is Success<T>;

  /// Returns true if this is a [FailureResult].
  bool get isFailure => this is FailureResult<T>;

  /// Returns the data if successful, or null otherwise.
  T? get dataOrNull => switch (this) {
        Success(data: final d) => d,
        FailureResult() => null,
      };

  /// Returns the failure if failed, or null otherwise.
  Failure? get failureOrNull => switch (this) {
        Success() => null,
        FailureResult(failure: final f) => f,
      };

  /// Pattern-matches over the result.
  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) failure,
  }) {
    return switch (this) {
      Success(data: final d) => success(d),
      FailureResult(failure: final f) => failure(f),
    };
  }

  /// Maps the success value using [transform].
  Result<R> map<R>(R Function(T data) transform) {
    return switch (this) {
      Success(data: final d) => Result.success(transform(d)),
      FailureResult(failure: final f) => Result.failure(f),
    };
  }
}

/// Represents a successful computation holding [data].
final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Success<T> && other.data == data;

  @override
  int get hashCode => data.hashCode;
}

/// Represents a failed computation holding a [failure].
final class FailureResult<T> extends Result<T> {
  final Failure failure;
  const FailureResult(this.failure);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is FailureResult<T> && other.failure == failure;

  @override
  int get hashCode => failure.hashCode;
}
