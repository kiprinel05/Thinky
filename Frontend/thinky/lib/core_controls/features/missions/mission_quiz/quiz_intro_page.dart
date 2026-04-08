import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thinky/shared_controls/theme/app_colors.dart';
import 'package:thinky/shared_controls/widgets/animations/animated_widgets.dart';
import 'package:thinky/core_controls/constants/app_texts.dart';

class QuizIntroPage extends StatelessWidget {
  final VoidCallback onStart;

  const QuizIntroPage({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFB8BEFD),
              Color(0xFF9AA2FD),
              Color(0xFF8E97FD),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Soft background circles
              Positioned(
                top: -80,
                left: -60,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
              Positioned(
                bottom: 120,
                right: -40,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
              ),
              // Background image with soft overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: 0.4,
                  child: Image.asset(
                    'assets/welcome/page1/background_welcome.png',
                    fit: BoxFit.fitWidth,
                    alignment: Alignment.bottomCenter,
                    width: double.infinity,
                  ),
                ),
              ),
              // Content
              Column(
                children: [
                  AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white.withOpacity(0.9),
                        size: 20,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        left: 28,
                        right: 28,
                        bottom: MediaQuery.of(context).padding.bottom + 100,
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          ScaleInWidget(
                            delay: const Duration(milliseconds: 300),
                            child: Image.asset(
                              'assets/welcome/page2/thinking.png',
                              height: 260,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 28),
                          // Glassmorphism title card
                          FadeInWidget(
                            delay: const Duration(milliseconds: 400),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 20,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.25),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    Quiz.introTitle,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.alata(
                                      fontSize: 23,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      height: 1.35,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          FadeInWidget(
                            delay: const Duration(milliseconds: 500),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                Quiz.introSubtitle,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.alata(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white.withOpacity(0.92),
                                  height: 1.6,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 36),
                          // Smooth button with soft shadow
                          FadeInWidget(
                            delay: const Duration(milliseconds: 600),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(32),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                  BoxShadow(
                                    color: AppColors.primaryPurple.withOpacity(0.15),
                                    blurRadius: 20,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: onStart,
                                  borderRadius: BorderRadius.circular(32),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 20),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(32),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.8),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          Quiz.startQuizButton,
                                          style: GoogleFonts.alata(
                                            color: AppColors.primaryPurple,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Icon(
                                          Icons.arrow_forward_rounded,
                                          color: AppColors.primaryPurple,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}




