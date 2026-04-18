import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:thinky/shared_controls/theme/app_colors_extension.dart';
import 'package:thinky/shared_controls/widgets/animations/animated_widgets.dart';

import 'animals_mascots.dart';

/// Quiz-style feedback overlay: blurred backdrop + mascot + card + CTA.
///
/// Used after the user verifies Pixy's guess and after submitting teaching.
/// The callback decides what happens next (advance, retry, ...).
class AnimalsFeedbackOverlay extends StatelessWidget {
  const AnimalsFeedbackOverlay({
    super.key,
    required this.accentColor,
    required this.icon,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.mascot = AnimalsMascotKind.professor,
    this.isBusy = false,
  });

  final Color accentColor;
  final IconData icon;
  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final AnimalsMascotKind mascot;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.black.withValues(alpha: isDark ? 0.52 : 0.28),
            ),
          ),
        ),
        Center(
          child: FadeInWidget(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxW = constraints.maxWidth.clamp(0.0, 400.0);
                  final mascotW = (maxW * 0.48).clamp(150.0, 200.0);
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimalsMascotHead(
                        kind: mascot,
                        width: mascotW,
                        viewportHeight: 188,
                      ),
                      Transform.translate(
                        offset: const Offset(0, -36),
                        child: Material(
                          color: colors.cardColor,
                          elevation: isDark ? 16 : 12,
                          shadowColor: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(28),
                          child: Container(
                            width: maxW,
                            padding: const EdgeInsets.fromLTRB(22, 36, 22, 22),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: colors.border.withValues(alpha: 0.65),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: accentColor.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    icon,
                                    size: 28,
                                    color: accentColor,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  title,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.alata(
                                    fontSize: 17,
                                    color: accentColor,
                                    fontWeight: FontWeight.w800,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  message,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.alata(
                                    fontSize: 15,
                                    color: colors.textPrimary,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 22),
                                if (secondaryLabel != null &&
                                    onSecondary != null) ...[
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      onPressed: isBusy ? null : onSecondary,
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                          color: accentColor,
                                          width: 2,
                                        ),
                                        foregroundColor: accentColor,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: Text(
                                        secondaryLabel!,
                                        style: GoogleFonts.alata(
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    onPressed: isBusy ? null : onPrimary,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: accentColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: isBusy
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : Text(
                                            primaryLabel,
                                            style: GoogleFonts.alata(
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.6,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
