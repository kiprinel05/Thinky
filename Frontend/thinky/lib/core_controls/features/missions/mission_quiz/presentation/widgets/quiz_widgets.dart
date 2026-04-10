import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:thinky/shared_controls/assets/app_assets.dart';
import 'package:thinky/shared_controls/theme/app_colors_extension.dart';

class ProfessorHeadAbovePanel extends StatelessWidget {
  const ProfessorHeadAbovePanel({
    super.key,
    required this.width,
    required this.viewportHeight,
    this.imageScale = 1.2,
    this.imageOffsetY = 0,
  });

  final double width;
  final double viewportHeight;
  final double imageScale;
  final double imageOffsetY;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: viewportHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Transform.translate(
            offset: Offset(0, imageOffsetY),
            child: Transform.scale(
              scale: imageScale,
              alignment: Alignment.bottomCenter,
              child: Image.asset(
                AppAssets.missionQuizProfessor,
                width: width,
                fit: BoxFit.fitWidth,
                alignment: Alignment.topCenter,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.school_rounded,
                  size: width * 0.45,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QuizMascotBehindCard extends StatelessWidget {
  const QuizMascotBehindCard({
    super.key,
    required this.width,
    required this.slotHeight,
    this.imageScale = 1.12,
    this.offsetY = 0,
  });

  final double width;
  final double slotHeight;
  final double imageScale;
  final double offsetY;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: slotHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Transform.translate(
            offset: Offset(0, offsetY),
            child: Transform.scale(
              scale: imageScale,
              alignment: Alignment.bottomCenter,
              child: Image.asset(
                AppAssets.welcomePage2Thinking,
                width: width,
                fit: BoxFit.fitWidth,
                alignment: Alignment.topCenter,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.smart_toy_rounded,
                  size: width * 0.48,
                  color: Colors.white.withValues(alpha: 0.95),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QuizSummaryStatRow extends StatelessWidget {
  const QuizSummaryStatRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.colors,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final AppColorsExtension colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.inputFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.alata(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.alata(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }
}
