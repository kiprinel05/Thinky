import 'package:flutter/material.dart';
import 'features/onboarding/presentation/intro_page.dart';
import 'core/services/auth_service.dart';
import 'core/services/app_state_service.dart';
import 'features/missions/presentation/missions_menu_page.dart';
import 'features/welcome/presentation/welcome_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  Widget _initialRoute = const IntroPage();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _determineInitialRoute();
  }

  Future<void> _determineInitialRoute() async {
    final isAuthenticated = await AuthService.isAuthenticated();
    final hasSeenWelcome = await AppStateService.hasSeenWelcome();

    Widget initialRoute;

    if (!isAuthenticated) {
      // Utilizatorul nu este autentificat - merge la intro
      initialRoute = const IntroPage();
    } else if (!hasSeenWelcome) {
      // Utilizatorul este autentificat dar nu a văzut welcome pages
      initialRoute = const WelcomePage();
    } else {
      // Utilizatorul este autentificat și a văzut welcome - merge direct la misiuni
      initialRoute = const MissionsMenuPage();
    }

    if (mounted) {
      setState(() {
        _initialRoute = initialRoute;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _initialRoute,
    );
  }
}
