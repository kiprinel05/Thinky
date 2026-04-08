import 'dart:convert';
import 'package:thinky/core/errors/error_logger.dart';
import 'package:thinky/core_controls/services/api_client.dart';
import 'package:thinky/core_controls/config/app_config.dart';
import 'vocabulary_models.dart';

/// Repository for Vocabulary Mission API calls
class VocabularyRepository {
  static const String _basePath = '/vocabulary';

  /// Start a new vocabulary mission — returns all questions
  static Future<VocabStartResponse> startMission() async {
    try {
      final response = await ApiClient.get('$_basePath/start');
      if (response.statusCode == 200) {
        return VocabStartResponse.fromJson(jsonDecode(response.body));
      }
      throw Exception('Failed to start vocabulary mission: ${response.statusCode}');
    } catch (e, stack) {
      ErrorLogger().logError(e, stackTrace: stack);
      rethrow;
    }
  }

  /// Submit an answer for a single question
  static Future<VocabAnswerResponse> submitAnswer({
    required int questionIndex,
    required int selectedImageId,
  }) async {
    try {
      final response = await ApiClient.post('$_basePath/answer', {
        'questionIndex': questionIndex,
        'selectedImageId': selectedImageId,
      });
      if (response.statusCode == 200) {
        return VocabAnswerResponse.fromJson(jsonDecode(response.body));
      }
      throw Exception('Failed to submit answer: ${response.statusCode}');
    } catch (e, stack) {
      ErrorLogger().logError(e, stackTrace: stack);
      rethrow;
    }
  }

  /// Get current mission progress
  static Future<VocabProgressResponse> getProgress() async {
    try {
      final response = await ApiClient.get('$_basePath/progress');
      if (response.statusCode == 200) {
        return VocabProgressResponse.fromJson(jsonDecode(response.body));
      }
      throw Exception('Failed to get progress: ${response.statusCode}');
    } catch (e, stack) {
      ErrorLogger().logError(e, stackTrace: stack);
      rethrow;
    }
  }

  /// Build full image URL from relative path
  static String getImageUrl(String relativePath) {
    return '${AppConfig.apiBaseUrl}$relativePath';
  }
}
