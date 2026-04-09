import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thinky/shared_controls/theme/app_colors.dart';
import 'package:thinky/shared_controls/theme/app_colors_extension.dart';
import 'package:thinky/shared_controls/widgets/animations/animated_widgets.dart';
import 'package:thinky/core_controls/constants/app_texts.dart' show Quiz;
import 'package:thinky/core_controls/services/language_service.dart';
import 'package:thinky/shared_controls/assets/app_assets.dart';
import 'domain/quiz_models.dart';
import 'quiz_answers_page.dart';

class QuizResultPage extends ConsumerWidget {
  final QuizResult result;
  final List<Question> questions;
  final Map<int, int> selectedAnswers;
  final VoidCallback onContinue;

  const QuizResultPage({
    super.key,
    required this.result,
    required this.questions,
    required this.selectedAnswers,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(textRefreshProvider);
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final percentage = result.percentage;
    final isExcellent = percentage >= 80;
    final isGood = percentage >= 60;

    // Score-based accent color
    final accentColor = isExcellent
        ? const Color(0xFF4CAF50) // green
        : isGood
            ? AppColors.primaryPurple
            : const Color(0xFFFF9A5C); // warm orange

    final gradientColors = isDark
        ? [
            const Color(0xFF3D4266),
            const Color(0xFF323654),
            colors.background,
          ]
        : const [
            Color(0xFFB8BEFD),
            Color(0xFF9AA2FD),
            Color(0xFF8E97FD),
          ];
    final gradientStops = isDark ? const [0.0, 0.45, 1.0] : const [0.0, 0.4, 1.0];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradientColors,
            stops: gradientStops,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Soft decorative circles
              Positioned(
                top: -60,
                right: -40,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: isDark ? 0.06 : 0.08),
                  ),
                ),
              ),
              Positioned(
                bottom: 200,
                left: -50,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: isDark ? 0.04 : 0.06),
                  ),
                ),
              ),
              Column(
                children: [
                  AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: 20,
                      ),
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        left: 24,
                        right: 24,
                        bottom: MediaQuery.of(context).padding.bottom + 100,
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          ScaleInWidget(
                            delay: const Duration(milliseconds: 200),
                            child: Image.asset(
                              AppAssets.missionQuizHappy,
                              height: 130,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 20),
                          FadeInWidget(
                            delay: const Duration(milliseconds: 250),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isExcellent ? '🎉' : isGood ? '👍' : '💪',
                                  style: const TextStyle(fontSize: 28),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  isExcellent
                                      ? Quiz.resultExcellent
                                      : isGood
                                          ? Quiz.resultGood
                                          : Quiz.resultKeepLearning,
                                  style: GoogleFonts.alata(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          // Score card with glass effect
                          FadeInWidget(
                            delay: const Duration(milliseconds: 300),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: 32,
                                horizontal: 24,
                              ),
                              decoration: BoxDecoration(
                                color: colors.cardColor,
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(color: colors.border),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                                    blurRadius: 24,
                                    offset: const Offset(0, 12),
                                  ),
                                  BoxShadow(
                                    color: accentColor.withValues(alpha: 0.15),
                                    blurRadius: 20,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '${percentage.toInt()}%',
                                    style: GoogleFonts.alata(
                                      fontSize: 56,
                                      fontWeight: FontWeight.w800,
                                      color: accentColor,
                                      letterSpacing: -1,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accentColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      '${result.correctAnswers} ${Quiz.resultOutOf} ${result.totalQuestions} ${Quiz.resultCorrect}',
                                      style: GoogleFonts.alata(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: accentColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          FadeInWidget(
                            delay: const Duration(milliseconds: 350),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                Quiz.resultHelperText,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.alata(
                                  fontSize: 15,
                                  color: isDark ? colors.textSecondary : Colors.white.withValues(alpha: 0.92),
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Show detailed results button
                          FadeInWidget(
                            delay: const Duration(milliseconds: 400),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => QuizAnswersPage(
                                        questions: questions,
                                        selectedAnswers:
                                            Map<int, int>.from(selectedAnswers),
                                      ),
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  side: BorderSide(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                  backgroundColor: Colors.white.withValues(alpha: isDark ? 0.1 : 0.15),
                                ),
                                child: Text(
                                  Quiz.showDetailedResults,
                                  style: GoogleFonts.alata(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Continue button
                          FadeInWidget(
                            delay: const Duration(milliseconds: 450),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                  BoxShadow(
                                    color: AppColors.primaryPurple.withValues(alpha: isDark ? 0.35 : 0.3),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: onContinue,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark ? colors.surface : Colors.white,
                                  foregroundColor: AppColors.primaryPurple,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  Quiz.continueToMissions,
                                  style: GoogleFonts.alata(
                                    color: isDark ? AppColors.primaryPurpleLight : AppColors.primaryPurple,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    letterSpacing: 0.5,
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

