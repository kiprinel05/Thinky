import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:thinky/core_controls/network/api_endpoints.dart';
import 'package:thinky/core_controls/network/api_exceptions.dart';
import 'package:thinky/core_controls/config/app_config.dart';
import 'package:thinky/core_controls/storage/local_storage.dart';
import 'package:thinky/base_controls/base_repository.dart';
import 'package:thinky/shared/models/result.dart';
import '../presentation/controllers/auth_state.dart';

/// Auth response from API
class AuthResponse {
  final String accessToken;
  final String tokenType;
  final int userId;
  final String? username;
  final String? email;
  final bool isGuest;
  final String? guestName;

  AuthResponse({
    required this.accessToken,
    required this.tokenType,
    required this.userId,
    this.username,
    this.email,
    required this.isGuest,
    this.guestName,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String? ?? 'bearer',
      userId: json['user_id'] as int,
      username: json['username'] as String?,
      email: json['email'] as String?,
      isGuest: json['is_guest'] as bool? ?? false,
      guestName: json['guest_name'] as String?,
    );
  }

  AuthUser toUser() {
    return AuthUser(
      id: userId,
      username: username,
      email: email,
      isGuest: isGuest,
      guestName: guestName,
    );
  }
}

/// Auth Repository - handles all authentication API calls and local storage
/// using BaseRepository patterns
class AuthRepository extends BaseRepository {
  AuthRepository(super.storage);

  /// Check if user is authenticated
  bool get isAuthenticated => storage.isAuthenticated;

  /// Get current user from storage
  AuthUser? get currentUser {
    if (!isAuthenticated) return null;
    final userId = storage.userId;
    if (userId == null) return null;
    
    return AuthUser(
      id: userId,
      username: storage.username,
      email: storage.email,
      isGuest: storage.isGuest,
      guestName: storage.guestName,
    );
  }

  /// Login with email and password
  Future<Result<AuthResponse, ApiException>> login({
    required String email,
    required String password,
  }) async {
    final result = await post<AuthResponse>(
      endpoint: ApiEndpoints.login,
      body: {
        'email': email,
        'password': password,
      },
      parser: (data) => AuthResponse.fromJson(data),
    );

    if (result.isSuccess) {
      await _saveAuthData(result.getOrThrow());
    }
    
    return result;
  }

  /// Register new user
  Future<Result<AuthResponse, ApiException>> register({
    required String username,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final result = await post<AuthResponse>(
      endpoint: ApiEndpoints.register,
      body: {
        'username': username,
        'email': email,
        'password': password,
        'confirm_password': confirmPassword,
      },
      parser: (data) => AuthResponse.fromJson(data),
    );

    if (result.isSuccess) {
      await _saveAuthData(result.getOrThrow());
    }
    
    return result;
  }

  /// Register as guest
  Future<Result<AuthResponse, ApiException>> registerGuest({required String name}) async {
    final result = await post<AuthResponse>(
      endpoint: ApiEndpoints.guest,
      body: {'name': name},
      parser: (data) => AuthResponse.fromJson(data),
    );

    if (result.isSuccess) {
      await _saveAuthData(result.getOrThrow());
    }
    
    return result;
  }

  /// Offline guest registration fallback
  Future<Result<AuthResponse, ApiException>> registerGuestOffline({required String name}) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final authResponse = AuthResponse(
        accessToken: 'guest_local_token_$timestamp',
        tokenType: 'guest',
        userId: timestamp,
        username: name,
        email: null,
        isGuest: true,
        guestName: name,
      );

      await _saveAuthData(authResponse);
      return Result.success(authResponse);
    } catch (e) {
      return const Result.failure(CacheException('Failed to save guest offline'));
    }
  }

  /// Logout - clear all auth data
  Future<void> logout() async {
    await storage.clearAuthData();
  }

  /// Save auth data to local storage
  Future<void> _saveAuthData(AuthResponse response) async {
    await storage.setAuthToken(response.accessToken);
    await storage.setUserId(response.userId);
    if (response.username != null) {
      await storage.setUsername(response.username!);
    }
    if (response.email != null) {
      await storage.setEmail(response.email!);
    }
    await storage.setIsGuest(response.isGuest);
    if (response.guestName != null) {
      await storage.setGuestName(response.guestName!);
    }
  }
}