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
}
