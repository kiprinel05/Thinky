import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:thinky/core_controls/constants/app_texts.dart';
import 'package:thinky/core_controls/services/language_service.dart';
import 'package:thinky/shared_controls/theme/app_colors.dart';
import 'package:thinky/shared_controls/theme/app_colors_extension.dart';
import 'package:thinky/shared_controls/widgets/drawing/drawing_canvas.dart';
import 'package:thinky/shared_controls/widgets/error_handler_ui.dart';
import 'package:thinky/shared_controls/assets/app_assets.dart';
import 'controllers/color_circle_controller.dart';

/// Color Circle Mission Page
/// 
/// A creative mission where the user colors a pre-drawn circle in red.
/// Features:
/// - Pre-drawn circle outline for coloring
/// - Interactive drawing canvas
/// - Color palette (red pre-selected)
/// - Pixy mascot with emotion animations
/// - Modern glassmorphism design
class ColorCirclePage extends ConsumerStatefulWidget {
  const ColorCirclePage({super.key});

  @override
  ConsumerState<ColorCirclePage> createState() => _ColorCirclePageState();
}

class _ColorCirclePageState extends ConsumerState<ColorCirclePage>
    with TickerProviderStateMixin {
  final GlobalKey _canvasKey = GlobalKey();
  final GlobalKey<DrawingCanvasState> _canvasStateKey = GlobalKey<DrawingCanvasState>();
  bool _isEraserSelected = false;
  
  late AnimationController _pixyBounceController;
  late AnimationController _resultSlideController;
  late AnimationController _thinkingController;
  
  late Animation<double> _pixyBounce;
  late Animation<Offset> _resultSlide;
  late Animation<double> _thinkingRotation;

  @override
  void initState() {
    super.initState();
    
    // Pixy bounce animation (idle)
    _pixyBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pixyBounce = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _pixyBounceController, curve: Curves.easeInOut),
    );
    
    // Result slide-in animation
    _resultSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _resultSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _resultSlideController,
      curve: Curves.easeOutBack,
    ));
    
    // Thinking animation (rotation)
    _thinkingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _thinkingRotation = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(parent: _thinkingController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pixyBounceController.dispose();
    _resultSlideController.dispose();
    _thinkingController.dispose();
    super.dispose();
  }

  Future<void> _onCheckDrawing() async {
    final canvasState = _canvasStateKey.currentState;
    if (canvasState == null || !canvasState.hasDrawing) {
      ErrorHandlerUI.showWarning(context, Drawing.colorCircleFirst);
      return;
    }
    
    // Export canvas to PNG
    final imageBytes = await canvasState.exportToPng();
    if (imageBytes == null) {
      ErrorHandlerUI.showError(context, Drawing.captureError);
      return;
    }
    
    // Start thinking animation
    _thinkingController.repeat(reverse: true);
    
    // Analyze the drawing
    await ref.read(colorCircleControllerProvider.notifier).analyzeDrawing(imageBytes);
    
    // Stop thinking, show result
    _thinkingController.stop();
    _resultSlideController.forward(from: 0);
  }

  void _onClearCanvas() {
    _canvasStateKey.currentState?.clear();
    ref.read(colorCircleControllerProvider.notifier).clearCanvas();
  }

  void _onTryAgain() {
    _resultSlideController.reverse();
    ref.read(colorCircleControllerProvider.notifier).resetForRetry();
  }

  void _onComplete() {
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(textRefreshProvider);
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(colorCircleControllerProvider);
    
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Stack(
          children: [
            _buildBackground(isDark),
            
            Column(
              children: [
                _buildAppBar(colors),
                
                _buildPixySection(state, colors),
                
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildCanvasSection(state, colors),
                  ),
                ),
                
                // Color palette with eraser
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: ColorPalette(
                    colors: ColorPalette.defaultColors,
                    selectedColor: state.selectedColor,
                    onColorSelected: (color) {
                      setState(() => _isEraserSelected = false);
                      ref.read(colorCircleControllerProvider.notifier).selectColor(color);
                    },
                    showEraser: true,
                    isEraserSelected: _isEraserSelected,
                    onEraserSelected: () {
                      setState(() => _isEraserSelected = true);
                    },
                  ),
                ),
                
                // Action buttons (extra bottom padding for navbar)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    0,
                    24,
                    MediaQuery.of(context).padding.bottom + 80,
                  ),
                  child: _buildActionButtons(state, colors),
                ),
              ],
            ),
            
            if (state.isAnalyzing) _buildThinkingOverlay(colors),
            if (state.showResult) _buildResultOverlay(state, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground(bool isDark) {
    final topA = isDark ? 0.2 : 0.3;
    final botA = isDark ? 0.14 : 0.22;
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -50,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.drawingRed.withValues(alpha: topA),
                  AppColors.drawingRed.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -50,
          left: -80,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.missionPeach.withValues(alpha: botA),
                  AppColors.missionPeach.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(AppColorsExtension colors) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                size: 20,
                color: colors.textPrimary,
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Drawing.subtitle,
                  style: GoogleFonts.alata(
                    fontSize: 12,
                    color: AppColors.drawingRed,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  Drawing.colorCircleTitle,
                  style: GoogleFonts.alata(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPixySection(ColorCircleState state, AppColorsExtension colors) {
    String pixyAsset = _getPixyAsset(state.pixyEmotion);
    String message = _getPixyMessage(state);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          // Pixy mascot
          AnimatedBuilder(
            animation: state.isAnalyzing ? _thinkingRotation : _pixyBounce,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, state.isAnalyzing ? 0 : -_pixyBounce.value),
                child: Transform.rotate(
                  angle: state.isAnalyzing ? _thinkingRotation.value : 0,
                  child: child,
                ),
              );
            },
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: colors.cardColor,
                shape: BoxShape.circle,
                border: Border.all(color: colors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.drawingRed.withValues(alpha: 0.28),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  pixyAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.smart_toy,
                    size: 40,
                    color: AppColors.drawingRed,
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Text(
                message,
                style: GoogleFonts.alata(
                  fontSize: 14,
                  color: colors.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPixyAsset(String emotion) {
    switch (emotion) {
      case 'thinking':
        return AppAssets.welcomePage2Thinking;
      case 'happy':
      case 'encouraging':
        return AppAssets.welcomePage1Hello;
      default:
        return AppAssets.welcomePage1Hello;
    }
  }

  String _getPixyMessage(ColorCircleState state) {
    if (state.isAnalyzing) {
      return Drawing.colorCircleThinking;
    }
    if (state.showResult && state.analysisResult != null) {
      return state.analysisResult!.message;
    }
    return Drawing.colorCircleInstruction;
  }

  Widget _buildCanvasSection(ColorCircleState state, AppColorsExtension colors) {
    final outlineColor = Color.lerp(colors.textSecondary, colors.border, 0.35)!;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            DrawingCanvas(
              key: _canvasStateKey,
              repaintKey: _canvasKey,
              selectedColor: state.selectedColor,
              strokeWidth: 20.0,
              backgroundColor: colors.surface,
              isEraserMode: _isEraserSelected,
              onDrawingChanged: () {
                ref.read(colorCircleControllerProvider.notifier).setHasDrawing(true);
              },
            ),
            IgnorePointer(
              child: CustomPaint(
                size: Size.infinite,
                painter: CircleOutlinePainter(strokeColor: outlineColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(ColorCircleState state, AppColorsExtension colors) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: GestureDetector(
            onTap: _onClearCanvas,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: colors.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colors.border,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.refresh,
                      color: colors.iconColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      Drawing.clear,
                      style: GoogleFonts.alata(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 16),
        
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: state.isAnalyzing ? null : _onCheckDrawing,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.drawingRed, AppColors.orangeAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.drawingRed.withValues(alpha: 0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  Drawing.checkColoringSparkle,
                  style: GoogleFonts.alata(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThinkingOverlay(AppColorsExtension colors) {
    return Container(
      color: Colors.black.withValues(alpha: 0.32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: colors.cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 30,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _thinkingRotation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _thinkingRotation.value,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: colors.inputFill,
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        AppAssets.welcomePage2Thinking,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.smart_toy,
                          size: 50,
                          color: AppColors.drawingRed,
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                Text(
                  Drawing.pixyCheckingTitle,
                  style: GoogleFonts.alata(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  Drawing.colorCircleAnalyzingSub,
                  style: GoogleFonts.alata(
                    fontSize: 14,
                    color: colors.textSecondary,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.drawingRed),
                    strokeWidth: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultOverlay(ColorCircleState state, AppColorsExtension colors) {
    final result = state.analysisResult;
    if (result == null) return const SizedBox.shrink();
    
    final isCorrect = result.isCorrect;
    final accent = isCorrect ? AppColors.success : AppColors.warning;
    
    return SlideTransition(
      position: _resultSlide,
      child: Container(
        color: Colors.black.withValues(alpha: 0.42),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: colors.cardColor,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: colors.border),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.28),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isCorrect
                            ? [AppColors.success, AppColors.correctGreen]
                            : [AppColors.warning, AppColors.orangeAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      isCorrect ? Icons.check_rounded : Icons.lightbulb_outline,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Text(
                    isCorrect ? Drawing.resultPerfect : Drawing.almostTitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.alata(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Text(
                    result.message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.alata(
                      fontSize: 16,
                      color: colors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  if (isCorrect)
                    _buildGradientButton(
                      onTap: _onComplete,
                      label: Drawing.continueAction,
                      gradientColors: [AppColors.success, AppColors.correctGreen],
                    )
                  else
                    Column(
                      children: [
                        _buildGradientButton(
                          onTap: _onTryAgain,
                          label: Drawing.tryAgain,
                          gradientColors: [
                            AppColors.drawingRed,
                            AppColors.orangeAccent,
                          ],
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required VoidCallback onTap,
    required String label,
    required List<Color> gradientColors,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.alata(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter for the pre-drawn circle outline
class CircleOutlinePainter extends CustomPainter {
  CircleOutlinePainter({required this.strokeColor});

  final Color strokeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
    
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width < size.height ? size.width : size.height) * 0.42;
    
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CircleOutlinePainter oldDelegate) =>
      oldDelegate.strokeColor != strokeColor;
}
