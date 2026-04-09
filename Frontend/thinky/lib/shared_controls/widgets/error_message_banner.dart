import 'package:flutter/material.dart';
import 'package:thinky/shared_controls/theme/app_colors.dart';
import 'package:thinky/shared_controls/theme/app_dimens.dart';
import 'package:thinky/shared_controls/theme/app_typography.dart';

class ErrorMessageBanner extends StatelessWidget {
  final String message;

  const ErrorMessageBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? AppColors.error.withValues(alpha: 0.22)
        : AppColors.errorLight;
    final borderColor = isDark
        ? AppColors.error.withValues(alpha: 0.55)
        : AppColors.error.withAlpha(128);
    final iconColor =
        isDark ? const Color(0xFFFFAB91) : AppColors.errorDark;
    final textColor =
        isDark ? const Color(0xFFFFDAD4) : AppColors.errorDark;

    return Container(
      padding: const EdgeInsets.all(AppDimens.md),
      margin: const EdgeInsets.only(bottom: AppDimens.lg),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimens.inputRadius),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: iconColor),
          const SizedBox(width: AppDimens.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.error.copyWith(color: textColor),
            ),
          ),
        ],
      ),
    );
  }
}
