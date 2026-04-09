import 'package:thinky/core_controls/network/api_exceptions.dart' as api;
import 'package:thinky/core_controls/services/text_service.dart';

/// Maps API / thrown errors to short, localized messages for banners and UI.
class UserFacingErrorMapper {
  UserFacingErrorMapper._();

  static String _u(String key) => TextService.getString('UserErrors', key);

  static String _defaultForStatus(int? code) {
    if (code == null) return _u('somethingWentWrong');
    if (code >= 500) return _u('serverUnavailable');
    return switch (code) {
      400 => _u('badRequest'),
      401 => _u('somethingWentWrong'),
      403 => _u('accessDenied'),
      404 => _u('notFound'),
      409 => _u('conflict'),
      422 => _u('validationFailed'),
      _ => _u('somethingWentWrong'),
    };
  }

  /// True when [message] matches the generic phrase from [api.ServerException.fromStatusCode].
  static bool _isGenericStatusPhrase(String message, int? code) {
    if (code == null) return false;
    final generic = api.ServerException.fromStatusCode(code).message;
    return message.trim().toLowerCase() == generic.toLowerCase();
  }

  static String map(Object error) {
    if (error is api.AuthException) {
      return _u('wrongEmailOrPassword');
    }
    if (error is api.UnauthorizedException) {
      return _u('sessionExpiredMessage');
    }
    if (error is api.NetworkException) {
      return _u('couldNotConnect');
    }
    if (error is api.TimeoutException) {
      return _u('requestTimedOut');
    }
    if (error is api.ValidationException) {
      return _u('validationFailed');
    }
    if (error is api.CacheException) {
      return _u('somethingWentWrong');
    }
    if (error is api.ServerException) {
      final msg = error.message.trim();
      if (msg.contains('Failed to parse response')) {
        return _u('somethingWentWrong');
      }
      final code = error.statusCode;
      if (code != null && code >= 500) {
        return _u('serverUnavailable');
      }
      if (msg.isNotEmpty && !_isGenericStatusPhrase(msg, code)) {
        return msg;
      }
      return _defaultForStatus(code);
    }

    final s = error.toString();
    if (s.contains('TimeoutException') || s.toLowerCase().contains('timeout')) {
      return _u('requestTimedOut');
    }
    if (s.toLowerCase().contains('socketexception') ||
        s.toLowerCase().contains('failed host lookup') ||
        s.toLowerCase().contains('network is unreachable')) {
      return _u('couldNotConnect');
    }

    return _u('somethingWentWrong');
  }
}
