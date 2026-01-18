import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import 'package:thinky/shared_controls/widgets/animations/animated_widgets.dart';
import 'package:thinky/core_controls/services/app_state_service.dart'; // Keep for now, or migrate to provider
import 'package:thinky/core_controls/routing/route_names.dart';
import 'package:thinky/core_controls/features/auth/presentation/controllers/auth_controller.dart';
import 'package:thinky/core_controls/constants/app_texts.dart';

class WelcomePage extends ConsumerStatefulWidget {
  const WelcomePage({super.key});

  @override
  ConsumerState<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends ConsumerState<WelcomePage> {
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
      // Mark welcome as seen
      await AppStateService.setHasSeenWelcome(true);
      await AppStateService.setLastRoute('missions');

      if (mounted) {
        context.go(RouteNames.missions);
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

class WelcomePage1 extends ConsumerWidget {
  final VoidCallback onNext;
  final bool isFirstPage;

  const WelcomePage1({
    super.key,
    required this.onNext,
    required this.isFirstPage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final userName = authState.user?.username ?? authState.user?.guestName ?? 'there';

    return Stack(
      children: [
        // Background image
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Image.asset(
            'assets/welcome/page1/background_welcome.png',
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
                              '${Welcome.hi} $userName',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.alata(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              Welcome.title,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.alata(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              Welcome.introMessage,
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
                'assets/welcome/page1/hello.png',
                height: MediaQuery.of(context).size.height * 0.55,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 20),
            // Button
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
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(235, 234, 236, 1),
                    minimumSize: const Size.fromHeight(56),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(38),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    Welcome.nextButton,
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

class WelcomePage2 extends StatelessWidget {
  final VoidCallback onNext;
  final bool isFirstPage;

  const WelcomePage2({
    super.key,
    required this.onNext,
    required this.isFirstPage,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Image.asset(
            'assets/welcome/page2/background_welcome.png',
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
                              Welcome.robotQuestion,
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
                              Welcome.robotAnswer,
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
                'assets/welcome/page2/thinking.png',
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
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(235, 234, 236, 1),
                    minimumSize: const Size.fromHeight(56),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(38),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    Welcome.startButton,
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