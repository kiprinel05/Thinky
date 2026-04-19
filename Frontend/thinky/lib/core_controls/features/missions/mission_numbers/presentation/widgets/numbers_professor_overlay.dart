import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thinky/core_controls/constants/app_texts.dart';
import 'package:thinky/shared_controls/theme/app_colors.dart';
import 'package:thinky/shared_controls/theme/app_colors_extension.dart';

/// Shared "professor steps in" modal for the Numbers mission.
///
/// Renders consistently across the counting and drawing pages: orange palette
/// (matches the rest of the mission, instead of the old indigo
/// [AppColors.numbersPrimary]), gentle slide-in card, optional title and hint.
class NumbersProfessorOverlay extends StatelessWidget {
  /// Slide animation driven by the parent (so it can be reused with the page's
  /// existing AnimationController).
  final Animation<Offset> slideAnimation;
  final String message;

  /// Optional title shown above the message (defaults to "The teacher says:").
  final String? title;

  /// Optional secondary hint (e.g. "How to draw a 3" hint).
  final String? hint;

  /// Optional explicit label for the dismiss button (defaults to
  /// "I UNDERSTAND!").
  final String? understoodLabel;
  final VoidCallback onUnderstood;

  const NumbersProfessorOverlay({
    super.key,
    required this.slideAnimation,
    required this.message,
    required this.onUnderstood,
    this.title,
    this.hint,
    this.understoodLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark
        ? AppColors.numbersOrangeLight
        : AppColors.numbersOrangeDark;
    final resolvedTitle = title ?? NumbersMission.professorSays;
    final resolvedAction = understoodLabel ?? NumbersMission.professorUnderstood;

    return Container(
      color: Colors.black.withValues(alpha: 0.45),
      child: Center(
        child: SlideTransition(
          position: slideAnimation,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
            decoration: BoxDecoration(
              color: colors.cardColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppColors.numbersOrange.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.numbersOrange.withValues(alpha: 0.18),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.numbersOrange.withValues(alpha: 0.18),
                        AppColors.numbersOrangeLight.withValues(alpha: 0.10),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.numbersOrange.withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Text('👨‍🏫', style: TextStyle(fontSize: 44)),
                ),
                const SizedBox(height: 16),
                Text(
                  resolvedTitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.alata(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.alata(
                    fontSize: 14,
                    height: 1.55,
                    color: colors.textPrimary,
                  ),
                ),
                if (hint != null && hint!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.numbersOrange.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.numbersOrange.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('💡', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            hint!,
                            style: GoogleFonts.alata(
                              fontSize: 12,
                              color: accent,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onUnderstood,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.numbersOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      resolvedAction,
                      style: GoogleFonts.alata(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
