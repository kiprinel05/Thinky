import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thinky/core_controls/constants/app_texts.dart';
import 'package:thinky/core_controls/services/language_service.dart';
import 'package:thinky/shared_controls/theme/app_colors.dart';
import 'package:thinky/shared_controls/theme/app_colors_extension.dart';
import 'package:thinky/shared_controls/widgets/drawing/drawing_canvas.dart';
import '../../domain/numbers_models.dart';
import '../controllers/numbers_controller.dart';
import '../controllers/numbers_state.dart';
import '../widgets/numbers_professor_overlay.dart';

/// Part 2: Drawing digits — free-draw flow.
///
/// 1. Child draws ANY digit 0-9 on the canvas.
/// 2. Pixy proposes a guess + simulated confidence (which grows with each
///    teaching example, hitting ~100% by the 4th–5th confirmed example).
/// 3. Child confirms ("yes Pixy was right") or corrects ("no, it was X").
/// 4. If the child claims a digit very different from a clearly-recognized
///    drawing, the professor steps in to discourage teaching the AI wrong
///    things.
class NumbersDrawingPage extends ConsumerStatefulWidget {
  const NumbersDrawingPage({super.key});

  @override
  ConsumerState<NumbersDrawingPage> createState() => _NumbersDrawingPageState();
}

