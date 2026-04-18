import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:thinky/core_controls/constants/app_texts.dart';
import 'package:thinky/core_controls/features/missions/mission_quiz/domain/quiz_lesson_content.dart';
import 'package:thinky/core_controls/features/missions/mission_quiz/presentation/widgets/quiz_widgets.dart';
import 'package:thinky/shared_controls/theme/app_colors.dart';
import 'package:thinky/shared_controls/theme/app_colors_extension.dart';
import 'package:thinky/shared_controls/theme/app_dimens.dart';
import 'package:thinky/shared_controls/widgets/buttons/primary_button.dart';

import '../../domain/vocabulary_lesson_content.dart';

/// "Learn with Pixy" carousel shown after the Word Match mission completes.
/// Design mirrors the other mission learning views (Pixy Learns, Draw Shapes,
/// Grouping) for consistency.
class VocabularyLearningView extends StatefulWidget {
  final VoidCallback onDone;

  const VocabularyLearningView({super.key, required this.onDone});

  @override
  State<VocabularyLearningView> createState() => _VocabularyLearningViewState();
}

class _VocabularyLearningViewState extends State<VocabularyLearningView> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < vocabularyLessonCards.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLast = _currentPage == vocabularyLessonCards.length - 1;

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
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
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: AppDimens.sm),
                Text(
                  Vocabulary.lessonButton,
                  style: GoogleFonts.alata(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimens.sm),
                _buildProgressBar(),
                const SizedBox(height: AppDimens.sm),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: vocabularyLessonCards.length,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (context, index) {
                      final card = vocabularyLessonCards[index];
                      return _LessonPage(
                        card: card,
                        colors: colors,
                        isDark: isDark,
                      );
                    },
                  ),
                ),
                _buildDotIndicator(),
                const SizedBox(height: AppDimens.sm),
                SafeArea(
                  top: false,
                  minimum: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (isLast) ...[
                          PrimaryButton(
                            text: Vocabulary.continueMissions,
                            onPressed: widget.onDone,
                          ),
                          const SizedBox(height: AppDimens.sm),
                          SizedBox(
                            width: double.infinity,
                            height: AppDimens.buttonHeight,
                            child: OutlinedButton(
                              onPressed: widget.onDone,
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
                                Vocabulary.backToResults,
                                style: GoogleFonts.alata(
                                  color: AppColors.primaryPurple,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          PrimaryButton(
                            text: Vocabulary.lessonNext,
                            onPressed: _nextPage,
                          ),
                          const SizedBox(height: AppDimens.sm),
                          Center(
                            child: TextButton(
                              onPressed: widget.onDone,
                              child: Text(
                                Vocabulary.backToResults,
                                style: GoogleFonts.alata(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildProgressBar() {
    final progress = (_currentPage + 1) / vocabularyLessonCards.length;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.pagePaddingHorizontal + 8,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_currentPage + 1} / ${vocabularyLessonCards.length}',
                style: GoogleFonts.alata(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: GoogleFonts.alata(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                builder: (context, value, _) {
                  return LinearProgressIndicator(
                    value: value,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDotIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(vocabularyLessonCards.length, (i) {
        final isActive = i == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 20 : 7,
          height: 7,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isActive
                ? Colors.white
                : Colors.white.withValues(alpha: 0.3),
          ),
        );
      }),
    );
  }
}

class _LessonPage extends StatelessWidget {
  final LessonCard card;
  final AppColorsExtension colors;
  final bool isDark;

  const _LessonPage({
    required this.card,
    required this.colors,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.pagePaddingHorizontal,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ProfessorHeadAbovePanel(
              width: 110,
              viewportHeight: 100,
              imageScale: 1.35,
              imageOffsetY: -8,
            ),
            Transform.translate(
              offset: const Offset(0, -16),
              child: _LessonCardWidget(
                card: card,
                colors: colors,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonCardWidget extends StatelessWidget {
  final LessonCard card;
  final AppColorsExtension colors;
  final bool isDark;

  const _LessonCardWidget({
    required this.card,
    required this.colors,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.cardPadding,
        vertical: AppDimens.cardPadding + 4,
      ),
      decoration: BoxDecoration(
        color: colors.cardColor,
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryPurple.withValues(alpha: 0.15),
                  AppColors.primaryPurple.withValues(alpha: 0.06),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primaryPurple.withValues(alpha: 0.2),
              ),
            ),
            child: Icon(card.icon, size: 24, color: AppColors.primaryPurple),
          ),
          const SizedBox(height: AppDimens.md),
          Text(
            card.title(),
            textAlign: TextAlign.center,
            style: GoogleFonts.alata(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: AppDimens.md),
          Text(
            card.body(),
            textAlign: TextAlign.left,
            style: GoogleFonts.alata(
              fontSize: 13.5,
              height: 1.65,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimens.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimens.md),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1)
                  .withValues(alpha: isDark ? 0.08 : 1.0),
              borderRadius: BorderRadius.circular(AppDimens.radiusLg),
              border: Border.all(
                color: isDark
                    ? const Color(0xFFFFD54F).withValues(alpha: 0.25)
                    : const Color(0xFFFFE082),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_rounded,
                  size: 20,
                  color: isDark
                      ? const Color(0xFFFFD54F)
                      : const Color(0xFFF9A825),
                ),
                const SizedBox(width: AppDimens.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Vocabulary.lessonDidYouKnow,
                        style: GoogleFonts.alata(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? const Color(0xFFFFD54F)
                              : const Color(0xFFF57F17),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        card.funFact(),
                        style: GoogleFonts.alata(
                          fontSize: 12,
                          height: 1.55,
                          color: isDark
                              ? colors.textSecondary
                              : const Color(0xFF5D4037),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
