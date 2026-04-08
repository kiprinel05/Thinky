import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thinky/shared_controls/theme/app_theme.dart';

/// Wraps a widget in MaterialApp + Theme + Riverpod for widget testing.
/// Use this instead of manually creating MaterialApp in every widget test.
class TestAppWrapper extends StatelessWidget {
  final Widget child;
  final List<Override>? providerOverrides;
  final NavigatorObserver? navigatorObserver;

  const TestAppWrapper({
    super.key,
    required this.child,
    this.providerOverrides,
    this.navigatorObserver,
  });

  @override
  Widget build(BuildContext context) {
    final app = MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(body: child),
      navigatorObservers: [
        if (navigatorObserver != null) navigatorObserver!,
      ],
    );

    if (providerOverrides != null && providerOverrides!.isNotEmpty) {
      return ProviderScope(
        overrides: providerOverrides!,
        child: app,
      );
    }

    return ProviderScope(child: app);
  }
}
