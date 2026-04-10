import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:thinky/shared_controls/widgets/animations/animated_widgets.dart';
import 'package:thinky/shared_controls/theme/app_colors.dart';
import 'package:thinky/shared_controls/theme/app_colors_extension.dart';
import 'package:thinky/shared_controls/widgets/states/app_content_skeletons.dart';
import 'package:thinky/core_controls/constants/app_texts.dart';
import 'package:thinky/core_controls/services/language_service.dart';

import '../controllers/quiz_controller.dart';
import '../controllers/quiz_state.dart';
import '../widgets/quiz_widgets.dart';

class QuizQuestionView extends ConsumerStatefulWidget {
  final QuizState state;
  final QuizController controller;

  const QuizQuestionView({
    super.key,
    required this.state,
    required this.controller,
  });

  @override
  ConsumerState<QuizQuestionView> createState() => _QuizQuestionViewState();
}

class _QuizQuestionViewState extends ConsumerState<QuizQuestionView>
    with SingleTickerProviderStateMixin {
  late AnimationController _pixyAnimController;
  late Animation<double> _pixyScaleAnim;

  @override
  void initState() {
    super.initState();
    _pixyAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pixyScaleAnim = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pixyAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pixyAnimController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(QuizQuestionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentQ = widget.state.currentQuestionIndex;
    final oldQ = oldWidget.state.currentQuestionIndex;
    if (currentQ == oldQ) {
      final newSel = widget.state.selectedAnswers[currentQ];
      final oldSel = oldWidget.state.selectedAnswers[currentQ];
      if (newSel != null && oldSel != newSel) {
        _pixyAnimController.forward(from: 0.0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(textRefreshProvider);

    if (widget.state.questions.isEmpty) {
      final colors = context.appColors;
      return Center(
        child: Text(
          Quiz.noQuestions,
          style: GoogleFonts.alata(color: colors.textPrimary),
        ),
      );
    }

    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      clipBehavior: Clip.none,
      children: [
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
        Column(
          children: [
            _buildProgressBar(isDark),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: _pixyScaleAnim,
                      alignment: Alignment.bottomCenter,
                      child: const QuizMascotBehindCard(
                        width: 140,
                        slotHeight: 140,
                        imageScale: 1.15,
                        offsetY: -20,
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -28),
                      child: _buildQuestionCard(colors, isDark),
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              minimum: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: _buildNavigationButtons(isDark),
              ),
            ),
          ],
        ),
        if (widget.state.showFeedback) _buildFeedbackOverlay(colors, isDark),
        if (widget.state.isSubmitting)
          Container(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
            child: AppContentSkeletons.quizSubmittingOverlay(context),
          ),
      ],
    );
  }

  Widget _buildProgressBar(bool isDark) {
    final state = widget.state;
    final total = state.questions.length;
    final current = state.currentQuestionIndex + 1;
    final progress = current / total;

    return FadeInWidget(
      delay: const Duration(milliseconds: 120),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.2),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(28),
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.28),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${Quiz.questionLabel} $current ${Quiz.ofLabel} $total',
                          style: GoogleFonts.alata(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          Quiz.missionHintLine,
                          style: GoogleFonts.alata(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontSize: 12,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: isDark ? 0.16 : 0.28,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      '${(progress * 100).toInt()}%',
                      style: GoogleFonts.alata(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Stack(
                  children: [
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: isDark ? 0.14 : 0.22,
                        ),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFFFFF), Color(0xFFE8ECFF)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(
                                alpha: isDark ? 0.2 : 0.55,
                              ),
                              blurRadius: 8,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(AppColorsExtension colors, bool isDark) {
    final state = widget.state;
    final question = state.currentQuestion;
    if (question == null) return const SizedBox();

    final selectedAnswerId = state.currentSelectedAnswerId;
    final cardShadow = isDark
        ? BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        : BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          );

    return FadeInWidget(
      key: ValueKey(question.id),
      delay: const Duration(milliseconds: 200),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.border),
          boxShadow: [cardShadow],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withValues(
                  alpha: isDark ? 0.2 : 0.08,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${Quiz.questionLabel} ${state.currentQuestionIndex + 1}',
                style: GoogleFonts.alata(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryPurple,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              question.question,
              style: GoogleFonts.alata(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            ...question.options.map((option) {
              final isSelected = selectedAnswerId == option.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () => widget.controller.selectAnswer(option.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFF8E97FD), Color(0xFF9AA2FD)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isSelected ? null : colors.inputFill,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected ? Colors.transparent : colors.border,
                        width: 2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primaryPurple.withValues(
                                  alpha: 0.25,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 6),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? Colors.white
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white
                                  : colors.textHint,
                              width: 2.5,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Color(0xFF8E97FD),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            option.text,
                            style: GoogleFonts.alata(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : colors.textPrimary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(bool isDark) {
    final state = widget.state;
    final hasSelection = state.hasSelectedAnswer;
    final isLast = state.isLastQuestion;
    final showPrev = state.currentQuestionIndex > 0;
    final purple = AppColors.primaryPurple;
    final disabledFill = isDark
        ? purple.withValues(alpha: 0.28)
        : purple.withValues(alpha: 0.4);

    return Row(
      children: [
        if (showPrev) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: widget.controller.previousQuestion,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: purple, width: 2),
                foregroundColor: purple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                Quiz.previous,
                style: GoogleFonts.alata(
                  color: purple,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
        Expanded(
          child: ElevatedButton(
            onPressed: hasSelection && !state.isSubmitting
                ? widget.controller.showFeedback
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: hasSelection ? purple : disabledFill,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: hasSelection ? 4 : 0,
            ),
            child: state.isSubmitting
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    isLast ? Quiz.seeResult : Quiz.next,
                    style: GoogleFonts.alata(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackOverlay(AppColorsExtension colors, bool isDark) {
    final state = widget.state;
    final isCorrect = state.isLastAnswerCorrect;
    final Color accentColor = isCorrect
        ? const Color(0xFF43A047)
        : const Color(0xFFFF6E40);
    final String titleText = isCorrect
        ? Quiz.feedbackCorrectTitle
        : Quiz.feedbackIncorrectTitle;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.black.withValues(alpha: isDark ? 0.52 : 0.28),
            ),
          ),
        ),
        Center(
          child: FadeInWidget(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxW = constraints.maxWidth.clamp(0.0, 400.0);
                  final professorW = (maxW * 0.48).clamp(150.0, 200.0);
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ProfessorHeadAbovePanel(
                        width: professorW,
                        viewportHeight: 192,
                        imageScale: 1.32,
                        imageOffsetY: -36,
                      ),
                      Transform.translate(
                        offset: const Offset(0, -36),
                        child: Material(
                          color: colors.cardColor,
                          elevation: isDark ? 16 : 12,
                          shadowColor: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(28),
                          child: Container(
                            width: maxW,
                            padding: const EdgeInsets.fromLTRB(22, 36, 22, 22),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: colors.border.withValues(alpha: 0.65),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: accentColor.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isCorrect
                                        ? Icons.check_rounded
                                        : Icons.school_rounded,
                                    size: 28,
                                    color: accentColor,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  titleText,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.alata(
                                    fontSize: 17,
                                    color: accentColor,
                                    fontWeight: FontWeight.w800,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  state.feedbackText,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.alata(
                                    fontSize: 15,
                                    color: colors.textPrimary,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 22),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    onPressed:
                                        widget.controller.goToNextAfterFeedback,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: accentColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Text(
                                      Quiz.continueAction,
                                      style: GoogleFonts.alata(
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
