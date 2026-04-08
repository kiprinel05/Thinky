import 'package:flutter/material.dart';
import 'package:thinky/shared_controls/theme/app_colors.dart';
import 'package:thinky/shared_controls/theme/app_colors_extension.dart';
import 'package:thinky/shared_controls/theme/app_typography.dart';
import 'package:thinky/core_controls/constants/app_texts.dart';

class ErrorStateWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String? retryText;
  final IconData icon;
  final double iconSize;

  const ErrorStateWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.retryText,
    this.icon = Icons.error_outline,
    this.iconSize = 60,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final resolvedRetryText = retryText ?? Common.tryAgain;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: AppColors.error.withAlpha(179),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  foregroundColor: colors.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: Text(resolvedRetryText),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
