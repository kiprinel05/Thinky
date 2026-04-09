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
  const NetworkException(super.message, {String? code, super.stackTrace})
      : super(code: code ?? 'NETWORK_ERROR');
}

/// Timeout exception
class TimeoutException extends AppException {
  const TimeoutException(super.message, {String? code, super.stackTrace})
      : super(code: code ?? 'TIMEOUT');
}

/// Server Error (500, etc.)
class ServerException extends AppException {
  final int? statusCode;
  const ServerException(super.message, {this.statusCode, String? code, super.stackTrace})
      : super(code: code ?? 'SERVER_ERROR');
}

/// Unauthorized (401, 403)
class UnauthorizedException extends AppException {
  const UnauthorizedException(super.message, {String? code, super.stackTrace})
      : super(code: code ?? 'UNAUTHORIZED');
}

/// Not Found (404)
class NotFoundException extends AppException {
  const NotFoundException(super.message, {String? code, super.stackTrace})
      : super(code: code ?? 'NOT_FOUND');
}

/// Validation Error (400, 422, or local validation)
class ValidationException extends AppException {
  const ValidationException(super.message, {String? code, super.stackTrace})
      : super(code: code ?? 'VALIDATION_ERROR');
}

/// Cache Error
class CacheException extends AppException {
  const CacheException(super.message, {String? code, super.stackTrace})
      : super(code: code ?? 'CACHE_ERROR');
}

/// Unknown / Unexpected Error
class UnknownException extends AppException {
  const UnknownException(super.message, {String? code, super.stackTrace})
      : super(code: code ?? 'UNKNOWN');
}
