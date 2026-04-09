import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thinky/core_controls/constants/app_texts.dart';
import 'package:thinky/core_controls/features/missions/mission_pattern/data/pattern_models.dart';
import 'package:thinky/core_controls/services/language_service.dart';
import 'package:thinky/core/errors/error_logger.dart';
import 'package:thinky/shared_controls/theme/app_colors.dart';
import 'package:thinky/shared_controls/theme/app_colors_extension.dart';
import '../controllers/pattern_controller.dart';

class PatternMissionPage extends ConsumerWidget {
  const PatternMissionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(textRefreshProvider);
    final colors = context.appColors;
    final state = ref.watch(patternControllerProvider);
    final controller = ref.read(patternControllerProvider.notifier);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          PatternMission.title,
          style: GoogleFonts.alata(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.patternPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: _buildBody(context, colors, state, controller),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppColorsExtension colors,
    PatternState state,
    PatternController controller,
  ) {
    if (state.phase == PatternPhase.loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.patternPurple),
            const SizedBox(height: 16),
            Text(
              PatternMission.loadingPattern,
              style: GoogleFonts.alata(fontSize: 16, color: colors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (state.phase == PatternPhase.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                UserErrors.somethingWentWrong,
                textAlign: TextAlign.center,
                style: GoogleFonts.alata(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.errorMessage ?? UserErrors.somethingWentWrong,
                textAlign: TextAlign.center,
                style: GoogleFonts.alata(fontSize: 15, color: colors.textSecondary),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: controller.startMission,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.patternPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                ),
                child: Text(PatternMission.tryAgain, style: GoogleFonts.alata(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      );
    }

    if (state.phase == PatternPhase.missionComplete) {
       return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.stars_rounded, size: 80, color: AppColors.goldAccent),
              const SizedBox(height: 20),
              Text(
                PatternMission.missionCompleteTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.alata(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.patternPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: Text(
                  PatternMission.backToMenu,
                  style: GoogleFonts.alata(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final round = state.currentRound!;
    final isFeedback = state.phase == PatternPhase.feedback;
    final optionsBg = Color.lerp(colors.surface, AppColors.patternPurple, 0.06)!;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Text(
            round.instruction,
            style: GoogleFonts.alata(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
              height: 1.25,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        // 2. The Pattern Display
        Expanded(
          flex: 4,
          child: Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ...round.sequence.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: _ShapeWidget(item: item, size: 60),
                      )),
                  // The "Mystery" Box
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: _MysteryBox(
                      isRevealed: isFeedback,
                      result: state.lastResult,
                      cardColor: colors.cardColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // 3. Options
        Expanded(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: optionsBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              border: Border(top: BorderSide(color: colors.border)),
            ),
            child: Column(
              children: [
                Text(
                  PatternMission.chooseNext,
                  style: GoogleFonts.alata(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.patternPurple,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  alignment: WrapAlignment.center,
                  children: round.options.map((option) {
                    final isSelected = state.selectedOptionId == option.id;
                    return GestureDetector(
                      onTap: isFeedback ? null : () => controller.selectOption(option.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.patternPurple
                                : colors.border,
                            width: isSelected ? 3 : 1.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.patternPurple.withValues(alpha: 0.25),
                                    blurRadius: 12,
                                    spreadRadius: 1,
                                  )
                                ]
                              : [],
                        ),
                        child: _ShapeWidget(item: option, size: 50),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),

        // 4. Action Button
        if (state.selectedOptionId != null || isFeedback)
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: isFeedback
                    ? controller.nextRound
                    : (state.phase == PatternPhase.submitting ? null : controller.submitAnswer),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFeedback
                      ? (state.isCorrect ? AppColors.success : AppColors.warning)
                      : AppColors.patternPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                child: state.phase == PatternPhase.submitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        isFeedback
                            ? (state.isCorrect
                                ? PatternMission.nextPattern
                                : PatternMission.tryAgain)
                            : PatternMission.checkAnswer,
                        style: GoogleFonts.alata(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
          
        // Feedback Message Toast
        if (isFeedback)
           Container(
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
             decoration: BoxDecoration(
               color: state.isCorrect
                   ? AppColors.success.withValues(alpha: 0.14)
                   : AppColors.warning.withValues(alpha: 0.14),
               borderRadius: BorderRadius.circular(12),
               border: Border.all(
                 color: state.isCorrect
                     ? AppColors.success.withValues(alpha: 0.35)
                     : AppColors.warning.withValues(alpha: 0.35),
               ),
             ),
             width: double.infinity,
             child: Text(
               state.lastResult?.message ?? '',
               textAlign: TextAlign.center,
               style: GoogleFonts.alata(
                 color: state.isCorrect ? AppColors.success : AppColors.warning,
                 fontWeight: FontWeight.w700,
                 fontSize: 16,
                 height: 1.35,
               ),
             ),
           ),
      ],
    );
  }
}

class _ShapeWidget extends StatelessWidget {
  final PatternItem item;
  final double size;

  const _ShapeWidget({required this.item, required this.size});

  @override
  Widget build(BuildContext context) {
    Color color = _parseColor(item.color);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: ShapePainter(shape: item.shape, color: color),
      ),
    );
  }

  Color _parseColor(String colorStr) {
    if (colorStr.startsWith('#')) {
      return Color(int.parse(colorStr.substring(1), radix: 16) + 0xFF000000);
    }
    if (colorStr.length == 6) {
       // Check if hex digits
       try {
         return Color(int.parse(colorStr, radix: 16) + 0xFF000000);
       } catch (e) {
         ErrorLogger().logDebug('Invalid hex color: $e');
       }
    }
    switch(colorStr.toLowerCase()) {
      case 'red': return Colors.red;
      case 'blue': return Colors.blue;
      case 'green': return Colors.green;
      case 'yellow': return Colors.yellow;
      case 'orange': return Colors.orange;
      case 'purple': return Colors.purple;
      default: return Colors.grey;
    }
  }
}

class ShapePainter extends CustomPainter {
  final String shape;
  final Color color;

  ShapePainter({required this.shape, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    switch (shape.toLowerCase()) {
      case 'circle':
        canvas.drawCircle(center, radius, paint);
        break;
      case 'square':
        canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
        break;
      case 'triangle':
        path.moveTo(size.width / 2, 0);
        path.lineTo(size.width, size.height);
        path.lineTo(0, size.height);
        path.close();
        canvas.drawPath(path, paint);
        break;
      case 'star':
        path.moveTo(size.width * 0.5, 0);
        path.lineTo(size.width * 0.63, size.height * 0.38);
        path.lineTo(size.width, size.height * 0.38);
        path.lineTo(size.width * 0.69, size.height * 0.61);
        path.lineTo(size.width * 0.81, size.height);
        path.lineTo(size.width * 0.5, size.height * 0.77);
        path.lineTo(size.width * 0.19, size.height);
        path.lineTo(size.width * 0.31, size.height * 0.61);
        path.lineTo(0, size.height * 0.38);
        path.lineTo(size.width * 0.37, size.height * 0.38);
        path.close();
        canvas.drawPath(path, paint);
        break;
      default:
        canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _MysteryBox extends StatefulWidget {
  final bool isRevealed;
  final PatternResultResponse? result;
  final Color cardColor;

  const _MysteryBox({
    required this.isRevealed,
    this.result,
    required this.cardColor,
  });

  @override
  State<_MysteryBox> createState() => _MysteryBoxState();
}

class _MysteryBoxState extends State<_MysteryBox> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
       vsync: this, duration: const Duration(seconds: 2)
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isRevealed && widget.result != null && widget.result!.correct) {
       return Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
             color: widget.cardColor,
             border: Border.all(color: AppColors.success, width: 3),
             borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
             Icons.check,
             color: AppColors.success,
             size: 40,
          ),
       );
    }
    
    if (widget.isRevealed && widget.result != null && !widget.result!.correct) {
       return Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
             color: widget.cardColor,
             border: Border.all(color: AppColors.error, width: 3),
             borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
             Icons.close,
             color: AppColors.error,
             size: 40,
          ),
       );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
         return Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
               color: widget.cardColor,
               borderRadius: BorderRadius.circular(10),
               border: Border.all(
                  color: AppColors.patternPurple
                      .withValues(alpha: 0.45 + 0.45 * _controller.value),
                  width: 3,
               ),
               boxShadow: [
                  BoxShadow(
                     color: AppColors.patternPurple
                         .withValues(alpha: 0.22 * _controller.value),
                     blurRadius: 10,
                     spreadRadius: 2 * _controller.value,
                  )
               ]
            ),
            child: Center(
               child: Text(
                  '?',
                  style: GoogleFonts.alata(
                     fontSize: 32,
                     fontWeight: FontWeight.w800,
                     color: AppColors.patternPurple,
                  ),
               ),
            ),
         );
      },
    );
  }
}
