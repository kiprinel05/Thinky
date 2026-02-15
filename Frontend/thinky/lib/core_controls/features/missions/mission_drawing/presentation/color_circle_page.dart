import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:thinky/shared_controls/widgets/drawing/drawing_canvas.dart';
import 'package:thinky/shared_controls/theme/app_colors.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Color the circle first!',
            style: GoogleFonts.alata(),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Export canvas to PNG
    final imageBytes = await canvasState.exportToPng();
    if (imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not capture drawing. Try again!',
            style: GoogleFonts.alata(),
          ),
          backgroundColor: AppColors.error,
        ),
      );
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
    final state = ref.watch(colorCircleControllerProvider);
    
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      body: SafeArea(
        child: Stack(
          children: [
            // Background decorations
            _buildBackground(),
            
            // Main content
            Column(
              children: [
                // App bar
                _buildAppBar(),
                
                // Pixy mascot with emotion
                _buildPixySection(state),
                
                // Drawing canvas with pre-drawn circle
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildCanvasSection(state),
                  ),
                ),
                
                // Color palette
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: ColorPalette(
                    colors: ColorPalette.defaultColors,
                    selectedColor: state.selectedColor,
                    onColorSelected: (color) {
                      ref.read(colorCircleControllerProvider.notifier).selectColor(color);
                    },
                  ),
                ),
                
                // Action buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: _buildActionButtons(state),
                ),
              ],
            ),
            
            // Thinking overlay
            if (state.isAnalyzing) _buildThinkingOverlay(),
            
            // Result overlay
            if (state.showResult) _buildResultOverlay(state),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        // Top gradient blob - orange theme
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
                  const Color(0xFFFF5722).withOpacity(0.3),
                  const Color(0xFFFF5722).withOpacity(0.0),
                ],
              ),
            ),
          ),
        ),
        // Bottom gradient blob
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
                  const Color(0xFFE91E63).withOpacity(0.2),
                  const Color(0xFFE91E63).withOpacity(0.0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 20,
                color: Color(0xFF3F414E),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Creative Mission',
                  style: GoogleFonts.alata(
                    fontSize: 12,
                    color: const Color(0xFFFF5722),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Color the Circle Red',
                  style: GoogleFonts.alata(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3F414E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPixySection(ColorCircleState state) {
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
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF5722).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  pixyAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.smart_toy,
                    size: 40,
                    color: Color(0xFFFF5722),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Text(
                message,
                style: GoogleFonts.alata(
                  fontSize: 14,
                  color: const Color(0xFF3F414E),
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
        return 'assets/welcome/page1/robot.png';
      case 'happy':
        return 'assets/welcome/page1/robot.png';
      case 'encouraging':
        return 'assets/welcome/page1/robot.png';
      case 'hint_color':
        return 'assets/welcome/page1/robot.png';
      default:
        return 'assets/welcome/page1/robot.png';
    }
  }

  String _getPixyMessage(ColorCircleState state) {
    if (state.isAnalyzing) {
      return 'Hmm, let me check your coloring... 🤔';
    }
    if (state.showResult && state.analysisResult != null) {
      return state.analysisResult!.message;
    }
    return 'Color the circle using RED! Stay inside the lines! 🎨';
  }

  Widget _buildCanvasSection(ColorCircleState state) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Drawing canvas (for user input)
            DrawingCanvas(
              key: _canvasStateKey,
              repaintKey: _canvasKey,
              selectedColor: state.selectedColor,
              strokeWidth: 20.0, // Thicker for coloring
              backgroundColor: Colors.white,
              onDrawingChanged: () {
                ref.read(colorCircleControllerProvider.notifier).setHasDrawing(true);
              },
            ),
            // Pre-drawn circle outline overlay
            IgnorePointer(
              child: CustomPaint(
                size: Size.infinite,
                painter: CircleOutlinePainter(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(ColorCircleState state) {
    return Row(
      children: [
        // Clear button
        Expanded(
          flex: 1,
          child: GestureDetector(
            onTap: _onClearCanvas,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFE0E0E0),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.refresh,
                      color: Color(0xFF8A8A8F),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Clear',
                      style: GoogleFonts.alata(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF8A8A8F),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Check drawing button
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: state.isAnalyzing ? null : _onCheckDrawing,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF5722), Color(0xFFFF8A65)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF5722).withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'Check Coloring ✨',
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

  Widget _buildThinkingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 30,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Thinking Pixy
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
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF8F5),
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/welcome/page1/robot.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.smart_toy,
                          size: 50,
                          color: Color(0xFFFF5722),
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                Text(
                  'Pixy is checking...',
                  style: GoogleFonts.alata(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3F414E),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'Looking at your beautiful coloring! 🎨',
                  style: GoogleFonts.alata(
                    fontSize: 14,
                    color: const Color(0xFF8A8A8F),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF5722)),
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

  Widget _buildResultOverlay(ColorCircleState state) {
    final result = state.analysisResult;
    if (result == null) return const SizedBox.shrink();
    
    final isCorrect = result.isCorrect;
    
    return SlideTransition(
      position: _resultSlide,
      child: Container(
        color: Colors.black.withOpacity(0.4),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: (isCorrect ? const Color(0xFF4CAF50) : const Color(0xFFFF9800))
                        .withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Result icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isCorrect
                            ? [const Color(0xFF4CAF50), const Color(0xFF81C784)]
                            : [const Color(0xFFFF9800), const Color(0xFFFFB74D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isCorrect ? const Color(0xFF4CAF50) : const Color(0xFFFF9800))
                              .withOpacity(0.4),
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
                  
                  // Title
                  Text(
                    isCorrect ? 'Perfect! 🎉' : 'Almost there!',
                    style: GoogleFonts.alata(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3F414E),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Message
                  Text(
                    result.message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.alata(
                      fontSize: 16,
                      color: const Color(0xFF8A8A8F),
                      height: 1.5,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Action buttons
                  if (isCorrect)
                    _buildGradientButton(
                      onTap: _onComplete,
                      label: 'Continue',
                      colors: [const Color(0xFF4CAF50), const Color(0xFF81C784)],
                    )
                  else
                    Column(
                      children: [
                        _buildGradientButton(
                          onTap: _onTryAgain,
                          label: 'Try Again',
                          colors: [const Color(0xFFFF5722), const Color(0xFFFF8A65)],
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
    required List<Color> colors,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colors.first.withOpacity(0.4),
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
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF424242) // Dark gray outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
    
    // Draw circle in the center of the canvas
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width < size.height ? size.width : size.height) * 0.35;
    
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
