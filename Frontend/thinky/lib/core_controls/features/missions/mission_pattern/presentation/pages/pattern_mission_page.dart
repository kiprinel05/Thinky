import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thinky/core_controls/features/missions/mission_pattern/data/pattern_models.dart';
import 'package:thinky/core/errors/error_logger.dart';
import '../controllers/pattern_controller.dart';

class PatternMissionPage extends ConsumerWidget {
  const PatternMissionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(patternControllerProvider);
    final controller = ref.read(patternControllerProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Complete the Pattern',
          style: GoogleFonts.fredoka(color: Colors.white, fontSize: 24),
        ),
        backgroundColor: const Color(0xFF9C27B0), // Purple
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: _buildBody(context, state, controller),
    );
  }

  Widget _buildBody(
      BuildContext context, PatternState state, PatternController controller) {
    if (state.phase == PatternPhase.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.phase == PatternPhase.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
             const SizedBox(height: 16),
             Text(
              'Something went wrong',
              style: GoogleFonts.fredoka(fontSize: 20, fontWeight: FontWeight.bold),
            ),
             Padding(
               padding: const EdgeInsets.all(16.0),
               child: Text(state.errorMessage ?? 'Unknown error', textAlign: TextAlign.center),
             ),
             ElevatedButton(
               onPressed: controller.startMission,
               child: const Text('Try Again'),
             )
          ],
        ),
      );
    }

    if (state.phase == PatternPhase.missionComplete) {
       return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.stars_rounded, size: 80, color: Colors.amber),
            const SizedBox(height: 20),
            Text(
              'Mission Complete!',
              style: GoogleFonts.fredoka(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9C27B0),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: Text(
                'Back to Menu',
                style: GoogleFonts.fredoka(fontSize: 20, color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    final round = state.currentRound!;
    final isFeedback = state.phase == PatternPhase.feedback;

    return Column(
      children: [
        // 1. Instruction
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            round.instruction,
            style: GoogleFonts.fredoka(fontSize: 24, color: Colors.grey[800]),
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
                    child: _MysteryBox(isRevealed: isFeedback, result: state.lastResult),
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
              color: Colors.purple[50], // Lighter purple bg for options area
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              children: [
                Text(
                  'Choose next:',
                  style: GoogleFonts.fredoka(fontSize: 18, color: Colors.purple[800]),
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected 
                                ? const Color(0xFF9C27B0) 
                                : Colors.grey[300]!,
                            width: isSelected ? 4 : 2,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF9C27B0).withOpacity(0.3),
                                    blurRadius: 10,
                                    spreadRadius: 2,
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
                      ? (state.isCorrect ? Colors.green : Colors.orange)
                      : const Color(0xFF9C27B0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                child: state.phase == PatternPhase.submitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        isFeedback
                            ? (state.isCorrect ? 'Next Pattern' : 'Try Again') 
                            : 'Check Answer',
                        style: GoogleFonts.fredoka(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
          
        // Feedback Message Toast
        if (isFeedback)
           Container(
             padding: const EdgeInsets.all(12),
             decoration: BoxDecoration(
               color: state.isCorrect ? Colors.green[100] : Colors.orange[100],
               borderRadius: BorderRadius.circular(8),
             ),
             width: double.infinity,
             child: Text(
               state.lastResult?.message ?? '',
               textAlign: TextAlign.center,
               style: GoogleFonts.fredoka(
                 color: state.isCorrect ? Colors.green[800] : Colors.orange[800],
                 fontWeight: FontWeight.bold,
                 fontSize: 18
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

  const _MysteryBox({required this.isRevealed, this.result});

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
             color: Colors.white,
             border: Border.all(color: Colors.green, width: 3),
             borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
             Icons.check,
             color: Colors.green,
             size: 40,
          ),
       );
    }
    
    if (widget.isRevealed && widget.result != null && !widget.result!.correct) {
       return Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
             color: Colors.white,
             border: Border.all(color: Colors.red, width: 3),
             borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
             Icons.close,
             color: Colors.red,
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
               color: Colors.grey[200],
               borderRadius: BorderRadius.circular(10),
               border: Border.all(
                  color: const Color(0xFF9C27B0).withOpacity(0.5 + 0.5 * _controller.value),
                  width: 3,
               ),
               boxShadow: [
                  BoxShadow(
                     color: const Color(0xFF9C27B0).withOpacity(0.3 * _controller.value),
                     blurRadius: 10,
                     spreadRadius: 2 * _controller.value,
                  )
               ]
            ),
            child: Center(
               child: Text(
                  '?',
                  style: GoogleFonts.fredoka(
                     fontSize: 32, 
                     fontWeight: FontWeight.bold,
                     color: const Color(0xFF9C27B0),
                  ),
               ),
            ),
         );
      },
    );
  }
}
