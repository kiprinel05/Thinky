import 'dart:convert';
import 'dart:typed_data';

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

  /// Cross-platform: takes raw [audioBytes] + [filename] so the same code
  /// works on web (where there's no file system) and native.
  static Future<DescribeAnswerResponse> transcribeAudio({
    required Uint8List audioBytes,
    required String filename,
    required int questionIndex,
  }) async {
    try {
      final url =
          Uri.parse('${AppConfig.apiBaseUrl}$_basePath/transcribe');

      final request = http.MultipartRequest('POST', url);
      request.fields['questionIndex'] = questionIndex.toString();

      // Pick a reasonable MIME type from the filename's extension. Whisper
      // accepts m4a / wav / mp3 / ogg / webm — we just need to declare one.
      final ext = filename.split('.').last.toLowerCase();
      MediaType mediaType;
      switch (ext) {
        case 'm4a':
        case 'mp4':
        case 'aac':
          mediaType = MediaType('audio', 'm4a');
          break;
        case 'ogg':
        case 'opus':
          mediaType = MediaType('audio', 'ogg');
          break;
        case 'webm':
          mediaType = MediaType('audio', 'webm');
          break;
        case 'mp3':
          mediaType = MediaType('audio', 'mpeg');
          break;
        default:
          mediaType = MediaType('audio', 'wav');
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          'audio',
          audioBytes,
          filename: filename,
          contentType: mediaType,
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
