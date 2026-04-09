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
      return buildError(context, state.errorMessage ?? 'Unknown error', controller.loadQuestions);
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
    // If result exists, show Result View
    if (widget.state.quizResult != null) {
      return _QuizResultView(result: widget.state.quizResult!);
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
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 160,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? const [
                        Color(0xFF5C64B8),
                        Color(0xFF454B7A),
                      ]
                    : const [
                        Color(0xFF8E97FD),
                        Color(0xFF9AA2FD),
                      ],
              ),
            ),
          ),
        ),
        Column(
          children: [
            _buildProgressBar(isDark),
            const SizedBox(height: 8),
            _buildPixyMascot(isDark),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _buildQuestionCard(colors, isDark),
                    const SizedBox(height: 24),
                    _buildNavigationButtons(isDark),
                    const SizedBox(height: 32),
                  ],
                ),
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${Quiz.questionLabel} $current ${Quiz.ofLabel} $total',
                style: GoogleFonts.alata(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: isDark ? 0.14 : 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: GoogleFonts.alata(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: isDark ? 0.18 : 0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.white, Color(0xFFE3E7FF)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: isDark ? 0.25 : 0.6),
                          blurRadius: 6,
                          spreadRadius: 1,
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
    );
  }

  Widget _buildPixyMascot(bool isDark) {
    return FadeInWidget(
      delay: const Duration(milliseconds: 400),
      child: ScaleTransition(
        scale: _pixyScaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.15),
          ),
          child: Image.asset(
            AppAssets.welcomePage2Thinking,
            // Keep original path structure if that's how assets are declared
            height: 120,
            fit: BoxFit.contain,
            errorBuilder: (c, e, s) => const Icon(Icons.person, size: 80, color: Colors.white),
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
                color: AppColors.primaryPurple.withValues(alpha: isDark ? 0.2 : 0.08),
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
                                color: AppColors.primaryPurple.withValues(alpha: 0.25),
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
                            color: isSelected ? Colors.white : Colors.transparent,
                            border: Border.all(
                              color: isSelected ? Colors.white : colors.textHint,
                              width: 2.5,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, size: 16, color: Color(0xFF8E97FD))
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            option.text,
                            style: GoogleFonts.alata(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? Colors.white : colors.textPrimary,
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
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
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
                 ? widget.controller.showFeedback // Show detailed explanation first
                 : null,
             style: ElevatedButton.styleFrom(
               backgroundColor: hasSelection ? purple : disabledFill,
               padding: const EdgeInsets.symmetric(vertical: 16),
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
               elevation: hasSelection ? 4 : 0,
             ),
             child: state.isSubmitting
                 ? const SizedBox(
                     height: 22,
                     width: 22,
                     child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
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
    final Color accentColor = isCorrect ? const Color(0xFF4CAF50) : const Color(0xFFFF7043);
    final String titleText = isCorrect ? Quiz.feedbackCorrectTitle : Quiz.feedbackIncorrectTitle;

    return Stack(
      children: [
         Positioned.fill(
           child: BackdropFilter(
             filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
             child: Container(
               color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.25),
             ),
           ),
         ),
         Center(
           child: Padding(
             padding: const EdgeInsets.symmetric(horizontal: 24),
             child: FadeInWidget(
               child: Column(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   Container(
                     padding: const EdgeInsets.all(24),
                     decoration: BoxDecoration(
                       color: colors.cardColor,
                       borderRadius: BorderRadius.circular(24),
                       border: Border.all(color: colors.border),
                     ),
                     child: Column(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         ClipRRect(
                           borderRadius: BorderRadius.circular(20),
                           child: Image.asset(
                             AppAssets.welcomePage1Hello,
                             height: 88,
                             fit: BoxFit.contain,
                             errorBuilder: (_, __, ___) => Icon(
                               isCorrect
                                   ? Icons.check_circle_rounded
                                   : Icons.school_rounded,
                               size: 56,
                               color: accentColor,
                             ),
                           ),
                         ),
                         const SizedBox(height: 12),
                         Icon(
                            isCorrect ? Icons.check_circle_rounded : Icons.lightbulb_rounded,
                            size: 32,
                            color: accentColor,
                         ),
                         const SizedBox(height: 12),
                         Text(
                           titleText,
                           style: GoogleFonts.alata(fontSize: 18, color: accentColor, fontWeight: FontWeight.bold),
                         ),
                         const SizedBox(height: 12),
                         Text(
                           state.feedbackText,
                           textAlign: TextAlign.center,
                           style: GoogleFonts.alata(
                             fontSize: 15,
                             color: colors.textPrimary,
                             height: 1.4,
                           ),
                         ),
                         const SizedBox(height: 24),
                         SizedBox(
                           width: double.infinity,
                           child: ElevatedButton(
                             onPressed: widget.controller.goToNextAfterFeedback,
                             style: ElevatedButton.styleFrom(backgroundColor: accentColor, shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(vertical: 14)),
                             child: Text(Quiz.continueAction, style: GoogleFonts.alata(color: Colors.white, fontWeight: FontWeight.bold)),
                           ),
                         )
                       ],
                     ),
                   ),
                 ],
               ),
             ),
           ),
         )
      ],
    );
  }
}

class _QuizResultView extends ConsumerWidget {
  final QuizResult result;

  const _QuizResultView({required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(textRefreshProvider);
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pct = result.percentage.toInt();
    final tier = pct >= 80
        ? Quiz.resultExcellent
        : pct >= 60
            ? Quiz.resultGood
            : Quiz.resultKeepLearning;

    final gradientColors = isDark
        ? [
            AppColors.primaryPurpleDark,
            const Color(0xFF3D4266),
            colors.background,
          ]
        : [
            AppColors.primaryPurple,
            AppColors.primaryPurple.withValues(alpha: 0.85),
            colors.background,
          ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors,
          stops: const [0.0, 0.35, 1.0],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Image.asset(
                AppAssets.missionQuizHappy,
                height: 120,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.emoji_events_rounded,
                  size: 88,
                  color: Color(0xFFFFCA28),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                Quiz.completedTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.alata(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tier,
                textAlign: TextAlign.center,
                style: GoogleFonts.alata(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  children: [
                    Text(
                      Quiz.scoreLabel,
                      style: GoogleFonts.alata(
                        fontSize: 14,
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$pct%',
                      style: GoogleFonts.alata(
                        fontSize: 56,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.primaryPurpleLight : AppColors.primaryPurple,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${result.correctAnswers} ${Quiz.resultOutOf} ${result.totalQuestions} ${Quiz.resultCorrect}',
                      style: GoogleFonts.alata(
                        fontSize: 15,
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      Quiz.resultHelperText,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.alata(
                        fontSize: 13,
                        height: 1.45,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: colors.surface,
                    foregroundColor: AppColors.primaryPurple,
                    elevation: 0,
                    side: const BorderSide(color: AppColors.primaryPurple, width: 2),
                  ),
                  child: Text(
                    Quiz.continueToMissions,
                    style: GoogleFonts.alata(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}