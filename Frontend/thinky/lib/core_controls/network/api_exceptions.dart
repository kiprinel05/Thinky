import 'package:thinky/core/errors/exceptions.dart';

/// Base exception for all API errors — extends AppException for unified handling
abstract class ApiException extends AppException {
  final int? statusCode;

  const ApiException(super.message, [this.statusCode])
      : super(code: 'API_ERROR');

  @override
  String toString() => message;
}

/// Network connectivity error (no internet, timeout)
class NetworkException extends ApiException {
  const NetworkException([super.message = 'Network error occurred']);
}

/// Request timeout error
class TimeoutException extends ApiException {
  const TimeoutException([super.message = 'Request timed out']);
}

/// Server returned an error response (4xx, 5xx)
class ServerException extends ApiException {
  final Map<String, dynamic>? responseBody;

  const ServerException(
    String message, {
    int? statusCode,
    this.responseBody,
  }) : super(message, statusCode);

  factory ServerException.fromStatusCode(int statusCode, [String? message]) {
    final defaultMessage = switch (statusCode) {
      400 => 'Bad request',
      401 => 'Unauthorized',
      403 => 'Forbidden',
      404 => 'Not found',
      409 => 'Conflict',
      422 => 'Validation error',
      500 => 'Internal server error',
      502 => 'Bad gateway',
      503 => 'Service unavailable',
      _ => 'Server error',
    };
    return ServerException(
      message ?? defaultMessage,
      statusCode: statusCode,
    );
  }
}

/// Unauthorized (401) - Token expired or invalid
class UnauthorizedException extends ApiException {
  const UnauthorizedException([String message = 'Unauthorized'])
      : super(message, 401);
}

/// Validation error (422)
class ValidationException extends ApiException {
  final Map<String, List<String>>? fieldErrors;

  const ValidationException(
    String message, {
    this.fieldErrors,
  }) : super(message, 422);
}

/// Authentication error (login failed, wrong credentials)
class AuthException extends ApiException {
  const AuthException(super.message, [super.statusCode]);
}

/// Local storage/cache error
class CacheException extends ApiException {
  const CacheException([super.message = 'Cache error occurred']);
}
