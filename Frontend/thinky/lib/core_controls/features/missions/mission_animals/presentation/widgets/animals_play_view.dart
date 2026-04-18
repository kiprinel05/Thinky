import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:thinky/core_controls/constants/app_texts.dart';
import 'package:thinky/core_controls/features/missions/mission_animals/data/animals_repository.dart';
import 'package:thinky/core_controls/features/missions/mission_animals/presentation/controllers/animals_controller.dart';
import 'package:thinky/shared_controls/theme/app_colors.dart';
import 'package:thinky/shared_controls/theme/app_colors_extension.dart';
import 'package:thinky/shared_controls/widgets/animations/animated_widgets.dart';
import 'package:thinky/shared_controls/widgets/states/app_content_skeletons.dart';

import 'animals_feedback_overlay.dart';
import 'animals_mascots.dart';
import 'animals_mission_image.dart';
import 'animals_teaching_grid.dart';

/// Main playing screen.
///
/// One screen handles the full round:
///  • `pendingGuess`   → image + "Ask Pixy" CTA
///  • `guessShown`     → image + Pixy's guess + Yes / No
///  • `verifyFeedback` → blur overlay with Continue
///  • `teaching`       → same layout, card swaps to selection grid
///  • `teachingFeedback` → blur overlay with Continue / Retry
class AnimalsPlayView extends ConsumerStatefulWidget {
  const AnimalsPlayView({super.key});

  @override
  ConsumerState<AnimalsPlayView> createState() => _AnimalsPlayViewState();
}

class _AnimalsPlayViewState extends ConsumerState<AnimalsPlayView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pixyAnimController;
  late final Animation<double> _pixyScaleAnim;

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
  Widget build(BuildContext context) {
    final state = ref.watch(animalsControllerProvider);
    final controller = ref.read(animalsControllerProvider.notifier);
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isTeachingBody = state.playStep == AnimalsPlayStep.teaching ||
        state.playStep == AnimalsPlayStep.teachingFeedback ||
        state.isLoadingTeaching;

    final showVerifyOverlay =
        state.playStep == AnimalsPlayStep.verifyFeedback &&
            state.verifyResponse != null;
    final showTeachingOverlay =
        state.playStep == AnimalsPlayStep.teachingFeedback &&
            state.teachingResult != null;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          children: [
            _ProgressBar(
              round: state.currentRound,
              total: state.totalRounds,
              isDark: isDark,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: isTeachingBody
                      ? _TeachingBody(
                          key: const ValueKey('teaching'),
                          state: state,
                          colors: colors,
                          onToggle: controller.toggleImageSelection,
                          onSubmit: controller.submitTeaching,
                        )
                      : _VerifyBody(
                          key: ValueKey(
                            'verify-${state.currentImage?.id}-${state.playStep.name}',
                          ),
                          state: state,
                          colors: colors,
                          isDark: isDark,
                          pixyScale: _pixyScaleAnim,
                          onAskPixy: controller.makePixyGuess,
                          onYes: () => controller.verifyGuess(true),
                          onNo: () => controller.verifyGuess(false),
                        ),
                ),
              ),
            ),
          ],
        ),
        if (state.isLoading &&
            !showVerifyOverlay &&
            !showTeachingOverlay &&
            state.playStep != AnimalsPlayStep.pendingGuess)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                child: AppContentSkeletons.quizSubmittingOverlay(context),
              ),
            ),
          ),
        if (showVerifyOverlay)
          _VerifyFeedbackOverlayHost(state: state, controller: controller),
        if (showTeachingOverlay)
          _TeachingFeedbackOverlayHost(state: state, controller: controller),
      ],
    );
  }
}

// ───────────────────────────────────────────────────────────── progress bar ──

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.round,
    required this.total,
    required this.isDark,
  });

  final int round;
  final int total;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final safeTotal = total == 0 ? 1 : total;
    final progress = (round / safeTotal).clamp(0.0, 1.0);

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
                          '${Animals.roundShort} $round / $total',
                          style: GoogleFonts.alata(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          Animals.missionTitle,
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
}

// ───────────────────────────────────────────────────────────── verify body ──

class _VerifyBody extends StatelessWidget {
  const _VerifyBody({
    super.key,
    required this.state,
    required this.colors,
    required this.isDark,
    required this.pixyScale,
    required this.onAskPixy,
    required this.onYes,
    required this.onNo,
  });

