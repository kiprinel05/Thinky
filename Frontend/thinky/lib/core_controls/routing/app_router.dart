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
import 'package:thinky/core_controls/features/navigation/main_shell_page.dart';
import 'package:thinky/core_controls/features/missions/presentation/missions_menu_page.dart';
import 'package:thinky/core_controls/features/missions/mission_pixy_learns/presentation/pages/pixy_learns_page.dart';
import 'package:thinky/core_controls/features/missions/mission_quiz/presentation/pages/quiz_page_new.dart';
import 'package:thinky/core_controls/features/missions/mission_drawing/presentation/draw_triangle_page.dart';
import 'package:thinky/core_controls/features/missions/mission_drawing/presentation/color_circle_page.dart';
import 'package:thinky/core_controls/features/missions/mission_animals/presentation/pages/animals_mission_page.dart';
import 'package:thinky/core_controls/features/missions/mission_grouping/presentation/pages/grouping_mission_page.dart';
import 'package:thinky/core_controls/features/missions/mission_vocabulary/presentation/pages/vocabulary_mission_page.dart';
import 'package:thinky/core_controls/features/missions/mission_describe/presentation/pages/describe_mission_page.dart';
import 'package:thinky/core_controls/features/missions/mission_pattern/presentation/pages/pattern_mission_page.dart';
import 'package:thinky/core_controls/features/missions/mission_numbers/presentation/pages/numbers_mission_page.dart';
import 'package:thinky/core_controls/features/workshop/presentation/workshop_browse_page.dart';
import 'package:thinky/core_controls/features/workshop/presentation/workshop_detail_page.dart';
import 'package:thinky/core_controls/features/workshop/presentation/create_mission_page.dart';
import 'package:thinky/core_controls/features/workshop/presentation/my_missions_page.dart';
import 'package:thinky/core_controls/features/workshop/presentation/workshop_play_page.dart';
import 'package:thinky/core_controls/features/mascot/presentation/mascot_chat_page.dart';
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

    // Welcome
    GoRoute(
      path: RouteNames.welcome,
      builder: (context, state) => const WelcomePage(),
    ),

    // Main Shell — bottom navigation bar wraps Missions and Profile
    ShellRoute(
      builder: (context, state, child) => MainShellPage(child: child),
      routes: [
        GoRoute(
          path: RouteNames.missions,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: MissionsMenuPage(),
          ),
        ),
        GoRoute(
          path: RouteNames.profile,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ProfilePage(),
          ),
        ),
        GoRoute(
          path: RouteNames.workshop,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: WorkshopBrowsePage(),
          ),
        ),
        GoRoute(
          path: '/mascot-chat',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: MascotChatPage(),
          ),
        ),
      ],
    ),

    // Individual mission routes — full-screen without nav bar
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

    // Color Circle Mission
    GoRoute(
      path: RouteNames.colorCircle,
      builder: (context, state) => const ColorCirclePage(),
    ),

    // Animals Mission
    GoRoute(
      path: RouteNames.animalsMission,
      builder: (context, state) => const AnimalsMissionPage(),
    ),

    // Grouping Mission
    GoRoute(
      path: RouteNames.groupingMission,
      builder: (context, state) => const GroupingMissionPage(),
    ),

    // Vocabulary Mission
    GoRoute(
      path: RouteNames.vocabularyMission,
      builder: (context, state) => const VocabularyMissionPage(),
    ),

    // Describe Mission
    GoRoute(
      path: RouteNames.describeMission,
      builder: (context, state) => const DescribeMissionPage(),
    ),

    // Pattern Mission
    GoRoute(
      path: RouteNames.patternMission,
      builder: (context, state) => const PatternMissionPage(),
    ),

    // Numbers Mission
    GoRoute(
      path: RouteNames.numbersMission,
      builder: (context, state) => const NumbersMissionPage(),
    ),

    // Workshop full-screen routes
    GoRoute(
      path: '/workshop/mission/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return WorkshopDetailPage(missionId: id);
      },
    ),
    GoRoute(
      path: RouteNames.workshopCreate,
      builder: (context, state) => const CreateMissionPage(),
    ),
    GoRoute(
      path: RouteNames.workshopMyMissions,
      builder: (context, state) => const MyMissionsPage(),
    ),
    GoRoute(
      path: '/workshop-play/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return WorkshopPlayPage(missionId: id);
      },
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

