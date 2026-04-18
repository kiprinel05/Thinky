import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'package:thinky/core/errors/error_logger.dart';
import 'package:thinky/core_controls/config/app_config.dart';

import 'describe_models.dart';

/// Repository for the Describe-It mission API.
///
/// Exposes two endpoints:
///  * [startMission] — preload 5 bilingual emoji scenes
///  * [transcribeAudio] — upload a recording + validate it for a round
class DescribeRepository {
  static const String _basePath = '/describe';

  static Future<DescribeStartResponse> startMission() async {
    try {
      final url = Uri.parse('${AppConfig.apiBaseUrl}$_basePath/start');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return DescribeStartResponse.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }
      throw Exception(
          'Failed to start describe mission: ${response.statusCode}');
    } catch (e, stack) {
      ErrorLogger().logError(e, stackTrace: stack);
      rethrow;
    }
  }

  static Future<DescribeAnswerResponse> transcribeAudio({
    required String filePath,
    required int questionIndex,
  }) async {
    try {
      final url =
          Uri.parse('${AppConfig.apiBaseUrl}$_basePath/transcribe');

      final request = http.MultipartRequest('POST', url);
      request.fields['questionIndex'] = questionIndex.toString();
      request.files.add(
        await http.MultipartFile.fromPath(
          'audio',
          filePath,
          contentType: MediaType('audio', 'wav'),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return DescribeAnswerResponse.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }
      throw Exception(
        'Failed to transcribe audio: ${response.statusCode} ${response.body}',
      );
    } catch (e, stack) {
      ErrorLogger().logError(e, stackTrace: stack);
      rethrow;
    }
  }
}
