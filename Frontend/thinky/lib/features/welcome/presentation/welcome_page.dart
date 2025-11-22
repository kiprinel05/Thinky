import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/widgets/animated_widgets.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/app_state_service.dart';
import '../../onboarding/presentation/intro_page.dart';
import '../../missions/presentation/missions_menu_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() async {
    if (_currentPage < 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Salvează că utilizatorul a văzut welcome pages
      await AppStateService.setHasSeenWelcome(true);
      await AppStateService.setLastRoute('missions');

      if (mounted) {
        Navigator.of(
          context,
        ).pushReplacement(FadePageRoute(page: const MissionsMenuPage()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF9AA2FD),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  WelcomePage1(
                    onNext: _nextPage,
                    isFirstPage: _currentPage == 0,
                  ),
                  WelcomePage2(
                    onNext: _nextPage,
                    isFirstPage: _currentPage == 0,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WelcomePage1 extends StatefulWidget {
  final VoidCallback onNext;
  final bool isFirstPage;

  const WelcomePage1({
    super.key,
    required this.onNext,
    required this.isFirstPage,
  });

  @override
  State<WelcomePage1> createState() => _WelcomePage1State();
}

class _WelcomePage1State extends State<WelcomePage1> {
  String _userName = 'there';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final user = await AuthService.getCurrentUser();
    if (user != null && mounted) {
      setState(() {
        _userName = user['username'] ?? user['guestName'] ?? 'there';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background image pe jumătatea de jos
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Image.asset(
            'welcome/page1/background_welcome.png',
            fit: BoxFit.fitWidth,
            alignment: Alignment.bottomCenter,
            width: double.infinity,
          ),
        ),
        // Content
        Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Text content
                    FadeInWidget(
                      delay: const Duration(milliseconds: 200),
                      child: SlideUpWidget(
                        delay: const Duration(milliseconds: 200),
                        offset: 30,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Hi $_userName',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.alata(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Welcome to Thinky',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.alata(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'My name is Pixy and I will be your friend in your journey of learning AI. Are you ready?',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.alata(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Colors.white,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ScaleInWidget(
              delay: const Duration(milliseconds: 600),
              child: Image.asset(
                'welcome/page1/hello.png',
                height: MediaQuery.of(context).size.height * 0.55,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 20),
            // Button peste background
            Padding(
              padding: const EdgeInsets.only(
                left: 24,
                right: 24,
                bottom: 24,
                top: 12,
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromRGBO(235, 234, 236, 1),
                    minimumSize: const Size.fromHeight(56),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(38),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'NEXT',
                    style: GoogleFonts.alata(
                      color: const Color(0xFF60646D),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class WelcomePage2 extends StatefulWidget {
  final VoidCallback onNext;
  final bool isFirstPage;

  const WelcomePage2({
    super.key,
    required this.onNext,
    required this.isFirstPage,
  });

  @override
  State<WelcomePage2> createState() => _WelcomePage2State();
}

class _WelcomePage2State extends State<WelcomePage2> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Image.asset(
            'welcome/page2/background_welcome.png',
            fit: BoxFit.fitWidth,
            alignment: Alignment.bottomCenter,
            width: double.infinity,
          ),
        ),
        // Content
        Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Text content - perfect centrat
                    FadeInWidget(
                      delay: const Duration(milliseconds: 200),
                      child: SlideUpWidget(
                        delay: const Duration(milliseconds: 200),
                        offset: 30,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'I would like to know...\nhow do robots learn?',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.alata(
                                fontSize: 24,
                                fontWeight: FontWeight.w400,
                                color: Colors.white,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Maybe you can help me find out!',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.alata(
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
                                color: Colors.white,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ScaleInWidget(
              delay: const Duration(milliseconds: 600),
              child: Image.asset(
                'welcome/page2/thinking.png',
                height: MediaQuery.of(context).size.height * 0.55,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromRGBO(235, 234, 236, 1),
                    minimumSize: const Size.fromHeight(56),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(38),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'LET\'S GET STARTED',
                    style: GoogleFonts.alata(
                      color: const Color(0xFF60646D),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