  final AnimalsMissionState state;
  final AppColorsExtension colors;
  final bool isDark;
  final Animation<double> pixyScale;
  final VoidCallback onAskPixy;
  final VoidCallback onYes;
  final VoidCallback onNo;

  @override
  Widget build(BuildContext context) {
    final image = state.currentImage;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          ScaleTransition(
            scale: pixyScale,
            alignment: Alignment.bottomCenter,
            child: const AnimalsMascotHead(
              kind: AnimalsMascotKind.pixy,
              width: 140,
              viewportHeight: 140,
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -28),
            child: FadeInWidget(
              key: ValueKey('round-${state.currentRound}'),
              delay: const Duration(milliseconds: 160),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: colors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withValues(alpha: isDark ? 0.35 : 0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _RoundChip(
                      index: state.currentRound,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 14),
                    if (image != null)
                      AnimalsMissionImage(
                        imageUrl:
                            AnimalsRepository.getImageUrl(image.url),
                        colors: colors,
                        maxHeight: 240,
                        borderRadius: 20,
                      ),
                    const SizedBox(height: 16),
                    _VerifyCardBody(
                      state: state,
                      colors: colors,
                      isDark: isDark,
                      onAskPixy: onAskPixy,
                      onYes: onYes,
                      onNo: onNo,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundChip extends StatelessWidget {
  const _RoundChip({required this.index, required this.isDark});

  final int index;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.primaryPurple.withValues(
            alpha: isDark ? 0.2 : 0.08,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          '${Animals.roundShort} $index',
          style: GoogleFonts.alata(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.primaryPurple,
          ),
        ),
      ),
    );
  }
}

class _VerifyCardBody extends StatelessWidget {
  const _VerifyCardBody({
    required this.state,
    required this.colors,
    required this.isDark,
    required this.onAskPixy,
    required this.onYes,
    required this.onNo,
  });

  final AnimalsMissionState state;
  final AppColorsExtension colors;
  final bool isDark;
  final VoidCallback onAskPixy;
  final VoidCallback onYes;
  final VoidCallback onNo;

  @override
  Widget build(BuildContext context) {
    if (state.playStep == AnimalsPlayStep.pendingGuess) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            Animals.lookAtImage,
            style: GoogleFonts.alata(
              fontSize: 15,
              color: colors.textPrimary,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _PrimaryPurpleButton(
            label: Animals.askPixy,
            busy: state.isLoading,
            onPressed: state.isLoading ? null : onAskPixy,
          ),
        ],
      );
    }

    if (state.playStep == AnimalsPlayStep.guessShown &&
        state.lastGuess != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            Animals.guessLeadIn,
            textAlign: TextAlign.center,
            style: GoogleFonts.alata(
              fontSize: 13.5,
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          ScaleInWidget(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.primaryPurple,
                    AppColors.primaryPurpleLight,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryPurple.withValues(alpha: 0.32),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Text(
                state.lastGuess!.guess.toUpperCase(),
                textAlign: TextAlign.center,
                style: GoogleFonts.alata(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            Animals.verifyQuestion,
            textAlign: TextAlign.center,
            style: GoogleFonts.alata(
              fontSize: 14,
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _VerifyChoice(
                  label: Animals.verifyYes,
                  icon: Icons.check_rounded,
                  accent: const Color(0xFF43A047),
                  enabled: !state.isLoading,
                  onTap: onYes,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _VerifyChoice(
                  label: Animals.verifyNo,
                  icon: Icons.close_rounded,
                  accent: const Color(0xFFFF6E40),
                  enabled: !state.isLoading,
                  onTap: onNo,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}

class _VerifyChoice extends StatelessWidget {
  const _VerifyChoice({
    required this.label,
    required this.icon,
    required this.accent,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accent.withValues(alpha: 0.55), width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 19),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.alata(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────── teaching body ──

class _TeachingBody extends ConsumerWidget {
  const _TeachingBody({
    super.key,
    required this.state,
    required this.colors,
    required this.onToggle,
    required this.onSubmit,
  });

  final AnimalsMissionState state;
  final AppColorsExtension colors;
  final void Function(String) onToggle;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final teachingData = state.teachingImages;
    final showTileFeedback =
        state.playStep == AnimalsPlayStep.teachingFeedback &&
            state.teachingResult != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          FadeInWidget(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withValues(alpha: isDark ? 0.35 : 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.primaryPurple,
                              AppColors.primaryPurpleLight,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryPurple
                                  .withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              Animals.teachPixy,
                              style: GoogleFonts.alata(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              teachingData != null
                                  ? Animals.selectAllTargetFor(
                                      teachingData.targetAnimal,
                                    )
                                  : Animals.pixyThinkingShort,
                              style: GoogleFonts.alata(
                                fontSize: 13,
                                color: colors.textSecondary,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (teachingData == null)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 26),
                      child: Center(
                        child: SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: AppColors.primaryPurple,
                          ),
                        ),
                      ),
                    )
                  else ...[
                    AnimalsTeachingGrid(
                      images: teachingData.images,
                      selectedIds: state.selectedImageIds,
                      correctIds: teachingData.correctImageIds.toSet(),
                      colors: colors,
                      enabled: state.playStep == AnimalsPlayStep.teaching &&
                          !state.isLoading,
                      showFeedback: showTileFeedback,
                      submittedSelection: state.selectedImageIds,
                      onToggle: onToggle,
                    ),
                    const SizedBox(height: 18),
                    if (state.playStep == AnimalsPlayStep.teaching)
                      _PrimaryPurpleButton(
                        label: state.selectedImageIds.isEmpty
                            ? Animals.submitTeaching
                            : Animals.submitTeachingCount(
                                state.selectedImageIds.length,
                              ),
                        busy: state.isLoading,
                        onPressed: state.selectedImageIds.isEmpty ||
                                state.isLoading
                            ? null
                            : onSubmit,
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────── CTA button ──

class _PrimaryPurpleButton extends StatelessWidget {
  const _PrimaryPurpleButton({
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final disabledFill = isDark
        ? AppColors.primaryPurple.withValues(alpha: 0.28)
        : AppColors.primaryPurple.withValues(alpha: 0.4);
    final isEnabled = onPressed != null && !busy;

    return ElevatedButton(
      onPressed: isEnabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isEnabled ? AppColors.primaryPurple : disabledFill,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: isEnabled ? 4 : 0,
      ),
      child: busy
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            )
          : Text(
              label,
              style: GoogleFonts.alata(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15,
                letterSpacing: 0.5,
              ),
            ),
    );
  }
}

// ───────────────────────────────────────────────────── feedback overlays ──

class _VerifyFeedbackOverlayHost extends StatelessWidget {
  const _VerifyFeedbackOverlayHost({
    required this.state,
    required this.controller,
  });

  final AnimalsMissionState state;
  final AnimalsController controller;

  @override
  Widget build(BuildContext context) {
    final response = state.verifyResponse!;
    final userWasRight = response.userWasRight;
    final pixyWasCorrect = response.wasActuallyCorrect;

    final accent = userWasRight
        ? const Color(0xFF43A047)
        : const Color(0xFFFF6E40);
    final title = userWasRight
        ? Animals.verifyYes
        : Animals.oopsTitle;
    final icon = userWasRight
        ? Icons.check_rounded
        : Icons.school_rounded;
    final primaryLabel = pixyWasCorrect
        ? Animals.nextRoundExcited
        : Animals.teachPixy;

    return AnimalsFeedbackOverlay(
      accentColor: accent,
      icon: icon,
      title: title,
      message: response.message,
      primaryLabel: primaryLabel,
      mascot: AnimalsMascotKind.professor,
      isBusy: state.isLoading || state.isLoadingTeaching,
      onPrimary: controller.proceedAfterVerify,
    );
  }
}

class _TeachingFeedbackOverlayHost extends StatelessWidget {
  const _TeachingFeedbackOverlayHost({
    required this.state,
    required this.controller,
  });

  final AnimalsMissionState state;
  final AnimalsController controller;

  @override
  Widget build(BuildContext context) {
    final result = state.teachingResult!;
    final accent = result.isCorrect
        ? const Color(0xFF43A047)
        : const Color(0xFFFF6E40);
    final title = result.isCorrect
        ? Animals.missionCompleteTitle.isEmpty
            ? Animals.verifyYes
            : Animals.continueShort
        : Animals.oopsTitle;
    final icon = result.isCorrect
        ? Icons.celebration_rounded
        : Icons.refresh_rounded;

    return AnimalsFeedbackOverlay(
      accentColor: accent,
      icon: icon,
      title: title,
      message: result.message,
      primaryLabel: result.isCorrect
          ? Animals.nextRoundExcited
          : Animals.retry,
      secondaryLabel: null,
      onSecondary: null,
      mascot: AnimalsMascotKind.pixy,
      isBusy: state.isLoading,
      onPrimary: result.isCorrect
          ? controller.continueAfterTeaching
          : controller.retryTeaching,
    );
  }
}
