import 'package:flutter/material.dart';

import 'package:thinky/shared_controls/assets/app_assets.dart';

enum AnimalsMascotKind { pixy, professor }

/// Mascot head that peeks above a card.
///
/// Mirrors the `QuizMascotBehindCard` / `ProfessorHeadAbovePanel` pattern used
/// across the app so Teach Pixy Animals stays visually consistent.
class AnimalsMascotHead extends StatelessWidget {
  const AnimalsMascotHead({
    super.key,
    required this.kind,
    required this.width,
    required this.viewportHeight,
    this.imageScale,
    this.offsetY,
  });

  final AnimalsMascotKind kind;
  final double width;
  final double viewportHeight;
  final double? imageScale;
  final double? offsetY;

  @override
  Widget build(BuildContext context) {
    final asset = switch (kind) {
      AnimalsMascotKind.pixy => AppAssets.welcomePage2Thinking,
      AnimalsMascotKind.professor => AppAssets.missionQuizProfessor,
    };
    final scale = imageScale ??
        (kind == AnimalsMascotKind.professor ? 1.32 : 1.15);
    final offset = offsetY ?? (kind == AnimalsMascotKind.professor ? -36 : -20);

    return SizedBox(
      width: width,
      height: viewportHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Transform.translate(
            offset: Offset(0, offset),
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.bottomCenter,
              child: Image.asset(
                asset,
                width: width,
                fit: BoxFit.fitWidth,
                alignment: Alignment.topCenter,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, __, ___) => Icon(
                  kind == AnimalsMascotKind.professor
                      ? Icons.school_rounded
                      : Icons.smart_toy_rounded,
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
