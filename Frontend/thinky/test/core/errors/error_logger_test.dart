import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:thinky/core/errors/error_logger.dart';

import 'error_logger_test.mocks.dart';

@GenerateMocks([Logger])
void main() {
  group('ErrorLogger', () {
    late MockLogger mockLogger;

    setUp(() {
      mockLogger = MockLogger();
      ErrorLogger.logger = mockLogger;
    });

    test('logDebug calls Logger.d with correct message', () {
      ErrorLogger().logDebug('my debug msg');
      verify(mockLogger.d('my debug msg')).called(1);
    });

    test('logInfo calls Logger.i with correct message', () {
      ErrorLogger().logInfo('my info msg');
      verify(mockLogger.i('my info msg')).called(1);
    });

    test(
      'logError calls Logger.e with error string, error object, and stackTrace',
      () {
        final stackTrace = StackTrace.fromString('#0      fake (file.dart:1:1)');
        ErrorLogger().logError('some error', stackTrace: stackTrace);
        verify(
          mockLogger.e(
            'ERROR: some error',
            error: 'some error',
            stackTrace: stackTrace,
          ),
        ).called(1);
      },
    );

    test('ErrorLogger is singleton (same instance)', () {
      expect(identical(ErrorLogger(), ErrorLogger()), isTrue);
    });
  });
}
