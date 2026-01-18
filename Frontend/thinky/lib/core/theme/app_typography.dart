import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// AppTypography - Centralized text styles for the Thinky app
/// All styles extracted from existing UI to maintain visual consistency
abstract class AppTypography {
  // ══════════════════════════════════════════════════════════════════════════
  // HEADINGS
  // ══════════════════════════════════════════════════════════════════════════
  
  /// Main heading - 26px, bold
  /// Used in: Welcome titles, page headers
  static TextStyle get h1 => GoogleFonts.alata(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
  );
  
  /// Secondary heading - 18px, bold
  /// Used in: Section titles, card headers
  static TextStyle get h2 => GoogleFonts.alata(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  
  /// Tertiary heading - 16px, medium
  /// Used in: Subtitles
  static TextStyle get h3 => GoogleFonts.alata(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  // ══════════════════════════════════════════════════════════════════════════
  // BODY TEXT
  // ══════════════════════════════════════════════════════════════════════════
  
  /// Body large - 16px, regular
  static TextStyle get bodyLarge => GoogleFonts.alata(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
  
  /// Body medium - 14px, medium weight
  /// Used in: Quiz options, descriptions
  static TextStyle get bodyMedium => GoogleFonts.alata(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.4,
  );
  
  /// Body small - 12px, regular
  /// Used in: Captions, labels
  static TextStyle get bodySmall => GoogleFonts.alata(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
  
  // ══════════════════════════════════════════════════════════════════════════
  // BUTTON TEXT
  // ══════════════════════════════════════════════════════════════════════════
  
  /// Primary button text - 15px, bold, white
  /// Used in: Main CTAs (LOG IN, REGISTER, etc.)
  static TextStyle get buttonPrimary => GoogleFonts.alata(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: 0.5,
  );
  
  /// Secondary button text - 12px, bold
  /// Used in: Social login buttons
  static TextStyle get buttonSecondary => GoogleFonts.alata(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
  );
  
  /// Outlined button text - 15px, bold, purple
  static TextStyle get buttonOutlined => GoogleFonts.alata(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryPurple,
    letterSpacing: 0.5,
  );
  
  // ══════════════════════════════════════════════════════════════════════════
  // INPUT TEXT
  // ══════════════════════════════════════════════════════════════════════════
  
  /// Input hint text - 14px, hint color
  static TextStyle get inputHint => GoogleFonts.alata(
    fontSize: 14,
    color: AppColors.textHint,
  );
  
  /// Input text - 14px, primary color
  static TextStyle get inputText => GoogleFonts.alata(
    fontSize: 14,
    color: AppColors.textPrimary,
  );
  
  // ══════════════════════════════════════════════════════════════════════════
  // SPECIAL TEXT
  // ══════════════════════════════════════════════════════════════════════════
  
  /// Progress label - 14px, bold, white
  static TextStyle get progressLabel => GoogleFonts.alata(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
  
  /// Badge text - 11px, medium weight
  static TextStyle get badge => GoogleFonts.alata(
    fontSize: 11,
    fontWeight: FontWeight.w500,
  );
  
  /// Mission card title - 14px, semi-bold, white
  static TextStyle get missionTitle => GoogleFonts.alata(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
  
  /// Error text - 12px
  static TextStyle get error => GoogleFonts.alata(
    fontSize: 12,
    color: AppColors.errorDark,
  );
}
