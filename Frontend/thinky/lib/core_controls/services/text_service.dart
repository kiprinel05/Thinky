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
  static Future<void> init() async {
    if (_initialized) return;

    try {
      final String jsonString = await rootBundle.loadString('assets/i18n/texts.json');
      _texts = jsonDecode(jsonString);
      _initialized = true;
      ErrorLogger().logInfo('TextService initialized successfully');
    } catch (e, stack) {
      ErrorLogger().logError('Failed to load texts: $e', stackTrace: stack);
      // Fallback empty map or retain existing to prevent crash
      _texts = {};
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
