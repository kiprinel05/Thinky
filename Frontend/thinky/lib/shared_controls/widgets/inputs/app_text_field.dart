import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_dimens.dart';

/// AppTextField - Styled text input field
/// Follows the app's design system standards
class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool enabled;
  final int? maxLines;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;

  const AppTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.prefixIcon,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.maxLines = 1,
    this.textInputAction,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      enabled: enabled,
      maxLines: maxLines,
      textInputAction: textInputAction,
      focusNode: focusNode,
      style: AppTypography.inputText,
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        errorText: errorText,
        hintStyle: AppTypography.inputHint,
        filled: true,
        fillColor: AppColors.backgroundGrey,
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
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon,
      ),
    );
  }
}

/// PasswordTextField - Text field with toggle visibility
class PasswordTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const PasswordTextField({
    super.key,
    this.controller,
    this.hintText = 'Password',
    this.validator,
    this.onChanged,
  });

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: widget.controller,
      hintText: widget.hintText,
      obscureText: _obscureText,
      validator: widget.validator,
      onChanged: widget.onChanged,
      suffixIcon: IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility : Icons.visibility_off,
          color: AppColors.textGrey,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      ),
    );
  }
}
