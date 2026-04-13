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

/// Part 2: Drawing digits and helping Pixy recognize numbers
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

  static const Color _primaryColor = Color(0xFFFF9A5C);
  static const Color _primaryLight = Color(0xFFFFB347);
  static const Color _primaryDark = Color(0xFFE87B3A);
  static const Color _successColor = Color(0xFF4CAF50);
  static const Color _errorColor = Color(0xFFFF6B6B);
  bool _hasDrawing = false;

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

  @override
  Widget build(BuildContext context) {
    ref.watch(textRefreshProvider);
    final colors = context.appColors;
    final state = ref.watch(numbersStateProvider);

    // Trigger overlays
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
                        if (state.phase == NumbersPhase.drawing) _buildDrawingActions(state),
                        if (state.phase == NumbersPhase.drawingResult) _buildResultSection(state),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (state.phase == NumbersPhase.professorIntervention)
              _buildProfessorOverlay(state),
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
                      color: _primaryDark, size: 18),
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
                      style: GoogleFonts.alata(fontSize: 12, color: _primaryDark),
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
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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

  // ══════════════════════════════════════════════════════════════════════════
  // DRAWING PROMPT
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildPrompt(NumbersState state) {
    final colors = context.appColors;
    final target = state.round?.targetNumber ?? 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryColor.withValues(alpha: 0.1), _primaryLight.withValues(alpha: 0.06)],
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
            child: Text(
              '$target',
              style: GoogleFonts.alata(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  NumbersMission.drawTheDigit(target),
                  style: GoogleFonts.alata(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  NumbersMission.drawDigitHint,
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
              DrawingCanvas(
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
              // Ghost digit guide
              if (!_hasDrawing)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Center(
                      child: Text(
                        '${state.round?.targetNumber ?? 1}',
                        style: GoogleFonts.alata(
                          fontSize: 140,
                          fontWeight: FontWeight.w700,
                          color: colors.textHint.withValues(alpha: 0.2),
                        ),
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
                colors: [_primaryColor.withValues(alpha: 0.1), _primaryLight.withValues(alpha: 0.06)],
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
                          color: _primaryDark,
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
  // DRAWING ACTIONS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildDrawingActions(NumbersState state) {
    final colors = context.appColors;
    final controller = ref.read(numbersStateProvider.notifier);

    return Row(
      children: [
        // Clear button
        Expanded(
          child: GestureDetector(
            onTap: () {
              _canvasKey.currentState?.clear();
              setState(() => _hasDrawing = false);
            },
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
                  Icon(Icons.delete_outline_rounded, color: _primaryDark, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    NumbersMission.clear,
                    style: GoogleFonts.alata(
                      color: _primaryDark,
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
        // Submit button
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

  // ══════════════════════════════════════════════════════════════════════════
  // RESULT SECTION
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildResultSection(NumbersState state) {
    final colors = context.appColors;
    final result = state.drawingResult;
    if (result == null) return const SizedBox.shrink();
    final controller = ref.read(numbersStateProvider.notifier);

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: result.isCorrect
                ? _successColor.withValues(alpha: 0.08)
                : _errorColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: result.isCorrect
                  ? _successColor.withValues(alpha: 0.3)
                  : _errorColor.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    result.isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: result.isCorrect ? _successColor : _errorColor,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      result.isCorrect
                          ? NumbersMission.drawingRecognized
                          : NumbersMission.drawingGuessed(
                              '${result.guessedDigit ?? "?"}',
                            ),
                      style: GoogleFonts.alata(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: result.isCorrect ? _successColor : _errorColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (result.confidence > 0)
                Text(
                  NumbersMission.confidencePercent(
                    (result.confidence * 100).toInt(),
                  ),
                  style: GoogleFonts.alata(
                    fontSize: 12,
                    color: colors.textSecondary,
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
          child: GestureDetector(
            onTap: () {
              _canvasKey.currentState?.clear();
              setState(() => _hasDrawing = false);
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
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
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
  // PROFESSOR OVERLAY
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildProfessorOverlay(NumbersState state) {
    final colors = context.appColors;
    final controller = ref.read(numbersStateProvider.notifier);
    final message = state.drawingResult?.professorMessage ?? '';
    final hint = state.drawingResult?.professorHint;

    return Container(
      color: Colors.black.withValues(alpha: 0.45),
      child: Center(
        child: SlideTransition(
          position: _professorSlideAnim,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 28),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: colors.cardColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: colors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.numbersPrimary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('👨‍🏫', style: TextStyle(fontSize: 48)),
                ),
                const SizedBox(height: 20),
                Text(
                  NumbersMission.professorSays,
                  style: GoogleFonts.alata(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.numbersPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.alata(
                    fontSize: 14,
                    height: 1.6,
                    color: colors.textPrimary,
                  ),
                ),
                if (hint != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Text('💡', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            hint,
                            style: GoogleFonts.alata(
                              fontSize: 12,
                              color: _primaryDark,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _canvasKey.currentState?.clear();
                      setState(() => _hasDrawing = false);
                      controller.dismissProfessor();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.numbersPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      NumbersMission.professorUnderstood,
                      style: GoogleFonts.alata(fontWeight: FontWeight.w700, letterSpacing: 1),
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
                    color: _primaryDark,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_primaryColor, _primaryLight]),
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
                      _canvasKey.currentState?.clear();
                      setState(() => _hasDrawing = false);
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
                      style: GoogleFonts.alata(fontWeight: FontWeight.w700, letterSpacing: 1),
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
