import 'package:flutter_test/flutter_test.dart';
import 'package:thinky/core_controls/network/api_exceptions.dart' as api;
import 'package:thinky/core_controls/network/user_facing_error_mapper.dart';
import 'package:thinky/core_controls/services/text_service.dart';

void main() {
  setUp(() {
    TextService.loadFromMap({
      'UserErrors': {
        'wrongEmailOrPassword': 'WRONG_CREDS',
        'sessionExpiredMessage': 'SESSION',
        'couldNotConnect': 'NET',
        'requestTimedOut': 'TIME',
        'validationFailed': 'VALIDATION',
        'somethingWentWrong': 'GENERIC',
        'badRequest': 'BAD_REQ',
        'accessDenied': 'DENIED',
        'notFound': 'NF',
        'conflict': 'CF',
        'serverUnavailable': 'SRV',
      },
    });
  });

  tearDown(TextService.resetForTesting);

  group('UserFacingErrorMapper', () {
    test('AuthException maps to wrongEmailOrPassword', () {
      expect(
        UserFacingErrorMapper.map(const api.AuthException('x', 401)),
        'WRONG_CREDS',
      );
    });

    test('UnauthorizedException maps to session message', () {
      expect(
        UserFacingErrorMapper.map(const api.UnauthorizedException()),
        'SESSION',
      );
    });

    test('NetworkException maps to couldNotConnect', () {
      expect(UserFacingErrorMapper.map(const api.NetworkException()), 'NET');
    });

    test('TimeoutException maps to requestTimedOut', () {
      expect(UserFacingErrorMapper.map(const api.TimeoutException()), 'TIME');
    });

    test('ValidationException maps to validationFailed', () {
      expect(
        UserFacingErrorMapper.map(const api.ValidationException('e')),
        'VALIDATION',
      );
    });

    test('ServerException 500 maps to serverUnavailable', () {
      expect(
        UserFacingErrorMapper.map(
          api.ServerException.fromStatusCode(500),
        ),
        'SRV',
      );
    });

    test('ServerException keeps API detail when not generic phrase', () {
      expect(
        UserFacingErrorMapper.map(
          const api.ServerException('Email already taken', statusCode: 400),
        ),
        'Email already taken',
      );
    });

    test('ServerException generic 400 maps to badRequest', () {
      expect(
        UserFacingErrorMapper.map(
          api.ServerException.fromStatusCode(400),
        ),
        'BAD_REQ',
      );
    });

    test('unknown object maps to generic', () {
      expect(UserFacingErrorMapper.map(Object()), 'GENERIC');
    });
  });
}
