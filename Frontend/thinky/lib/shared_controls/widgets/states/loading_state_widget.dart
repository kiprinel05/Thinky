import 'package:flutter/material.dart';
import 'package:thinky/shared_controls/theme/app_colors.dart';
import 'package:thinky/shared_controls/theme/app_colors_extension.dart';
import 'package:thinky/shared_controls/theme/app_typography.dart';

class LoadingStateWidget extends StatelessWidget {
  final String? message;
  final Color? indicatorColor;
  /// Optional skeleton widget shown instead of the spinner.
  /// Use for page-level loading states; leave null for inline/button loaders.
  final Widget? skeleton;

  const LoadingStateWidget({
    super.key,
    this.message,
    this.indicatorColor,
    this.skeleton,
  });

  @override
  Widget build(BuildContext context) {
    if (skeleton != null) return skeleton!;

    final colors = context.appColors;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: indicatorColor ?? AppColors.primaryPurple,
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: AppTypography.bodyMedium.copyWith(
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
