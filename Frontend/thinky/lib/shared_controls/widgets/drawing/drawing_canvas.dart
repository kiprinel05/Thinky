import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A point in the drawing with its color and stroke width
class DrawingPoint {
  final Offset offset;
  final Color color;
  final double strokeWidth;
  final bool isNewStroke;

  DrawingPoint({
    required this.offset,
    required this.color,
    this.strokeWidth = 8.0,
    this.isNewStroke = false,
  });
}

/// Interactive drawing canvas widget
class DrawingCanvas extends StatefulWidget {
  final Color selectedColor;
  final double strokeWidth;
  final Color backgroundColor;
  final VoidCallback? onDrawingChanged;
  final GlobalKey? repaintKey;

  const DrawingCanvas({
    super.key,
    this.selectedColor = Colors.blue,
    this.strokeWidth = 8.0,
    this.backgroundColor = Colors.white,
    this.onDrawingChanged,
    this.repaintKey,
  });

  @override
  State<DrawingCanvas> createState() => DrawingCanvasState();
}

class DrawingCanvasState extends State<DrawingCanvas> {
  final List<DrawingPoint> _points = [];
  final GlobalKey _canvasKey = GlobalKey();
  bool _isDrawing = false;

  /// Clear all drawings
  void clear() {
    setState(() {
      _points.clear();
    });
    widget.onDrawingChanged?.call();
  }

  /// Check if canvas has any drawings
  bool get hasDrawing => _points.isNotEmpty;

  /// Export the canvas to PNG bytes
  Future<Uint8List?> exportToPng() async {
    try {
      final keyToUse = widget.repaintKey ?? _canvasKey;
      final boundary = keyToUse.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      
      if (boundary == null) {
        debugPrint('DrawingCanvas: Could not find render boundary');
        return null;
      }

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) {
        debugPrint('DrawingCanvas: Could not convert to byte data');
        return null;
      }

      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint('DrawingCanvas: Error exporting to PNG: $e');
      return null;
    }
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDrawing = true;
      _points.add(DrawingPoint(
        offset: details.localPosition,
        color: widget.selectedColor,
        strokeWidth: widget.strokeWidth,
        isNewStroke: true,
      ));
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDrawing) return;
    
    setState(() {
      _points.add(DrawingPoint(
        offset: details.localPosition,
        color: widget.selectedColor,
        strokeWidth: widget.strokeWidth,
        isNewStroke: false,
      ));
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _isDrawing = false;
    widget.onDrawingChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: widget.repaintKey ?? _canvasKey,
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CustomPaint(
              painter: _DrawingPainter(
                points: _points,
                backgroundColor: widget.backgroundColor,
              ),
              size: Size.infinite,
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter for drawing strokes
class _DrawingPainter extends CustomPainter {
  final List<DrawingPoint> points;
  final Color backgroundColor;

  _DrawingPainter({
    required this.points,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    if (points.isEmpty) return;

    // Draw strokes
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      
      if (point.isNewStroke || i == 0) {
        // Start of new stroke - draw a dot
        final dotPaint = Paint()
          ..color = point.color
          ..strokeWidth = point.strokeWidth
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.fill;
        canvas.drawCircle(point.offset, point.strokeWidth / 2, dotPaint);
      } else {
        // Continue stroke - draw line from previous point
        final prevPoint = points[i - 1];
        final linePaint = Paint()
          ..color = point.color
          ..strokeWidth = point.strokeWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke;
        canvas.drawLine(prevPoint.offset, point.offset, linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) {
    // Always repaint to ensure smooth drawing updates
    return true;
  }
}

/// Color palette for selecting drawing colors
class ColorPalette extends StatelessWidget {
  final List<Color> colors;
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;

  const ColorPalette({
    super.key,
    required this.colors,
    required this.selectedColor,
    required this.onColorSelected,
  });

  static const List<Color> defaultColors = [
    Color(0xFF2196F3), // Blue
    Color(0xFFF44336), // Red
    Color(0xFF4CAF50), // Green
    Color(0xFFFFEB3B), // Yellow
    Color(0xFF9C27B0), // Purple
    Color(0xFFFF9800), // Orange
    Color(0xFF000000), // Black
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: colors.map((color) {
          final isSelected = color == selectedColor;
          return GestureDetector(
            onTap: () => onColorSelected(color),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSelected ? 44 : 36,
              height: isSelected ? 44 : 36,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.transparent,
                  width: 3,
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: color.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }
}
