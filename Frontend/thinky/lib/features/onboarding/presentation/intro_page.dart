import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thinky/features/auth/presentation/guest_name_page.dart';
import '../../auth/presentation/login_page.dart';
import '../../auth/presentation/register_page.dart';

class IntroPage extends StatelessWidget {
  const IntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Top decorative background over white base
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/backgrounds/background.png',
              fit: BoxFit.cover,
              // height: 320,
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
                    // Top section: logo
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
                        // Illustration
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
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const RegisterPage(),
                                ),
                              );
                            },
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
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const GuestNamePage(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                255,
                                255,
                                253,
                                253,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(38),
                              ),
                            ),
                            child: Text(
                              'CONTINUE AS GUEST',
                              style: GoogleFonts.alata(
                                color: const Color.fromRGBO(142, 151, 253, 1),
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
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
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const LoginPage(),
                                  ),
                                );
                              },
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
                        const SizedBox(height: 15),
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
