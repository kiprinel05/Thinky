import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:thinky/core_controls/constants/app_texts.dart';
import 'package:thinky/core_controls/features/missions/mission_animals/presentation/widgets/animals_mascots.dart';
import 'package:thinky/core_controls/services/language_service.dart';
import 'package:thinky/shared_controls/theme/app_colors.dart';
import 'package:thinky/shared_controls/theme/app_colors_extension.dart';
import 'package:thinky/shared_controls/widgets/buttons/primary_button.dart';

import '../../data/vocabulary_models.dart';
import '../controllers/vocabulary_controller.dart';
import 'vocabulary_learning_view.dart';

/// Word Match mission — bilingual, emoji-based.
class VocabularyMissionPage extends ConsumerStatefulWidget {
  const VocabularyMissionPage({super.key});

  @override
  ConsumerState<VocabularyMissionPage> createState() =>
      _VocabularyMissionPageState();
}

class _VocabularyMissionPageState extends ConsumerState<VocabularyMissionPage>
    with TickerProviderStateMixin {
  late AnimationController _wordBounceController;
  late AnimationController _feedbackController;
  late AnimationController _sparkleController;

  late Animation<double> _wordScale;
  late Animation<double> _feedbackSlide;
  late Animation<double> _sparkleOpacity;

  @override
  void initState() {
    super.initState();

    _wordBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _wordScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _wordBounceController, curve: Curves.elasticOut),
    );

    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _feedbackSlide = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(parent: _feedbackController, curve: Curves.easeOutBack),
    );

    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _sparkleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _sparkleController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
        reverseCurve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _wordBounceController.dispose();
    _feedbackController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  String _activeLang() => ref.read(languageProvider).languageCode;

  @override
  Widget build(BuildContext context) {
    ref.watch(textRefreshProvider);
    ref.watch(languageProvider);

    final colors = context.appColors;
    final state = ref.watch(vocabularyControllerProvider);

    ref.listen<VocabMissionState>(vocabularyControllerProvider, (prev, next) {
      if (next.phase == VocabMissionPhase.question &&
          prev?.phase != VocabMissionPhase.question) {
        _wordBounceController.forward(from: 0.0);
      }
      if (next.phase == VocabMissionPhase.feedback &&
          prev?.phase != VocabMissionPhase.feedback) {
        _feedbackController.forward(from: 0.0);
        if (next.lastAnswer?.correct == true) {
          _sparkleController.forward(from: 0.0);
        }
      }
    });

    return Scaffold(
      backgroundColor: colors.background,
      body: _buildPhase(state, colors),
    );
  }

  Widget _buildPhase(VocabMissionState state, AppColorsExtension colors) {
    switch (state.phase) {
      case VocabMissionPhase.intro:
        return _IntroScaffold(
          onStart: () {
            ref.read(vocabularyControllerProvider.notifier).startFromIntro();
          },
          onBack: () => Navigator.of(context).pop(true),
        );
      case VocabMissionPhase.loading:
        return _LoadingScaffold(message: Vocabulary.loadingWords);
      case VocabMissionPhase.submitting:
        return _QuestionScaffold(
          state: state,
          languageCode: _activeLang(),
          isSubmitting: true,
          wordScaleAnim: _wordScale,
          wordBounceController: _wordBounceController,
          onBack: () => Navigator.of(context).pop(true),
          onSelect: (_) {},
          onSubmit: () {},
        );
      case VocabMissionPhase.question:
        return _QuestionScaffold(
          state: state,
          languageCode: _activeLang(),
          isSubmitting: false,
          wordScaleAnim: _wordScale,
          wordBounceController: _wordBounceController,
          onBack: () => Navigator.of(context).pop(true),
          onSelect: (id) {
            ref.read(vocabularyControllerProvider.notifier).selectImage(id);
          },
          onSubmit: () {
            ref
                .read(vocabularyControllerProvider.notifier)
                .submitAnswer(languageCode: _activeLang());
          },
        );
      case VocabMissionPhase.feedback:
        return _FeedbackScaffold(
          state: state,
          languageCode: _activeLang(),
          feedbackSlide: _feedbackSlide,
          feedbackController: _feedbackController,
          sparkleOpacity: _sparkleOpacity,
          sparkleController: _sparkleController,
          onNext: () {
            ref.read(vocabularyControllerProvider.notifier).nextQuestion();
          },
        );
      case VocabMissionPhase.missionComplete:
        return _CompleteScaffold(
          state: state,
          onContinue: () => Navigator.of(context).pop(true),
          onLearn: _openLearningView,
          onRetry: () {
            ref.read(vocabularyControllerProvider.notifier).restart();
          },
        );
      case VocabMissionPhase.error:
        return _ErrorScaffold(
          message: state.errorMessage,
          onRetry: () {
            ref.read(vocabularyControllerProvider.notifier).startFromIntro();
          },
          onBack: () => Navigator.of(context).pop(true),
        );
    }
  }

  Future<void> _openLearningView() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (ctx) => VocabularyLearningView(
          onDone: () => Navigator.of(ctx).pop(),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SHARED LAYOUT HELPERS
// ═══════════════════════════════════════════════════════════════════════════

/// Soft gradient + decorative circles used by every phase for visual unity.
class _BackgroundDecor extends StatelessWidget {
  const _BackgroundDecor({this.vibrant = false});

  /// When true, the gradient is more saturated (used for intro / complete).
  final bool vibrant;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.appColors;
    return Stack(
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
                    : vibrant
                        ? [
                            const Color(0xFF9DAAFF),
                            const Color(0xFFE8EAFF),
                            colors.background,
                          ]
                        : [
                            const Color(0xFFE2E6FF),
                            const Color(0xFFF3F4FF),
                            colors.background,
                          ],
                stops: vibrant
                    ? const [0.0, 0.28, 0.55]
                    : const [0.0, 0.35, 0.8],
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
                color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.3),
              ),
            ),
          ),
        ),
        Positioned(
          top: 140,
          left: -50,
          child: IgnorePointer(
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryPurple.withValues(
                  alpha: isDark ? 0.12 : 0.15,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onBack;
  final Widget? trailing;
  final bool onGradient;

  const _TopBar({
    required this.title,
    required this.onBack,
    this.subtitle,
    this.trailing,
    this.onGradient = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final titleColor = onGradient ? Colors.white : colors.textPrimary;
    final subtitleColor = onGradient
        ? Colors.white.withValues(alpha: 0.82)
        : colors.textSecondary;
    final btnBg = onGradient
        ? Colors.white.withValues(alpha: 0.18)
        : colors.cardColor;
    final btnBorder = onGradient
        ? Colors.white.withValues(alpha: 0.28)
        : colors.border;
    final iconColor = onGradient ? Colors.white : colors.textPrimary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: btnBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: btnBorder),
              ),
              child: Icon(Icons.arrow_back, color: iconColor, size: 20),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.alata(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.alata(
                        fontSize: 12,
                        color: subtitleColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  final int correct;
  final int answered;
  final bool onGradient;

  const _ScorePill({
    required this.correct,
    required this.answered,
    this.onGradient = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = onGradient ? Colors.white : AppColors.primaryPurple;
    final bg = onGradient
        ? Colors.white.withValues(alpha: 0.18)
        : AppColors.primaryPurple.withValues(alpha: 0.12);
    final border = onGradient
        ? Colors.white.withValues(alpha: 0.28)
        : AppColors.primaryPurple.withValues(alpha: 0.25);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Text(
        '$correct/$answered',
        style: GoogleFonts.alata(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

class _ProgressDots extends StatelessWidget {
  final int total;
  final int answered;
  final int current;
  final bool onGradient;

  const _ProgressDots({
    required this.total,
    required this.answered,
    required this.current,
    this.onGradient = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(total, (index) {
          Color dotColor;
          double size;
          if (index < answered) {
            dotColor = AppColors.correctGreen;
            size = 8;
          } else if (index == current) {
            dotColor = onGradient ? Colors.white : AppColors.primaryPurple;
            size = 12;
          } else {
            dotColor = onGradient
                ? Colors.white.withValues(alpha: 0.3)
                : colors.border;
            size = 8;
          }
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          );
        }),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// INTRO PHASE
// ═══════════════════════════════════════════════════════════════════════════

class _IntroScaffold extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback onBack;

  const _IntroScaffold({required this.onStart, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        const _BackgroundDecor(vibrant: true),
        SafeArea(
          child: Column(
            children: [
              _TopBar(
                title: Vocabulary.title,
                subtitle: Vocabulary.subtitle,
                onBack: onBack,
                onGradient: true,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height * 0.72,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 8),
                        const AnimalsMascotHead(
                          kind: AnimalsMascotKind.pixy,
                          width: 130,
                          viewportHeight: 120,
                          imageScale: 1.25,
                          offsetY: -14,
                        ),
                        Transform.translate(
                          offset: const Offset(0, -16),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: colors.cardColor,
                              borderRadius: BorderRadius.circular(24),
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
                                  '📖',
                                  style: GoogleFonts.alata(fontSize: 44),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  Vocabulary.introTitle,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.alata(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  Vocabulary.introBody,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.alata(
                                    fontSize: 14,
                                    height: 1.55,
                                    color: colors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _FeaturePill(
                                      icon: Icons.format_list_numbered_rounded,
                                      text: Vocabulary.introFeature1,
                                    ),
                                    _FeaturePill(
                                      icon: Icons.category_rounded,
                                      text: Vocabulary.introFeature2,
                                    ),
                                    _FeaturePill(
                                      icon: Icons.auto_awesome_rounded,
                                      text: Vocabulary.introFeature3,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 22),
                                PrimaryButton(
                                  text: Vocabulary.startButton,
                                  onPressed: onStart,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeaturePill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.primaryPurple.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primaryPurple),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.alata(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LOADING PHASE
// ═══════════════════════════════════════════════════════════════════════════

class _LoadingScaffold extends StatelessWidget {
  final String message;
  const _LoadingScaffold({required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Stack(
      children: [
        const _BackgroundDecor(),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.primaryPurple),
              const SizedBox(height: 18),
              Text(
                message,
                style: GoogleFonts.alata(
                  fontSize: 16,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// QUESTION PHASE
// ═══════════════════════════════════════════════════════════════════════════

class _QuestionScaffold extends StatelessWidget {
  final VocabMissionState state;
  final String languageCode;
  final bool isSubmitting;
  final Animation<double> wordScaleAnim;
  final AnimationController wordBounceController;
  final VoidCallback onBack;
  final ValueChanged<int> onSelect;
  final VoidCallback onSubmit;

  const _QuestionScaffold({
    required this.state,
    required this.languageCode,
    required this.isSubmitting,
    required this.wordScaleAnim,
    required this.wordBounceController,
    required this.onBack,
    required this.onSelect,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final question = state.currentQuestion;
    if (question == null) {
      return _LoadingScaffold(message: Vocabulary.loadingWords);
    }

    return Stack(
      children: [
        const _BackgroundDecor(),
        SafeArea(
          child: Column(
            children: [
              _TopBar(
                title: Vocabulary.title,
                subtitle: Vocabulary.questionPrompt,
                onBack: onBack,
                trailing: state.answeredCount > 0
                    ? _ScorePill(
                        correct: state.correctCount,
                        answered: state.answeredCount,
                      )
                    : null,
              ),
              _ProgressDots(
                total: state.totalQuestions,
                answered: state.answeredCount,
                current: state.currentIndex,
              ),
              // Center the word card + grid block vertically so there isn't
              // a huge dead zone below when the grid is short.
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: wordBounceController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: wordScaleAnim.value,
                              child: child,
                            );
                          },
                          child: _WordCard(
                            word: question.wordFor(languageCode),
                          ),
                        ),
                        const SizedBox(height: 22),
                        // Grid is sized by its content — 2 rows of ~160px tiles.
                        // Using AspectRatio on a SizedBox keeps it crisp.
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final crossAxis =
                                question.images.length >= 6 ? 3 : 2;
                            final spacing = 12.0;
                            final tileSize = (constraints.maxWidth -
                                    spacing * (crossAxis - 1)) /
                                crossAxis;
                            final rowCount =
                                (question.images.length / crossAxis).ceil();
                            final gridHeight = tileSize * rowCount +
                                spacing * (rowCount - 1);
                            return SizedBox(
                              height: gridHeight,
                              child: _EmojiGrid(
                                question: question,
                                languageCode: languageCode,
                                selectedId: state.selectedImageId,
                                onSelect:
                                    isSubmitting ? null : onSelect,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                child: PrimaryButton(
                  text: isSubmitting
                      ? Vocabulary.submittingShort
                      : Vocabulary.submitAnswer,
                  onPressed: state.hasSelection && !isSubmitting
                      ? onSubmit
                      : null,
                  isEnabled: state.hasSelection && !isSubmitting,
                  isLoading: isSubmitting,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WordCard extends StatelessWidget {
  final String word;
  const _WordCard({required this.word});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8E97FD), Color(0xFFA5AEFD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8E97FD).withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            word,
            textAlign: TextAlign.center,
            style: GoogleFonts.alata(
              fontSize: 38,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1.2,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            Vocabulary.chooseEmoji,
            style: GoogleFonts.alata(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmojiGrid extends StatelessWidget {
  final VocabQuestion question;
  final String languageCode;
  final int? selectedId;
  final ValueChanged<int>? onSelect;

  const _EmojiGrid({
    required this.question,
    required this.languageCode,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final images = question.images;
    // 2 columns look best on phones; bump to 3 for 6-option hard rounds.
    final crossAxis = images.length >= 6 ? 3 : 2;
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxis,
        childAspectRatio: 1.0,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final image = images[index];
        return _EmojiTile(
          image: image,
          languageCode: languageCode,
          selected: selectedId == image.id,
          onTap: onSelect == null ? null : () => onSelect!(image.id),
        );
      },
    );
  }
}

class _EmojiTile extends StatelessWidget {
  final VocabImage image;
  final String languageCode;
  final bool selected;
  final VoidCallback? onTap;

  const _EmojiTile({
    required this.image,
    required this.languageCode,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      label: image.labelFor(languageCode),
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: colors.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.primaryPurple : colors.border,
              width: selected ? 3.0 : 1.5,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primaryPurple.withValues(alpha: 0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Text(
                      image.emoji,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 96,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
              if (selected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryPurple,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check,
                        color: Colors.white, size: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FEEDBACK PHASE
// ═══════════════════════════════════════════════════════════════════════════

class _FeedbackScaffold extends StatelessWidget {
  final VocabMissionState state;
  final String languageCode;
  final Animation<double> feedbackSlide;
  final AnimationController feedbackController;
  final Animation<double> sparkleOpacity;
  final AnimationController sparkleController;
  final VoidCallback onNext;

  const _FeedbackScaffold({
    required this.state,
    required this.languageCode,
    required this.feedbackSlide,
    required this.feedbackController,
    required this.sparkleOpacity,
    required this.sparkleController,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final answer = state.lastAnswer;
    final feedback = state.lastFeedback;
    final question = state.currentQuestion;
    if (answer == null || feedback == null || question == null) {
      return _LoadingScaffold(message: Vocabulary.loadingWords);
    }

    final isCorrect = answer.correct;
    final accentColor =
        isCorrect ? AppColors.correctGreen : AppColors.missionPeach;

    final correctImage = question.images.firstWhere(
      (img) => img.id == answer.correctImageId,
      orElse: () => question.images.first,
    );

    return Stack(
      children: [
        const _BackgroundDecor(),
        SafeArea(
          child: AnimatedBuilder(
            animation: feedbackController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, feedbackSlide.value),
                child: Opacity(
                  opacity: feedbackController.value,
                  child: child,
                ),
              );
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 86,
                          height: 86,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              isCorrect ? '🎉' : '💡',
                              style: const TextStyle(fontSize: 44),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          feedback.message,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.alata(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (!isCorrect) ...[
                          Text(
                            Vocabulary.theRightAnswer,
                            style: GoogleFonts.alata(
                              fontSize: 13,
                              color: colors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _CorrectAnswerChip(
                            image: correctImage,
                            languageCode: languageCode,
                          ),
                          const SizedBox(height: 20),
                        ] else ...[
                          _CorrectAnswerChip(
                            image: correctImage,
                            languageCode: languageCode,
                          ),
                          const SizedBox(height: 20),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryPurple.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.primaryPurple.withValues(
                                alpha: 0.28,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🤖',
                                  style: TextStyle(fontSize: 20)),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  feedback.encouragement,
                                  style: GoogleFonts.alata(
                                    fontSize: 13,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: onNext,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 4,
                            ),
                            child: Text(
                              state.currentIndex + 1 >= state.totalQuestions
                                  ? Vocabulary.seeResultsWithTrophy
                                  : Vocabulary.nextWordArrow,
                              style: GoogleFonts.alata(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (isCorrect)
          AnimatedBuilder(
            animation: sparkleController,
            builder: (context, _) {
              return IgnorePointer(
                child: Opacity(
                  opacity: sparkleOpacity.value * 0.7,
                  child: SizedBox.expand(
                    child: CustomPaint(
                      painter:
                          _SparklePainter(progress: sparkleController.value),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _CorrectAnswerChip extends StatelessWidget {
  final VocabImage image;
  final String languageCode;

  const _CorrectAnswerChip({
    required this.image,
    required this.languageCode,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: colors.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.correctGreen, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.correctGreen.withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(image.emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(width: 14),
          Text(
            image.labelFor(languageCode),
            style: GoogleFonts.alata(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.correctGreen,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MISSION COMPLETE PHASE
// ═══════════════════════════════════════════════════════════════════════════

class _CompleteScaffold extends StatelessWidget {
  final VocabMissionState state;
  final VoidCallback onContinue;
  final VoidCallback onLearn;
  final VoidCallback onRetry;

  const _CompleteScaffold({
    required this.state,
    required this.onContinue,
    required this.onLearn,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accuracy = state.totalQuestions > 0
        ? (state.correctCount / state.totalQuestions * 100).toInt()
        : 0;
    final accentColor = accuracy >= 80
        ? AppColors.correctGreen
        : accuracy >= 50
            ? AppColors.primaryPurple
            : AppColors.missionPeach;

    final messageLine = accuracy >= 90
        ? Vocabulary.completeLineHigh
        : accuracy >= 70
            ? Vocabulary.completeLineMid
            : Vocabulary.completeLineLow;

    return Stack(
      children: [
        const _BackgroundDecor(vibrant: true),
        SafeArea(
          child: Column(
            children: [
              _TopBar(
                title: Vocabulary.title,
                onBack: onContinue,
                onGradient: true,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height * 0.72,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 8),
                        const AnimalsMascotHead(
                          kind: AnimalsMascotKind.pixy,
                          width: 130,
                          viewportHeight: 120,
                          imageScale: 1.25,
                          offsetY: -14,
                        ),
                        Transform.translate(
                          offset: const Offset(0, -16),
                          child: Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: colors.cardColor,
                              borderRadius: BorderRadius.circular(24),
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
                                Container(
                                  width: 86,
                                  height: 86,
                                  decoration: BoxDecoration(
                                    color: accentColor.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Text('🏆',
                                        style: TextStyle(fontSize: 44)),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  Vocabulary.completeTitle,
                                  style: GoogleFonts.alata(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  messageLine,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.alata(
                                    fontSize: 14,
                                    height: 1.5,
                                    color: colors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 22),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _StatBox(
                                        label: Vocabulary.statAccuracy,
                                        value: '$accuracy%',
                                        color: accentColor,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _StatBox(
                                        label: Vocabulary.statCorrect,
                                        value:
                                            '${state.correctCount}/${state.totalQuestions}',
                                        color: AppColors.primaryPurple,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 22),
                                PrimaryButton(
                                  text: Vocabulary.learnWithPixy,
                                  onPressed: onLearn,
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: OutlinedButton(
                                    onPressed: onContinue,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primaryPurple,
                                      side: const BorderSide(
                                        color: AppColors.primaryPurple,
                                        width: 2,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Text(
                                      Vocabulary.continueMissions,
                                      style: GoogleFonts.alata(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryPurple,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextButton(
                                  onPressed: onRetry,
                                  child: Text(
                                    Vocabulary.tryAgain,
                                    style: GoogleFonts.alata(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: colors.textSecondary,
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
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.alata(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.alata(
              fontSize: 12,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ERROR PHASE
// ═══════════════════════════════════════════════════════════════════════════

class _ErrorScaffold extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  const _ErrorScaffold({
    required this.message,
    required this.onRetry,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Stack(
      children: [
        const _BackgroundDecor(),
        SafeArea(
          child: Column(
            children: [
              _TopBar(title: Vocabulary.title, onBack: onBack),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 60, color: AppColors.error),
                        const SizedBox(height: 16),
                        Text(
                          Common.error,
                          style: GoogleFonts.alata(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          message ?? UserErrors.somethingWentWrong,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.alata(
                            fontSize: 14,
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        PrimaryButton(
                          text: Vocabulary.tryAgain,
                          onPressed: onRetry,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SPARKLE PAINTER — Success animation on correct answer
// ═══════════════════════════════════════════════════════════════════════════

class _SparklePainter extends CustomPainter {
  final double progress;
  final Random _random = Random(42);

  _SparklePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 12; i++) {
      final x = _random.nextDouble() * size.width;
      final y = _random.nextDouble() * size.height * 0.6;
      final sparkleSize = 4.0 + _random.nextDouble() * 8;
      final delay = _random.nextDouble() * 0.5;

      final adjustedProgress = ((progress - delay) * 2).clamp(0.0, 1.0);
      if (adjustedProgress <= 0) continue;

      final scale = adjustedProgress < 0.5
          ? adjustedProgress * 2
          : 2 - adjustedProgress * 2;

      final s = sparkleSize * scale;
      if (s <= 0) continue;

      paint.color = Color.lerp(
        const Color(0xFFFFD54F),
        const Color(0xFF8E97FD),
        _random.nextDouble(),
      )!
          .withAlpha((200 * scale).toInt());

      canvas.drawLine(Offset(x - s, y), Offset(x + s, y), paint);
      canvas.drawLine(Offset(x, y - s), Offset(x, y + s), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
