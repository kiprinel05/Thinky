import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:thinky/base_controls/base_page.dart';
import 'package:thinky/base_controls/base_state.dart';
import 'package:thinky/shared_controls/widgets/animations/animated_widgets.dart';
import '../controllers/quiz_controller.dart';
import '../controllers/quiz_state.dart';
import 'package:thinky/core_controls/features/missions/mission_quiz/domain/quiz_models.dart';
import 'package:thinky/core_controls/constants/app_texts.dart';
import 'package:thinky/core_controls/services/language_service.dart';
import 'package:thinky/shared_controls/assets/app_assets.dart';
import 'package:thinky/shared_controls/theme/app_colors.dart';
import 'package:thinky/shared_controls/theme/app_colors_extension.dart';
import 'package:thinky/shared_controls/widgets/states/app_content_skeletons.dart';

// We might need to import these if we extract them or just define here
// import 'quiz_result_page.dart'; // We will inline or use existing

class QuizPageNew extends BasePage {
  const QuizPageNew({super.key});

  @override
  String? get title => Quiz.title;

  @override
  Widget buildLoading(BuildContext context) {
    return AppContentSkeletons.quizPageBody(context);
  }

  // Specific implementation for Quiz - we want custom background handling perhaps?
  // BasePage provides Scaffold. The original page had a specific gradient background for header.

  @override
  Widget buildBody(BuildContext context, WidgetRef ref) {
    ref.watch(textRefreshProvider);
    // Watch state
    final state = ref.watch(quizStateProvider);
    final controller = ref.read(quizStateProvider.notifier);

    // Initial load
    if (state.status == StateStatus.initial) {
      // Trigger load safely
      Future.microtask(() => controller.loadQuestions());
      return buildLoading(context);
    }

    if (state.isLoading) {
      return buildLoading(context);
    }

    if (state.isError) {
      return buildError(
        context,
        state.errorMessage ?? 'Unknown error',
        controller.loadQuestions,
      );
    }

    // Success state - Show Content
    return _QuizContent(state: state, controller: controller);
  }
}

class _QuizContent extends ConsumerStatefulWidget {
  final QuizState state;
  final QuizController controller;

  const _QuizContent({required this.state, required this.controller});

  @override
  ConsumerState<_QuizContent> createState() => _QuizContentState();
}

