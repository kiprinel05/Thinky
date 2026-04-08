import 'package:flutter/material.dart';

/// AppColors - Centralized color palette for the Thinky app
/// All colors extracted from existing UI to maintain visual consistency
abstract class AppColors {
  // ══════════════════════════════════════════════════════════════════════════
  // PRIMARY COLORS
  // ══════════════════════════════════════════════════════════════════════════
  
  static const Color primaryPurple = Color(0xFF8E97FD);
  static const Color primaryPurpleLight = Color(0xFF9AA2FD);
  static const Color primaryPurpleDark = Color(0xFF7583CA);
  
  // ══════════════════════════════════════════════════════════════════════════
  // BACKGROUND COLORS
  // ══════════════════════════════════════════════════════════════════════════
  
  static const Color backgroundWhite = Colors.white;
  static const Color backgroundGrey = Color(0xFFF2F3F7);
  static const Color backgroundLight = Color(0xFFF5F6FA);
  
  // ══════════════════════════════════════════════════════════════════════════
  // TEXT COLORS
  // ══════════════════════════════════════════════════════════════════════════
  
  static const Color textPrimary = Color(0xFF222222);
  static const Color textSecondary = Color(0xFF8A8A8F);
  static const Color textHint = Color(0xFFB7BAC3);
  static const Color textGrey = Color(0xFF60646D);
  static const Color textMuted = Color(0xFFA3A6AD);
  
  // ══════════════════════════════════════════════════════════════════════════
  // BORDER COLORS
  // ══════════════════════════════════════════════════════════════════════════
  
  static const Color borderLight = Color(0xFFE6E7EB);
  static const Color borderGrey = Color(0xFFE0E2EA);
  
  // ══════════════════════════════════════════════════════════════════════════
  // STATUS COLORS
  // ══════════════════════════════════════════════════════════════════════════
  
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFFF9800);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color error = Color(0xFFFF7043);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color errorDark = Color(0xFFD32F2F);
  
  // ══════════════════════════════════════════════════════════════════════════
  // MISSION CARD COLORS
  // ══════════════════════════════════════════════════════════════════════════
  
  static const Color missionPurple = Color(0xFF8E97FD);
  static const Color missionPeach = Color(0xFFFFB59E);
  static const Color missionYellow = Color(0xFFFFC542);
  
  // ══════════════════════════════════════════════════════════════════════════
  // SOCIAL BUTTON COLORS
  // ══════════════════════════════════════════════════════════════════════════
  
  static const Color facebookBlue = Color(0xFF7583CA);
  
  // ══════════════════════════════════════════════════════════════════════════
  // OVERLAY COLORS
  // ══════════════════════════════════════════════════════════════════════════
  
  static const Color overlayDark = Color(0x80000000); // 50% black
  static const Color overlayLight = Color(0x40FFFFFF); // 25% white

  // ══════════════════════════════════════════════════════════════════════════
  // MISSION-SPECIFIC ACCENT COLORS
  // ══════════════════════════════════════════════════════════════════════════

  static const Color patternPurple = Color(0xFF9C27B0);
  static const Color numbersPrimary = Color(0xFF5C6BC0);
  static const Color drawingRed = Color(0xFFF44336);
  static const Color drawingBlue = Color(0xFF2196F3);
  static const Color goldAccent = Color(0xFFFFD700);
  static const Color orangeAccent = Color(0xFFFFA500);
  static const Color correctGreen = Color(0xFF66BB6A);
  static const Color incorrectRed = Color(0xFFFF5252);
  static const Color darkGoldenrod = Color(0xFFB8860B);

  // ══════════════════════════════════════════════════════════════════════════
  // NEUTRAL / UTILITY COLORS
  // ══════════════════════════════════════════════════════════════════════════

  static const Color transparent = Color(0x00000000);
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color greyLight = Color(0xFFE0E0E0);
}
