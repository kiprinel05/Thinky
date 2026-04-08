import 'package:flutter/material.dart';
import 'package:thinky/shared_controls/theme/app_colors.dart';
import 'package:thinky/shared_controls/theme/app_colors_extension.dart';
import 'package:thinky/shared_controls/theme/app_dimens.dart';
import 'package:thinky/shared_controls/theme/app_typography.dart';

class SocialButton extends StatelessWidget {
  final String icon;
  final String label;
  final bool filled;
  final VoidCallback onPressed;

  const SocialButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final content = Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 18),
            child: Image.asset(icon, height: 20, width: 20),
          ),
        ),
        Text(
          label,
          style: AppTypography.buttonSecondary.copyWith(
            color: filled ? AppColors.white : colors.iconColor,
          ),
        ),
      ],
    );

    if (filled) {
      return SizedBox(
        height: AppDimens.buttonHeight,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.facebookBlue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusRound),
            ),
            elevation: 0,
          ),
          child: content,
        ),
      );
    }

    return SizedBox(
      height: AppDimens.buttonHeight,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.iconColor,
          side: BorderSide(color: colors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusRound),
          ),
        ),
        child: content,
      ),
    );
  }
}
