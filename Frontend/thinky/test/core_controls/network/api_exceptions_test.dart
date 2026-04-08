import 'package:flutter_test/flutter_test.dart';
import 'package:thinky/core/errors/exceptions.dart' show AppException;
import 'package:thinky/core_controls/network/api_exceptions.dart' as api;

void main() {
  group('NetworkException', () {
    test('uses default message', () {
      const e = api.NetworkException();
      expect(e.message, 'Network error occurred');
      expect(e.toString(), 'Network error occurred');
    });

    test('uses custom message', () {
      const e = api.NetworkException('No route to host');
      expect(e.message, 'No route to host');
      expect(e.toString(), 'No route to host');
    });
  });

  group('TimeoutException', () {
    test('uses default message', () {
      const e = api.TimeoutException();
      expect(e.message, 'Request timed out');
      expect(e.toString(), 'Request timed out');
    });

    test('uses custom message', () {
      const e = api.TimeoutException('Deadline exceeded');
      expect(e.message, 'Deadline exceeded');
    });
  });

  group('ServerException.fromStatusCode', () {
    test('maps known status codes to default messages', () {
      final cases = <int, String>{
        400: 'Bad request',
        401: 'Unauthorized',
        403: 'Forbidden',
        404: 'Not found',
        409: 'Conflict',
        422: 'Validation error',
        500: 'Internal server error',
        502: 'Bad gateway',
        503: 'Service unavailable',
      };
      for (final entry in cases.entries) {
        final e = api.ServerException.fromStatusCode(entry.key);
        expect(e.message, entry.value, reason: 'status ${entry.key}');
        expect(e.statusCode, entry.key);
      }
    });

    test('maps unknown status code to Server error', () {
      final e = api.ServerException.fromStatusCode(418);
      expect(e.message, 'Server error');
      expect(e.statusCode, 418);
    });
  });

  group('ServerException', () {
    test('fromStatusCode accepts custom message override', () {
      final e = api.ServerException.fromStatusCode(404, 'Resource missing');
      expect(e.message, 'Resource missing');
      expect(e.statusCode, 404);
    });

    test('stores responseBody', () {
      const body = <String, dynamic>{'error': 'x'};
      const e = api.ServerException(
        'Bad request',
        statusCode: 400,
        responseBody: body,
      );
      expect(e.responseBody, body);
      expect(e.statusCode, 400);
    });
  });

  group('UnauthorizedException', () {
    test('uses default message and statusCode 401', () {
      const e = api.UnauthorizedException();
      expect(e.message, 'Unauthorized');
      expect(e.statusCode, 401);
    });
  });

  group('ValidationException', () {
    test('stores optional fieldErrors', () {
      const errors = <String, List<String>>{
        'email': ['invalid format'],
      };
      const e = api.ValidationException('Invalid', fieldErrors: errors);
      expect(e.message, 'Invalid');
      expect(e.statusCode, 422);
      expect(e.fieldErrors, errors);
    });
  });

  group('AuthException', () {
    test('with message only', () {
      const e = api.AuthException('Login failed');
      expect(e.message, 'Login failed');
      expect(e.statusCode, isNull);
    });

    test('with message and statusCode', () {
      const e = api.AuthException('Wrong password', 403);
      expect(e.message, 'Wrong password');
      expect(e.statusCode, 403);
    });
  });

  group('CacheException', () {
    test('uses default message', () {
      const e = api.CacheException();
      expect(e.message, 'Cache error occurred');
    });
  });

  group('type hierarchy', () {
    test('concrete API errors are ApiException subclasses', () {
      expect(api.NetworkException(), isA<api.ApiException>());
      expect(api.TimeoutException(), isA<api.ApiException>());
      expect(api.ServerException.fromStatusCode(500), isA<api.ApiException>());
      expect(api.UnauthorizedException(), isA<api.ApiException>());
      expect(
        const api.ValidationException('x'),
        isA<api.ApiException>(),
      );
      expect(const api.AuthException('x'), isA<api.ApiException>());
      expect(api.CacheException(), isA<api.ApiException>());
    });

    test('concrete API errors are AppException subclasses', () {
      expect(api.NetworkException(), isA<AppException>());
      expect(api.TimeoutException(), isA<AppException>());
      expect(api.ServerException.fromStatusCode(500), isA<AppException>());
      expect(api.UnauthorizedException(), isA<AppException>());
      expect(
        const api.ValidationException('x'),
        isA<AppException>(),
      );
      expect(const api.AuthException('x'), isA<AppException>());
      expect(api.CacheException(), isA<AppException>());
    });
  });
}
