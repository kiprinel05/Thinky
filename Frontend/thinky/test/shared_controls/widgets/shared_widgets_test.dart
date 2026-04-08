import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thinky/shared_controls/widgets/error_message_banner.dart';
import 'package:thinky/shared_controls/widgets/or_divider.dart';
import 'package:thinky/shared_controls/widgets/states/error_state_widget.dart';
import 'package:thinky/shared_controls/widgets/states/empty_state_widget.dart';
import 'package:thinky/shared_controls/widgets/states/loading_state_widget.dart';
import 'package:thinky/test_support/test_wrappers/test_app_wrapper.dart';

void main() {
  group('ErrorMessageBanner', () {
    testWidgets('renders the message text', (tester) async {
      // Arrange
      const message = 'Test error';

      // Act
      await tester.pumpWidget(
        TestAppWrapper(child: ErrorMessageBanner(message: message)),
      );

      // Assert
      expect(find.text(message), findsOneWidget);
    });

    testWidgets('shows error icon', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        TestAppWrapper(
          child: const ErrorMessageBanner(message: 'Any'),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });

  group('OrDivider', () {
    testWidgets('renders the text', (tester) async {
      // Arrange
      const label = 'OR';

      // Act
      await tester.pumpWidget(
        TestAppWrapper(child: const OrDivider(text: label)),
      );

      // Assert
      expect(find.text(label), findsOneWidget);
    });

    testWidgets('shows two dividers', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        TestAppWrapper(child: const OrDivider(text: 'or')),
      );

      // Assert
      expect(find.byType(Divider), findsNWidgets(2));
    });
  });

  group('ErrorStateWidget', () {
    testWidgets('renders message', (tester) async {
      // Arrange
      const message = 'Something went wrong';

      // Act
      await tester.pumpWidget(
        TestAppWrapper(
          child: const ErrorStateWidget(message: message),
        ),
      );

      // Assert
      expect(find.text(message), findsOneWidget);
    });

    testWidgets('shows retry button when onRetry is provided', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        TestAppWrapper(
          child: ErrorStateWidget(
            message: 'Failed',
            onRetry: () {},
          ),
        ),
      );

      // Assert
      expect(find.widgetWithText(ElevatedButton, 'Try again'), findsOneWidget);
    });

    testWidgets('hides retry button when onRetry is null', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        TestAppWrapper(
          child: const ErrorStateWidget(message: 'Failed'),
        ),
      );

      // Assert
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.text('Try again'), findsNothing);
    });

    testWidgets('onRetry callback fires on tap', (tester) async {
      // Arrange
      var tapped = false;

      // Act
      await tester.pumpWidget(
        TestAppWrapper(
          child: ErrorStateWidget(
            message: 'Failed',
            onRetry: () => tapped = true,
          ),
        ),
      );
      await tester.tap(find.text('Try again'));
      await tester.pump();

      // Assert
      expect(tapped, isTrue);
    });
  });

  group('EmptyStateWidget', () {
    testWidgets('renders message', (tester) async {
      // Arrange
      const message = 'No items yet';

      // Act
      await tester.pumpWidget(
        TestAppWrapper(
          child: const EmptyStateWidget(message: message),
        ),
      );

      // Assert
      expect(find.text(message), findsOneWidget);
    });

    testWidgets('shows default icon', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        TestAppWrapper(
          child: const EmptyStateWidget(message: 'Empty'),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    });
  });

  group('LoadingStateWidget', () {
    testWidgets('shows spinner', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        TestAppWrapper(child: const LoadingStateWidget()),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows message when provided', (tester) async {
      // Arrange
      const message = 'Loading data…';

      // Act
      await tester.pumpWidget(
        TestAppWrapper(
          child: const LoadingStateWidget(message: message),
        ),
      );

      // Assert
      expect(find.text(message), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('hides message when null', (tester) async {
      // Arrange
      const wouldBeMessage = 'This should not appear';

      // Act
      await tester.pumpWidget(
        TestAppWrapper(child: const LoadingStateWidget()),
      );

      // Assert
      expect(find.text(wouldBeMessage), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
