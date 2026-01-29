import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'route_names.dart';
import 'package:thinky/core_controls/features/onboarding/presentation/intro_page.dart';
import 'package:thinky/core_controls/features/welcome/presentation/welcome_page.dart';
import 'package:thinky/core_controls/features/auth/presentation/login_page.dart';
import 'package:thinky/core_controls/features/auth/presentation/register_page.dart';
import 'package:thinky/core_controls/features/auth/presentation/guest_name_page.dart';
import 'package:thinky/core_controls/features/auth/presentation/forgot_password_page.dart';
import 'package:thinky/core_controls/features/auth/presentation/profile_page.dart';
import 'package:thinky/core_controls/features/missions/presentation/missions_menu_page.dart';
import 'package:thinky/core_controls/features/missions/mission_pixy_learns/presentation/pages/pixy_learns_page.dart';
import 'package:thinky/core_controls/features/missions/mission_quiz/presentation/pages/quiz_page_new.dart';
import 'package:thinky/core_controls/features/missions/mission_drawing/presentation/draw_triangle_page.dart';
import '../services/auth_service.dart';
import '../services/app_state_service.dart';
import 'package:thinky/core/errors/error_logger.dart';

/// AppRouter - Centralized routing configuration using go_router
/// Handles navigation guards, redirects, and all app routes
class AppRouter {
  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  /// The main router instance
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: true,
    redirect: _guardRedirect,
    observers: [LoggingNavigatorObserver()],
    routes: _routes,
  );

  /// Navigation guard - handles auth redirects
  static Future<String?> _guardRedirect(
    BuildContext context,
    GoRouterState state,
  ) async {
    final isAuthenticated = await AuthService.isAuthenticated();
    final hasSeenWelcome = await AppStateService.hasSeenWelcome();
    final currentPath = state.uri.path;

    // Public routes that don't require auth
    const publicRoutes = [
      RouteNames.splash,
      RouteNames.intro,
      RouteNames.login,
      RouteNames.register,
      RouteNames.guestName,
      RouteNames.forgotPassword,
    ];

    // Splash screen logic
    if (currentPath == RouteNames.splash) {
      if (!isAuthenticated) {
        return RouteNames.intro;
      } else if (!hasSeenWelcome) {
        return RouteNames.welcome;
      } else {
        return RouteNames.missions;
      }
    }

    // Protect authenticated routes
    if (!isAuthenticated && !publicRoutes.contains(currentPath)) {
      return RouteNames.intro;
    }

    return null; // No redirect needed
  }

  /// All app routes
  static final List<RouteBase> _routes = [
    // Splash / Loading
    GoRoute(
      path: RouteNames.splash,
      builder: (context, state) => const _SplashScreen(),
    ),

    // Onboarding
    GoRoute(
      path: RouteNames.intro,
      builder: (context, state) => const IntroPage(),
    ),

    // Authentication
    GoRoute(
      path: RouteNames.login,
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: RouteNames.register,
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: RouteNames.guestName,
      builder: (context, state) => const GuestNamePage(),
    ),
    GoRoute(
      path: RouteNames.forgotPassword,
      builder: (context, state) => const ForgotPasswordPage(),
    ),
    GoRoute(
      path: RouteNames.profile,
      builder: (context, state) => const ProfilePage(),
    ),

    // Welcome
    GoRoute(
      path: RouteNames.welcome,
      builder: (context, state) => const WelcomePage(),
    ),

    // Missions
    GoRoute(
      path: RouteNames.missions,
      builder: (context, state) => const MissionsMenuPage(),
    ),
    GoRoute(
      path: RouteNames.pixyLearns,
      builder: (context, state) => const PixyLearnsPage(),
    ),

    // Quiz
    GoRoute(
      path: RouteNames.quiz,
      builder: (context, state) => const QuizPageNew(),
    ),

    // Drawing Mission
    GoRoute(
      path: RouteNames.drawTriangle,
      builder: (context, state) => const DrawTrianglePage(),
    ),
  ];
}

/// Simple splash screen while checking auth status
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

/// Extension for easy navigation
extension GoRouterExtension on BuildContext {
  /// Navigate to a route, replacing the current route
  void goToRoute(String path, {Object? extra}) {
    GoRouter.of(this).go(path, extra: extra);
  }

  /// Push a route onto the stack
  void pushRoute(String path, {Object? extra}) {
    GoRouter.of(this).push(path, extra: extra);
  }

  /// Pop the current route
  void popRoute<T extends Object?>([T? result]) {
    GoRouter.of(this).pop(result);
  }

  /// Check if can pop
  bool canPopRoute() {
    return GoRouter.of(this).canPop();
  }
}

/// Observer for navigation events to log them using LoggerService
class LoggingNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    ErrorLogger().logDebug('Navigation PUSH: ${route.settings.name}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    ErrorLogger().logDebug('Navigation POP: ${route.settings.name}');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    ErrorLogger().logDebug('Navigation REPLACE: ${newRoute?.settings.name}');
  }
}

