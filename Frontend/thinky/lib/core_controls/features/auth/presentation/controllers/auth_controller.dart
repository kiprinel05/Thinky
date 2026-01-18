import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thinky/core_controls/storage/local_storage.dart';
import 'package:thinky/base_controls/base_controller.dart';
import 'package:thinky/base_controls/base_state.dart';
import '../../data/auth_repository.dart';
import 'auth_state.dart';

/// Provider for LocalStorage instance
final localStorageProvider = Provider<LocalStorage>((ref) {
  throw UnimplementedError('LocalStorage must be overridden in ProviderScope');
});

/// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final storage = ref.watch(localStorageProvider);
  return AuthRepository(storage);
});

/// Provider for current auth state
final authStateProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthController(repository);
});

/// Provider for login form state
final loginFormProvider = StateNotifierProvider.autoDispose<LoginFormController, LoginFormState>((ref) {
  final authController = ref.read(authStateProvider.notifier);
  return LoginFormController(authController);
});

/// Provider for register form state
final registerFormProvider = StateNotifierProvider.autoDispose<RegisterFormController, RegisterFormState>((ref) {
  final authController = ref.read(authStateProvider.notifier);
  return RegisterFormController(authController);
});

/// Auth Controller - manages global auth state using BaseAsyncController
class AuthController extends BaseAsyncController<AuthState> {
  final AuthRepository _repository;

  AuthController(this._repository) : super(AuthState.initial()) {
    _loadInitialState();
  }

  /// Load initial auth state from storage
  void _loadInitialState() {
    final user = _repository.currentUser;
    final token = _repository.token;
    
    if (user != null && token != null) {
      state = AuthState.authenticated(user: user, token: token);
    }
  }

  /// Check if user is authenticated
  bool get isAuthenticated => _repository.isAuthenticated;

  // Implementation of abstract methods from BaseController
  @override
  void setLoading() => state = AuthState.loading();
  
  @override
  void setError(String message) => state = AuthState.error(message);
  
  @override
  void setSuccess() {} // Not used directly as success state needs data
  
  @override
  void clearError() {
    if (state.isError) {
      state = state.copyWith(status: StateStatus.initial, errorMessage: null);
    }
  }

  @override
  void reset() => state = AuthState.initial();

  /// Login user
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    final result = await executeAsync<AuthResponse?>(
      operation: () async {
        final result = await _repository.login(email: email, password: password);
        return result.getOrThrow();
      },
      loadingState: () => AuthState.loading(),
      successState: (response) => AuthState.authenticated(
        user: response!.toUser(),
        token: response.accessToken,
      ),
      errorState: (message) => AuthState.error(message),
    );

    return result != null;
  }

  /// Register user
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final result = await executeAsync<AuthResponse?>(
      operation: () async {
        final result = await _repository.register(
          username: username,
          email: email,
          password: password,
          confirmPassword: confirmPassword,
        );
        return result.getOrThrow();
      },
      loadingState: () => AuthState.loading(),
      successState: (response) => AuthState.authenticated(
        user: response!.toUser(),
        token: response.accessToken,
      ),
      errorState: (message) => AuthState.error(message),
    );

    return result != null;
  }

  /// Register as guest
  Future<bool> registerGuest({required String name}) async {
    // Try offline fallback on error automatically handled by repo logic if implemented there,
    // but here we are using repo that returns Result.
    
    final result = await executeAsync<AuthResponse?>(
      operation: () async {
        final result = await _repository.registerGuest(name: name);
        if (result.isSuccess) return result.getOrThrow();
        
        // If main registration failed, try offline
        final offlineResult = await _repository.registerGuestOffline(name: name);
        return offlineResult.fold(
          onSuccess: (data) => data,
          onFailure: (error) => throw result.errorOrNull ?? error,
        );
      },
      loadingState: () => AuthState.loading(),
      successState: (response) => AuthState.authenticated(
        user: response!.toUser(),
        token: response.accessToken,
      ),
      errorState: (message) => AuthState.error(message),
    );

    return result != null;
  }

  /// Logout user
  Future<void> logout() async {
    await _repository.logout();
    reset();
  }
}

/// Login Form Controller - manages login form state
class LoginFormController extends BaseFormController<LoginFormState> {
  final AuthController _authController;

  LoginFormController(this._authController) : super(const LoginFormState());

  void setEmail(String email) {
    state = state.copyWith(email: email, errorMessage: null);
  }

  void setPassword(String password) {
    state = state.copyWith(password: password, errorMessage: null);
  }

  void togglePasswordVisibility() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  @override
  bool validate() => state.isValid;
  
  @override
  bool get isDirty => state.email.isNotEmpty || state.password.isNotEmpty;
  
  @override
  bool get isSubmitting => state.isSubmitting;

  @override
  void resetForm() => state = const LoginFormState();

  @override
  Future<bool> submit() async {
    if (!validate()) {
      state = state.copyWith(errorMessage: 'Please fill in all fields');
      return false;
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    final success = await _authController.login(
      email: state.email.trim(),
      password: state.password,
    );

    if (!success) {
      final error = _authController.state.errorMessage ?? 'Login failed';
      state = state.copyWith(isSubmitting: false, errorMessage: error);
    } else {
      state = state.copyWith(isSubmitting: false);
    }

    return success;
  }
}

/// Register Form Controller - manages register form state
class RegisterFormController extends BaseFormController<RegisterFormState> {
  final AuthController _authController;

  RegisterFormController(this._authController) : super(const RegisterFormState());

  void setUsername(String username) {
    state = state.copyWith(username: username, errorMessage: null);
  }

  void setEmail(String email) {
    state = state.copyWith(email: email, errorMessage: null);
  }

  void setPassword(String password) {
    state = state.copyWith(password: password, errorMessage: null);
  }

  void setConfirmPassword(String confirmPassword) {
    state = state.copyWith(confirmPassword: confirmPassword, errorMessage: null);
  }

  void togglePasswordVisibility() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  void toggleConfirmPasswordVisibility() {
    state = state.copyWith(obscureConfirmPassword: !state.obscureConfirmPassword);
  }

  @override
  bool validate() {
    if (!state.isValid) return false;
    if (state.password != state.confirmPassword) return false;
    return true;
  }
  
  @override
  bool get isDirty => state.username.isNotEmpty || state.email.isNotEmpty;
  
  @override
  bool get isSubmitting => state.isSubmitting;

  @override
  void resetForm() => state = const RegisterFormState();

  @override
  Future<bool> submit() async {
    if (!state.isValid) {
      if (state.password != state.confirmPassword) {
        state = state.copyWith(errorMessage: 'Passwords do not match');
      } else {
        state = state.copyWith(errorMessage: 'Please fill in all fields');
      }
      return false;
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    final success = await _authController.register(
      username: state.username.trim(),
      email: state.email.trim(),
      password: state.password,
      confirmPassword: state.confirmPassword,
    );

    if (!success) {
      final error = _authController.state.errorMessage ?? 'Registration failed';
      state = state.copyWith(isSubmitting: false, errorMessage: error);
    } else {
      state = state.copyWith(isSubmitting: false);
    }

    return success;
  }
}