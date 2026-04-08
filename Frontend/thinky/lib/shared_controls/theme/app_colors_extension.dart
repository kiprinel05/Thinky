import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Semantic color tokens that resolve automatically based on the active theme.
///
/// Usage in any widget:
/// ```dart
/// final colors = context.appColors;
/// Container(color: colors.background);
/// Text('Hi', style: TextStyle(color: colors.textPrimary));
/// ```
///
/// Pages never need to know whether dark mode is on.
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color background;
  final Color surface;
  final Color cardColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final Color textMuted;
  final Color border;
  final Color divider;
  final Color inputFill;
  final Color iconColor;
  final Color shimmer;

  const AppColorsExtension({
    required this.background,
    required this.surface,
    required this.cardColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.textMuted,
    required this.border,
    required this.divider,
    required this.inputFill,
    required this.iconColor,
    required this.shimmer,
  });

  // ══════════════════════════════════════════════════════════════════════
  // LIGHT instance
  // ══════════════════════════════════════════════════════════════════════

  static const light = AppColorsExtension(
    background: AppColors.backgroundWhite,
    surface: AppColors.backgroundGrey,
    cardColor: AppColors.backgroundGrey,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textHint: AppColors.textHint,
    textMuted: AppColors.textMuted,
    border: AppColors.borderLight,
    divider: AppColors.borderLight,
    inputFill: AppColors.backgroundGrey,
    iconColor: AppColors.textGrey,
    shimmer: AppColors.backgroundLight,
  );

  // ══════════════════════════════════════════════════════════════════════
  // DARK instance
  // ══════════════════════════════════════════════════════════════════════

  static const dark = AppColorsExtension(
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    cardColor: AppColors.darkCard,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    textHint: AppColors.darkTextHint,
    textMuted: AppColors.darkTextHint,
    border: AppColors.darkBorder,
    divider: AppColors.darkBorder,
    inputFill: AppColors.darkCard,
    iconColor: AppColors.darkTextSecondary,
    shimmer: AppColors.darkCard,
  );

  // ══════════════════════════════════════════════════════════════════════
  // Required overrides
  // ══════════════════════════════════════════════════════════════════════

  @override
  ThemeExtension<AppColorsExtension> copyWith({
    Color? background,
    Color? surface,
    Color? cardColor,
    Color? textPrimary,
    Color? textSecondary,
    Color? textHint,
    Color? textMuted,
    Color? border,
    Color? divider,
    Color? inputFill,
    Color? iconColor,
    Color? shimmer,
  }) {
    return AppColorsExtension(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      cardColor: cardColor ?? this.cardColor,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textHint: textHint ?? this.textHint,
      textMuted: textMuted ?? this.textMuted,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      inputFill: inputFill ?? this.inputFill,
      iconColor: iconColor ?? this.iconColor,
      shimmer: shimmer ?? this.shimmer,
    );
  }

  @override
  ThemeExtension<AppColorsExtension> lerp(
    covariant ThemeExtension<AppColorsExtension>? other,
    double t,
  ) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      cardColor: Color.lerp(cardColor, other.cardColor, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textHint: Color.lerp(textHint, other.textHint, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
      iconColor: Color.lerp(iconColor, other.iconColor, t)!,
      shimmer: Color.lerp(shimmer, other.shimmer, t)!,
    );
  }
}

/// Convenience accessor so every widget can do `context.appColors.textPrimary`.
extension AppColorsExtensionAccess on BuildContext {
  AppColorsExtension get appColors =>
      Theme.of(this).extension<AppColorsExtension>()!;
}
