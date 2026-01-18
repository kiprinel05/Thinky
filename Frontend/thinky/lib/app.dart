import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:thinky/core_controls/routing/app_router.dart';
import 'package:thinky/shared_controls/theme/app_theme.dart';

/// ThinkyApp - Main application widget
/// Uses Riverpod for state management and go_router for navigation
class ThinkyApp extends StatelessWidget {
  const ThinkyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Thinky',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}