import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thinky/core_controls/services/text_service.dart';
import 'package:thinky/core/errors/error_logger.dart';

/// Provider for the current locale state.
final languageProvider = StateNotifierProvider<LanguageService, Locale>((ref) {
  return LanguageService(ref);
});

/// Incremented every time the translation map reloads so widgets rebuild.
/// Any widget that shows translated text should `ref.watch(textRefreshProvider)`.
final textRefreshProvider = StateProvider<int>((ref) => 0);

class LanguageService extends StateNotifier<Locale> {
  static const String _languageKey = 'app_language';
  static const Locale _defaultLocale = Locale('en');

  final Ref _ref;

  LanguageService(this._ref) : super(_defaultLocale) {
    init();
  }

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_languageKey);

      if (languageCode != null) {
        state = Locale(languageCode);
      } else {
        state = _defaultLocale;
      }

      await TextService.loadLanguage(state.languageCode);
      _ref.read(textRefreshProvider.notifier).state++;
      ErrorLogger().logInfo(
          'LanguageService initialized with locale: ${state.languageCode}');
    } catch (e, stack) {
      ErrorLogger().logError(
          'Failed to initialize LanguageService: $e',
          stackTrace: stack);
      state = _defaultLocale;
    }
  }

  Future<void> setLanguage(Locale locale) async {
    if (state == locale) return;

    try {
      await TextService.loadLanguage(locale.languageCode);

      state = locale;

      // Bump the refresh counter so every widget watching textRefreshProvider
      // rebuilds with the freshly loaded strings.
      _ref.read(textRefreshProvider.notifier).state++;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, locale.languageCode);

      ErrorLogger().logInfo('Language changed to: ${locale.languageCode}');
    } catch (e, stack) {
      ErrorLogger().logError('Failed to set language: $e', stackTrace: stack);
    }
  }
}
