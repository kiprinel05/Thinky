/// Base class for all application exceptions
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final StackTrace? stackTrace;

  const AppException(this.message, {this.code, this.stackTrace});

  @override
  String toString() {
    if (code != null) {
      return '[$code] $message';
    }
    return message;
  }
}

/// Generic network exception (no internet, socket error)
class NetworkException extends AppException {
  const NetworkException(String message, {String? code, StackTrace? stackTrace})
      : super(message, code: code ?? 'NETWORK_ERROR', stackTrace: stackTrace);
}

/// Timeout exception
class TimeoutException extends AppException {
  const TimeoutException(String message, {String? code, StackTrace? stackTrace})
      : super(message, code: code ?? 'TIMEOUT', stackTrace: stackTrace);
}

/// Server Error (500, etc.)
class ServerException extends AppException {
  final int? statusCode;
  const ServerException(String message, {this.statusCode, String? code, StackTrace? stackTrace})
      : super(message, code: code ?? 'SERVER_ERROR', stackTrace: stackTrace);
}

/// Unauthorized (401, 403)
class UnauthorizedException extends AppException {
  const UnauthorizedException(String message, {String? code, StackTrace? stackTrace})
      : super(message, code: code ?? 'UNAUTHORIZED', stackTrace: stackTrace);
}

/// Not Found (404)
class NotFoundException extends AppException {
  const NotFoundException(String message, {String? code, StackTrace? stackTrace})
      : super(message, code: code ?? 'NOT_FOUND', stackTrace: stackTrace);
}

/// Validation Error (400, 422, or local validation)
class ValidationException extends AppException {
  const ValidationException(String message, {String? code, StackTrace? stackTrace})
      : super(message, code: code ?? 'VALIDATION_ERROR', stackTrace: stackTrace);
}

/// Cache Error
class CacheException extends AppException {
  const CacheException(String message, {String? code, StackTrace? stackTrace})
      : super(message, code: code ?? 'CACHE_ERROR', stackTrace: stackTrace);
}

/// Unknown / Unexpected Error
class UnknownException extends AppException {
  const UnknownException(String message, {String? code, StackTrace? stackTrace})
      : super(message, code: code ?? 'UNKNOWN', stackTrace: stackTrace);
}
