import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thinky/core_controls/services/text_service.dart';
import 'package:thinky/core/errors/error_logger.dart';

/// Provider for the current locale state
final languageProvider = StateNotifierProvider<LanguageService, Locale>((ref) {
  return LanguageService();
});

/// Service responsible for managing the application language state
class LanguageService extends StateNotifier<Locale> {
  static const String _languageKey = 'app_language';
  static const Locale _defaultLocale = Locale('en');
  
  LanguageService() : super(_defaultLocale) {
    // Sync TextService with saved language when service is first created
    init();
  }

  /// Initialize the service by loading the saved language preference
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_languageKey);
      
      if (languageCode != null) {
        state = Locale(languageCode);
      } else {
        state = _defaultLocale;
      }
      
      // Load texts for the current locale
      await TextService.loadLanguage(state.languageCode);
      ErrorLogger().logInfo('LanguageService initialized with locale: ${state.languageCode}');
    } catch (e, stack) {
      ErrorLogger().logError('Failed to initialize LanguageService: $e', stackTrace: stack);
      state = _defaultLocale;
    }
  }

  /// Change the application language and save preference
  Future<void> setLanguage(Locale locale) async {
    if (state == locale) return;

    try {
      // Load new texts first
      await TextService.loadLanguage(locale.languageCode);
      
      // Update state
      state = locale;
      
      // Persist preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, locale.languageCode);
      
      ErrorLogger().logInfo('Language changed to: ${locale.languageCode}');
    } catch (e, stack) {
      ErrorLogger().logError('Failed to set language: $e', stackTrace: stack);
    }
  }
}
