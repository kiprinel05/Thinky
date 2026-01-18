import 'package:flutter/foundation.dart';

/// Result type for handling success/failure cases
/// Inspired by Kotlin's Result and Rust's Result types
@immutable
sealed class Result<T, E> {
  const Result._();

  /// Creates a success result with the given value
  const factory Result.success(T value) = Success<T, E>;

  /// Creates a failure result with the given error
  const factory Result.failure(E error) = Failure<T, E>;

  /// Returns true if this is a success result
  bool get isSuccess => this is Success<T, E>;

  /// Returns true if this is a failure result
  bool get isFailure => this is Failure<T, E>;

  /// Gets the success value or null
  T? get valueOrNull {
    return switch (this) {
      Success(:final value) => value,
      Failure() => null,
    };
  }

  /// Gets the error or null
  E? get errorOrNull {
    return switch (this) {
      Success() => null,
      Failure(:final error) => error,
    };
  }

  /// Maps the success value to a new type
  Result<U, E> map<U>(U Function(T value) transform) {
    return switch (this) {
      Success(:final value) => Result.success(transform(value)),
      Failure(:final error) => Result.failure(error),
    };
  }

  /// Maps the error to a new type
  Result<T, F> mapError<F>(F Function(E error) transform) {
    return switch (this) {
      Success(:final value) => Result.success(value),
      Failure(:final error) => Result.failure(transform(error)),
    };
  }

  /// Folds the result into a single value
  U fold<U>({
    required U Function(T value) onSuccess,
    required U Function(E error) onFailure,
  }) {
    return switch (this) {
      Success(:final value) => onSuccess(value),
      Failure(:final error) => onFailure(error),
    };
  }

  /// Gets the value or throws the error
  T getOrThrow() {
    return switch (this) {
      Success(:final value) => value,
      Failure(:final error) => throw error as Object,
    };
  }

  /// Gets the value or returns the default
  T getOrElse(T Function() defaultValue) {
    return switch (this) {
      Success(:final value) => value,
      Failure() => defaultValue(),
    };
  }
}

/// Success case of Result
@immutable
class Success<T, E> extends Result<T, E> {
  final T value;

  const Success(this.value) : super._();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T, E> &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Success($value)';
}

/// Failure case of Result
@immutable
class Failure<T, E> extends Result<T, E> {
  final E error;

  const Failure(this.error) : super._();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure<T, E> &&
          runtimeType == other.runtimeType &&
          error == other.error;

  @override
  int get hashCode => error.hashCode;

  @override
  String toString() => 'Failure($error)';
}
