import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:thinky/core_controls/network/api_exceptions.dart';
import 'package:thinky/core_controls/config/app_config.dart';
import 'package:thinky/core_controls/storage/local_storage.dart';
import 'package:thinky/core_controls/services/text_service.dart';
import 'package:thinky/shared/models/result.dart';
import 'package:thinky/core/errors/error_logger.dart';

/// BaseRepository - Abstract base class for all repositories
/// Provides common API call patterns and error handling
abstract class BaseRepository {
  final LocalStorage storage;

  BaseRepository(this.storage);

  /// Get auth token from storage
  String? get token => storage.authToken;

  /// Get default headers with auth token + current language
  Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Accept-Language': TextService.currentLanguageCode,
        if (token != null) 'Authorization': 'Bearer $token',
      };

  /// Build full URL from endpoint
  String buildUrl(String endpoint) => '${AppConfig.apiBaseUrl}$endpoint';

  /// Execute a GET request with error handling
  Future<Result<T, ApiException>> get<T>({
    required String endpoint,
    required T Function(dynamic data) parser,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      final url = buildUrl(endpoint);
      ErrorLogger().logInfo('[GET] Request: $url');
      
      final response = await http
          .get(
            Uri.parse(url),
            headers: headers,
          )
          .timeout(timeout);

      ErrorLogger().logDebug('[GET] Response: ${response.statusCode} - ${response.body}');
      return _handleResponse(response, parser);
    } catch (e, stack) {
      ErrorLogger().logError('[GET] Error: $endpoint', stackTrace: stack);
      return _handleException(e);
    }
  }

  /// Execute a POST request with error handling
  Future<Result<T, ApiException>> post<T>({
    required String endpoint,
    required Map<String, dynamic> body,
    required T Function(dynamic data) parser,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      final url = buildUrl(endpoint);
      final jsonBody = jsonEncode(body);
      ErrorLogger().logInfo('[POST] Request: $url\nBody: $jsonBody');

      final response = await http
          .post(
            Uri.parse(url),
            headers: headers,
            body: jsonBody,
          )
          .timeout(timeout);

      ErrorLogger().logDebug('[POST] Response: ${response.statusCode} - ${response.body}');
      return _handleResponse(response, parser);
    } catch (e, stack) {
      ErrorLogger().logError('[POST] Error: $endpoint', stackTrace: stack);
      return _handleException(e);
    }
  }

  /// Execute a PUT request with error handling
  Future<Result<T, ApiException>> put<T>({
    required String endpoint,
    required Map<String, dynamic> body,
    required T Function(dynamic data) parser,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      final url = buildUrl(endpoint);
      final jsonBody = jsonEncode(body);
      ErrorLogger().logInfo('[PUT] Request: $url\nBody: $jsonBody');

      final response = await http
          .put(
            Uri.parse(url),
            headers: headers,
            body: jsonBody,
          )
          .timeout(timeout);

      ErrorLogger().logDebug('[PUT] Response: ${response.statusCode} - ${response.body}');
      return _handleResponse(response, parser);
    } catch (e, stack) {
      ErrorLogger().logError('[PUT] Error: $endpoint', stackTrace: stack);
      return _handleException(e);
    }
  }

  /// Execute a DELETE request with error handling
  Future<Result<void, ApiException>> delete({
    required String endpoint,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      final url = buildUrl(endpoint);
      ErrorLogger().logInfo('[DELETE] Request: $url');

      final response = await http
          .delete(
            Uri.parse(url),
            headers: headers,
          )
          .timeout(timeout);

      ErrorLogger().logDebug('[DELETE] Response: ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const Result.success(null);
      } else {
        return Result.failure(
          ServerException.fromStatusCode(response.statusCode),
        );
      }
    } catch (e, stack) {
      ErrorLogger().logError('[DELETE] Error: $endpoint', stackTrace: stack);
      return _handleException(e);
    }
  }

  /// Handle HTTP response
  Result<T, ApiException> _handleResponse<T>(
    http.Response response,
    T Function(dynamic data) parser,
  ) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final data = jsonDecode(response.body);
        return Result.success(parser(data));
      } catch (e) {
        return Result.failure(
          ServerException('Failed to parse response: $e'),
        );
      }
    } else if (response.statusCode == 401) {
      String? detail;
      try {
        final errorData = jsonDecode(response.body);
        final d = errorData['detail'];
        if (d != null) detail = d.toString();
      } catch (e) {
        ErrorLogger().logDebug('Could not parse 401 body: $e');
      }
      if (token == null) {
        return Result.failure(
          AuthException(detail ?? 'Invalid credentials', 401),
        );
      }
      return Result.failure(
        UnauthorizedException(detail ?? 'Unauthorized'),
      );
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
  }

  /// Handle exceptions
  Result<T, ApiException> _handleException<T>(Object e) {
    if (e is ApiException) {
      return Result.failure(e);
    } else if (e.toString().contains('TimeoutException') ||
        e.toString().contains('timeout')) {
      return const Result.failure(TimeoutException());
    } else {
      return Result.failure(NetworkException('Network error: $e'));
    }
  }
}

/// BaseReadRepository - Repository for read-only operations
abstract class BaseReadRepository<T> extends BaseRepository {
  BaseReadRepository(super.storage);

  /// Get all items
  Future<Result<List<T>, ApiException>> getAll();

  /// Get item by ID
  Future<Result<T, ApiException>> getById(int id);
}

/// BaseCrudRepository - Repository with full CRUD operations
abstract class BaseCrudRepository<T> extends BaseReadRepository<T> {
  BaseCrudRepository(super.storage);

  /// Create new item
  Future<Result<T, ApiException>> create(Map<String, dynamic> data);

  /// Update existing item
  Future<Result<T, ApiException>> update(int id, Map<String, dynamic> data);

  /// Delete item
  Future<Result<void, ApiException>> deleteItem(int id);
}
