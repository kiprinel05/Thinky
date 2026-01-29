import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:thinky/core_controls/config/app_config.dart';
import 'package:thinky/core_controls/network/api_endpoints.dart';
import 'package:thinky/core_controls/storage/local_storage.dart';
import 'package:thinky/shared/models/result.dart';
import 'package:thinky/core_controls/network/api_exceptions.dart';
import 'package:thinky/core/errors/error_logger.dart';
import 'drawing_models.dart';

/// Repository for drawing analysis API calls
class DrawingRepository {
  final LocalStorage storage;

  DrawingRepository(this.storage);

  /// Get auth token from storage
  String? get token => storage.authToken;

  Future<Result<DrawingAnalysisResult, ApiException>> analyzeDrawing({
    required Uint8List imageBytes,
    String targetShape = 'triangle',
    String targetColor = 'blue',
  }) async {
    try {
      final url = '${AppConfig.apiBaseUrl}${ApiEndpoints.drawingAnalyze}?target_shape=$targetShape&target_color=$targetColor';
      ErrorLogger().logInfo('[MULTIPART POST] Request: $url');

      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse(url));
      
      // Add auth header if available
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add the image file
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: 'drawing.png',
      ));

      // Send request
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      
      final response = await http.Response.fromStream(streamedResponse);
      
      ErrorLogger().logDebug('[MULTIPART POST] Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return Result.success(DrawingAnalysisResult.fromJson(data));
      } else if (response.statusCode == 401) {
        return const Result.failure(UnauthorizedException());
      } else {
        String message = 'Analysis failed';
        try {
          final errorData = jsonDecode(response.body);
          message = errorData['detail'] ?? message;
        } catch (_) {}
        return Result.failure(
          ServerException(message, statusCode: response.statusCode),
        );
      }
    } catch (e, stack) {
      ErrorLogger().logError('[MULTIPART POST] Error: /drawing/analyze', stackTrace: stack);
      
      if (e.toString().contains('TimeoutException') ||
          e.toString().contains('timeout')) {
        return const Result.failure(TimeoutException());
      }
      return Result.failure(NetworkException('Network error: $e'));
    }
  }
}
