import 'package:flutter/material.dart';
import 'package:thinky/shared_controls/theme/app_colors.dart';
import 'package:thinky/shared_controls/theme/app_dimens.dart';
import 'package:thinky/shared_controls/theme/app_typography.dart';

class OrDivider extends StatelessWidget {
  final String text;

  const OrDivider({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.lg),
      child: Row(
        children: [
          const Expanded(
            child: Divider(color: AppColors.borderLight, thickness: 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.lg),
            child: Text(
              text,
              style: AppTypography.badge.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const Expanded(
            child: Divider(color: AppColors.borderLight, thickness: 1),
          ),
        ],
      ),
    );
  }
}
