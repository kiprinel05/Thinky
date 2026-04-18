import 'dart:convert';

import 'package:thinky/core/errors/error_logger.dart';
import 'package:thinky/core_controls/services/api_client.dart';

import 'vocabulary_models.dart';

/// Repository for the Word Match mission API.
///
/// Images are emoji glyphs returned inline — no file-serving endpoint is
/// needed anymore.
class VocabularyRepository {
  static const String _basePath = '/vocabulary';

  /// Start a new round — returns a fresh set of bilingual questions.
  static Future<VocabStartResponse> startMission() async {
    try {
      final response = await ApiClient.get('$_basePath/start');
      if (response.statusCode == 200) {
        return VocabStartResponse.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }
      throw Exception(
        'Failed to start vocabulary mission: ${response.statusCode}',
      );
    } catch (e, stack) {
      ErrorLogger().logError(e, stackTrace: stack);
      rethrow;
    }
  }

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
        return VocabAnswerResponse.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }
      throw Exception('Failed to submit answer: ${response.statusCode}');
    } catch (e, stack) {
      ErrorLogger().logError(e, stackTrace: stack);
      rethrow;
    }
  }

  static Future<VocabProgressResponse> getProgress() async {
    try {
      final response = await ApiClient.get('$_basePath/progress');
      if (response.statusCode == 200) {
        return VocabProgressResponse.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }
      throw Exception('Failed to get progress: ${response.statusCode}');
    } catch (e, stack) {
      ErrorLogger().logError(e, stackTrace: stack);
      rethrow;
    }
  }
}
