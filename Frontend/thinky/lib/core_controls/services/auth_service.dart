import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thinky/core_controls/config/app_config.dart';
import '../models/auth_response.dart';
import 'api_client.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _usernameKey = 'username';
  static const String _emailKey = 'email';
  static const String _isGuestKey = 'is_guest';
  static const String _guestNameKey = 'guest_name';
  static const String _isAdminKey = 'is_admin';

  static Future<void> saveAuthData(AuthResponse response) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, response.accessToken);
    await prefs.setInt(_userIdKey, response.userId);
    if (response.username != null) {
      await prefs.setString(_usernameKey, response.username!);
    }
    if (response.email != null) {
      await prefs.setString(_emailKey, response.email!);
    }
    await prefs.setBool(_isGuestKey, response.isGuest);
    if (response.guestName != null) {
      await prefs.setString(_guestNameKey, response.guestName!);
    }
    await prefs.setBool(_isAdminKey, response.isAdmin);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = await getToken();
    if (token == null) return null;

    return {
      'userId': prefs.getInt(_userIdKey),
      'username': prefs.getString(_usernameKey),
      'email': prefs.getString(_emailKey),
      'isGuest': prefs.getBool(_isGuestKey) ?? false,
      'guestName': prefs.getString(_guestNameKey),
      'isAdmin': prefs.getBool(_isAdminKey) ?? false,
    };
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_isGuestKey);
    await prefs.remove(_guestNameKey);
    await prefs.remove(_isAdminKey);
  }

  static Future<AuthResponse> register({
    required String username,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final response = await ApiClient.post(AppConfig.registerEndpoint, {
        'username': username,
        'email': email,
        'password': password,
        'confirm_password': confirmPassword,
      });

      if (response.statusCode == 201) {
        final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
        await saveAuthData(authResponse);
        return authResponse;
      } else {
        final errorData = jsonDecode(response.body);
        throw AuthError.fromJson(errorData);
      }
    } catch (e) {
      if (e is AuthError) rethrow;
      throw AuthError.fromString('Network error: ${e.toString()}');
    }
  }

  static Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiClient.post(AppConfig.loginEndpoint, {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
        await saveAuthData(authResponse);
        return authResponse;
      } else {
        final errorData = jsonDecode(response.body);
        throw AuthError.fromJson(errorData);
      }
    } catch (e) {
      if (e is AuthError) rethrow;
      throw AuthError.fromString('Network error: ${e.toString()}');
    }
  }

  static Future<AuthResponse> registerGuest({required String name}) async {
    try {
      final response =
          await ApiClient.post(AppConfig.guestEndpoint, {'name': name}).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw AuthError.fromString(
                'Request timeout: Server is not responding',
              );
            },
          );

      if (response.statusCode == 201) {
        final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
        await saveAuthData(authResponse);
        return authResponse;
      } else {
        String errorMessage = 'Unknown error';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['detail'] ?? errorData.toString();
        } catch (e) {
          errorMessage = 'Server error: ${response.statusCode}';
        }
        throw AuthError.fromString(errorMessage);
      }
    } catch (e) {
      if (e is AuthError) {
        rethrow;
      }
      if (e.toString().contains('timeout') ||
          e.toString().contains('TimeoutException')) {
        throw AuthError.fromString('Server is not responding');
      }
      throw AuthError.fromString('Network error: ${e.toString()}');
    }
  }

  /// Offline guest registration fallback.
  /// Generates a local guest profile and stores it in SharedPreferences
  /// so the app can continue without contacting the backend.
  static Future<AuthResponse> registerGuestOffline({
    required String name,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final authResponse = AuthResponse(
      accessToken: 'guest_local_token_$timestamp',
      tokenType: 'guest',
      userId: timestamp,
      username: name,
      email: null,
      isGuest: true,
      guestName: name,
      isAdmin: false,
    );

    await saveAuthData(authResponse);
    return authResponse;
  }
}
