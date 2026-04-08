import 'package:flutter_test/flutter_test.dart';
import 'package:thinky/core/errors/exceptions.dart';

/// Concrete [AppException] for testing the base [toString] when [code] is omitted.
class _TestAppException extends AppException {
  const _TestAppException(super.message, {super.code, super.stackTrace});
}

void main() {
  group('AppException (via subclass)', () {
    test('toString returns plain message when code is null', () {
      // Arrange
      const exception = _TestAppException('Something went wrong');

      // Act
      final text = exception.toString();

      // Assert
      expect(text, 'Something went wrong');
      expect(exception.code, isNull);
    });

    test('toString includes bracketed code when code is set', () {
      // Arrange
      const exception = _TestAppException('Bad request', code: 'BAD');

      // Act
      final text = exception.toString();

      // Assert
      expect(text, '[BAD] Bad request');
    });

    test('stores optional stackTrace', () {
      // Arrange
      final trace = StackTrace.current;
      final exception = _TestAppException('x', stackTrace: trace);

      // Assert
      expect(exception.stackTrace, same(trace));
    });
  });

  group('NetworkException', () {
    test('creation with message uses default code', () {
      // Arrange & Act
      const exception = NetworkException('No network');

      // Assert
      expect(exception.message, 'No network');
      expect(exception.code, 'NETWORK_ERROR');
    });

    test('creation with custom code', () {
      // Arrange & Act
      const exception = NetworkException('Down', code: 'NET_CUSTOM');

      // Assert
      expect(exception.code, 'NET_CUSTOM');
    });

    test('toString uses default code', () {
      // Arrange
      const exception = NetworkException('Offline');

      // Act & Assert
      expect(exception.toString(), '[NETWORK_ERROR] Offline');
    });

    test('toString uses custom code', () {
      // Arrange
      const exception = NetworkException('Offline', code: 'X');

      // Act & Assert
      expect(exception.toString(), '[X] Offline');
    });

    test('optional stackTrace', () {
      // Arrange
      final trace = StackTrace.current;
      final exception = NetworkException('e', stackTrace: trace);

      // Assert
      expect(exception.stackTrace, same(trace));
    });
  });

  group('TimeoutException', () {
    test('creation with message uses default code', () {
      // Arrange & Act
      const exception = TimeoutException('Slow');

      // Assert
      expect(exception.message, 'Slow');
      expect(exception.code, 'TIMEOUT');
    });

    test('creation with custom code', () {
      // Arrange & Act
      const exception = TimeoutException('Slow', code: 'T_OUT');

      // Assert
      expect(exception.code, 'T_OUT');
    });

    test('toString uses default code', () {
      // Arrange
      const exception = TimeoutException('Expired');

      // Act & Assert
      expect(exception.toString(), '[TIMEOUT] Expired');
    });

    test('toString uses custom code', () {
      // Arrange
      const exception = TimeoutException('Expired', code: 'TO');

      // Act & Assert
      expect(exception.toString(), '[TO] Expired');
    });

    test('optional stackTrace', () {
      // Arrange
      final trace = StackTrace.current;
      final exception = TimeoutException('e', stackTrace: trace);

      // Assert
      expect(exception.stackTrace, same(trace));
    });
  });

  group('ServerException', () {
    test('creation with message uses default code and null statusCode', () {
      // Arrange & Act
      const exception = ServerException('Server down');

      // Assert
      expect(exception.message, 'Server down');
      expect(exception.code, 'SERVER_ERROR');
      expect(exception.statusCode, isNull);
    });

    test('creation with custom code and statusCode', () {
      // Arrange & Act
      const exception = ServerException(
        'Error',
        code: 'SVR',
        statusCode: 503,
      );

      // Assert
      expect(exception.code, 'SVR');
      expect(exception.statusCode, 503);
    });

    test('toString uses default code', () {
      // Arrange
      const exception = ServerException('Boom', statusCode: 500);

      // Act & Assert
      expect(exception.toString(), '[SERVER_ERROR] Boom');
    });

    test('toString uses custom code', () {
      // Arrange
      const exception = ServerException('Boom', code: 'HTTP_500', statusCode: 500);

      // Act & Assert
      expect(exception.toString(), '[HTTP_500] Boom');
    });

    test('optional stackTrace', () {
      // Arrange
      final trace = StackTrace.current;
      final exception = ServerException('e', stackTrace: trace);

      // Assert
      expect(exception.stackTrace, same(trace));
    });
  });

  group('UnauthorizedException', () {
    test('creation with message uses default code', () {
      // Arrange & Act
      const exception = UnauthorizedException('Denied');

      // Assert
      expect(exception.message, 'Denied');
      expect(exception.code, 'UNAUTHORIZED');
    });

    test('creation with custom code', () {
      // Arrange & Act
      const exception = UnauthorizedException('Denied', code: 'AUTH');

      // Assert
      expect(exception.code, 'AUTH');
    });

    test('toString uses default code', () {
      // Arrange
      const exception = UnauthorizedException('No access');

      // Act & Assert
      expect(exception.toString(), '[UNAUTHORIZED] No access');
    });

    test('toString uses custom code', () {
      // Arrange
      const exception = UnauthorizedException('No access', code: '401');

      // Act & Assert
      expect(exception.toString(), '[401] No access');
    });

    test('optional stackTrace', () {
      // Arrange
      final trace = StackTrace.current;
      final exception = UnauthorizedException('e', stackTrace: trace);

      // Assert
      expect(exception.stackTrace, same(trace));
    });
  });

  group('NotFoundException', () {
    test('creation with message uses default code', () {
      // Arrange & Act
      const exception = NotFoundException('Missing');

      // Assert
      expect(exception.message, 'Missing');
      expect(exception.code, 'NOT_FOUND');
    });

    test('creation with custom code', () {
      // Arrange & Act
      const exception = NotFoundException('Missing', code: 'NF');

      // Assert
      expect(exception.code, 'NF');
    });

    test('toString uses default code', () {
      // Arrange
      const exception = NotFoundException('Nope');

      // Act & Assert
      expect(exception.toString(), '[NOT_FOUND] Nope');
    });

    test('toString uses custom code', () {
      // Arrange
      const exception = NotFoundException('Nope', code: '404');

      // Act & Assert
      expect(exception.toString(), '[404] Nope');
    });

    test('optional stackTrace', () {
      // Arrange
      final trace = StackTrace.current;
      final exception = NotFoundException('e', stackTrace: trace);

      // Assert
      expect(exception.stackTrace, same(trace));
    });
  });

  group('ValidationException', () {
    test('creation with message uses default code', () {
      // Arrange & Act
      const exception = ValidationException('Invalid');

      // Assert
      expect(exception.message, 'Invalid');
      expect(exception.code, 'VALIDATION_ERROR');
    });

    test('creation with custom code', () {
      // Arrange & Act
      const exception = ValidationException('Invalid', code: 'VAL');

      // Assert
      expect(exception.code, 'VAL');
    });

    test('toString uses default code', () {
      // Arrange
      const exception = ValidationException('Bad input');

      // Act & Assert
      expect(exception.toString(), '[VALIDATION_ERROR] Bad input');
    });

    test('toString uses custom code', () {
      // Arrange
      const exception = ValidationException('Bad input', code: 'FIELDS');

      // Act & Assert
      expect(exception.toString(), '[FIELDS] Bad input');
    });

    test('optional stackTrace', () {
      // Arrange
      final trace = StackTrace.current;
      final exception = ValidationException('e', stackTrace: trace);

      // Assert
      expect(exception.stackTrace, same(trace));
    });
  });

  group('CacheException', () {
    test('creation with message uses default code', () {
      // Arrange & Act
      const exception = CacheException('Cache miss');

      // Assert
      expect(exception.message, 'Cache miss');
      expect(exception.code, 'CACHE_ERROR');
    });

    test('creation with custom code', () {
      // Arrange & Act
      const exception = CacheException('Cache miss', code: 'CACHE');

      // Assert
      expect(exception.code, 'CACHE');
    });

    test('toString uses default code', () {
      // Arrange
      const exception = CacheException('Failed');

      // Act & Assert
      expect(exception.toString(), '[CACHE_ERROR] Failed');
    });

    test('toString uses custom code', () {
      // Arrange
      const exception = CacheException('Failed', code: 'C1');

      // Act & Assert
      expect(exception.toString(), '[C1] Failed');
    });

    test('optional stackTrace', () {
      // Arrange
      final trace = StackTrace.current;
      final exception = CacheException('e', stackTrace: trace);

      // Assert
      expect(exception.stackTrace, same(trace));
    });
  });

  group('UnknownException', () {
    test('creation with message uses default code', () {
      // Arrange & Act
      const exception = UnknownException('Weird');

      // Assert
      expect(exception.message, 'Weird');
      expect(exception.code, 'UNKNOWN');
    });

    test('creation with custom code', () {
      // Arrange & Act
      const exception = UnknownException('Weird', code: 'UKN');

      // Assert
      expect(exception.code, 'UKN');
    });

    test('toString uses default code', () {
      // Arrange
      const exception = UnknownException('Unexpected');

      // Act & Assert
      expect(exception.toString(), '[UNKNOWN] Unexpected');
    });

    test('toString uses custom code', () {
      // Arrange
      const exception = UnknownException('Unexpected', code: '???');

      // Act & Assert
      expect(exception.toString(), '[???] Unexpected');
    });

    test('optional stackTrace', () {
      // Arrange
      final trace = StackTrace.current;
      final exception = UnknownException('e', stackTrace: trace);

      // Assert
      expect(exception.stackTrace, same(trace));
    });
  });
}
