import 'dart:async' as async_lib;
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:thinky/core/errors/exception_mapper.dart';
import 'package:thinky/core/errors/exceptions.dart';

class _TestError extends Error {}

void main() {
  group('ExceptionMapper.map', () {
    test('returns same instance when error is already AppException', () {
      // Arrange
      const original = NetworkException('Already mapped');

      // Act
      final mapped = ExceptionMapper.map(original);

      // Assert
      expect(mapped, same(original));
      expect(mapped, isA<NetworkException>());
    });

    test('maps SocketException to NetworkException', () {
      // Arrange
      final error = SocketException('Failed host lookup');

      // Act
      final mapped = ExceptionMapper.map(error);

      // Assert
      expect(mapped, isA<NetworkException>());
      expect(
        mapped.message,
        'No Internet Connection. Please check your settings.',
      );
      expect(mapped.code, 'NETWORK_ERROR');
    });

    test('maps HttpException to NetworkException', () {
      // Arrange
      final error = HttpException('Connection closed');

      // Act
      final mapped = ExceptionMapper.map(error);

      // Assert
      expect(mapped, isA<NetworkException>());
      expect(mapped.message, 'Could not reach the server.');
      expect(mapped.code, 'NETWORK_ERROR');
    });

    test('maps FormatException to ValidationException', () {
      // Arrange
      const error = FormatException('Invalid JSON');

      // Act
      final mapped = ExceptionMapper.map(error);

      // Assert
      expect(mapped, isA<ValidationException>());
      expect(mapped.message, 'Data format error. Please try again.');
      expect(mapped.code, 'VALIDATION_ERROR');
    });

    test('maps dart:async TimeoutException to app TimeoutException', () {
      // Arrange
      final error = async_lib.TimeoutException('Future timed out');

      // Act
      final mapped = ExceptionMapper.map(error);

      // Assert
      expect(mapped, isA<TimeoutException>());
      expect(
        mapped.message,
        'The connection timed out. Please try again.',
      );
      expect(mapped.code, 'TIMEOUT');
    });

    test('maps http.ClientException to NetworkException', () {
      // Arrange
      final error = http.ClientException('client failed');

      // Act
      final mapped = ExceptionMapper.map(error);

      // Assert
      expect(mapped, isA<NetworkException>());
      expect(mapped.message, 'Network client error.');
      expect(mapped.code, 'NETWORK_ERROR');
    });

    test('maps unknown error to UnknownException', () {
      // Arrange
      const error = 'not an error type';

      // Act
      final mapped = ExceptionMapper.map(error);

      // Assert
      expect(mapped, isA<UnknownException>());
      expect(mapped.message, 'An unexpected error occurred.');
      expect(mapped.code, 'UNKNOWN');
      expect(mapped.stackTrace, isNull);
    });

    test('UnknownException carries stackTrace when error is Error', () {
      // Arrange
      final error = _TestError();

      // Act
      final mapped = ExceptionMapper.map(error);

      // Assert
      expect(mapped, isA<UnknownException>());
      expect(mapped.stackTrace, same(error.stackTrace));
    });
  });
}
