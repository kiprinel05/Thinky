import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thinky/shared_controls/theme/app_colors.dart';
import 'package:thinky/shared_controls/theme/app_colors_extension.dart';
import 'package:thinky/shared_controls/widgets/animations/animated_widgets.dart';
import 'domain/quiz_models.dart';

class QuizAnswersPage extends StatelessWidget {
  final List<Question> questions;
  final Map<int, int> selectedAnswers;

  const QuizAnswersPage({
    super.key,
    required this.questions,
    required this.selectedAnswers,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0.5,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
        iconTheme: IconThemeData(color: colors.textPrimary),
        title: Text(
          'Quiz answers',
          style: GoogleFonts.alata(
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            children: [
              ...questions.asMap().entries.map((entry) {
                final index = entry.key;
                final question = entry.value;
                final userAnswerId = selectedAnswers[index];
                final userOption = question.options
                    .where((o) => o.id == userAnswerId)
                    .cast<AnswerOption?>()
                    .firstOrNull;
                final correctOption = question.options.firstWhere(
                  (o) => o.id == question.correctAnswerId,
                );
                final bool isCorrect =
                    userAnswerId != null && userAnswerId == correctOption.id;

                final Color statusColor = isCorrect
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFFF7043);
                final String statusText = isCorrect ? 'Correct' : 'Incorrect';

                List<AnswerOption> orderedOptions;
                if (!isCorrect && userOption != null) {
                  final others = question.options.where((o) =>
                      o.id != userOption.id &&
                      o.id != correctOption.id);
                  orderedOptions = [
                    userOption,
                    correctOption,
                    ...others,
                  ];
                } else {
                  orderedOptions = question.options;
                }

                return FadeInWidget(
                  delay: Duration(milliseconds: 100 + index * 60),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: colors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Question ${index + 1}',
                                style: GoogleFonts.alata(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryPurple,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isCorrect
                                          ? Icons.check_circle_rounded
                                          : Icons.error_rounded,
                                      size: 14,
                                      color: statusColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      statusText,
                                      style: GoogleFonts.alata(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: statusColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            question.question,
                            style: GoogleFonts.alata(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...orderedOptions.map((option) {
                            final bool isUser =
                                userAnswerId != null &&
                                option.id == userAnswerId;
                            final bool isCorrectOption =
                                option.id == correctOption.id;

                            late Color bgColor;
                            late Color textColor;
                            IconData? icon;

                            if (isCorrectOption) {
                              if (isDark) {
                                bgColor = const Color(0xFF1B3D24);
                                textColor = const Color(0xFFA5D6A7);
                              } else {
                                bgColor = const Color(0xFFE8F5E9);
                                textColor = const Color(0xFF2E7D32);
                              }
                              icon = Icons.check_circle_rounded;
                            } else if (isUser && !isCorrectOption) {
                              if (isDark) {
                                bgColor = const Color(0xFF3D1F1F);
                                textColor = const Color(0xFFEF9A9A);
                              } else {
                                bgColor = const Color(0xFFFFEBEE);
                                textColor = const Color(0xFFC62828);
                              }
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
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    if (icon != null) ...[
                                      Icon(
                                        icon,
                                        size: 18,
                                        color: textColor,
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Expanded(
                                      child: Text(
                                        option.text,
                                        style: GoogleFonts.alata(
                                          fontSize: 13,
                                          color: textColor,
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
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
