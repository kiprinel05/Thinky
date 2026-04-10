import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:thinky/shared_controls/widgets/animations/animated_widgets.dart';
import 'package:thinky/shared_controls/theme/app_colors.dart';
import 'package:thinky/shared_controls/theme/app_colors_extension.dart';
import 'package:thinky/core_controls/constants/app_texts.dart';
import 'package:thinky/core_controls/services/language_service.dart';
import 'package:thinky/core_controls/features/missions/mission_quiz/domain/quiz_models.dart';

class QuizAnswerReviewView extends ConsumerWidget {
  const QuizAnswerReviewView({
    super.key,
    required this.questions,
    required this.selectedAnswers,
    required this.onBack,
  });

  final List<Question> questions;
  final Map<int, int> selectedAnswers;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(textRefreshProvider);
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ColoredBox(
      color: colors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: colors.textPrimary,
                    onPressed: onBack,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Quiz.reviewTitle,
                          style: GoogleFonts.alata(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          Quiz.reviewSubtitle,
                          style: GoogleFonts.alata(
                            fontSize: 13,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                itemCount: questions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final q = questions[index];
                  final pickedId = selectedAnswers[index];
                  final correctId = q.correctAnswerId;
                  final isRight = pickedId == correctId;

                  return FadeInWidget(
                    delay: Duration(milliseconds: 80 + index * 50),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: colors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.25 : 0.04,
                            ),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryPurple.withValues(
                                    alpha: isDark ? 0.2 : 0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${Quiz.questionLabel} ${index + 1}',
                                  style: GoogleFonts.alata(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryPurple,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: (isRight
                                          ? AppColors.success
                                          : AppColors.error)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isRight
                                          ? Icons.check_circle_rounded
                                          : Icons.cancel_rounded,
                                      size: 14,
                                      color: isRight
                                          ? AppColors.success
                                          : AppColors.error,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isRight
                                          ? Quiz.reviewCorrectBadge
                                          : Quiz.reviewMissedBadge,
                                      style: GoogleFonts.alata(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: isRight
                                            ? AppColors.success
                                            : AppColors.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            q.question,
                            style: GoogleFonts.alata(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 14),
                          ...q.options.map((option) {
                            final bool isPicked = option.id == pickedId;
                            final bool isCorrectOpt = option.id == correctId;

                            Color bgColor;
                            Color textColor;
                            IconData? icon;

                            if (isCorrectOpt) {
                              bgColor = isDark
                                  ? const Color(0xFF1B3D24)
                                  : AppColors.successLight;
                              textColor = isDark
                                  ? const Color(0xFFA5D6A7)
                                  : const Color(0xFF2E7D32);
                              icon = Icons.check_circle_rounded;
                            } else if (isPicked && !isCorrectOpt) {
                              bgColor = isDark
                                  ? const Color(0xFF3D1F1F)
                                  : AppColors.errorLight;
                              textColor = isDark
                                  ? const Color(0xFFEF9A9A)
                                  : AppColors.errorDark;
                              icon = Icons.cancel_rounded;
                            } else {
                              bgColor = colors.inputFill;
                              textColor = colors.textSecondary;
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    if (icon != null) ...[
                                      Icon(icon, size: 18, color: textColor),
                                      const SizedBox(width: 8),
                                    ],
                                    Expanded(
                                      child: Text(
                                        option.text,
                                        style: GoogleFonts.alata(
                                          fontSize: 13,
                                          color: textColor,
                                          fontWeight:
                                              (isPicked || isCorrectOpt)
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: FilledButton(
                onPressed: onBack,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  Quiz.backToSummary,
                  style: GoogleFonts.alata(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