class _NumbersDrawingPageState extends ConsumerState<NumbersDrawingPage>
    with TickerProviderStateMixin {
  final GlobalKey<DrawingCanvasState> _canvasKey = GlobalKey<DrawingCanvasState>();
  final GlobalKey _repaintKey = GlobalKey();

  late AnimationController _pixyBounceController;
  late AnimationController _professorSlideController;
  late AnimationController _upgradeAnimController;
  late Animation<double> _pixyBounceAnim;
  late Animation<Offset> _professorSlideAnim;
  late Animation<double> _upgradeScaleAnim;

  static const Color _primaryColor = AppColors.numbersOrange;
  static const Color _primaryLight = AppColors.numbersOrangeLight;
  static const Color _successColor = AppColors.success;
  static const Color _errorColor = AppColors.incorrectRed;
  bool _hasDrawing = false;

  /// Theme-aware orange used for icons/labels on cards. Lighter in dark mode
  /// so it stays readable against the dark surface.
  Color _accent(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppColors.numbersOrangeLight
          : AppColors.numbersOrangeDark;

  @override
  void initState() {
    super.initState();
    _pixyBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pixyBounceAnim = Tween<double>(begin: 0, end: -8).animate(
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

  void _resetCanvas() {
    _canvasKey.currentState?.clear();
    setState(() => _hasDrawing = false);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(textRefreshProvider);
    final colors = context.appColors;
    final state = ref.watch(numbersStateProvider);

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
                _buildHeader(state),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        _buildPrompt(state),
                        const SizedBox(height: 16),
                        _buildCanvasSection(state),
                        const SizedBox(height: 16),
                        _buildPixySection(state),
                        const SizedBox(height: 12),
                        _buildPhaseActions(state),
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
                title: NumbersMission.drawingCheatingTitle,
                message: state.drawingResult?.professorMessage ?? '',
                hint: state.drawingResult?.professorHint,
                onUnderstood: () {
                  _resetCanvas();
                  ref.read(numbersStateProvider.notifier).dismissProfessor();
                },
              ),
            if (state.phase == NumbersPhase.modelUpgrade)
              _buildUpgradeOverlay(state),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HEADER
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildHeader(NumbersState state) {
    final colors = context.appColors;
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
                    color: _primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      color: _accent(context), size: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      NumbersMission.part2Title,
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
                      style: GoogleFonts.alata(fontSize: 12, color: _accent(context)),
                    ),
                  ],
                ),
              ),
              _buildExamplesChip(state),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: state.upgradeProgress.clamp(0.0, 1.0),
              backgroundColor: _primaryColor.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                NumbersMission.progressUpgrade(state.correctCount),
                style: GoogleFonts.alata(fontSize: 10, color: colors.textSecondary),
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
                          ? _primaryColor
                          : isPast
                              ? _successColor.withValues(alpha: 0.15)
                              : Colors.grey.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(level.emoji, style: const TextStyle(fontSize: 12)),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExamplesChip(NumbersState state) {
    if (state.examplesTaught == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _primaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.school_rounded, size: 14, color: _accent(context)),
          const SizedBox(width: 4),
          Text(
            NumbersMission.examplesTaught(state.examplesTaught),
            style: GoogleFonts.alata(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _accent(context),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PROMPT (no target — free draw)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildPrompt(NumbersState state) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _primaryColor.withValues(alpha: 0.1),
            _primaryLight.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _primaryColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.draw_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  NumbersMission.freeDrawTitle,
                  style: GoogleFonts.alata(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  NumbersMission.freeDrawSubtitle,
                  style: GoogleFonts.alata(
                    fontSize: 12,
                    color: colors.textSecondary,
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
  // CANVAS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildCanvasSection(NumbersState state) {
    final colors = context.appColors;
    final canvasIsLocked = state.phase == NumbersPhase.drawingAwaitingConfirmation ||
        state.phase == NumbersPhase.drawingPickCorrection ||
        state.phase == NumbersPhase.drawingResult;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: 260,
          child: Stack(
            children: [
              IgnorePointer(
                ignoring: canvasIsLocked,
                child: DrawingCanvas(
                  key: _canvasKey,
                  repaintKey: _repaintKey,
                  selectedColor: colors.textPrimary,
                  strokeWidth: 10.0,
                  onDrawingChanged: () {
                    setState(() {
                      _hasDrawing = _canvasKey.currentState?.hasDrawing ?? false;
                    });
                  },
                ),
              ),
              if (!_hasDrawing && state.phase == NumbersPhase.drawing)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.gesture_rounded,
                            size: 48,
                            color: colors.textHint.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '0 1 2 3 4 5 6 7 8 9',
                            style: GoogleFonts.alata(
                              fontSize: 18,
                              letterSpacing: 4,
                              color: colors.textHint.withValues(alpha: 0.5),
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
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PIXY SECTION
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildPixySection(NumbersState state) {
    final colors = context.appColors;
    String pixyText;
    String pixyEmoji;

    if (state.phase == NumbersPhase.drawingResult && state.drawingResult != null) {
      pixyText = state.drawingResult!.pixyMessage;
      pixyEmoji = _emotionToEmoji(state.drawingResult!.pixyEmotion);
    } else if ((state.phase == NumbersPhase.drawingAwaitingConfirmation ||
            state.phase == NumbersPhase.drawingPickCorrection) &&
        state.drawingGuess != null) {
      pixyText = state.drawingGuess!.pixyMessage;
      pixyEmoji = _emotionToEmoji(state.drawingGuess!.pixyEmotion);
    } else {
      pixyText = NumbersMission.pixyDrawPrompt;
      pixyEmoji = '🤖';
    }

    return AnimatedBuilder(
      animation: _pixyBounceAnim,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _pixyBounceAnim.value),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _primaryColor.withValues(alpha: 0.1),
                  _primaryLight.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _primaryColor.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.cardColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.border),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryColor.withValues(alpha: 0.1),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Text(pixyEmoji, style: const TextStyle(fontSize: 28)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        NumbersMission.modelLevelName(state.modelLevel),
                        style: GoogleFonts.alata(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _accent(context),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        pixyText,
                        style: GoogleFonts.alata(
                          fontSize: 13,
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
  // PHASE-DEPENDENT ACTIONS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildPhaseActions(NumbersState state) {
    switch (state.phase) {
      case NumbersPhase.drawing:
        return _buildDrawingActions(state);
      case NumbersPhase.drawingAwaitingConfirmation:
        return _buildConfirmActions(state);
      case NumbersPhase.drawingPickCorrection:
        return _buildCorrectionPicker(state);
      case NumbersPhase.drawingResult:
        return _buildResultActions(state);
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Step 1: child draws and submits ───────────────────────────────────────
  Widget _buildDrawingActions(NumbersState state) {
    final colors = context.appColors;
    final controller = ref.read(numbersStateProvider.notifier);

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _resetCanvas,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: colors.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _primaryColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline_rounded,
                      color: _accent(context), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    NumbersMission.clear,
                    style: GoogleFonts.alata(
                      color: _accent(context),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: _hasDrawing && !state.isSubmitting
                ? () async {
                    final imageBytes = await _canvasKey.currentState?.exportToPng();
                    if (imageBytes != null) {
                      controller.submitDrawing(imageBytes);
                    }
                  }
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _hasDrawing && !state.isSubmitting
                    ? _primaryColor
                    : _primaryColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  if (_hasDrawing && !state.isSubmitting)
                    BoxShadow(
                      color: _primaryColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (state.isSubmitting) ...[
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      NumbersMission.analyzing,
                      style: GoogleFonts.alata(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ] else ...[
                    const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      NumbersMission.sendToPixy,
                      style: GoogleFonts.alata(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Step 2: was Pixy right? ──────────────────────────────────────────────
  Widget _buildConfirmActions(NumbersState state) {
    final colors = context.appColors;
    final controller = ref.read(numbersStateProvider.notifier);
    final guess = state.drawingGuess;
    if (guess == null) return const SizedBox.shrink();

    final confidencePct = (guess.confidence * 100).clamp(0, 100).toInt();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _primaryColor.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_primaryColor, _primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryColor.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${guess.guessedDigit ?? "?"}',
                    style: GoogleFonts.alata(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      NumbersMission.askWasItCorrect,
                      style: GoogleFonts.alata(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildConfidenceBar(confidencePct),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SecondaryActionButton(
                  label: NumbersMission.noCorrectIt,
                  icon: Icons.close_rounded,
                  color: _errorColor,
                  onTap:
                      state.isSubmitting ? null : controller.startCorrection,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PrimaryActionButton(
                  label: NumbersMission.yesPixyCorrect,
                  icon: Icons.check_rounded,
                  color: _successColor,
                  isLoading: state.isSubmitting,
                  onTap:
                      state.isSubmitting ? null : controller.confirmPixyGuess,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceBar(int percent) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          NumbersMission.pixyConfidence(percent),
          style: GoogleFonts.alata(
            fontSize: 11,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: percent / 100.0,
            backgroundColor: _primaryColor.withValues(alpha: 0.12),
            valueColor: const AlwaysStoppedAnimation<Color>(_primaryColor),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  // ── Step 2b: child picks the digit they actually drew ────────────────────
  Widget _buildCorrectionPicker(NumbersState state) {
    final colors = context.appColors;
    final controller = ref.read(numbersStateProvider.notifier);
    final pixyGuess = state.drawingGuess?.guessedDigit;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _primaryColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.touch_app_rounded, color: _accent(context), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  NumbersMission.pickWhatYouDrew,
                  style: GoogleFonts.alata(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: state.isSubmitting ? null : controller.cancelCorrection,
                child: Icon(
                  Icons.close_rounded,
                  color: colors.textSecondary,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.1,
            ),
            itemCount: 10,
            itemBuilder: (context, index) {
              final isPixyGuess = pixyGuess == index;
              return GestureDetector(
                onTap: state.isSubmitting
                    ? null
                    : () => controller.correctPixyGuess(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isPixyGuess
                        ? colors.background
                        : _primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isPixyGuess
                          ? colors.border
                          : _primaryColor.withValues(alpha: 0.35),
                      width: isPixyGuess ? 1 : 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$index',
                      style: GoogleFonts.alata(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: isPixyGuess
                            ? colors.textHint
                            : _accent(context),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          if (state.isSubmitting) ...[
            const SizedBox(height: 12),
            const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── After teach: feedback + next ─────────────────────────────────────────
  Widget _buildResultActions(NumbersState state) {
    final colors = context.appColors;
    final result = state.drawingResult;
    if (result == null) return const SizedBox.shrink();
    final controller = ref.read(numbersStateProvider.notifier);

    final isCelebration = result.wasPixyCorrect && !result.isLying;
    final accent = isCelebration ? _successColor : _primaryColor;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isCelebration
                        ? Icons.celebration_rounded
                        : Icons.school_rounded,
                    color: accent,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      isCelebration
                          ? NumbersMission.drawingRecognized
                          : NumbersMission.drawingTeachThanks,
                      style: GoogleFonts.alata(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
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
          child: GestureDetector(
            onTap: () {
              _resetCanvas();
              controller.nextRound();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _primaryColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _primaryColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.arrow_forward_rounded,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    NumbersMission.nextDigit,
                    style: GoogleFonts.alata(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MODEL UPGRADE OVERLAY
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildUpgradeOverlay(NumbersState state) {
    final colors = context.appColors;
    final controller = ref.read(numbersStateProvider.notifier);

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
                  color: _primaryColor.withValues(alpha: 0.3),
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
                    color: _accent(context),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_primaryColor, _primaryLight],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    NumbersMission.upgradeLevelLine(
                      state.modelLevel.emoji,
                      NumbersMission.modelLevelName(state.modelLevel),
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
                  NumbersMission.upgradeDrawingSubtitle,
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
                    onPressed: () {
                      _resetCanvas();
                      controller.dismissUpgrade();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
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
                          fontWeight: FontWeight.w700, letterSpacing: 1),
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

// ── Reusable little buttons (kept private — only used here) ──────────────────

class _PrimaryActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final VoidCallback? onTap;

  const _PrimaryActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: disabled ? color.withValues(alpha: 0.4) : color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: disabled
              ? null
              : [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading) ...[
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 8),
            ] else ...[
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.alata(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _SecondaryActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: disabled ? 0.04 : 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: color.withValues(alpha: disabled ? 0.2 : 0.45),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.alata(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
