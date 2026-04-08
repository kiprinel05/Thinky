import 'package:flutter_test/flutter_test.dart';
import 'package:thinky/base_controls/base_state.dart';

class TestState extends BaseState {
  const TestState({required super.status, super.errorMessage});
}

void main() {
  group('StateStatus', () {
    test('defines initial, loading, success, error', () {
      expect(StateStatus.values, contains(StateStatus.initial));
      expect(StateStatus.values, contains(StateStatus.loading));
      expect(StateStatus.values, contains(StateStatus.success));
      expect(StateStatus.values, contains(StateStatus.error));
    });
  });

  group('BaseState', () {
    test('initial: isInitial only; hasData false', () {
      const state = TestState(status: StateStatus.initial);

      expect(state.isInitial, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.isSuccess, isFalse);
      expect(state.isError, isFalse);
      expect(state.hasData, isFalse);
    });

    test('loading: isLoading only; hasData false', () {
      const state = TestState(status: StateStatus.loading);

      expect(state.isInitial, isFalse);
      expect(state.isLoading, isTrue);
      expect(state.isSuccess, isFalse);
      expect(state.isError, isFalse);
      expect(state.hasData, isFalse);
    });

    test('success: isSuccess; hasData true', () {
      const state = TestState(status: StateStatus.success);

      expect(state.isInitial, isFalse);
      expect(state.isLoading, isFalse);
      expect(state.isSuccess, isTrue);
      expect(state.isError, isFalse);
      expect(state.hasData, isTrue);
    });

    test('error: message set; isError; hasData true', () {
      const state = TestState(
        status: StateStatus.error,
        errorMessage: 'Something went wrong',
      );

      expect(state.isError, isTrue);
      expect(state.errorMessage, 'Something went wrong');
      expect(state.hasData, isTrue);
    });

    test('initial and loading have hasData false; error has hasData true', () {
      expect(const TestState(status: StateStatus.initial).hasData, isFalse);
      expect(const TestState(status: StateStatus.loading).hasData, isFalse);
      expect(
        const TestState(status: StateStatus.error, errorMessage: 'e').hasData,
        isTrue,
      );
    });
  });
}
