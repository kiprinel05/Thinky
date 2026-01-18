import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:thinky/shared_controls/theme/app_colors.dart';
import 'package:thinky/shared_controls/theme/app_typography.dart';
import 'package:thinky/shared_controls/theme/app_dimens.dart';
import 'package:thinky/core_controls/routing/route_names.dart';
import 'package:thinky/shared_controls/widgets/buttons/primary_button.dart';
import 'package:thinky/shared_controls/widgets/inputs/app_text_field.dart';
import '../controllers/auth_controller.dart';

/// RegisterPage - Refactored to use Riverpod for state management
/// UI remains identical to original design
class RegisterPage extends ConsumerWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(registerFormProvider);
    final formController = ref.read(registerFormProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      backgroundColor: AppColors.backgroundWhite,
      body: Stack(
        children: [
          // Background image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/auth/register/background.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.pagePaddingHorizontal),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppDimens.lg),
                  
                  // Title
                  Text(
                    'Create your account',
                    style: AppTypography.h1,
                  ),
                  
                  const SizedBox(height: AppDimens.lg + 2),
                  
                  // Social signup buttons
                  _SocialSignupButton(
                    icon: 'assets/auth/icons/facebook.png',
                    label: 'CONTINUE WITH FACEBOOK',
                    filled: true,
                    onPressed: () {},
                  ),
                  
                  const SizedBox(height: AppDimens.md),
                  
                  _SocialSignupButton(
                    icon: 'assets/auth/icons/google.png',
                    label: 'CONTINUE WITH GOOGLE',
                    filled: false,
                    onPressed: () {},
                  ),
                  
                  // OR divider
                  const _OrDivider(),
                  
                  // Error message
                  if (formState.errorMessage != null)
                    _ErrorMessage(message: formState.errorMessage!),
                  
                  // Username field
                  AppTextField(
                    hintText: 'Username',
                    onChanged: formController.setUsername,
                  ),
                  
                  const SizedBox(height: AppDimens.lg),
                  
                  // Email field
                  AppTextField(
                    hintText: 'Email address',
                    keyboardType: TextInputType.emailAddress,
                    onChanged: formController.setEmail,
                  ),
                  
                  const SizedBox(height: AppDimens.lg),
                  
                  // Password field
                  _PasswordField(
                    hintText: 'Password',
                    obscureText: formState.obscurePassword,
                    onChanged: formController.setPassword,
                    onToggleVisibility: formController.togglePasswordVisibility,
                  ),
                  
                  const SizedBox(height: AppDimens.lg),
                  
                  // Confirm password field
                  _PasswordField(
                    hintText: 'Confirm password',
                    obscureText: formState.obscureConfirmPassword,
                    onChanged: formController.setConfirmPassword,
                    onToggleVisibility: formController.toggleConfirmPasswordVisibility,
                  ),
                  
                  const SizedBox(height: AppDimens.xl),
                  
                  // Register button
                  PrimaryButton(
                    text: 'CREATE ACCOUNT',
                    isLoading: formState.isSubmitting,
                    isEnabled: formState.username.isNotEmpty &&
                        formState.email.isNotEmpty &&
                        formState.password.isNotEmpty &&
                        formState.confirmPassword.isNotEmpty,
                    onPressed: () => _handleRegister(context, ref),
                  ),
                  
                  const SizedBox(height: AppDimens.lg),
                  
                  // Already have account link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go(RouteNames.login),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'LOG IN',
                          style: AppTypography.buttonSecondary.copyWith(
                            color: AppColors.primaryPurple,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppDimens.lg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRegister(BuildContext context, WidgetRef ref) async {
    final formController = ref.read(registerFormProvider.notifier);
    final success = await formController.submit();

    if (success && context.mounted) {
      context.go(RouteNames.welcome);
    }
  }
}

/// Social signup button widget
class _SocialSignupButton extends StatelessWidget {
  final String icon;
  final String label;
  final bool filled;
  final VoidCallback onPressed;

  const _SocialSignupButton({
    required this.icon,
    required this.label,
    required this.filled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
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
            color: filled ? Colors.white : AppColors.textGrey,
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
          foregroundColor: AppColors.textGrey,
          side: const BorderSide(color: AppColors.borderLight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusRound),
          ),
        ),
        child: content,
      ),
    );
  }
}

/// OR divider widget
class _OrDivider extends StatelessWidget {
  const _OrDivider();

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
              'OR SIGN UP WITH EMAIL',
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

/// Password field with visibility toggle
class _PasswordField extends StatelessWidget {
  final String hintText;
  final bool obscureText;
  final ValueChanged<String> onChanged;
  final VoidCallback onToggleVisibility;

  const _PasswordField({
    required this.hintText,
    required this.obscureText,
    required this.onChanged,
    required this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      hintText: hintText,
      obscureText: obscureText,
      onChanged: onChanged,
      suffixIcon: IconButton(
        icon: Icon(
          obscureText ? Icons.visibility : Icons.visibility_off,
          color: AppColors.textGrey,
        ),
        onPressed: onToggleVisibility,
      ),
    );
  }
}

/// Error message widget
class _ErrorMessage extends StatelessWidget {
  final String message;

  const _ErrorMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.md),
      margin: const EdgeInsets.only(bottom: AppDimens.lg),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(AppDimens.inputRadius),
        border: Border.all(color: AppColors.error.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.errorDark),
          const SizedBox(width: AppDimens.sm),
          Expanded(
            child: Text(message, style: AppTypography.error),
          ),
        ],
      ),
    );
  }
}