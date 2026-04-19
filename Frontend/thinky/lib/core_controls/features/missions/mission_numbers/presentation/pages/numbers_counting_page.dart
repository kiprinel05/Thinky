import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thinky/core_controls/constants/app_texts.dart';
import 'package:thinky/core_controls/services/language_service.dart';
import 'package:thinky/shared_controls/theme/app_colors.dart';
import 'package:thinky/shared_controls/theme/app_colors_extension.dart';
import 'package:thinky/shared_controls/widgets/animations/animated_widgets.dart';
import '../../domain/numbers_models.dart';
import '../controllers/numbers_controller.dart';
import '../controllers/numbers_state.dart';
import '../widgets/numbers_professor_overlay.dart';

/// Part 1 of the Numbers mission: count the objects on screen and pick the
/// correct number. Pixy makes its own guess and the child can either pick the
/// same number (= "I agree with Pixy") or pick a different one — there is a
/// single primary CTA at the bottom in both cases.
class NumbersCountingPage extends ConsumerStatefulWidget {
  const NumbersCountingPage({super.key});

  @override
  ConsumerState<NumbersCountingPage> createState() =>
      _NumbersCountingPageState();
}

class _NumbersCountingPageState extends ConsumerState<NumbersCountingPage>
    with TickerProviderStateMixin {
  late AnimationController _pixyBounceController;
  late AnimationController _professorSlideController;
  late AnimationController _upgradeAnimController;
  late Animation<double> _pixyBounceAnim;
  late Animation<Offset> _professorSlideAnim;
  late Animation<double> _upgradeScaleAnim;

  @override
  void initState() {
    super.initState();
    _pixyBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pixyBounceAnim = Tween<double>(begin: 0, end: -12).animate(
      CurvedAnimation(parent: _pixyBounceController, curve: Curves.easeInOut),
    );

    _professorSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _professorSlideAnim = Tween<Offset>(
      begin: const Offset(0, 1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _professorSlideController,
      curve: Curves.elasticOut,
    ));

    _upgradeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _upgradeScaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _upgradeAnimController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _pixyBounceController.dispose();
    _professorSlideController.dispose();
    _upgradeAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(textRefreshProvider);
    final colors = context.appColors;
    final state = ref.watch(numbersStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent =
        isDark ? AppColors.numbersOrangeLight : AppColors.numbersOrangeDark;

    if (state.phase == NumbersPhase.professorIntervention) {
      _professorSlideController.forward();
    } else {
      _professorSlideController.reverse();
    }

    if (state.phase == NumbersPhase.modelUpgrade) {
      _upgradeAnimController.forward(from: 0.0);
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(state, colors, accent),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        _buildObjectsArea(state, colors, isDark),
                        const SizedBox(height: 16),
                        _buildPixySection(state, colors, accent, isDark),
                        const SizedBox(height: 16),
                        if (state.phase == NumbersPhase.counting)
                          _buildAnswerArea(state, colors, accent, isDark),
                        if (state.phase == NumbersPhase.pixyGuessing)
                          _buildResultSection(state, colors, isDark),
                        if (state.phase == NumbersPhase.transitionToPart2)
                          _buildTransitionCard(colors, accent, isDark),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (state.phase == NumbersPhase.professorIntervention)
              NumbersProfessorOverlay(
                slideAnimation: _professorSlideAnim,
                message: state.countingResult?.professorMessage ?? '',
                onUnderstood: () =>
                    ref.read(numbersStateProvider.notifier).dismissProfessor(),
              ),
            if (state.phase == NumbersPhase.modelUpgrade)
              _buildUpgradeOverlay(state, colors, accent, isDark),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HEADER
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildHeader(
    NumbersState state,
    AppColorsExtension colors,
    Color accent,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: colors.cardColor,
        border: Border(bottom: BorderSide(color: colors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.numbersOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      color: accent, size: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      NumbersMission.part1Title,
                      style: GoogleFonts.alata(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      NumbersMission.levelLine(
                        NumbersMission.modelLevelName(state.modelLevel),
                        state.modelLevel.emoji,
                      ),
                      style: GoogleFonts.alata(
                        fontSize: 12,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: state.upgradeProgress.clamp(0.0, 1.0),
              backgroundColor:
                  AppColors.numbersOrange.withValues(alpha: 0.12),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.numbersOrange),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                NumbersMission.progressUpgrade(state.correctCount),
                style: GoogleFonts.alata(
                    fontSize: 10, color: colors.textSecondary),
              ),
              Row(
                children: List.generate(3, (i) {
                  final level = PixyModelLevel.values[i];
                  final isActive = state.modelLevel == level;
                  final isPast = state.modelLevel.index > level.index;
                  return Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.numbersOrange
                          : isPast
                              ? AppColors.success.withValues(alpha: 0.15)
                              : colors.border,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(level.emoji,
                        style: const TextStyle(fontSize: 12)),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // OBJECTS DISPLAY
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildObjectsArea(
    NumbersState state,
    AppColorsExtension colors,
    bool isDark,
  ) {
    final round = state.round;
    if (round == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.numbersOrange
                .withValues(alpha: isDark ? 0.18 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            NumbersMission.howManyObjects,
            style: GoogleFonts.alata(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: List.generate(round.objects.length, (index) {
              return ScaleInWidget(
                delay: Duration(milliseconds: 100 * index),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.numbersOrange
                        .withValues(alpha: isDark ? 0.14 : 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.numbersOrange
                          .withValues(alpha: isDark ? 0.3 : 0.15),
                    ),
                  ),
                  child: Text(
                    round.objects[index].emoji,
                    style: const TextStyle(fontSize: 42),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PIXY SECTION
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildPixySection(
    NumbersState state,
    AppColorsExtension colors,
    Color accent,
    bool isDark,
  ) {
    final round = state.round;
    if (round == null) return const SizedBox.shrink();

    String pixyText;
    String pixyEmoji;

    if (state.phase == NumbersPhase.pixyGuessing &&
        state.countingResult != null) {
      pixyText = state.countingResult!.pixyMessage;
      pixyEmoji = _emotionToEmoji(state.countingResult!.pixyEmotion);
    } else {
      pixyText = round.pixyMessage;
      pixyEmoji = '🤖';
    }

    return AnimatedBuilder(
      animation: _pixyBounceAnim,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _pixyBounceAnim.value),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.numbersOrange
                      .withValues(alpha: isDark ? 0.20 : 0.12),
                  AppColors.numbersOrangeLight
                      .withValues(alpha: isDark ? 0.14 : 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.numbersOrange
                    .withValues(alpha: isDark ? 0.32 : 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.cardColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.border),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.numbersOrange
                            .withValues(alpha: 0.15),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Text(pixyEmoji, style: const TextStyle(fontSize: 32)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        NumbersMission.modelLevelName(state.modelLevel),
                        style: GoogleFonts.alata(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pixyText,
                        style: GoogleFonts.alata(
                          fontSize: 14,
                          color: colors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ANSWER AREA — single-CTA flow
  // ══════════════════════════════════════════════════════════════════════════

  /// Replaces the old dual-button (Confirm Pixy / Send) row.
  ///
  /// The user picks a number from the 1–5 grid; if they happen to pick the
  /// same number as Pixy's guess we surface a small "you agree with Pixy"
  /// chip. Either way there is exactly ONE primary CTA at the bottom.
  Widget _buildAnswerArea(
    NumbersState state,
    AppColorsExtension colors,
    Color accent,
    bool isDark,
  ) {
    final controller = ref.read(numbersStateProvider.notifier);
    final pixyGuess = state.round?.pixyGuess;
    final selected = state.selectedAnswer;
    final agreesWithPixy = selected != null && selected == pixyGuess;

    return Column(
      children: [
        Text(
          NumbersMission.chooseCorrectNumber,
          style: GoogleFonts.alata(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final number = i + 1;
            final isSelected = selected == number;
            final isPixyChoice = pixyGuess == number;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: GestureDetector(
                onTap: state.isSubmitting
                    ? null
                    : () => controller.selectAnswer(number),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.numbersOrange
                            : colors.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.numbersOrangeDark
                              : AppColors.numbersOrange
                                  .withValues(alpha: 0.3),
                          width: isSelected ? 2.5 : 1.5,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: AppColors.numbersOrange
                                  .withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$number',
                        style: GoogleFonts.alata(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : accent,
                        ),
                      ),
                    ),
                    if (isPixyChoice)
                      Positioned(
                        top: -8,
                        right: -8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: colors.cardColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.numbersOrange
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                          child: const Text(
                            '🤖',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        // Subtle status row: either "Pick a number" hint or "agree with Pixy" chip
        SizedBox(
          height: 28,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: agreesWithPixy
                ? _PixyAgreementChip(
                    key: const ValueKey('agree'),
                    label: NumbersMission.sameAsPixyChip,
                  )
                : selected == null
                    ? Center(
                        key: const ValueKey('hint'),
                        child: Text(
                          NumbersMission.pickANumberFirst,
                          style: GoogleFonts.alata(
                            fontSize: 12,
                            color: colors.textHint,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('empty')),
          ),
        ),
        const SizedBox(height: 12),
        // SINGLE primary CTA — replaces the awkward Confirm + Send pair
        SizedBox(
          width: double.infinity,
          child: _buildPrimaryButton(
            label: NumbersMission.submitMyAnswer,
            icon: Icons.send_rounded,
            enabled: selected != null && !state.isSubmitting,
            isLoading: state.isSubmitting,
            onTap: () => controller.submitCount(),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // RESULT SECTION
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildResultSection(
    NumbersState state,
    AppColorsExtension colors,
    bool isDark,
  ) {
    final result = state.countingResult;
    if (result == null) return const SizedBox.shrink();
    final controller = ref.read(numbersStateProvider.notifier);
    final positive = result.isCorrect ? AppColors.success : AppColors.incorrectRed;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: positive.withValues(alpha: isDark ? 0.16 : 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: positive.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Icon(
                result.isCorrect
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                color: positive,
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                result.isCorrect
                    ? NumbersMission.resultCorrect
                    : NumbersMission.resultWrongAnswer('${result.correctAnswer}'),
                style: GoogleFonts.alata(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: positive,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                result.pixyMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.alata(
                  fontSize: 13,
                  color: colors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: _buildPrimaryButton(
            label: NumbersMission.nextRound,
            icon: Icons.arrow_forward_rounded,
            enabled: true,
            onTap: () => controller.nextRound(),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TRANSITION TO PART 2
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildTransitionCard(
    AppColorsExtension colors,
    Color accent,
    bool isDark,
  ) {
    final controller = ref.read(numbersStateProvider.notifier);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.numbersOrange.withValues(alpha: isDark ? 0.22 : 0.15),
            AppColors.numbersOrangeLight.withValues(alpha: isDark ? 0.16 : 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.numbersOrange.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          const Text('🎨', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            NumbersMission.transitionTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.alata(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            NumbersMission.transitionSubtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.alata(
              fontSize: 13,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          _buildPrimaryButton(
            label: NumbersMission.goToDrawing,
            icon: Icons.brush_rounded,
            enabled: true,
            onTap: () => controller.switchToPart2(),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MODEL UPGRADE OVERLAY
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildUpgradeOverlay(
    NumbersState state,
    AppColorsExtension colors,
    Color accent,
    bool isDark,
  ) {
    final controller = ref.read(numbersStateProvider.notifier);
    final newLevel = state.modelLevel;

    return Container(
      color: Colors.black.withValues(alpha: 0.45),
      child: Center(
        child: ScaleTransition(
          scale: _upgradeScaleAnim,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 28),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: colors.cardColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: colors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.numbersOrange.withValues(alpha: 0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎉', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 16),
                Text(
                  NumbersMission.upgradeTitle,
                  style: GoogleFonts.alata(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.numbersOrange,
                        AppColors.numbersOrangeLight,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    NumbersMission.upgradeLevelLine(
                      newLevel.emoji,
                      NumbersMission.modelLevelName(newLevel),
                    ),
                    style: GoogleFonts.alata(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  NumbersMission.upgradeSubtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.alata(
                    fontSize: 13,
                    height: 1.6,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => controller.dismissUpgrade(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.numbersOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      NumbersMission.continueCaps,
                      style: GoogleFonts.alata(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.numbersOrange
              : AppColors.numbersOrange.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            if (enabled)
              BoxShadow(
                color: AppColors.numbersOrange.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else
              Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.alata(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _emotionToEmoji(String emotion) {
    switch (emotion) {
      case 'happy':
        return '😊';
      case 'sad':
        return '😢';
      case 'confused':
        return '😵';
      case 'thinking':
        return '🤔';
      default:
        return '🤖';
    }
  }
}

/// Tiny chip telling the child their selection happens to match Pixy's guess.
class _PixyAgreementChip extends StatelessWidget {
  final String label;
  const _PixyAgreementChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.success.withValues(alpha: 0.35),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.alata(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.success,
          ),
        ),
      ),
    );
  }
}
