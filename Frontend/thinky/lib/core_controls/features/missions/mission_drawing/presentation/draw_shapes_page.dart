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
import 'controllers/drawing_controller.dart';
import 'draw_shapes_learning_view.dart';

/// Draw Shapes Mission Page
///
/// 3 rounds: triangle (blue), circle (red), square (green).
/// Outline drawings accepted (no fill required).
class DrawShapesPage extends ConsumerStatefulWidget {
  const DrawShapesPage({super.key});

  @override
  ConsumerState<DrawShapesPage> createState() => _DrawShapesPageState();
}

class _DrawShapesPageState extends ConsumerState<DrawShapesPage>
    with TickerProviderStateMixin {
  final GlobalKey _canvasKey = GlobalKey();
  final GlobalKey<DrawingCanvasState> _canvasStateKey = GlobalKey<DrawingCanvasState>();
  final bool _isEraserSelected = false;
  
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
      ErrorHandlerUI.showWarning(context, Drawing.drawFirst);
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
    await ref.read(drawingControllerProvider.notifier).analyzeDrawing(imageBytes);
    
    // Stop thinking, show result
    _thinkingController.stop();
    _resultSlideController.forward(from: 0);
  }

  void _onClearCanvas() {
    _canvasStateKey.currentState?.clear();
    ref.read(drawingControllerProvider.notifier).clearCanvas();
  }

  void _onTryAgain() {
    _resultSlideController.reverse();
    ref.read(drawingControllerProvider.notifier).resetForRetry();
  }

  void _onNextRound() {
    _resultSlideController.reverse();
    _canvasStateKey.currentState?.clear();
    ref.read(drawingControllerProvider.notifier).nextRound();
  }

  void _onComplete() {
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(textRefreshProvider);
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(drawingControllerProvider);
    
    if (state.showLearning) {
      return Scaffold(
        body: DrawShapesLearningView(
          onDone: () => ref.read(drawingControllerProvider.notifier).closeLearning(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Stack(
          children: [
            _buildBackground(isDark),
            
            Column(
              children: [
                _buildAppBar(state, colors),
                
                _buildPixySection(state, colors),
                
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildCanvasSection(state, colors),
                  ),
                ),
                
                // Color palette
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: ColorPalette(
                    colors: ColorPalette.defaultColors,
                    selectedColor: state.selectedColor,
                    onColorSelected: (color) {
                      ref.read(drawingControllerProvider.notifier).selectColor(color);
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
    final topA = isDark ? 0.18 : 0.3;
    final botA = isDark ? 0.12 : 0.2;
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
                  AppColors.primaryPurple.withValues(alpha: topA),
                  AppColors.primaryPurple.withValues(alpha: 0.0),
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
                  AppColors.missionYellow.withValues(alpha: botA),
                  AppColors.missionYellow.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(DrawingState state, AppColorsExtension colors) {
    final config = state.currentRoundConfig;
    final roundTitle =
        '${Drawing.drawPromptPart1}${_shapeLabel(config.shape)}${Drawing.drawPromptPart2}${_colorLabel(config.color)}${Drawing.drawPromptPart3}';
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
                  '${Drawing.missionDrawShapes} • ${Drawing.roundCaption} ${state.currentRound}/${state.totalRounds}',
                  style: GoogleFonts.alata(
                    fontSize: 12,
                    color: AppColors.primaryPurple,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  roundTitle,
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

  String _shapeLabel(String shape) {
    switch (shape) {
      case 'triangle':
        return Drawing.shapeTriangle;
      case 'circle':
        return Drawing.shapeCircle;
      case 'square':
        return Drawing.shapeSquare;
      default:
        return shape;
    }
  }

  String _colorLabel(String color) {
    switch (color) {
      case 'blue':
        return Drawing.colorNameBlue;
      case 'red':
        return Drawing.colorNameRed;
      case 'green':
        return Drawing.colorNameGreen;
      default:
        return color;
    }
  }

  Widget _buildPixySection(DrawingState state, AppColorsExtension colors) {
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
                    color: AppColors.primaryPurple.withValues(alpha: 0.28),
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
                    color: AppColors.primaryPurple,
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Speech bubble
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
      case 'hint_color':
        return AppAssets.welcomePage1Hello;
      default:
        return AppAssets.welcomePage1Hello;
    }
  }

  String _getPixyMessage(DrawingState state) {
    if (state.isAnalyzing) {
      return Drawing.thinking;
    }
    if (state.showResult && state.analysisResult != null) {
      return state.analysisResult!.message;
    }
    final config = state.currentRoundConfig;
    return '${Drawing.drawPromptPart1}${_shapeLabel(config.shape)}${Drawing.drawPromptPart2}${_colorLabel(config.color)}${Drawing.drawPromptPart3}';
  }

  Widget _buildCanvasSection(DrawingState state, AppColorsExtension colors) {
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
        child: DrawingCanvas(
          key: _canvasStateKey,
          repaintKey: _canvasKey,
          selectedColor: state.selectedColor,
          strokeWidth: 12.0,
          isEraserMode: _isEraserSelected,
          onDrawingChanged: () {
            ref.read(drawingControllerProvider.notifier).setHasDrawing(true);
          },
        ),
      ),
    );
  }

  Widget _buildActionButtons(DrawingState state, AppColorsExtension colors) {
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
                gradient: const LinearGradient(
                  colors: [AppColors.primaryPurple, AppColors.primaryPurpleLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryPurple.withValues(alpha: 0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  Drawing.checkDrawingSparkle,
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
                          color: AppColors.primaryPurple,
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                Text(
                  Drawing.thinkingTitle,
                  style: GoogleFonts.alata(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  Drawing.analyzingMessage,
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
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
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

  Widget _buildResultOverlay(DrawingState state, AppColorsExtension colors) {
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
                    isCorrect
                        ? '${Drawing.successTitle} ${Drawing.successEmoji}'
                        : Drawing.almostTitle,
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
                  
                  if (isCorrect && state.currentRound < state.totalRounds)
                    _buildGradientButton(
                      onTap: _onNextRound,
                      label: Drawing.nextRound,
                      gradientColors: [AppColors.success, AppColors.correctGreen],
                    )
                  else if (isCorrect)
                    Column(
                      children: [
                        _buildGradientButton(
                          onTap: () => ref.read(drawingControllerProvider.notifier).openLearning(),
                          label: Drawing.shapesLessonButton,
                          gradientColors: [AppColors.primaryPurple, AppColors.primaryPurpleLight],
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _onComplete,
                          child: Text(
                            Drawing.shapesBackToMissions,
                            style: GoogleFonts.alata(
                              fontSize: 14,
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _buildGradientButton(
                          onTap: _onTryAgain,
                          label: Drawing.tryAgain,
                          gradientColors: [
                            AppColors.primaryPurple,
                            AppColors.primaryPurpleLight,
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
