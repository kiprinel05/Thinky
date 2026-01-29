import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:logger/logger.dart';
import 'package:thinky/core/errors/error_logger.dart';
import 'package:thinky/core_controls/services/text_service.dart';

import 'logger_and_text_service_test.mocks.dart';

@GenerateMocks([Logger])
void main() {
  group('TextService', () {
    setUp(() {
       TextService.loadFromMap({
         'Common': {
           'ok': 'OK',
           'cancel': 'Cancel'
         },
         'Errors': {
           'unknown': 'Unknown Error'
         }
       });
    });

    test('getString returns correct value', () {
      expect(TextService.getString('Common', 'ok'), 'OK');
      expect(TextService.getString('Errors', 'unknown'), 'Unknown Error');
    });

    test('getString returns key path if missing', () {
      expect(TextService.getString('Common', 'missing'), 'Common.missing');
      expect(TextService.getString('MissingCategory', 'key'), 'MissingCategory.key');
    });
  });

  group('ErrorLogger', () {
    late MockLogger mockLogger;

    setUp(() {
      mockLogger = MockLogger();
      ErrorLogger.logger = mockLogger;
    });

    test('calls logger methods correctly', () {
      ErrorLogger().logDebug('debug message');
      verify(mockLogger.d('debug message')).called(1);

      ErrorLogger().logInfo('info message');
      verify(mockLogger.i('info message')).called(1);
      
      ErrorLogger().logError('error message');
      verify(mockLogger.e('ERROR: error message', error: 'error message', stackTrace: anyNamed('stackTrace'))).called(1);
    });
  });
}
