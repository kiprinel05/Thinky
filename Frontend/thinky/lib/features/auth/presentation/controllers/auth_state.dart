import 'package:flutter/foundation.dart';
import '../../../../core/base/base_state.dart';

/// User entity for authenticated user data
@immutable
class AuthUser {
  final int id;
  final String? username;
  final String? email;
  final bool isGuest;
  final String? guestName;

  const AuthUser({
    required this.id,
    this.username,
    this.email,
    required this.isGuest,
    this.guestName,
  });

  String get displayName => username ?? guestName ?? 'User';

  AuthUser copyWith({
    int? id,
    String? username,
    String? email,
    bool? isGuest,
    String? guestName,
  }) {
    return AuthUser(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      isGuest: isGuest ?? this.isGuest,
      guestName: guestName ?? this.guestName,
    );
  }
}

/// Authentication state
@immutable
class AuthState extends BaseState {
  final AuthUser? user;
  final String? token;

  const AuthState({
    super.status = StateStatus.initial,
    super.errorMessage,
    this.user,
    this.token,
  });

  bool get isAuthenticated => token != null && token!.isNotEmpty;

  AuthState copyWith({
    StateStatus? status,
    String? errorMessage,
    AuthUser? user,
    String? token,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      user: user ?? this.user,
      token: token ?? this.token,
    );
  }

  /// Initial state factory
  factory AuthState.initial() => const AuthState();

  /// Loading state factory
  factory AuthState.loading() => const AuthState(status: StateStatus.loading);

  /// Success state factory
  factory AuthState.authenticated({
    required AuthUser user,
    required String token,
  }) {
    return AuthState(
      status: StateStatus.success,
      user: user,
      token: token,
    );
  }

  /// Error state factory
  factory AuthState.error(String message) {
    return AuthState(
      status: StateStatus.error,
      errorMessage: message,
    );
  }
}

/// Login form state
@immutable
class LoginFormState {
  final String email;
  final String password;
  final bool isSubmitting;
  final String? errorMessage;
  final bool obscurePassword;

  const LoginFormState({
    this.email = '',
    this.password = '',
    this.isSubmitting = false,
    this.errorMessage,
    this.obscurePassword = true,
  });

  bool get isValid => email.isNotEmpty && password.isNotEmpty;

  LoginFormState copyWith({
    String? email,
    String? password,
    bool? isSubmitting,
    String? errorMessage,
    bool? obscurePassword,
  }) {
    return LoginFormState(
      email: email ?? this.email,
      password: password ?? this.password,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      obscurePassword: obscurePassword ?? this.obscurePassword,
    );
  }
}

/// Register form state
@immutable
class RegisterFormState {
  final String username;
  final String email;
  final String password;
  final String confirmPassword;
  final bool isSubmitting;
  final String? errorMessage;
  final bool obscurePassword;
  final bool obscureConfirmPassword;

  const RegisterFormState({
    this.username = '',
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.isSubmitting = false,
    this.errorMessage,
    this.obscurePassword = true,
    this.obscureConfirmPassword = true,
  });

  bool get isValid =>
      username.isNotEmpty &&
      email.isNotEmpty &&
      password.isNotEmpty &&
      confirmPassword.isNotEmpty &&
      password == confirmPassword;

  RegisterFormState copyWith({
    String? username,
    String? email,
    String? password,
    String? confirmPassword,
    bool? isSubmitting,
    String? errorMessage,
    bool? obscurePassword,
    bool? obscureConfirmPassword,
  }) {
    return RegisterFormState(
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      obscureConfirmPassword: obscureConfirmPassword ?? this.obscureConfirmPassword,
    );
  }
}
