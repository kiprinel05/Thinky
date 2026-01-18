import 'dart:convert';
import 'package:http/http.dart' as http;
import '../network/api_exceptions.dart';
import '../config/app_config.dart';
import '../storage/local_storage.dart';
import '../../shared/models/result.dart';

/// BaseRepository - Abstract base class for all repositories
/// Provides common API call patterns and error handling
abstract class BaseRepository {
  final LocalStorage storage;

  BaseRepository(this.storage);

  /// Get auth token from storage
  String? get token => storage.authToken;

  /// Get default headers with auth token
  Map<String, String> get headers => {
        'Content-Type': 'application/json',
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
      final response = await http
          .get(
            Uri.parse(buildUrl(endpoint)),
            headers: headers,
          )
          .timeout(timeout);

      return _handleResponse(response, parser);
    } catch (e) {
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
      final response = await http
          .post(
            Uri.parse(buildUrl(endpoint)),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(timeout);

      return _handleResponse(response, parser);
    } catch (e) {
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
      final response = await http
          .put(
            Uri.parse(buildUrl(endpoint)),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(timeout);

      return _handleResponse(response, parser);
    } catch (e) {
      return _handleException(e);
    }
  }

  /// Execute a DELETE request with error handling
  Future<Result<void, ApiException>> delete({
    required String endpoint,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      final response = await http
          .delete(
            Uri.parse(buildUrl(endpoint)),
            headers: headers,
          )
          .timeout(timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const Result.success(null);
      } else {
        return Result.failure(
          ServerException.fromStatusCode(response.statusCode),
        );
      }
    } catch (e) {
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
      return const Result.failure(UnauthorizedException());
    } else {
      String message = 'Request failed';
      try {
        final errorData = jsonDecode(response.body);
        message = errorData['detail'] ?? message;
      } catch (_) {}
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
