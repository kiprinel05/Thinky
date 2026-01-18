import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thinky/core_controls/services/logger_service.dart';
import 'base_state.dart';

/// BaseController - Abstract base class for all StateNotifier controllers
/// Provides common state management patterns
abstract class BaseController<T extends BaseState> extends StateNotifier<T> {
  BaseController(super.initialState);

  /// Set state to loading
  void setLoading();

  /// Set state to error with message
  void setError(String message);

  /// Set state to success
  void setSuccess();

  /// Clear any error message
  void clearError();

  /// Reset to initial state
  void reset();
}

/// BaseAsyncController - Controller with async operation support
/// Provides common patterns for API calls
abstract class BaseAsyncController<T extends BaseState> extends BaseController<T> {
  BaseAsyncController(super.initialState);

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  /// Safe state update - only updates if controller is still active
  void safeUpdate(T newState) {
    if (!_isDisposed) {
      state = newState;
    }
  }

  /// Execute an async operation with automatic loading/error handling
  Future<R?> executeAsync<R>({
    required Future<R> Function() operation,
    required T Function() loadingState,
    required T Function(R result) successState,
    required T Function(String error) errorState,
    String? defaultErrorMessage,
  }) async {
    safeUpdate(loadingState());

    try {
      final result = await operation();
      safeUpdate(successState(result));
      return result;
    } catch (e, stack) {
      final message = defaultErrorMessage ?? e.toString();
      LoggerService.e('Async Error in ${runtimeType}: $message', e, stack);
      safeUpdate(errorState(message));
      return null;
    }
  }

  /// Execute operation without changing to loading state
  Future<R?> executeSilent<R>({
    required Future<R> Function() operation,
    required T Function(R result) successState,
    T Function(String error)? errorState,
  }) async {
    try {
      final result = await operation();
      safeUpdate(successState(result));
      return result;
    } catch (e, stack) {
      LoggerService.e('Silent Error in ${runtimeType}: $e', e, stack);
      if (errorState != null) {
        safeUpdate(errorState(e.toString()));
      }
      return null;
    }
  }
}

/// BaseFormController - Controller for form handling
/// Provides validation and submission patterns
abstract class BaseFormController<T> extends StateNotifier<T> {
  BaseFormController(super.initialState);

  /// Validate all form fields
  bool validate();

  /// Submit the form
  Future<bool> submit();

  /// Reset form to initial state
  void resetForm();

  /// Check if form has been modified
  bool get isDirty;

  /// Check if form is currently submitting
  bool get isSubmitting;
}
