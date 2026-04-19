import 'package:flutter/material.dart';

import 'package:thinky/shared_controls/theme/app_colors.dart';

/// A small custom-painted Pixy mascot — a friendly purple robot face. Used
/// across the chat (avatar, header, suggestion chips). No image asset
/// required so it scales crisply at any size and theme.
class PixyAvatar extends StatelessWidget {
  final double size;
  final bool withGlow;
  final Color? backgroundColor;

  const PixyAvatar({
    super.key,
    this.size = 40,
    this.withGlow = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.primaryPurple;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            bg,
            HSLColor.fromColor(bg).withLightness(0.55).toColor(),
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.32),
        boxShadow: withGlow
            ? [
                BoxShadow(
                  color: bg.withValues(alpha: 0.35),
                  blurRadius: size * 0.4,
                  offset: const Offset(0, 4),
                ),
              ]
            : const [],
      ),
      child: CustomPaint(
        painter: _PixyFacePainter(),
      ),
    );
  }
}

class _PixyFacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final whitePaint = Paint()..color = Colors.white;
    final eyePaint = Paint()..color = AppColors.primaryPurple;
    final cheekPaint = Paint()
      ..color = const Color(0xFFFFB59E).withValues(alpha: 0.55);

    // Antenna dot.
    canvas.drawCircle(Offset(w * 0.5, h * 0.12), w * 0.05, whitePaint);
    canvas.drawLine(
      Offset(w * 0.5, h * 0.17),
      Offset(w * 0.5, h * 0.27),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..strokeWidth = w * 0.04
        ..strokeCap = StrokeCap.round,
    );

    // Face plate (rounded rect).
    final faceRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.18, h * 0.32, w * 0.64, h * 0.5),
      Radius.circular(w * 0.12),
    );
    canvas.drawRRect(faceRect, whitePaint);

    // Eyes.
    canvas.drawCircle(Offset(w * 0.36, h * 0.55), w * 0.07, eyePaint);
    canvas.drawCircle(Offset(w * 0.64, h * 0.55), w * 0.07, eyePaint);

    // Eye highlights.
    final highlight = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(w * 0.38, h * 0.53), w * 0.022, highlight);
    canvas.drawCircle(Offset(w * 0.66, h * 0.53), w * 0.022, highlight);

    // Cheeks.
    canvas.drawCircle(Offset(w * 0.3, h * 0.7), w * 0.05, cheekPaint);
    canvas.drawCircle(Offset(w * 0.7, h * 0.7), w * 0.05, cheekPaint);

    // Smile.
    final smile = Path()
      ..moveTo(w * 0.42, h * 0.7)
      ..quadraticBezierTo(w * 0.5, h * 0.78, w * 0.58, h * 0.7);
    canvas.drawPath(
      smile,
      Paint()
        ..color = AppColors.primaryPurple
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.035
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _PixyFacePainter oldDelegate) => false;
}
