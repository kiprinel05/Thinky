import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';

import 'package:thinky/core_controls/network/base_repository.dart';
import 'package:thinky/core_controls/config/app_config.dart';
import 'package:thinky/core_controls/network/api_endpoints.dart';
import 'package:thinky/core_controls/network/api_exceptions.dart';
import 'package:thinky/shared/models/result.dart';
import 'package:thinky/core/errors/error_logger.dart';
import '../domain/numbers_models.dart';

/// Repository for Numbers Mission API calls
class NumbersRepository extends BaseRepository {
  NumbersRepository(super.storage);

  /// Start a new numbers session
  Future<Result<NumbersSessionData, ApiException>> startSession() async {
    return post<NumbersSessionData>(
      endpoint: ApiEndpoints.numbersStart,
      body: {},
      parser: (data) => NumbersSessionData.fromJson(data),
    );
  }

  /// Get current round data
  Future<Result<NumbersRound, ApiException>> getRound() async {
    return get<NumbersRound>(
      endpoint: ApiEndpoints.numbersRound,
      parser: (data) => NumbersRound.fromJson(data),
    );
  }

  /// Submit a counting answer (Part 1)
  Future<Result<CountingResult, ApiException>> submitCount({
    required int answer,
    bool confirmed = false,
  }) async {
    return post<CountingResult>(
      endpoint: ApiEndpoints.numbersSubmitCount,
      body: {
        'answer': answer,
        'confirmed': confirmed,
      },
      parser: (data) => CountingResult.fromJson(data),
    );
  }

  /// Submit a digit drawing (Part 2) — multipart upload
  Future<Result<DrawingResult, ApiException>> submitDrawing(Uint8List imageBytes) async {
    try {
      final url = buildUrl(ApiEndpoints.numbersSubmitDrawing);
      ErrorLogger().logInfo('[POST multipart] Request: $url');

      final request = http.MultipartRequest('POST', Uri.parse(url))
        ..headers.addAll({
          if (token != null) 'Authorization': 'Bearer $token',
        })
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: 'digit.png',
          contentType: MediaType('image', 'png'),
        ));

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 15),
      );
      final response = await http.Response.fromStream(streamedResponse);

      ErrorLogger().logDebug('[POST multipart] Response: ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return Result.success(DrawingResult.fromJson(data));
      } else if (response.statusCode == 401) {
        return const Result.failure(UnauthorizedException());
      } else {
        String message = 'Request failed';
        try {
          final errorData = jsonDecode(response.body);
          message = errorData['detail'] ?? message;
        } catch (e) {
          ErrorLogger().logDebug('Could not parse error body: $e');
        }
        return Result.failure(
          ServerException(message, statusCode: response.statusCode),
        );
      }
    } catch (e, stack) {
      ErrorLogger().logError('[POST multipart] Error: drawing upload', stackTrace: stack);
      return Result.failure(NetworkException('Network error: $e'));
    }
  }

  /// Get session progress
  Future<Result<NumbersProgress, ApiException>> getProgress() async {
    return get<NumbersProgress>(
      endpoint: ApiEndpoints.numbersProgress,
      parser: (data) => NumbersProgress.fromJson(data),
    );
  }
}
