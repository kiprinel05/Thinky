import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:thinky/core/errors/error_logger.dart';
import 'package:thinky/shared_controls/theme/app_colors.dart';
import 'package:thinky/shared_controls/theme/app_colors_extension.dart';

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

/// Interactive drawing canvas widget.
/// Canvas is always white (like paper) regardless of theme — this ensures
/// consistent backend analysis and proper eraser behaviour.
class DrawingCanvas extends StatefulWidget {
  final Color selectedColor;
  final double strokeWidth;
  final VoidCallback? onDrawingChanged;
  final GlobalKey? repaintKey;
  final bool isEraserMode;

  /// Always white — drawing surfaces should behave like paper.
  Color get backgroundColor => Colors.white;

  const DrawingCanvas({
    super.key,
    this.selectedColor = AppColors.drawingBlue,
    this.strokeWidth = 8.0,
    this.onDrawingChanged,
    this.repaintKey,
    this.isEraserMode = false,
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
        ErrorLogger().logError('DrawingCanvas: Could not find render boundary');
        return null;
      }

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) {
        ErrorLogger().logError('DrawingCanvas: Could not convert to byte data');
        return null;
      }

      return byteData.buffer.asUint8List();
    } catch (e, stack) {
      ErrorLogger().logError(e, stackTrace: stack);
      return null;
    }
  }

  Color get _effectiveColor =>
      widget.isEraserMode ? widget.backgroundColor : widget.selectedColor;

  /// Min distance between points to reduce lag (fewer points = smoother)
  static const double _minPointDistance = 4.0;

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDrawing = true;
      _points.add(DrawingPoint(
        offset: details.localPosition,
        color: _effectiveColor,
        strokeWidth: widget.isEraserMode ? widget.strokeWidth * 1.5 : widget.strokeWidth,
        isNewStroke: true,
      ));
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDrawing) return;
    final pos = details.localPosition;
    // Decimate: only add point if far enough from last - reduces lag dramatically
    if (_points.isNotEmpty) {
      final last = _points.last.offset;
      final dx = pos.dx - last.dx;
      final dy = pos.dy - last.dy;
      if (dx * dx + dy * dy < _minPointDistance * _minPointDistance) return;
    }
    setState(() {
      _points.add(DrawingPoint(
        offset: pos,
        color: _effectiveColor,
        strokeWidth: widget.isEraserMode ? widget.strokeWidth * 1.5 : widget.strokeWidth,
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
                  color: AppColors.black.withOpacity(0.1),
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
  final bool showEraser;
  final bool isEraserSelected;
  final VoidCallback? onEraserSelected;

  const ColorPalette({
    super.key,
    required this.colors,
    required this.selectedColor,
    required this.onColorSelected,
    this.showEraser = false,
    this.isEraserSelected = false,
    this.onEraserSelected,
  });

  static const List<Color> defaultColors = [
    AppColors.drawingBlue,
    AppColors.drawingRed,
    AppColors.success,
    Color(0xFFFFEB3B), // Yellow — no matching AppColors token
    AppColors.patternPurple,
    AppColors.orangeAccent,
    AppColors.black,
  ];

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: appColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (showEraser && onEraserSelected != null) ...[
            GestureDetector(
              onTap: onEraserSelected,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isEraserSelected ? 44 : 36,
                height: isEraserSelected ? 44 : 36,
                decoration: BoxDecoration(
                  color: AppColors.greyLight,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isEraserSelected ? AppColors.white : AppColors.transparent,
                    width: 3,
                  ),
                  boxShadow: [
                    if (isEraserSelected)
                      BoxShadow(
                        color: AppColors.grey.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: isEraserSelected ? AppColors.white : appColors.iconColor,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          ...colors.map((color) {
            final isSelected = !isEraserSelected && color == selectedColor;
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
                    color: isSelected ? AppColors.white : AppColors.transparent,
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
                    ? const Icon(Icons.check, color: AppColors.white, size: 20)
                    : null,
              ),
            );
          }),
        ],
      ),
    );
  }
}
