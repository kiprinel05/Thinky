/// API Exceptions - Custom exception classes for network errors
/// Provides typed exceptions for better error handling

/// Base exception for all API errors
abstract class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

/// Network connectivity error (no internet, timeout)
class NetworkException extends ApiException {
  const NetworkException([String message = 'Network error occurred'])
      : super(message);
}

/// Request timeout error
class TimeoutException extends ApiException {
  const TimeoutException([String message = 'Request timed out'])
      : super(message);
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
  const AuthException(String message, [int? statusCode])
      : super(message, statusCode);
}

/// Local storage/cache error
class CacheException extends ApiException {
  const CacheException([String message = 'Cache error occurred'])
      : super(message);
}
