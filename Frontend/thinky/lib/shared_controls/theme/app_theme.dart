import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_dimens.dart';

/// AppTheme - Centralized theme configuration for the Thinky app
/// Provides ThemeData and common widget styles
abstract class AppTheme {
  /// Main application theme
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    
    // Colors
    primaryColor: AppColors.primaryPurple,
    scaffoldBackgroundColor: AppColors.backgroundWhite,
    
    // Color Scheme
    colorScheme: const ColorScheme.light(
      primary: AppColors.primaryPurple,
      secondary: AppColors.primaryPurpleLight,
      error: AppColors.error,
      surface: AppColors.backgroundWhite,
    ),
    
    // AppBar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: AppColors.textPrimary,
      centerTitle: true,
      titleTextStyle: AppTypography.h2,
    ),
    
    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, AppDimens.buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusRound),
        ),
        elevation: 0,
        textStyle: AppTypography.buttonPrimary,
      ),
    ),
    
    // Outlined Button Theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryPurple,
        minimumSize: const Size(double.infinity, AppDimens.buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusRound),
        ),
        side: const BorderSide(
          color: AppColors.primaryPurple,
          width: AppDimens.buttonBorderWidth,
        ),
        textStyle: AppTypography.buttonOutlined,
      ),
    ),
    
    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryPurple,
        textStyle: AppTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.backgroundGrey,
      hintStyle: AppTypography.inputHint,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimens.inputPaddingHorizontal,
        vertical: AppDimens.inputPaddingVertical,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.inputRadius),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.inputRadius),
        borderSide: BorderSide.none,
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.inputRadius),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.inputRadius),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    ),
    
    // Card Theme
    cardTheme: CardThemeData(
      color: AppColors.backgroundWhite,
      elevation: AppDimens.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
      ),
    ),
    
    // Divider Theme
    dividerTheme: const DividerThemeData(
      color: AppColors.borderLight,
      thickness: 1,
    ),
    
    // Progress Indicator Theme
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primaryPurple,
    ),
    
    // Snackbar Theme
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.textPrimary,
      contentTextStyle: AppTypography.bodyMedium.copyWith(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );

  // ══════════════════════════════════════════════════════════════════════════
  // COMMON DECORATIONS
  // ══════════════════════════════════════════════════════════════════════════
  
  /// Standard card decoration with shadow
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: AppColors.backgroundWhite,
    borderRadius: BorderRadius.circular(AppDimens.cardRadius),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.08),
        blurRadius: 18,
        offset: const Offset(0, 10),
      ),
    ],
  );
  
  /// Primary gradient for buttons and highlights
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [AppColors.primaryPurple, AppColors.primaryPurpleLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// Vertical gradient for header backgrounds
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.primaryPurple, AppColors.primaryPurpleLight],
  );
}
