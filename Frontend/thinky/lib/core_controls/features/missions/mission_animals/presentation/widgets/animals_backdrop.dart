import 'package:flutter/material.dart';

import 'package:thinky/shared_controls/theme/app_colors.dart';
import 'package:thinky/shared_controls/theme/app_colors_extension.dart';

/// Purple gradient + decorative circles used on every Animals mission screen,
/// matching the look of the Quiz and Pixy Learns missions.
class AnimalsBackdrop extends StatelessWidget {
  const AnimalsBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        const Color(0xFF4A5288),
                        const Color(0xFF353A5C),
                        colors.background,
                      ]
                    : [
                        const Color(0xFF9DAAFF),
                        const Color(0xFFE8EAFF),
                        colors.background,
                      ],
                stops: const [0.0, 0.28, 0.55],
              ),
            ),
          ),
        ),
        Positioned(
          top: -60,
          right: -40,
          child: IgnorePointer(
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: isDark ? 0.06 : 0.35),
              ),
            ),
          ),
        ),
        Positioned(
          top: 120,
          left: -50,
          child: IgnorePointer(
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryPurple.withValues(
                  alpha: isDark ? 0.12 : 0.18,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
