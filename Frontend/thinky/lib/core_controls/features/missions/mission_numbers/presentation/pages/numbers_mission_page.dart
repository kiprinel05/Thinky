import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thinky/base_controls/base_state.dart';
import 'package:thinky/core_controls/constants/app_texts.dart';
import 'package:thinky/core_controls/services/language_service.dart';
import 'package:thinky/shared_controls/theme/app_colors_extension.dart';
import 'package:thinky/shared_controls/widgets/animations/animated_widgets.dart';
import '../controllers/numbers_controller.dart';
import '../controllers/numbers_state.dart';
import 'numbers_counting_page.dart';
import 'numbers_drawing_page.dart';

/// Main page for the "Învățăm numerele cu Pixy" mission
class NumbersMissionPage extends ConsumerStatefulWidget {
  const NumbersMissionPage({super.key});

  @override
  ConsumerState<NumbersMissionPage> createState() => _NumbersMissionPageState();
}

class _NumbersMissionPageState extends ConsumerState<NumbersMissionPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pixyAnimationController;
  late Animation<double> _pixyScaleAnimation;

  // Mission-specific warm orange color palette
  static const Color _primaryColor = Color(0xFFFF9A5C);
  static const Color _primaryLight = Color(0xFFFFB347);
  static const Color _primaryDark = Color(0xFFE87B3A);

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
      return _buildLoadingScreen();
    }

    switch (state.phase) {
      case NumbersPhase.intro:
        return _buildIntroScreen();
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
      case NumbersPhase.drawingResult:
        return const NumbersDrawingPage();
      case NumbersPhase.completion:
        return _buildCompletionScreen(state);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LOADING
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_primaryColor, _primaryLight],
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
                  style: const TextStyle(
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

  Widget _buildIntroScreen() {
    final controller = ref.read(numbersStateProvider.notifier);
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          // Orange gradient header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 320,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_primaryColor, _primaryLight],
                ),
                borderRadius: BorderRadius.only(
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

                        // Pixy mascot
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

                        // Title card
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
                                  color: _primaryColor.withValues(alpha: 0.12),
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
                                      colors: [_primaryColor, _primaryLight],
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

                        // Feature pills
                        FadeInWidget(
                          delay: const Duration(milliseconds: 500),
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            alignment: WrapAlignment.center,
                            children: [
                              _buildFeaturePill(Icons.calculate_rounded, NumbersMission.featureNumbers),
                              _buildFeaturePill(Icons.draw_rounded, NumbersMission.featureDraw),
                              _buildFeaturePill(Icons.auto_awesome, NumbersMission.featureLevels),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Start button
                        FadeInWidget(
                          delay: const Duration(milliseconds: 600),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              gradient: const LinearGradient(
                                colors: [_primaryColor, _primaryLight],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _primaryColor.withValues(alpha: 0.4),
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
                                padding: const EdgeInsets.symmetric(vertical: 20),
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
                                      color: Colors.white.withValues(alpha: 0.2),
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

  Widget _buildCompletionScreen(NumbersState state) {
    final colors = context.appColors;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_primaryColor, _primaryLight],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
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
                  const SizedBox(height: 16),
                  FadeInWidget(
                    delay: const Duration(milliseconds: 500),
                    child: Container(
                      padding: const EdgeInsets.all(24),
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
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            NumbersMission.completionBody,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.alata(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Model level badges
                  FadeInWidget(
                    delay: const Duration(milliseconds: 600),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLevelBadge('🐣', NumbersMission.badgeJunior, true),
                        const SizedBox(width: 12),
                        _buildLevelBadge('📚', NumbersMission.badgeStudent, true),
                        const SizedBox(width: 12),
                        _buildLevelBadge('🌟', NumbersMission.badgeExpert, true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  FadeInWidget(
                    delay: const Duration(milliseconds: 700),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: colors.textPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          NumbersMission.backToMissionsCaps,
                          style: GoogleFonts.alata(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════════════════════════

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

  Widget _buildFeaturePill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _primaryColor.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: _primaryDark),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.alata(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _primaryDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelBadge(String emoji, String label, bool unlocked) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: unlocked ? Colors.white.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: unlocked ? 0.4 : 0.1),
        ),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
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
