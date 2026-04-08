import 'package:flutter_test/flutter_test.dart';
import 'package:thinky/shared/models/result.dart';

void main() {
  group('Success creation and properties', () {
    test('Result.success wraps value and reports isSuccess', () {
      // Arrange
      const int value = 42;

      // Act
      final Result<int, String> result = Result.success(value);

      // Assert
      expect(result, isA<Success<int, String>>());
      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
    });

    test('valueOrNull returns the success value', () {
      // Arrange
      final Result<String, int> result = Result.success('ok');

      // Act
      final String? value = result.valueOrNull;

      // Assert
      expect(value, 'ok');
    });

    test('errorOrNull is null for success', () {
      // Arrange
      final Result<int, String> result = Result.success(1);

      // Act
      final String? error = result.errorOrNull;

      // Assert
      expect(error, isNull);
    });
  });

  group('Failure creation and properties', () {
    test('Result.failure wraps error and reports isFailure', () {
      // Arrange
      const String error = 'not found';

      // Act
      final Result<int, String> result = Result.failure(error);

      // Assert
      expect(result, isA<Failure<int, String>>());
      expect(result.isFailure, isTrue);
      expect(result.isSuccess, isFalse);
    });

    test('errorOrNull returns the failure error', () {
      // Arrange
      final Result<int, String> result = Result.failure('boom');

      // Act
      final String? error = result.errorOrNull;

      // Assert
      expect(error, 'boom');
    });

    test('valueOrNull is null for failure', () {
      // Arrange
      final Result<double, String> result = Result.failure('x');

      // Act
      final double? value = result.valueOrNull;

      // Assert
      expect(value, isNull);
    });
  });

  group('map transformation', () {
    test('maps success value and preserves error type on chained failure path', () {
      // Arrange
      final Result<int, String> result = Result.success(10);

      // Act
      final Result<String, String> mapped = result.map((v) => 'n=$v');

      // Assert
      expect(mapped.isSuccess, isTrue);
      expect(mapped.valueOrNull, 'n=10');
    });

    test('leaves failure unchanged (same error, no value transform)', () {
      // Arrange
      final Result<int, String> result = Result.failure('e');

      // Act
      final Result<int, String> mapped = result.map((v) => v * 2);

      // Assert
      expect(mapped.isFailure, isTrue);
      expect(mapped.errorOrNull, 'e');
      expect(mapped.valueOrNull, isNull);
    });
  });

  group('mapError transformation', () {
    test('maps failure error and preserves success value', () {
      // Arrange
      final Result<int, String> result = Result.failure('a');

      // Act
      final Result<int, int> mapped = result.mapError((e) => e.length);

      // Assert
      expect(mapped.isFailure, isTrue);
      expect(mapped.errorOrNull, 1);
    });

    test('leaves success unchanged', () {
      // Arrange
      final Result<int, String> result = Result.success(7);

      // Act
      final Result<int, String> mapped =
          result.mapError<String>((e) => '$e!');

      // Assert
      expect(mapped.isSuccess, isTrue);
      expect(mapped.valueOrNull, 7);
    });
  });

  group('fold', () {
    test('invokes onSuccess with value for success', () {
      // Arrange
      final Result<int, String> result = Result.success(3);
      int? successArg;
      String? failureArg;

      // Act
      final String out = result.fold(
        onSuccess: (v) {
          successArg = v;
          return 's:$v';
        },
        onFailure: (e) {
          failureArg = e;
          return 'f:$e';
        },
      );

      // Assert
      expect(out, 's:3');
      expect(successArg, 3);
      expect(failureArg, isNull);
    });

    test('invokes onFailure with error for failure', () {
      // Arrange
      final Result<int, String> result = Result.failure('err');
      int? successArg;
      String? failureArg;

      // Act
      final String out = result.fold(
        onSuccess: (v) {
          successArg = v;
          return 's:$v';
        },
        onFailure: (e) {
          failureArg = e;
          return 'f:$e';
        },
      );

      // Assert
      expect(out, 'f:err');
      expect(failureArg, 'err');
      expect(successArg, isNull);
    });
  });

  group('getOrThrow', () {
    test('returns value for success', () {
      // Arrange
      final Result<int, String> result = Result.success(99);

      // Act
      final int value = result.getOrThrow();

      // Assert
      expect(value, 99);
    });

    test('throws the error object for failure', () {
      // Arrange
      final Exception err = Exception('bad');
      final Result<int, Object> result = Result.failure(err);

      // Act & Assert
      expect(
        () => result.getOrThrow(),
        throwsA(same(err)),
      );
    });
  });

  group('getOrElse', () {
    test('returns success value without calling supplier', () {
      // Arrange
      final Result<int, String> result = Result.success(5);
      var supplierCalls = 0;

      // Act
      final int value = result.getOrElse(() {
        supplierCalls++;
        return -1;
      });

      // Assert
      expect(value, 5);
      expect(supplierCalls, 0);
    });

    test('calls supplier and returns its result for failure', () {
      // Arrange
      final Result<int, String> result = Result.failure('x');
      var supplierCalls = 0;

      // Act
      final int value = result.getOrElse(() {
        supplierCalls++;
        return 100;
      });

      // Assert
      expect(value, 100);
      expect(supplierCalls, 1);
    });
  });

  group('equality', () {
    test('Success instances with same value are equal', () {
      // Arrange
      final Result<int, String> a = Result.success(1);
      final Result<int, String> b = Result.success(1);

      // Act & Assert
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('Success instances with different values are not equal', () {
      // Arrange
      final Result<int, String> a = Result.success(1);
      final Result<int, String> b = Result.success(2);

      // Act & Assert
      expect(a, isNot(equals(b)));
    });

    test('Failure instances with same error are equal', () {
      // Arrange
      final Result<int, String> a = Result.failure('e');
      final Result<int, String> b = Result.failure('e');

      // Act & Assert
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('Failure instances with different errors are not equal', () {
      // Arrange
      final Result<int, String> a = Result.failure('a');
      final Result<int, String> b = Result.failure('b');

      // Act & Assert
      expect(a, isNot(equals(b)));
    });

    test('Success and Failure are not equal when value coincidentally matches string form', () {
      // Arrange
      final Result<String, String> success = Result.success('x');
      final Result<String, String> failure = Result.failure('x');

      // Act & Assert
      expect(success, isNot(equals(failure)));
    });
  });

  group('toString representations', () {
    test('Success toString includes value', () {
      // Arrange
      final Result<int, String> result = Result.success(42);

      // Act
      final String text = result.toString();

      // Assert
      expect(text, 'Success(42)');
    });

    test('Failure toString includes error', () {
      // Arrange
      final Result<int, String> result = Result.failure('oops');

      // Act
      final String text = result.toString();

      // Assert
      expect(text, 'Failure(oops)');
    });
  });
}
