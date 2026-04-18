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

import '../../data/pattern_models.dart';
import '../controllers/pattern_controller.dart';
import 'pattern_learning_view.dart';

/// Complete-the-Pattern mission — emoji-based, bilingual, phased.
///
/// Design mirrors the Word Match (vocabulary) mission so the whole app feels
/// consistent: gradient header, Pixy mascot, card-style prompt, clean feedback,
/// stat-filled completion screen with a "Learn with Pixy" lesson.
class PatternMissionPage extends ConsumerStatefulWidget {
  const PatternMissionPage({super.key});

  @override
  ConsumerState<PatternMissionPage> createState() => _PatternMissionPageState();
}

class _PatternMissionPageState extends ConsumerState<PatternMissionPage>
    with TickerProviderStateMixin {
  late AnimationController _promptBounceController;
  late AnimationController _feedbackController;
  late AnimationController _sparkleController;

  late Animation<double> _promptScale;
  late Animation<double> _feedbackSlide;
  late Animation<double> _sparkleOpacity;

  @override
  void initState() {
    super.initState();

    _promptBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _promptScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _promptBounceController, curve: Curves.elasticOut),
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
    _promptBounceController.dispose();
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
    final state = ref.watch(patternControllerProvider);

    ref.listen<PatternMissionState>(patternControllerProvider, (prev, next) {
      if (next.phase == PatternPhase.question &&
          prev?.phase != PatternPhase.question) {
        _promptBounceController.forward(from: 0.0);
      }
      if (next.phase == PatternPhase.feedback &&
          prev?.phase != PatternPhase.feedback) {
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

  Widget _buildPhase(PatternMissionState state, AppColorsExtension colors) {
    switch (state.phase) {
      case PatternPhase.intro:
        return _IntroScaffold(
          onStart: () {
            ref.read(patternControllerProvider.notifier).startFromIntro();
          },
          onBack: () => Navigator.of(context).pop(true),
        );
      case PatternPhase.loading:
        return _LoadingScaffold(message: PatternMission.loadingPattern);
      case PatternPhase.submitting:
        return _QuestionScaffold(
          state: state,
          languageCode: _activeLang(),
          isSubmitting: true,
          promptScaleAnim: _promptScale,
          promptBounceController: _promptBounceController,
          onBack: () => Navigator.of(context).pop(true),
          onSelect: (_) {},
          onSubmit: () {},
        );
      case PatternPhase.question:
        return _QuestionScaffold(
          state: state,
          languageCode: _activeLang(),
          isSubmitting: false,
          promptScaleAnim: _promptScale,
          promptBounceController: _promptBounceController,
          onBack: () => Navigator.of(context).pop(true),
          onSelect: (id) {
            ref.read(patternControllerProvider.notifier).selectOption(id);
          },
          onSubmit: () {
            ref.read(patternControllerProvider.notifier).submitAnswer();
          },
        );
      case PatternPhase.feedback:
        return _FeedbackScaffold(
          state: state,
          languageCode: _activeLang(),
          feedbackSlide: _feedbackSlide,
          feedbackController: _feedbackController,
          sparkleOpacity: _sparkleOpacity,
          sparkleController: _sparkleController,
          onNext: () {
            ref.read(patternControllerProvider.notifier).nextQuestion();
          },
        );
      case PatternPhase.missionComplete:
        return _CompleteScaffold(
          state: state,
          onContinue: () => Navigator.of(context).pop(true),
          onLearn: _openLearningView,
          onRetry: () {
            ref.read(patternControllerProvider.notifier).restart();
          },
        );
      case PatternPhase.error:
        return _ErrorScaffold(
          message: state.errorMessage,
          onRetry: () {
            ref.read(patternControllerProvider.notifier).startFromIntro();
          },
          onBack: () => Navigator.of(context).pop(true),
        );
    }
  }

  Future<void> _openLearningView() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (ctx) => PatternLearningView(
          onDone: () => Navigator.of(ctx).pop(),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SHARED LAYOUT HELPERS
// ═══════════════════════════════════════════════════════════════════════════

/// Purple gradient + decorative circles used by every phase for visual unity.
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
                        const Color(0xFF5B3A8A),
                        const Color(0xFF3B2A5E),
                        colors.background,
                      ]
                    : vibrant
                        ? [
                            const Color(0xFFB39DFF),
                            const Color(0xFFE8DCFF),
                            colors.background,
                          ]
                        : [
                            const Color(0xFFE5DCFF),
                            const Color(0xFFF4EFFF),
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
                color: AppColors.patternPurple.withValues(
                  alpha: isDark ? 0.14 : 0.18,
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
    final fg = onGradient ? Colors.white : AppColors.patternPurple;
    final bg = onGradient
        ? Colors.white.withValues(alpha: 0.18)
        : AppColors.patternPurple.withValues(alpha: 0.12);
    final border = onGradient
        ? Colors.white.withValues(alpha: 0.28)
        : AppColors.patternPurple.withValues(alpha: 0.25);

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
            dotColor = onGradient ? Colors.white : AppColors.patternPurple;
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
                title: PatternMission.title,
                subtitle: PatternMission.subtitle,
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
                                  '🧩',
                                  style: GoogleFonts.alata(fontSize: 44),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  PatternMission.introTitle,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.alata(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  PatternMission.introBody,
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
                                      text: PatternMission.introFeature1,
                                    ),
                                    _FeaturePill(
                                      icon: Icons.trending_up_rounded,
                                      text: PatternMission.introFeature2,
                                    ),
                                    _FeaturePill(
                                      icon: Icons.auto_awesome_rounded,
                                      text: PatternMission.introFeature3,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 22),
                                PrimaryButton(
                                  text: PatternMission.startButton,
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
        color: AppColors.patternPurple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.patternPurple.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.patternPurple),
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
              const CircularProgressIndicator(color: AppColors.patternPurple),
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
  final PatternMissionState state;
  final String languageCode;
  final bool isSubmitting;
  final Animation<double> promptScaleAnim;
  final AnimationController promptBounceController;
  final VoidCallback onBack;
  final ValueChanged<int> onSelect;
  final VoidCallback onSubmit;

  const _QuestionScaffold({
    required this.state,
    required this.languageCode,
    required this.isSubmitting,
    required this.promptScaleAnim,
    required this.promptBounceController,
    required this.onBack,
    required this.onSelect,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final question = state.currentQuestion;
    if (question == null) {
      return _LoadingScaffold(message: PatternMission.loadingPattern);
    }

    return Stack(
      children: [
        const _BackgroundDecor(),
        SafeArea(
          child: Column(
            children: [
              _TopBar(
                title: PatternMission.title,
                subtitle: PatternMission.questionPrompt,
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
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: promptBounceController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: promptScaleAnim.value,
                              child: child,
                            );
                          },
                          child: _PatternPromptCard(sequence: question.sequence),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          PatternMission.chooseNext,
                          style: GoogleFonts.alata(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.patternPurple,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _OptionGrid(
                          options: question.options,
                          selectedId: state.selectedOptionId,
                          onSelect: isSubmitting ? null : onSelect,
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
                      ? PatternMission.submittingShort
                      : PatternMission.submitAnswer,
                  onPressed:
                      state.hasSelection && !isSubmitting ? onSubmit : null,
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

/// Purple gradient card showing the visible sequence + a pulsing "?" tile.
class _PatternPromptCard extends StatelessWidget {
  final List<PatternItem> sequence;

  const _PatternPromptCard({required this.sequence});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB794F6), Color(0xFF9C27B0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.patternPurple.withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            PatternMission.instruction,
            textAlign: TextAlign.center,
            style: GoogleFonts.alata(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.6,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...sequence.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _PatternTile(emoji: item.emoji),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: _MysteryTile(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PatternTile extends StatelessWidget {
  final String emoji;
  const _PatternTile({required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: const TextStyle(fontSize: 30, height: 1.0)),
    );
  }
}

class _MysteryTile extends StatefulWidget {
  const _MysteryTile();

  @override
  State<_MysteryTile> createState() => _MysteryTileState();
}

class _MysteryTileState extends State<_MysteryTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final t = _pulse.value;
        return Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.9),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.35 * t),
                blurRadius: 14,
                spreadRadius: 1.5 * t,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            '?',
            style: GoogleFonts.alata(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.patternPurple,
            ),
          ),
        );
      },
    );
  }
}

class _OptionGrid extends StatelessWidget {
  final List<PatternItem> options;
  final int? selectedId;
  final ValueChanged<int>? onSelect;

  const _OptionGrid({
    required this.options,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final option in options)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: _OptionTile(
              option: option,
              selected: selectedId == option.id,
              onTap: onSelect == null ? null : () => onSelect!(option.id),
            ),
          ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  final PatternItem option;
  final bool selected;
  final VoidCallback? onTap;

  const _OptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      label: option.labelEn,
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            color: colors.cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.patternPurple : colors.border,
              width: selected ? 3.0 : 1.5,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.patternPurple.withValues(alpha: 0.25),
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
                child: Text(
                  option.emoji,
                  style: const TextStyle(fontSize: 44, height: 1.0),
                ),
              ),
              if (selected)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: AppColors.patternPurple,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check,
                        color: Colors.white, size: 14),
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
  final PatternMissionState state;
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
      return _LoadingScaffold(message: PatternMission.loadingPattern);
    }

    final isCorrect = answer.correct;
    final accentColor =
        isCorrect ? AppColors.correctGreen : AppColors.missionPeach;

    final correctOption = question.options.firstWhere(
      (opt) => opt.id == answer.correctOptionId,
      orElse: () => question.options.first,
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
                            PatternMission.theRightAnswer,
                            style: GoogleFonts.alata(
                              fontSize: 13,
                              color: colors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _CorrectAnswerChip(
                            option: correctOption,
                            languageCode: languageCode,
                          ),
                          const SizedBox(height: 20),
                        ] else ...[
                          _CorrectAnswerChip(
                            option: correctOption,
                            languageCode: languageCode,
                          ),
                          const SizedBox(height: 20),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.patternPurple.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.patternPurple.withValues(
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
                                  ? PatternMission.seeResultsWithTrophy
                                  : PatternMission.nextPattern,
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
  final PatternItem option;
  final String languageCode;

  const _CorrectAnswerChip({
    required this.option,
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
          Text(option.emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(width: 14),
          Text(
            option.labelFor(languageCode),
            style: GoogleFonts.alata(
              fontSize: 20,
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
  final PatternMissionState state;
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
            ? AppColors.patternPurple
            : AppColors.missionPeach;

    final messageLine = accuracy >= 90
        ? PatternMission.completeLineHigh
        : accuracy >= 70
            ? PatternMission.completeLineMid
            : PatternMission.completeLineLow;

    return Stack(
      children: [
        const _BackgroundDecor(vibrant: true),
        SafeArea(
          child: Column(
            children: [
              _TopBar(
                title: PatternMission.title,
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
                                    color:
                                        accentColor.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Text('🏆',
                                        style: TextStyle(fontSize: 44)),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  PatternMission.missionCompleteTitle,
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
                                        label: PatternMission.statAccuracy,
                                        value: '$accuracy%',
                                        color: accentColor,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _StatBox(
                                        label: PatternMission.statCorrect,
                                        value:
                                            '${state.correctCount}/${state.totalQuestions}',
                                        color: AppColors.patternPurple,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 22),
                                PrimaryButton(
                                  text: PatternMission.learnWithPixy,
                                  onPressed: onLearn,
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: OutlinedButton(
                                    onPressed: onContinue,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor:
                                          AppColors.patternPurple,
                                      side: const BorderSide(
                                        color: AppColors.patternPurple,
                                        width: 2,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Text(
                                      PatternMission.continueMissions,
                                      style: GoogleFonts.alata(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.patternPurple,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextButton(
                                  onPressed: onRetry,
                                  child: Text(
                                    PatternMission.tryAgain,
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
              _TopBar(title: PatternMission.title, onBack: onBack),
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
                          text: PatternMission.tryAgain,
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
        AppColors.patternPurple,
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
