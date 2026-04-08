import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thinky/core_controls/services/api_client.dart';
import 'package:thinky/core_controls/services/text_service.dart';
import 'package:thinky/core/errors/error_logger.dart';
import 'package:logger/logger.dart';
import 'package:mockito/mockito.dart';

/// Initialize SharedPreferences with given values for testing
Future<void> initTestPrefs([Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues(values);
}

/// Initialize TextService with a test map (no asset loading)
void initTestTexts([Map<String, dynamic>? texts]) {
  TextService.loadFromMap(texts ?? {});
}

/// Inject a MockClient into ApiClient for testing
void injectMockHttpClient(http.Client mockClient) {
  ApiClient.client = mockClient;
}

/// Create a successful HTTP response
http.Response successResponse(
  dynamic body, {
  int statusCode = 200,
  Map<String, String>? headers,
}) {
  return http.Response(
    body is String ? body : jsonEncode(body),
    statusCode,
    headers: headers ?? {'content-type': 'application/json'},
  );
}

/// Create an error HTTP response
http.Response errorResponse({
  int statusCode = 400,
  String detail = 'Bad Request',
}) {
  return http.Response(
    jsonEncode({'detail': detail}),
    statusCode,
    headers: {'content-type': 'application/json'},
  );
}

/// Create a mock Logger and inject it into ErrorLogger
Logger createMockLogger() {
  final mockLogger = _MockLoggerForHelper();
  ErrorLogger.logger = mockLogger;
  return mockLogger;
}

class _MockLoggerForHelper extends Mock implements Logger {}