class _QuizContentState extends ConsumerState<_QuizContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _pixyAnimationController;
  late Animation<double> _pixyScaleAnimation;

  @override
  void initState() {
    super.initState();
    _pixyAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pixyScaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _pixyAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _pixyAnimationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_QuizContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If selected answer changed to a new selection on current question, animate Pixy?
    // Original: _selectAnswer -> controller.forward(from: 0).
    final currentQ = widget.state.currentQuestionIndex;
    final oldQ = oldWidget.state.currentQuestionIndex;

    // Logic: if answer selected for THIS question just now.
    if (currentQ == oldQ) {
      final newSel = widget.state.selectedAnswers[currentQ];
      final oldSel = oldWidget.state.selectedAnswers[currentQ];
      if (newSel != null && oldSel != newSel) {
        _pixyAnimationController.forward(from: 0.0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(textRefreshProvider);
    // If result exists, show Result View (or detailed review)
    if (widget.state.quizResult != null) {
      return _QuizResultView(state: widget.state);
    }

    // Check if questions empty
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
                      scale: _pixyScaleAnimation,
                      alignment: Alignment.bottomCenter,
                      child: _QuizMascotBehindCard(
                        width: 160,
                        slotHeight: 130,
                        imageScale: 1,
                        offsetY: -40,
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
                ? widget
                      .controller
                      .showFeedback // Show detailed explanation first
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
                      _ProfessorHeadAbovePanel(
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

class _QuizResultView extends ConsumerStatefulWidget {
  final QuizState state;

  const _QuizResultView({required this.state});

  @override
  ConsumerState<_QuizResultView> createState() => _QuizResultViewState();
}

class _QuizResultViewState extends ConsumerState<_QuizResultView>
    with SingleTickerProviderStateMixin {
  late AnimationController _summaryAnim;
  late Animation<double> _summaryCurve;

  @override
  void initState() {
    super.initState();
    _summaryAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    );
    _summaryCurve = CurvedAnimation(
      parent: _summaryAnim,
      curve: Curves.easeOutCubic,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _summaryAnim.forward();
    });
  }

  @override
  void dispose() {
    _summaryAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(textRefreshProvider);
    if (widget.state.showAnswerReview) {
      return _QuizAnswerReviewView(
        questions: widget.state.questions,
        selectedAnswers: widget.state.selectedAnswers,
        onBack: () => ref.read(quizStateProvider.notifier).closeAnswerReview(),
      );
    }

    final result = widget.state.quizResult!;
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pct = result.percentage.toInt();
    final tier = pct >= 80
        ? Quiz.resultExcellent
        : pct >= 60
        ? Quiz.resultGood
        : Quiz.resultKeepLearning;
    final helperLine = _quizResultHelperLine(pct);
    final bodyFeedback = pct < 50 ? Quiz.keepImprovingSummary : helperLine;

    final heroGradient = isDark
        ? const [Color(0xFF3A3F66), Color(0xFF4E5490), Color(0xFF5A62B0)]
        : const [Color(0xFF5A63E0), Color(0xFF6F7AF0), Color(0xFF8E97FD)];

    final titleShadow = [
      Shadow(
        color: Colors.black.withValues(alpha: 0.45),
        blurRadius: 14,
        offset: const Offset(0, 2),
      ),
    ];

    final xpEarned = _quizSummaryXp(result);
    final showBadge = pct >= 80;

    return ColoredBox(
      color: colors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(22, 4, 22, 56),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: heroGradient,
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: const Alignment(0, -0.35),
                                radius: 1.15,
                                colors: [
                                  Colors.white.withValues(
                                    alpha: isDark ? 0.18 : 0.28,
                                  ),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.28 : 0.14,
                              ),
                            ),
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _summaryCurve,
                          builder: (context, __) {
                            return _QuizSummaryConfettiLayer(
                              progress: _summaryCurve.value,
                            );
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(22, 4, 22, 56),
                          child: Column(
                            children: [
                              _QuizFacePeek(
                                assetPath: AppAssets.missionQuizHappy,
                                width: 148,
                                imageHeight: 300,
                                heightFactor: 0.5,
                                verticalOffset: 6,
                                circleBackdrop: false,
                                isDark: isDark,
                                brightBackdrop: true,
                                imageAlignment: const Alignment(0, -0.38),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                Quiz.completedTitle,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.alata(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                  shadows: titleShadow,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Transform.translate(
                      offset: const Offset(0, -40),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: AnimatedBuilder(
                          animation: _summaryCurve,
                          builder: (context, __) {
                            final t = _summaryCurve.value;
                            final dispCorrect = (result.correctAnswers * t)
                                .round();
                            final dispPct = (result.percentage * t)
                                .round()
                                .clamp(0, 100);
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(
                                22,
                                26,
                                22,
                                28,
                              ),
                              decoration: BoxDecoration(
                                color: colors.surface,
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: colors.border.withValues(alpha: 0.85),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: isDark ? 0.4 : 0.1,
                                    ),
                                    blurRadius: 28,
                                    offset: const Offset(0, 14),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    tier,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.alata(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: colors.textPrimary,
                                      height: 1.15,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Text(
                                    '$dispCorrect/${result.totalQuestions}',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.alata(
                                      fontSize: 52,
                                      fontWeight: FontWeight.w800,
                                      color: colors.textPrimary,
                                      height: 1.0,
                                      letterSpacing: -1,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    '$dispPct%',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.alata(
                                      fontSize: 34,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? AppColors.primaryPurpleLight
                                          : AppColors.primaryPurple,
                                      height: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Text(
                                    bodyFeedback,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.alata(
                                      fontSize: 15,
                                      height: 1.45,
                                      fontWeight: FontWeight.w600,
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _QuizSummaryStatRow(
                    icon: Icons.check_circle_rounded,
                    iconColor: const Color(0xFF2E7D32),
                    label: Quiz.summaryCorrectRow,
                    value: '${result.correctAnswers}',
                    colors: colors,
                  ),
                  const SizedBox(height: 10),
                  _QuizSummaryStatRow(
                    icon: Icons.cancel_rounded,
                    iconColor: const Color(0xFFC62828),
                    label: Quiz.summaryWrongRow,
                    value: '${result.incorrectAnswers}',
                    colors: colors,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        showBadge
                            ? Icons.emoji_events_rounded
                            : Icons.star_rounded,
                        size: 20,
                        color: showBadge
                            ? const Color(0xFFFFB300)
                            : AppColors.primaryPurple,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          showBadge
                              ? Quiz.badgeUnlockedSummary
                              : Quiz.xpEarnedLine(xpEarned),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.alata(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _GradientMissionButton(
                    label: Quiz.startNextMission,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () =>
                        ref.read(quizStateProvider.notifier).openAnswerReview(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: AppColors.primaryPurple,
                      backgroundColor: colors.surface,
                      side: const BorderSide(
                        color: AppColors.primaryPurple,
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      Quiz.showDetailedResults,
                      style: GoogleFonts.alata(
                        color: AppColors.primaryPurple,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
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

int _quizSummaryXp(QuizResult r) => (20 + r.correctAnswers * 14).clamp(15, 220);

class _QuizSummaryStatRow extends StatelessWidget {
  const _QuizSummaryStatRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.colors,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final AppColorsExtension colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.inputFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.alata(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.alata(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientMissionButton extends StatefulWidget {
  const _GradientMissionButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  State<_GradientMissionButton> createState() => _GradientMissionButtonState();
}

class _GradientMissionButtonState extends State<_GradientMissionButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    const gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Color(0xFF7C4DFF), Color(0xFF5C6BC0), Color(0xFF42A5F5)],
    );
    final glow = BoxShadow(
      color: const Color(0xFF7C4DFF).withValues(alpha: _hovering ? 0.55 : 0.35),
      blurRadius: _hovering ? 22 : 14,
      spreadRadius: _hovering ? 1 : 0,
      offset: const Offset(0, 6),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedScale(
        scale: _hovering ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: Semantics(
          button: true,
          label: widget.label,
          child: Material(
            color: Colors.transparent,
            elevation: 0,
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: BorderRadius.circular(20),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [glow],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 20,
                  ),
                  child: Center(
                    child: Text(
                      widget.label,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.alata(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        letterSpacing: 0.4,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuizSummaryConfettiLayer extends StatelessWidget {
  const _QuizSummaryConfettiLayer({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(painter: _QuizConfettiPainter(progress: progress)),
      ),
    );
  }
}

class _QuizConfettiPainter extends CustomPainter {
  _QuizConfettiPainter({required this.progress});

  final double progress;

  static const _palette = [
    Color(0xFFFFE082),
    Color(0xFFFFAB91),
    Color(0xFF80DEEA),
    Color(0xFFCE93D8),
    Color(0xFFFFFFFF),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final rnd = math.Random(7);
    for (var i = 0; i < 20; i++) {
      final x = rnd.nextDouble() * size.width;
      final startY = -30.0;
      final endY = size.height * (0.35 + rnd.nextDouble() * 0.35);
      final y = startY + (endY - startY) * progress;
      final w = 5.0 + rnd.nextDouble() * 5;
      final h = 4.0 + rnd.nextDouble() * 6;
      final rot = rnd.nextDouble() * math.pi;
      final op =
          (0.15 + 0.55 * math.sin(progress * math.pi)) * (1 - i / 25.0 * 0.4);
      final paint = Paint()
        ..color = _palette[i % _palette.length].withValues(
          alpha: op.clamp(0.0, 1.0),
        )
        ..style = PaintingStyle.fill;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rot * progress);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: w, height: h),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _QuizConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

String _quizResultHelperLine(int pct) {
  if (pct >= 80) return Quiz.resultHelperTextHigh;
  if (pct >= 50) return Quiz.resultHelperTextMid;
  return Quiz.resultHelperTextLow;
}

String? _quizOptionLabel(Question q, int? answerId) {
  if (answerId == null) return null;
  for (final o in q.options) {
    if (o.id == answerId) return o.text;
  }
  return null;
}

/// Professor full-body asset above the feedback card.
///
/// Nu folosește [ClipRect] pe viewport: la offset negativ, capul poate „ieși” în sus
/// fără tăiere plată — doar [Stack] cu [clipBehavior: Clip.none].
class _ProfessorHeadAbovePanel extends StatelessWidget {
  const _ProfessorHeadAbovePanel({
    required this.width,
    required this.viewportHeight,
    this.imageScale = 1.2,
    this.imageOffsetY = 0,
  });

  final double width;
  final double viewportHeight;
  final double imageScale;

  /// Negativ = urcă întreaga figură (mai mult cap deasupra cardului).
  final double imageOffsetY;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: viewportHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Transform.translate(
            offset: Offset(0, imageOffsetY),
            child: Transform.scale(
              scale: imageScale,
              alignment: Alignment.bottomCenter,
              child: Image.asset(
                AppAssets.missionQuizProfessor,
                width: width,
                fit: BoxFit.fitWidth,
                alignment: Alignment.topCenter,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.school_rounded,
                  size: width * 0.45,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pixy (thinking) deasupra zonei cardului: fără [ClipRect], ancorat jos, ca să nu fie
/// tăiat la mijloc; cardul e desenat deasupra în [Stack] pentru overlap curat.
class _QuizMascotBehindCard extends StatelessWidget {
  const _QuizMascotBehindCard({
    required this.width,
    required this.slotHeight,
    this.imageScale = 1.12,
    this.offsetY = 0,
  });

  final double width;

  /// Înălțimea „slotului” de layout; desenul poate depăși în sus (clip none pe părinți).
  final double slotHeight;
  final double imageScale;

  /// Pozitiv coboară figura (mai departe de bara de progres).
  final double offsetY;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: slotHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Transform.translate(
            offset: Offset(0, offsetY),
            child: Transform.scale(
              scale: imageScale,
              alignment: Alignment.bottomCenter,
              child: Image.asset(
                AppAssets.welcomePage2Thinking,
                width: width,
                fit: BoxFit.fitWidth,
                alignment: Alignment.topCenter,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.smart_toy_rounded,
                  size: width * 0.48,
                  color: Colors.white.withValues(alpha: 0.95),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Clips the top of a tall character asset so only the “face” peeks above a card.
class _QuizFacePeek extends StatelessWidget {
  const _QuizFacePeek({
    required this.assetPath,
    required this.width,
    this.imageHeight = 260,
    this.heightFactor = 0.4,
    this.verticalOffset = 0,
    this.circleBackdrop = true,
    this.isDark = false,
    this.brightBackdrop = false,
    this.imageAlignment = const Alignment(0, -0.2),
  });

  final String assetPath;
  final double width;
  final double imageHeight;
  final double heightFactor;
  final double verticalOffset;
  final bool circleBackdrop;
  final bool isDark;

  /// Lighter halo (e.g. on purple headers).
  final bool brightBackdrop;

  /// Focus region inside the asset (professor: bias toward head at top).
  final Alignment imageAlignment;

  @override
  Widget build(BuildContext context) {
    final haloOpacity = brightBackdrop
        ? (isDark ? 0.14 : 0.45)
        : (isDark ? 0.1 : 0.22);

    return Transform.translate(
      offset: Offset(0, verticalOffset),
      child: SizedBox(
        width: width,
        height: imageHeight * heightFactor + 12,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            if (circleBackdrop)
              Positioned(
                top: 10,
                child: Container(
                  width: width * 0.95,
                  height: width * 0.95,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: haloOpacity),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(
                          alpha: brightBackdrop ? 0.25 : 0.15,
                        ),
                        blurRadius: 20,
                        spreadRadius: -6,
                      ),
                    ],
                  ),
                ),
              ),
            ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: heightFactor,
                child: Image.asset(
                  assetPath,
                  width: width,
                  height: imageHeight,
                  fit: BoxFit.cover,
                  alignment: imageAlignment,
                  errorBuilder: (_, __, ___) => Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Icon(
                      Icons.smart_toy_rounded,
                      size: width * 0.5,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
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

class _QuizAnswerReviewView extends ConsumerWidget {
  const _QuizAnswerReviewView({
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
    const green = Color(0xFF2E7D32);
    const coral = Color(0xFFE65100);

    return ColoredBox(
      color: colors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          Quiz.reviewSubtitle,
                          style: GoogleFonts.alata(
                            fontSize: 13,
                            height: 1.4,
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
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                itemCount: questions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final q = questions[index];
                  final pickedId = selectedAnswers[index];
                  final correctId = q.correctAnswerId;
                  final isRight = pickedId == correctId;
                  final pickedText = _quizOptionLabel(q, pickedId);
                  final correctText = _quizOptionLabel(q, correctId) ?? '';

                  return Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: colors.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isRight
                            ? green.withValues(alpha: 0.35)
                            : colors.border,
                        width: isRight ? 1.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.28 : 0.06,
                          ),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryPurple.withValues(
                                  alpha: isDark ? 0.22 : 0.1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${Quiz.questionLabel} ${index + 1}',
                                style: GoogleFonts.alata(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryPurple,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: (isRight ? green : coral).withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isRight
                                    ? Quiz.reviewCorrectBadge
                                    : Quiz.reviewMissedBadge,
                                style: GoogleFonts.alata(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: isRight ? green : coral,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          q.question,
                          style: GoogleFonts.alata(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _ReviewAnswerRow(
                          label: Quiz.yourAnswerLabel,
                          text: pickedText ?? Quiz.notAnsweredLabel,
                          emphasize: !isRight,
                          isDark: isDark,
                        ),
                        if (!isRight) ...[
                          const SizedBox(height: 10),
                          _ReviewAnswerRow(
                            label: Quiz.correctAnswerLabel,
                            text: correctText,
                            correct: true,
                            isDark: isDark,
                          ),
                        ],
                      ],
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

class _ReviewAnswerRow extends StatelessWidget {
  const _ReviewAnswerRow({
    required this.label,
    required this.text,
    this.emphasize = false,
    this.correct = false,
    required this.isDark,
  });

  final String label;
  final String text;
  final bool emphasize;
  final bool correct;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bg = correct
        ? const Color(0xFF2E7D32).withValues(alpha: isDark ? 0.2 : 0.08)
        : emphasize
        ? const Color(0xFFE65100).withValues(alpha: isDark ? 0.18 : 0.07)
        : colors.inputFill;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: correct
              ? const Color(0xFF2E7D32).withValues(alpha: 0.35)
              : emphasize
              ? const Color(0xFFE65100).withValues(alpha: 0.35)
              : colors.border.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.alata(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colors.textSecondary,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: GoogleFonts.alata(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
