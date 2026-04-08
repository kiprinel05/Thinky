import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thinky/core/errors/error_logger.dart';

final themeModeProvider =
    StateNotifierProvider<ThemeService, ThemeMode>((ref) => ThemeService());

class ThemeService extends StateNotifier<ThemeMode> {
  static const String _themeKey = 'app_theme_mode';

  ThemeService() : super(ThemeMode.light) {
    _load();
  }

  bool get isDarkMode => state == ThemeMode.dark;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString(_themeKey);
      if (value == 'dark') {
        state = ThemeMode.dark;
      } else if (value == 'system') {
        state = ThemeMode.system;
      }
    } catch (e, stack) {
      ErrorLogger().logError('ThemeService load failed: $e', stackTrace: stack);
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (state == mode) return;
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, mode.name);
      ErrorLogger().logInfo('Theme changed to: ${mode.name}');
    } catch (e, stack) {
      ErrorLogger().logError('ThemeService save failed: $e', stackTrace: stack);
    }
  }

  Future<void> toggleDarkMode() async {
    await setThemeMode(isDarkMode ? ThemeMode.light : ThemeMode.dark);
  }
}
