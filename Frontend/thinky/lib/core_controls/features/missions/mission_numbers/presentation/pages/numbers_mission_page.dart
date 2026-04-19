import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thinky/base_controls/base_state.dart';
import 'package:thinky/core_controls/constants/app_texts.dart';
import 'package:thinky/core_controls/services/language_service.dart';
import 'package:thinky/shared_controls/theme/app_colors.dart';
import 'package:thinky/shared_controls/theme/app_colors_extension.dart';
import 'package:thinky/shared_controls/widgets/animations/animated_widgets.dart';
import '../controllers/numbers_controller.dart';
import '../controllers/numbers_state.dart';
import 'numbers_counting_page.dart';
import 'numbers_drawing_page.dart';
import 'numbers_learning_view.dart';

/// Main page for the "Învățăm numerele cu Pixy" mission.
///
/// Owns the high-level phase routing (intro → counting/drawing → completion)
/// and renders the bookend screens (intro + completion). The orange theme is
/// pulled from [AppColors.numbersOrange] so dark mode and other missions stay
/// in sync.
class NumbersMissionPage extends ConsumerStatefulWidget {
  const NumbersMissionPage({super.key});

  @override
  ConsumerState<NumbersMissionPage> createState() => _NumbersMissionPageState();
}

class _NumbersMissionPageState extends ConsumerState<NumbersMissionPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pixyAnimationController;
  late Animation<double> _pixyScaleAnimation;

  @override
  void initState() {
    super.initState();
    _pixyAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pixyScaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
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
  Widget build(BuildContext context) {
    ref.watch(textRefreshProvider);
    final state = ref.watch(numbersStateProvider);

    if (state.status == StateStatus.loading) {
      return _buildLoadingScreen(context);
    }

    switch (state.phase) {
      case NumbersPhase.intro:
        return _buildIntroScreen(context);
      case NumbersPhase.counting:
      case NumbersPhase.pixyGuessing:
      case NumbersPhase.professorIntervention:
      case NumbersPhase.modelUpgrade:
      case NumbersPhase.transitionToPart2:
        if (state.currentPart == 2) {
          return const NumbersDrawingPage();
        }
        return const NumbersCountingPage();
      case NumbersPhase.drawing:
      case NumbersPhase.drawingAwaitingConfirmation:
      case NumbersPhase.drawingPickCorrection:
      case NumbersPhase.drawingResult:
        return const NumbersDrawingPage();
      case NumbersPhase.completion:
        return _buildCompletionScreen(context, state);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LOADING
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildLoadingScreen(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _heroGradient(isDark),
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
                const SizedBox(height: 24),
                Text(
                  NumbersMission.loadingPreparing,
                  style: GoogleFonts.alata(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
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
  // INTRO SCREEN
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildIntroScreen(BuildContext context) {
    final controller = ref.read(numbersStateProvider.notifier);
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 320,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _heroGradient(isDark),
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        ScaleInWidget(
                          delay: const Duration(milliseconds: 200),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                            child: ScaleTransition(
                              scale: _pixyScaleAnimation,
                              child: const Text(
                                '🤖',
                                style: TextStyle(fontSize: 80),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        FadeInWidget(
                          delay: const Duration(milliseconds: 400),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: colors.cardColor,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: colors.border),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.numbersOrange
                                      .withValues(alpha: isDark ? 0.25 : 0.12),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        AppColors.numbersOrange,
                                        AppColors.numbersOrangeLight,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(
                                    Icons.numbers_rounded,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  NumbersMission.introTitle,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.alata(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  NumbersMission.introBody,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.alata(
                                    fontSize: 14,
                                    color: colors.textSecondary,
                                    height: 1.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        FadeInWidget(
                          delay: const Duration(milliseconds: 500),
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            alignment: WrapAlignment.center,
                            children: [
                              _buildFeaturePill(
                                Icons.calculate_rounded,
                                NumbersMission.featureNumbers,
                                isDark,
                              ),
                              _buildFeaturePill(
                                Icons.draw_rounded,
                                NumbersMission.featureDraw,
                                isDark,
                              ),
                              _buildFeaturePill(
                                Icons.auto_awesome,
                                NumbersMission.featureLevels,
                                isDark,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        FadeInWidget(
                          delay: const Duration(milliseconds: 600),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.numbersOrange,
                                  AppColors.numbersOrangeLight,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.numbersOrange
                                      .withValues(alpha: 0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () => controller.startSession(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 20),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    NumbersMission.startAdventure,
                                    style: GoogleFonts.alata(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 17,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
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

  // ══════════════════════════════════════════════════════════════════════════
  // COMPLETION SCREEN
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildCompletionScreen(BuildContext context, NumbersState state) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = ref.read(numbersStateProvider.notifier);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _heroGradient(isDark),
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleInWidget(
                    delay: const Duration(milliseconds: 200),
                    child: const Text('🎉', style: TextStyle(fontSize: 80)),
                  ),
                  const SizedBox(height: 24),
                  FadeInWidget(
                    delay: const Duration(milliseconds: 400),
                    child: Text(
                      NumbersMission.completionCongrats,
                      style: GoogleFonts.alata(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  FadeInWidget(
                    delay: const Duration(milliseconds: 450),
                    child: Text(
                      NumbersMission.missionCompleteSubtitle(
                        NumbersMission.modelLevelName(state.modelLevel),
                        state.modelLevel.emoji,
                      ),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.alata(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeInWidget(
                    delay: const Duration(milliseconds: 500),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            NumbersMission.completionTitle,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.alata(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _StatTile(
                                value: '${state.correctCount}',
                                label: NumbersMission.statCorrectAnswers,
                              ),
                              _StatTile(
                                value: '${state.roundsCompleted}',
                                label: NumbersMission.statRounds,
                              ),
                              _StatTile(
                                value: state.modelLevel.emoji,
                                label: NumbersMission.statTopLevel,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeInWidget(
                    delay: const Duration(milliseconds: 600),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLevelBadge('🐣', NumbersMission.badgeJunior, true),
                        const SizedBox(width: 10),
                        _buildLevelBadge(
                          '📚',
                          NumbersMission.badgeStudent,
                          state.modelLevel.index >= 1,
                        ),
                        const SizedBox(width: 10),
                        _buildLevelBadge(
                          '🌟',
                          NumbersMission.badgeExpert,
                          state.modelLevel.index >= 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  FadeInWidget(
                    delay: const Duration(milliseconds: 700),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _openLearningView(context),
                            icon: const Icon(Icons.school_rounded, size: 18),
                            label: Text(
                              NumbersMission.learnWithPixy,
                              style: GoogleFonts.alata(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                letterSpacing: 0.8,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.numbersOrangeDark,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => controller.restart(),
                                icon: const Icon(Icons.refresh_rounded,
                                    size: 18),
                                label: Text(
                                  NumbersMission.tryAgainCaps,
                                  style: GoogleFonts.alata(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    width: 1.5,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextButton.icon(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.close_rounded,
                                    color: Colors.white, size: 18),
                                label: Text(
                                  NumbersMission.backToMissionsCaps,
                                  style: GoogleFonts.alata(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openLearningView(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NumbersLearningView(
          onDone: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  /// Hero gradient used by intro / loading / completion. The dark variant
  /// is a deeper, less saturated orange that doesn't blow out OLED screens.
  List<Color> _heroGradient(bool isDark) => isDark
      ? const [Color(0xFF8A4A20), Color(0xFFB6612C)]
      : const [AppColors.numbersOrange, AppColors.numbersOrangeLight];

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 18),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calculate_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  NumbersMission.appBarTitle,
                  style: GoogleFonts.alata(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturePill(IconData icon, String text, bool isDark) {
    final tint = isDark
        ? AppColors.numbersOrangeLight
        : AppColors.numbersOrangeDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.numbersOrange.withValues(alpha: isDark ? 0.18 : 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              AppColors.numbersOrange.withValues(alpha: isDark ? 0.3 : 0.15),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: tint),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.alata(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: tint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelBadge(String emoji, String label, bool unlocked) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: unlocked
            ? Colors.white.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: unlocked ? 0.4 : 0.1),
        ),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.alata(
              fontSize: 11,
              color: Colors.white.withValues(alpha: unlocked ? 1.0 : 0.4),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  const _StatTile({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.alata(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.alata(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }
}
