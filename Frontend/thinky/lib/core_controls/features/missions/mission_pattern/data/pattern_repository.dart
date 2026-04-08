import 'dart:convert';
import 'package:thinky/core/errors/error_logger.dart';
import 'package:thinky/core_controls/services/api_client.dart';
import 'pattern_models.dart';

class PatternRepository {
  static const String _basePath = '/pattern';

  /// Start a new pattern mission
  static Future<PatternStartResponse> startMission() async {
    try {
      final response = await ApiClient.get('$_basePath/start');
      if (response.statusCode == 200) {
        return PatternStartResponse.fromJson(jsonDecode(response.body));
      }
      throw Exception('Failed to start pattern mission: ${response.statusCode}');
    } catch (e, stack) {
      ErrorLogger().logError(e, stackTrace: stack);
      rethrow;
    }
  }

  /// Get the next round
  static Future<PatternStartResponse> nextRound() async {
    try {
      final response = await ApiClient.get('$_basePath/next');
      if (response.statusCode == 200) {
        return PatternStartResponse.fromJson(jsonDecode(response.body));
      }
      throw Exception('Failed to get next round: ${response.statusCode}');
    } catch (e, stack) {
      ErrorLogger().logError(e, stackTrace: stack);
      rethrow;
    }
  }

  /// Submit answer
  static Future<PatternResultResponse> submitAnswer(String selectedOptionId) async {
    try {
      final response = await ApiClient.post(
        '$_basePath/answer',
        {'selectedOptionId': selectedOptionId},
      );
      if (response.statusCode == 200) {
        return PatternResultResponse.fromJson(jsonDecode(response.body));
      }
      throw Exception('Failed to submit answer: ${response.statusCode}');
    } catch (e, stack) {
      ErrorLogger().logError(e, stackTrace: stack);
      rethrow;
    }
  }
}
