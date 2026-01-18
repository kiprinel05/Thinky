import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/animations/animated_widgets.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/inputs/app_text_field.dart';
import '../../../../core/services/app_state_service.dart';
import '../controllers/auth_controller.dart';

/// LoginPage - Refactored to use Riverpod for state management
/// UI remains identical to original design
class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(loginFormProvider);
    final formController = ref.read(loginFormProvider.notifier);

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
              'assets/auth/login/background.png',
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
                    'Welcome Back!',
                    style: AppTypography.h1,
                  ),
                  
                  const SizedBox(height: AppDimens.lg + 2),
                  
                  // Social login buttons
                  _SocialLoginButton(
                    icon: 'assets/auth/icons/facebook.png',
                    label: 'CONTINUE WITH FACEBOOK',
                    filled: true,
                    onPressed: () {},
                  ),
                  
                  const SizedBox(height: AppDimens.md),
                  
                  _SocialLoginButton(
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
                  
                  // Email field
                  AppTextField(
                    hintText: 'Email address',
                    keyboardType: TextInputType.emailAddress,
                    onChanged: formController.setEmail,
                  ),
                  
                  const SizedBox(height: AppDimens.lg),
                  
                  // Password field
                  PasswordTextField(
                    hintText: 'Password',
                    onChanged: formController.setPassword,
                  ),
                  
                  const SizedBox(height: AppDimens.xl),
                  
                  // Login button
                  PrimaryButton(
                    text: 'LOG IN',
                    isLoading: formState.isSubmitting,
                    isEnabled: formState.email.isNotEmpty && formState.password.isNotEmpty,
                    onPressed: () => _handleLogin(context, ref),
                  ),
                  
                  const SizedBox(height: AppDimens.md),
                  
                  // Forgot password
                  Center(
                    child: TextButton(
                      onPressed: () => context.push(RouteNames.forgotPassword),
                      child: Text(
                        'Forgot Password?',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.primaryPurple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin(BuildContext context, WidgetRef ref) async {
    final formController = ref.read(loginFormProvider.notifier);
    final success = await formController.submit();

    if (success && context.mounted) {
      await AppStateService.setHasSeenWelcome(true);
      await AppStateService.setLastRoute('missions');
      context.go(RouteNames.missions);
    }
  }
}

/// Social login button widget
class _SocialLoginButton extends StatelessWidget {
  final String icon;
  final String label;
  final bool filled;
  final VoidCallback onPressed;

  const _SocialLoginButton({
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
              'OR LOG IN WITH EMAIL',
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
          Icon(
            Icons.error_outline,
            color: AppColors.errorDark,
          ),
          const SizedBox(width: AppDimens.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.error,
            ),
          ),
        ],
      ),
    );
  }
}
