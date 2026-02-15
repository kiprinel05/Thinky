import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'; // For @visibleForTesting
import 'package:thinky/core/errors/error_logger.dart';

/// Service responsible for loading and providing translated texts from JSON
class TextService {
  static Map<String, dynamic> _texts = {};
  static bool _initialized = false;

  /// Private constructor
  TextService._();

  /// Initialize the service by loading the JSON file
  static String _currentLanguage = 'en';

  /// Initialize the service by loading the default language
  static Future<void> init({String languageCode = 'en'}) async {
    if (_initialized && _currentLanguage == languageCode) return;
    await loadLanguage(languageCode);
  }

  /// Load texts for a specific language
  static Future<void> loadLanguage(String languageCode) async {
    try {
      String jsonPath = 'assets/i18n/texts.json'; // Default english
      
      if (languageCode == 'ro') {
        jsonPath = 'assets/i18n/texts_ro.json';
      }
      
      final String jsonString = await rootBundle.loadString(jsonPath);
      _texts = jsonDecode(jsonString);
      _currentLanguage = languageCode;
      _initialized = true;
      ErrorLogger().logInfo('TextService loaded language: $languageCode from $jsonPath');
    } catch (e, stack) {
      ErrorLogger().logError('Failed to load texts for $languageCode: $e', stackTrace: stack);
      // If we fail to load specific language, try to fallback to english if not already loaded
      if (languageCode != 'en' && !_initialized) {
        await loadLanguage('en');
      } else if (!_initialized) {
        _texts = {};
      }
    }
  }

  // Helper for testing to inject texts without loading from assets
  @visibleForTesting
  static void loadFromMap(Map<String, dynamic> texts) {
    _texts = texts;
    _initialized = true;
  }

  /// Get a string value from the loaded JSON
  /// [category] corresponds to the top-level key (e.g. "Misc")
  /// [key] corresponds to the nested key (e.g. "test")
  static String getString(String category, String key) {
    if (!_initialized) {
      ErrorLogger().logInfo('TextService accessed before initialization: $category.$key');
      return '$category.$key';
    }

    final categoryMap = _texts[category];
    if (categoryMap is Map<String, dynamic>) {
      final value = categoryMap[key];
      if (value != null) {
        return value.toString();
      }
    }

    ErrorLogger().logInfo('Missing text key: $category.$key');
    return '$category.$key'; // Fallback to key name
  }
}
