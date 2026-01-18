import 'package:flutter/foundation.dart';

/// StateStatus - Common status enum for all state classes
enum StateStatus {
  initial,
  loading,
  success,
  error,
}

/// BaseState - Abstract base class for all immutable state objects
/// Provides common status tracking and error handling
@immutable
abstract class BaseState {
  final StateStatus status;
  final String? errorMessage;

  const BaseState({
    this.status = StateStatus.initial,
    this.errorMessage,
  });

  /// Whether the state is in initial status
  bool get isInitial => status == StateStatus.initial;

  /// Whether the state is currently loading
  bool get isLoading => status == StateStatus.loading;

  /// Whether the operation completed successfully
  bool get isSuccess => status == StateStatus.success;

  /// Whether there was an error
  bool get isError => status == StateStatus.error;

  /// Whether data is available (not initial and not loading)
  bool get hasData => isSuccess || isError;
}
