import 'dart:convert';

import 'package:thinky/core/errors/error_logger.dart';
import 'package:thinky/core_controls/services/api_client.dart';

import 'pattern_models.dart';

/// Repository for the Complete-the-Pattern mission API.
class PatternRepository {
  static const String _basePath = '/pattern';

  /// Start a new run — returns the full list of preloaded rounds.
  static Future<PatternStartResponse> startMission() async {
    try {
      final response = await ApiClient.get('$_basePath/start');
      if (response.statusCode == 200) {
        return PatternStartResponse.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }
      throw Exception(
        'Failed to start pattern mission: ${response.statusCode}',
      );
    } catch (e, stack) {
      ErrorLogger().logError(e, stackTrace: stack);
      rethrow;
    }
  }

  static Future<PatternAnswerResponse> submitAnswer({
    required int questionIndex,
    required int selectedOptionId,
  }) async {
    try {
      final response = await ApiClient.post('$_basePath/answer', {
        'questionIndex': questionIndex,
        'selectedOptionId': selectedOptionId,
      });
      if (response.statusCode == 200) {
        return PatternAnswerResponse.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }
      throw Exception('Failed to submit answer: ${response.statusCode}');
    } catch (e, stack) {
      ErrorLogger().logError(e, stackTrace: stack);
      rethrow;
    }
  }

  static Future<PatternProgressResponse> getProgress() async {
    try {
      final response = await ApiClient.get('$_basePath/progress');
      if (response.statusCode == 200) {
        return PatternProgressResponse.fromJson(
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
