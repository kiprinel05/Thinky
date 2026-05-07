import 'dart:convert';
import 'package:thinky/core/errors/error_logger.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:thinky/core_controls/config/app_config.dart';
import 'describe_models.dart';

/// Repository for Describe Mission API calls.
///
/// Handles starting the mission and uploading audio
/// as multipart form data for Whisper transcription.
class DescribeRepository {
  static const String _basePath = '/describe';

  /// Start a new describe mission — get image + keywords
  static Future<DescribeStartResponse> startMission() async {
    try {
      final url = Uri.parse('${AppConfig.apiBaseUrl}$_basePath/start');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return DescribeStartResponse.fromJson(jsonDecode(response.body));
      }
      throw Exception('Failed to start describe mission: ${response.statusCode}');
    } catch (e, stack) {
      ErrorLogger().logError(e, stackTrace: stack);
      rethrow;
    }
  }

  /// Get the next round image
  static Future<DescribeStartResponse> nextRound() async {
    try {
      final url = Uri.parse('${AppConfig.apiBaseUrl}$_basePath/next');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return DescribeStartResponse.fromJson(jsonDecode(response.body));
      }
      throw Exception('Failed to get next round: ${response.statusCode}');
    } catch (e, stack) {
      ErrorLogger().logError(e, stackTrace: stack);
      rethrow;
    }
  }

  /// Upload audio file for transcription + validation.
  ///
  /// Sends the audio as multipart/form-data to POST /transcribe.
  static Future<TranscriptionResponse> transcribeAudio(String filePath) async {
    try {
      final url = Uri.parse('${AppConfig.apiBaseUrl}$_basePath/transcribe');

      final request = http.MultipartRequest('POST', url);
      request.files.add(await http.MultipartFile.fromPath(
        'audio',
        filePath,
        contentType: MediaType('audio', 'wav'),
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return TranscriptionResponse.fromJson(jsonDecode(response.body));
      }
      throw Exception(
          'Failed to transcribe audio: ${response.statusCode} ${response.body}');
    } catch (e, stack) {
      ErrorLogger().logError(e, stackTrace: stack);
      rethrow;
    }
  }

  /// Submit text description for validation.
  static Future<TranscriptionResponse> submitText(String text) async {
    try {
      final url = Uri.parse('${AppConfig.apiBaseUrl}$_basePath/submit-text');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      );
      if (response.statusCode == 200) {
        return TranscriptionResponse.fromJson(jsonDecode(response.body));
      }
      throw Exception(
          'Failed to submit text: ${response.statusCode} ${response.body}');
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
