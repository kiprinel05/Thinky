import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:thinky/shared_controls/widgets/animations/animated_widgets.dart';
import 'package:thinky/shared_controls/widgets/buttons/primary_button.dart';
import 'package:thinky/shared_controls/assets/app_assets.dart';
import 'package:thinky/shared_controls/theme/app_colors.dart';
import 'package:thinky/shared_controls/theme/app_colors_extension.dart';
import 'package:thinky/shared_controls/theme/app_dimens.dart';
import 'package:thinky/core_controls/constants/app_texts.dart';
import 'package:thinky/core_controls/services/language_service.dart';

import '../controllers/quiz_controller.dart';
import '../controllers/quiz_state.dart';
import '../widgets/quiz_widgets.dart';
import 'quiz_answer_review_view.dart';
import 'quiz_learning_view.dart';

class QuizResultView extends ConsumerStatefulWidget {
  final QuizState state;

  const QuizResultView({super.key, required this.state});

  @override
  ConsumerState<QuizResultView> createState() => _QuizResultViewState();
}

class _QuizResultViewState extends ConsumerState<QuizResultView>
    with SingleTickerProviderStateMixin {
  late AnimationController _scoreAnim;
  late Animation<double> _scoreCurve;

  @override
  void initState() {
    super.initState();
    _scoreAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _scoreCurve = CurvedAnimation(
      parent: _scoreAnim,
      curve: Curves.easeOutCubic,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scoreAnim.forward();
    });
  }

  @override
  void dispose() {
    _scoreAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(textRefreshProvider);

    if (widget.state.showLearning) {
      return QuizLearningView(
        onDone: () => ref.read(quizStateProvider.notifier).closeLearning(),
      );
    }

    if (widget.state.showAnswerReview) {
      return QuizAnswerReviewView(
        questions: widget.state.questions,
        selectedAnswers: widget.state.selectedAnswers,
        onBack: () => ref.read(quizStateProvider.notifier).closeAnswerReview(),
      );
    }

    final result = widget.state.quizResult!;
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pct = result.percentage.toInt();
    final accentColor = pct >= 80
        ? AppColors.success
        : pct >= 60
            ? AppColors.primaryPurple
            : AppColors.error;
    final tier = pct >= 80
        ? Quiz.resultExcellent
        : pct >= 60
            ? Quiz.resultGood
            : Quiz.resultKeepLearning;
    final bodyFeedback =
        pct < 50 ? Quiz.keepImprovingSummary : _helperLine(pct);

    return Stack(
      children: [
        // Same gradient background as question page
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        const Color(0xFF4A5288),
                        const Color(0xFF353A5C),
                        colors.background,
                      ]
                    : [
                        const Color(0xFF9DAAFF),
                        const Color(0xFFE8EAFF),
                        colors.background,
                      ],
                stops: const [0.0, 0.28, 0.55],
              ),
            ),
          ),
        ),
        // Same decorative circles as question page
        Positioned(
          top: -60,
          right: -40,
          child: IgnorePointer(
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: isDark ? 0.06 : 0.35),
              ),
            ),
          ),
        ),
        Positioned(
          top: 120,
          left: -50,
          child: IgnorePointer(
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryPurple.withValues(
                  alpha: isDark ? 0.12 : 0.18,
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDimens.pagePaddingHorizontal,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: AppDimens.xxl),
                      ScaleInWidget(
                        delay: const Duration(milliseconds: 150),
                        child: Image.asset(
                          AppAssets.missionQuizHappy,
                          height: AppDimens.mascotSizeMd,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: AppDimens.lg),
                      FadeInWidget(
                        delay: const Duration(milliseconds: 200),
                        child: Text(
                          Quiz.completedTitle,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.alata(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color:
                                    Colors.black.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimens.xl),
                      // Score card — same card style as question card
                      FadeInWidget(
                        delay: const Duration(milliseconds: 280),
                        child: AnimatedBuilder(
                          animation: _scoreCurve,
                          builder: (context, _) {
                            final t = _scoreCurve.value;
                            final dispCorrect =
                                (result.correctAnswers * t).round();
                            final dispPct = (result.percentage * t)
                                .round()
                                .clamp(0, 100);
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(
                                AppDimens.cardPadding,
                              ),
                              decoration: BoxDecoration(
                                color: colors.cardColor,
                                borderRadius: BorderRadius.circular(
                                  AppDimens.cardRadius,
                                ),
                                border: Border.all(color: colors.border),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: isDark ? 0.35 : 0.08,
                                    ),
                                    blurRadius: 18,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    tier,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.alata(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: AppDimens.md),
                                  Text(
                                    '$dispCorrect/${result.totalQuestions}',
                                    style: GoogleFonts.alata(
                                      fontSize: 48,
                                      fontWeight: FontWeight.w800,
                                      color: colors.textPrimary,
                                      height: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: AppDimens.sm),
                                  Text(
                                    '$dispPct%',
                                    style: GoogleFonts.alata(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: accentColor,
                                    ),
                                  ),
                                  const SizedBox(height: AppDimens.lg),
                                  Text(
                                    bodyFeedback,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.alata(
                                      fontSize: 14,
                                      height: 1.5,
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: AppDimens.xl),
                      // Stat rows
                      FadeInWidget(
                        delay: const Duration(milliseconds: 360),
                        child: Column(
                          children: [
                            QuizSummaryStatRow(
                              icon: Icons.check_circle_rounded,
                              iconColor: AppColors.success,
                              label: Quiz.summaryCorrectRow,
                              value: '${result.correctAnswers}',
                              colors: colors,
                            ),
                            const SizedBox(height: AppDimens.sm),
                            QuizSummaryStatRow(
                              icon: Icons.cancel_rounded,
                              iconColor: AppColors.error,
                              label: Quiz.summaryWrongRow,
                              value: '${result.incorrectAnswers}',
                              colors: colors,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppDimens.md),
                      // XP earned badge
                      FadeInWidget(
                        delay: const Duration(milliseconds: 440),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimens.md,
                            vertical: AppDimens.sm + 2,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: isDark ? 0.18 : 0.10),
                            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                color: accentColor,
                                size: 22,
                              ),
                              const SizedBox(width: AppDimens.sm),
                              Text(
                                Quiz.xpEarnedLine(result.xpEarned),
                                style: GoogleFonts.alata(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: accentColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimens.xl),
                    ],
                  ),
                ),
              ),
              // Buttons pinned at bottom — same style as question page nav
              SafeArea(
                top: false,
                minimum: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PrimaryButton(
                        text: Quiz.lessonButton,
                        onPressed: () => ref
                            .read(quizStateProvider.notifier)
                            .openLearning(),
                      ),
                      const SizedBox(height: AppDimens.sm),
                      SizedBox(
                        width: double.infinity,
                        height: AppDimens.buttonHeight,
                        child: OutlinedButton(
                          onPressed: () => ref
                              .read(quizStateProvider.notifier)
                              .openAnswerReview(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryPurple,
                            side: const BorderSide(
                              color: AppColors.primaryPurple,
                              width: AppDimens.buttonBorderWidth,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppDimens.radiusRound,
                              ),
                            ),
                          ),
                          child: Text(
                            Quiz.showDetailedResults,
                            style: GoogleFonts.alata(
                              color: AppColors.primaryPurple,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _helperLine(int pct) {
    if (pct >= 80) return Quiz.resultHelperTextHigh;
    if (pct >= 50) return Quiz.resultHelperTextMid;
    return Quiz.resultHelperTextLow;
  }
}
