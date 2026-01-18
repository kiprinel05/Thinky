import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/route_names.dart';

class IntroPage extends StatelessWidget {
  const IntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/backgrounds/background.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(height: 8),
                    // Top section: logo & illustration
                    Column(
                      children: [
                        SizedBox(
                          height: 70,
                          child: Image.asset(
                            'assets/logos/logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 24),
                        AspectRatio(
                          aspectRatio: 19 / 11,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              'assets/illustrations/first_page_image.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Middle text
                    Column(
                      children: [
                        Text(
                          'Learn and Teach at\n the same time',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.alata(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF222222),
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Thousands of people use AI everyday but don't know how it works. \nBe the one to make a difference!",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.alata(
                            fontSize: 16,
                            height: 1.5,
                            color: const Color.fromRGBO(161, 164, 178, 1),
                          ),
                        ),
                      ],
                    ),
                    // Bottom actions
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => context.push(RouteNames.register),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8E97FD),
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(38),
                              ),
                            ),
                            child: Text(
                              'SIGN UP',
                              style: GoogleFonts.alata(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => context.push(RouteNames.guestName),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFFDFD),
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(38),
                              ),
                            ),
                            child: Text(
                              'CONTINUE AS GUEST',
                              style: GoogleFonts.alata(
                                color: const Color(0xFF8E97FD),
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 50),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'ALREADY HAVE AN ACCOUNT? ',
                              style: GoogleFonts.alata(
                                color: const Color(0xFF8A8A8F),
                                fontSize: 14,
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.push(RouteNames.login),
                              child: Text(
                                'LOG IN',
                                style: GoogleFonts.alata(
                                  color: const Color(0xFF8E97FD),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 35),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
