import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// LocalStorage - Wrapper for SharedPreferences
/// Provides typed access to local storage with consistent key management
class LocalStorage {
  static LocalStorage? _instance;
  late SharedPreferences _prefs;

  LocalStorage._();

  /// Protected constructor for testing subclasses
  @visibleForTesting
  LocalStorage.forTesting();

  /// Get singleton instance
  static Future<LocalStorage> getInstance() async {
    if (_instance == null) {
      _instance = LocalStorage._();
      _instance!._prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  /// For testing - allows injecting mock preferences
  static void setInstanceForTesting(LocalStorage instance) {
    _instance = instance;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STORAGE KEYS
  // ══════════════════════════════════════════════════════════════════════════

  static const String _keyAuthToken = 'auth_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUsername = 'username';
  static const String _keyEmail = 'email';
  static const String _keyIsGuest = 'is_guest';
  static const String _keyGuestName = 'guest_name';
  static const String _keyIsAdmin = 'is_admin';
  static const String _keyHasSeenWelcome = 'has_seen_welcome';
  static const String _keyLastRoute = 'last_route';

  // ══════════════════════════════════════════════════════════════════════════
  // AUTH DATA
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> setAuthToken(String token) async {
    await _prefs.setString(_keyAuthToken, token);
  }

  String? get authToken => _prefs.getString(_keyAuthToken);

  Future<void> setUserId(int id) async {
    await _prefs.setInt(_keyUserId, id);
  }

  int? get userId => _prefs.getInt(_keyUserId);

  Future<void> setUsername(String username) async {
    await _prefs.setString(_keyUsername, username);
  }

  String? get username => _prefs.getString(_keyUsername);

  Future<void> setEmail(String email) async {
    await _prefs.setString(_keyEmail, email);
  }

  String? get email => _prefs.getString(_keyEmail);

  Future<void> setIsGuest(bool isGuest) async {
    await _prefs.setBool(_keyIsGuest, isGuest);
  }

  bool get isGuest => _prefs.getBool(_keyIsGuest) ?? false;

  Future<void> setGuestName(String name) async {
    await _prefs.setString(_keyGuestName, name);
  }

  String? get guestName => _prefs.getString(_keyGuestName);

  Future<void> setIsAdmin(bool value) async {
    await _prefs.setBool(_keyIsAdmin, value);
  }

  bool get isAdmin => _prefs.getBool(_keyIsAdmin) ?? false;

  // ══════════════════════════════════════════════════════════════════════════
  // APP STATE
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> setHasSeenWelcome(bool hasSeen) async {
    await _prefs.setBool(_keyHasSeenWelcome, hasSeen);
  }

  bool get hasSeenWelcome => _prefs.getBool(_keyHasSeenWelcome) ?? false;

  Future<void> setLastRoute(String route) async {
    await _prefs.setString(_keyLastRoute, route);
  }

  String? get lastRoute => _prefs.getString(_keyLastRoute);

  // ══════════════════════════════════════════════════════════════════════════
  // CLEAR METHODS
  // ══════════════════════════════════════════════════════════════════════════

  /// Clear all auth-related data (for logout)
  Future<void> clearAuthData() async {
    await _prefs.remove(_keyAuthToken);
    await _prefs.remove(_keyUserId);
    await _prefs.remove(_keyUsername);
    await _prefs.remove(_keyEmail);
    await _prefs.remove(_keyIsGuest);
    await _prefs.remove(_keyGuestName);
    await _prefs.remove(_keyIsAdmin);
  }

  /// Clear app state (for logout)
  Future<void> clearAppState() async {
    await _prefs.remove(_keyHasSeenWelcome);
    await _prefs.remove(_keyLastRoute);
  }

  /// Clear all stored data
  Future<void> clearAll() async {
    await _prefs.clear();
  }

  /// Check if user is authenticated
  bool get isAuthenticated {
    final token = authToken;
    return token != null && token.isNotEmpty;
  }
}
