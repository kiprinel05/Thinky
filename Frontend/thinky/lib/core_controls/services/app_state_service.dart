import 'package:shared_preferences/shared_preferences.dart';

class AppStateService {
  static const String _hasSeenWelcomeKey = 'has_seen_welcome';
  static const String _lastRouteKey = 'last_route';

  static Future<void> setHasSeenWelcome(bool hasSeen) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenWelcomeKey, hasSeen);
  }

  static Future<bool> hasSeenWelcome() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSeenWelcomeKey) ?? false;
  }

  static Future<void> setLastRoute(String route) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastRouteKey, route);
  }

  static Future<String?> getLastRoute() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastRouteKey);
  }

  static Future<void> clearAppState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hasSeenWelcomeKey);
    await prefs.remove(_lastRouteKey);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
