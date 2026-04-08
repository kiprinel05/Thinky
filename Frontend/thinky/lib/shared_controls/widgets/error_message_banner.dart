import 'package:flutter/material.dart';
import 'package:thinky/shared_controls/theme/app_colors.dart';
import 'package:thinky/shared_controls/theme/app_dimens.dart';
import 'package:thinky/shared_controls/theme/app_typography.dart';

class ErrorMessageBanner extends StatelessWidget {
  final String message;

  const ErrorMessageBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.md),
      margin: const EdgeInsets.only(bottom: AppDimens.lg),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(AppDimens.inputRadius),
        border: Border.all(
          color: AppColors.error.withAlpha(128),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.errorDark),
          const SizedBox(width: AppDimens.sm),
          Expanded(
            child: Text(message, style: AppTypography.error),
          ),
        ],
      ),
    );
  }
}
