import 'dart:async';
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

import '../../data/describe_models.dart';
import '../controllers/describe_controller.dart';
import 'describe_learning_view.dart';

/// Describe-It mission — voice-driven, bilingual, emoji-based.
///
/// Visual design mirrors the Word Match / Pattern missions so the whole app
/// feels consistent: orange gradient background, Pixy mascot, rounded scene
/// card, phased flow with clear feedback + stats + learning carousel.
class DescribeMissionPage extends ConsumerStatefulWidget {
  const DescribeMissionPage({super.key});

  @override
  ConsumerState<DescribeMissionPage> createState() =>
      _DescribeMissionPageState();
}

class _DescribeMissionPageState extends ConsumerState<DescribeMissionPage>
    with TickerProviderStateMixin {
  late AnimationController _sceneBounceController;
  late AnimationController _pulseController;
  late AnimationController _feedbackController;
  late AnimationController _sparkleController;

  late Animation<double> _sceneScale;
  late Animation<double> _pulseScale;
  late Animation<double> _feedbackSlide;
  late Animation<double> _sparkleOpacity;

  Timer? _recordingTimer;
  int _recordingSeconds = 0;

  @override
  void initState() {
    super.initState();

    _sceneBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _sceneScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
          parent: _sceneBounceController, curve: Curves.elasticOut),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
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
    _sceneBounceController.dispose();
    _pulseController.dispose();
    _feedbackController.dispose();
    _sparkleController.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  String _activeLang() => ref.read(languageProvider).languageCode;

  void _startRecordingTimer() {
    _recordingSeconds = 0;
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _recordingSeconds = t.tick);
    });
  }

  void _stopRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(textRefreshProvider);
    ref.watch(languageProvider);

    final colors = context.appColors;
    final state = ref.watch(describeControllerProvider);

    ref.listen<DescribeMissionState>(describeControllerProvider,
        (prev, next) {
      if (next.phase == DescribeMissionPhase.viewing &&
          prev?.phase != DescribeMissionPhase.viewing) {
        _sceneBounceController.forward(from: 0.0);
      }
      if (next.phase == DescribeMissionPhase.recording &&
          prev?.phase != DescribeMissionPhase.recording) {
        _startRecordingTimer();
      } else if (next.phase != DescribeMissionPhase.recording) {
        _stopRecordingTimer();
      }
      if (next.phase == DescribeMissionPhase.feedback &&
          prev?.phase != DescribeMissionPhase.feedback) {
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

  Widget _buildPhase(
      DescribeMissionState state, AppColorsExtension colors) {
    switch (state.phase) {
      case DescribeMissionPhase.intro:
        return _IntroScaffold(
          onStart: () {
            ref.read(describeControllerProvider.notifier).startFromIntro();
          },
          onBack: () => Navigator.of(context).pop(true),
        );
      case DescribeMissionPhase.loading:
        return _LoadingScaffold(message: DescribeMission.loadingScenes);
      case DescribeMissionPhase.viewing:
        return _SceneScaffold(
          state: state,
          languageCode: _activeLang(),
          isRecording: false,
          isProcessing: false,
          sceneScaleAnim: _sceneScale,
          sceneBounceController: _sceneBounceController,
          pulseScaleAnim: _pulseScale,
          pulseController: _pulseController,
          recordingSeconds: 0,
          onBack: () => Navigator.of(context).pop(true),
          onRecord: () {
            ref.read(describeControllerProvider.notifier).startRecording();
          },
          onStop: () {},
        );
      case DescribeMissionPhase.recording:
        return _SceneScaffold(
          state: state,
          languageCode: _activeLang(),
          isRecording: true,
          isProcessing: false,
          sceneScaleAnim: _sceneScale,
          sceneBounceController: _sceneBounceController,
          pulseScaleAnim: _pulseScale,
          pulseController: _pulseController,
          recordingSeconds: _recordingSeconds,
          onBack: () {
            ref.read(describeControllerProvider.notifier).cancelRecording();
          },
          onRecord: () {},
          onStop: () {
            ref.read(describeControllerProvider.notifier).stopRecording();
          },
        );
      case DescribeMissionPhase.processing:
        return _ProcessingScaffold();
      case DescribeMissionPhase.feedback:
        return _FeedbackScaffold(
          state: state,
          languageCode: _activeLang(),
          feedbackSlide: _feedbackSlide,
          feedbackController: _feedbackController,
          sparkleOpacity: _sparkleOpacity,
          sparkleController: _sparkleController,
          onNext: () {
            ref.read(describeControllerProvider.notifier).nextQuestion();
          },
          onRetry: () {
            ref.read(describeControllerProvider.notifier).retryRecording();
          },
        );
      case DescribeMissionPhase.missionComplete:
        return _CompleteScaffold(
          state: state,
          onContinue: () => Navigator.of(context).pop(true),
          onLearn: _openLearningView,
          onRetry: () {
            ref.read(describeControllerProvider.notifier).restart();
          },
        );
      case DescribeMissionPhase.error:
        return _ErrorScaffold(
          message: state.errorMessage,
          onRetry: () {
            ref.read(describeControllerProvider.notifier).startFromIntro();
          },
          onBack: () => Navigator.of(context).pop(true),
        );
    }
  }

  Future<void> _openLearningView() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (ctx) => DescribeLearningView(
          onDone: () => Navigator.of(ctx).pop(),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SHARED LAYOUT HELPERS
// ═══════════════════════════════════════════════════════════════════════════

/// Soft gradient + decorative circles shared by every phase.
class _BackgroundDecor extends StatelessWidget {
  const _BackgroundDecor({this.vibrant = false});

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
                        const Color(0xFF7A3A1E),
                        const Color(0xFF4C2513),
                        colors.background,
                      ]
                    : vibrant
                        ? [
                            const Color(0xFFFFB48A),
                            const Color(0xFFFFE1CF),
                            colors.background,
                          ]
                        : [
                            const Color(0xFFFFE1CF),
                            const Color(0xFFFFF1E6),
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
                color: AppColors.describeOrange.withValues(
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

  const _ScorePill({required this.correct, required this.answered});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.describeOrange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.describeOrange.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        '$correct/$answered',
        style: GoogleFonts.alata(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.describeOrange,
        ),
      ),
    );
  }
}

class _ProgressDots extends StatelessWidget {
  final int total;
  final int answered;
  final int current;

  const _ProgressDots({
    required this.total,
    required this.answered,
    required this.current,
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
            dotColor = AppColors.describeOrange;
            size = 12;
          } else {
            dotColor = colors.border;
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
                title: DescribeMission.title,
                subtitle: DescribeMission.subtitle,
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
                                  '🎤',
                                  style: GoogleFonts.alata(fontSize: 44),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  DescribeMission.introTitle,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.alata(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  DescribeMission.introBody,
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
                                      icon: Icons.image_rounded,
                                      text: DescribeMission.introFeature1,
                                    ),
                                    _FeaturePill(
                                      icon: Icons.translate_rounded,
                                      text: DescribeMission.introFeature2,
                                    ),
                                    _FeaturePill(
                                      icon: Icons.hearing_rounded,
                                      text: DescribeMission.introFeature3,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 22),
                                PrimaryButton(
                                  text: DescribeMission.startButton,
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
        color: AppColors.describeOrange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.describeOrange.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.describeOrange),
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
// LOADING / PROCESSING PHASES
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
              const CircularProgressIndicator(
                color: AppColors.describeOrange,
              ),
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

class _ProcessingScaffold extends StatelessWidget {
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
              const Text('🎧', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              const CircularProgressIndicator(
                color: AppColors.describeOrange,
              ),
              const SizedBox(height: 18),
              Text(
                DescribeMission.processing,
                style: GoogleFonts.alata(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DescribeMission.processingHint,
                style: GoogleFonts.alata(
                  fontSize: 13,
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
// SCENE PHASE — shared by viewing & recording
// ═══════════════════════════════════════════════════════════════════════════

class _SceneScaffold extends StatelessWidget {
  final DescribeMissionState state;
  final String languageCode;
  final bool isRecording;
  final bool isProcessing;
  final Animation<double> sceneScaleAnim;
  final AnimationController sceneBounceController;
  final Animation<double> pulseScaleAnim;
  final AnimationController pulseController;
  final int recordingSeconds;
  final VoidCallback onBack;
  final VoidCallback onRecord;
  final VoidCallback onStop;

  const _SceneScaffold({
    required this.state,
    required this.languageCode,
    required this.isRecording,
    required this.isProcessing,
    required this.sceneScaleAnim,
    required this.sceneBounceController,
    required this.pulseScaleAnim,
    required this.pulseController,
    required this.recordingSeconds,
    required this.onBack,
    required this.onRecord,
    required this.onStop,
  });

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final question = state.currentQuestion;
    if (question == null) {
      return _LoadingScaffold(message: DescribeMission.loadingScenes);
    }

    return Stack(
      children: [
        const _BackgroundDecor(),
        SafeArea(
          child: Column(
            children: [
              _TopBar(
                title: DescribeMission.title,
                subtitle: DescribeMission.questionPrompt,
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
                          animation: sceneBounceController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: sceneScaleAnim.value,
                              child: child,
                            );
                          },
                          child: _SceneCard(
                            item: question,
                            languageCode: languageCode,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _HintCard(
                          hint: question.hintFor(languageCode),
                        ),
                        const SizedBox(height: 22),
                        if (isRecording)
                          _RecordingControls(
                            pulseScaleAnim: pulseScaleAnim,
                            pulseController: pulseController,
                            seconds: recordingSeconds,
                            onStop: onStop,
                            formatted: _formatDuration(recordingSeconds),
                          )
                        else
                          _TapToRecordButton(onTap: onRecord),
                        const SizedBox(height: 24),
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

/// The large orange scene card with the main emoji and theme label.
class _SceneCard extends StatelessWidget {
  final DescribeItem item;
  final String languageCode;

  const _SceneCard({required this.item, required this.languageCode});

  @override
  Widget build(BuildContext context) {
    final theme = item.themeFor(languageCode);
    final accent = item.accentColor;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent,
            Color.lerp(accent, Colors.black, 0.2) ?? accent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              theme.toUpperCase(),
              style: GoogleFonts.alata(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Stack(
            alignment: Alignment.center,
            children: [
              if (item.secondaryEmoji.isNotEmpty)
                Positioned(
                  top: 6,
                  right: -8,
                  child: Opacity(
                    opacity: 0.75,
                    child: Text(
                      item.secondaryEmoji,
                      style: const TextStyle(fontSize: 58, height: 1.0),
                    ),
                  ),
                ),
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 3,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  item.emoji,
                  style: const TextStyle(fontSize: 92, height: 1.0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  final String hint;

  const _HintCard({required this.hint});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.15)
              : const Color(0xFFFFCC80),
        ),
      ),
      child: Row(
        children: [
          const Text('💡', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hint,
              style: GoogleFonts.alata(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? Colors.white
                    : const Color(0xFF6D4C1B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TapToRecordButton extends StatelessWidget {
  final VoidCallback onTap;
  const _TapToRecordButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.describeOrange,
              boxShadow: [
                BoxShadow(
                  color: AppColors.describeOrange.withValues(alpha: 0.45),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.mic, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 10),
          Text(
            DescribeMission.tapToRecord,
            style: GoogleFonts.alata(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordingControls extends StatelessWidget {
  final Animation<double> pulseScaleAnim;
  final AnimationController pulseController;
  final int seconds;
  final String formatted;
  final VoidCallback onStop;

  const _RecordingControls({
    required this.pulseScaleAnim,
    required this.pulseController,
    required this.seconds,
    required this.formatted,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      children: [
        SizedBox(
          width: 180,
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: pulseController,
                builder: (context, _) {
                  return Transform.scale(
                    scale: pulseScaleAnim.value,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.describeOrange.withValues(
                          alpha:
                              0.18 * (1.3 - pulseScaleAnim.value).clamp(0.0, 1.0),
                        ),
                      ),
                    ),
                  );
                },
              ),
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.describeOrange.withValues(alpha: 0.25),
                ),
              ),
              GestureDetector(
                onTap: onStop,
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.describeOrange,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.describeOrange.withValues(
                          alpha: 0.55,
                        ),
                        blurRadius: 22,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.stop,
                      color: Colors.white, size: 38),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          formatted,
          style: GoogleFonts.alata(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.describeOrange,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          DescribeMission.listening,
          style: GoogleFonts.alata(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          DescribeMission.tapStopWhenDone,
          style: GoogleFonts.alata(
            fontSize: 12,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FEEDBACK PHASE
// ═══════════════════════════════════════════════════════════════════════════

class _FeedbackScaffold extends StatelessWidget {
  final DescribeMissionState state;
  final String languageCode;
  final Animation<double> feedbackSlide;
  final AnimationController feedbackController;
  final Animation<double> sparkleOpacity;
  final AnimationController sparkleController;
  final VoidCallback onNext;
  final VoidCallback onRetry;

  const _FeedbackScaffold({
    required this.state,
    required this.languageCode,
    required this.feedbackSlide,
    required this.feedbackController,
    required this.sparkleOpacity,
    required this.sparkleController,
    required this.onNext,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final answer = state.lastAnswer;
    final feedback = state.lastFeedback;
    final question = state.currentQuestion;
    if (answer == null || feedback == null || question == null) {
      return _LoadingScaffold(message: DescribeMission.loadingScenes);
    }

    final result = answer.result;
    final isCorrect = answer.correct;
    final accentColor =
        isCorrect ? AppColors.correctGreen : AppColors.describeOrange;
    final scorePct = (result.matchScore * 100).round();

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
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$scorePct%',
                            style: GoogleFonts.alata(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: accentColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          feedback.message,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.alata(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _TranscriptionCard(
                          transcription: result.transcription,
                        ),
                        if (result.matchedKeywords.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _KeywordRow(
                            label: DescribeMission.matchedLabel,
                            keywords: result.matchedKeywords,
                            color: AppColors.correctGreen,
                          ),
                        ],
                        if (result.missingKeywords.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _KeywordRow(
                            label: DescribeMission.missingLabel,
                            keywords: result.missingKeywords,
                            color: AppColors.describeOrange,
                          ),
                        ],
                        const SizedBox(height: 18),
                        _EncouragementBubble(
                          text: feedback.encouragement,
                        ),
                        const SizedBox(height: 24),
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
                                  ? DescribeMission.seeResultsWithTrophy
                                  : DescribeMission.nextScene,
                              style: GoogleFonts.alata(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: OutlinedButton.icon(
                            onPressed: onRetry,
                            icon: const Icon(Icons.mic, size: 18),
                            label: Text(
                              DescribeMission.recordAgain,
                              style: GoogleFonts.alata(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.describeOrange,
                              side: const BorderSide(
                                color: AppColors.describeOrange,
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
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

class _TranscriptionCard extends StatelessWidget {
  final String transcription;

  const _TranscriptionCard({required this.transcription});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shownText =
        transcription.trim().isEmpty ? '…' : transcription.trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DescribeMission.youSaid,
            style: GoogleFonts.alata(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colors.textSecondary,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '"$shownText"',
            style: GoogleFonts.alata(
              fontSize: 15,
              fontStyle: FontStyle.italic,
              height: 1.4,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _KeywordRow extends StatelessWidget {
  final String label;
  final List<String> keywords;
  final Color color;

  const _KeywordRow({
    required this.label,
    required this.keywords,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.alata(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: keywords
              .map(
                (kw) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: color.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    kw,
                    style: GoogleFonts.alata(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _EncouragementBubble extends StatelessWidget {
  final String text;
  const _EncouragementBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.describeOrange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.describeOrange.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🤖', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.alata(
                fontSize: 13,
                color: colors.textSecondary,
              ),
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
  final DescribeMissionState state;
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
        ? (state.correctCount / state.totalQuestions * 100).round()
        : 0;
    final avgPct = (state.averageScore * 100).round();
    final accentColor = accuracy >= 80
        ? AppColors.correctGreen
        : accuracy >= 50
            ? AppColors.describeOrange
            : AppColors.missionPeach;

    final messageLine = accuracy >= 90
        ? DescribeMission.completeLineHigh
        : accuracy >= 60
            ? DescribeMission.completeLineMid
            : DescribeMission.completeLineLow;

    return Stack(
      children: [
        const _BackgroundDecor(vibrant: true),
        SafeArea(
          child: Column(
            children: [
              _TopBar(
                title: DescribeMission.title,
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
                                  alignment: Alignment.center,
                                  child: const Text(
                                    '🏆',
                                    style: TextStyle(fontSize: 44),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  DescribeMission.missionCompleteTitle,
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
                                        label:
                                            DescribeMission.statAccuracy,
                                        value: '$accuracy%',
                                        color: accentColor,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _StatBox(
                                        label:
                                            DescribeMission.statCorrect,
                                        value:
                                            '${state.correctCount}/${state.totalQuestions}',
                                        color: AppColors.describeOrange,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _StatBox(
                                        label: DescribeMission
                                            .statAverageScore,
                                        value: '$avgPct%',
                                        color: AppColors.patternPurple,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 22),
                                PrimaryButton(
                                  text: DescribeMission.learnWithPixy,
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
                                          AppColors.describeOrange,
                                      side: const BorderSide(
                                        color: AppColors.describeOrange,
                                        width: 2,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Text(
                                      DescribeMission.continueMissions,
                                      style: GoogleFonts.alata(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.describeOrange,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextButton(
                                  onPressed: onRetry,
                                  child: Text(
                                    DescribeMission.tryAgain,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.alata(
              fontSize: 11,
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
              _TopBar(title: DescribeMission.title, onBack: onBack),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 60,
                          color: AppColors.incorrectRed,
                        ),
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
                          text: DescribeMission.tryAgain,
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
// SPARKLE PAINTER — success animation on correct answer
// ═══════════════════════════════════════════════════════════════════════════

class _SparklePainter extends CustomPainter {
  final double progress;
  final Random _random = Random(31);

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
        AppColors.describeOrange,
        _random.nextDouble(),
      )!
          .withValues(alpha: (scale).clamp(0.0, 1.0) * 0.8);

      canvas.drawLine(Offset(x - s, y), Offset(x + s, y), paint);
      canvas.drawLine(Offset(x, y - s), Offset(x, y + s), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
