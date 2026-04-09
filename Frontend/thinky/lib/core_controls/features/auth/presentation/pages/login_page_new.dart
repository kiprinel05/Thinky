import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:thinky/shared_controls/theme/app_colors.dart';
import 'package:thinky/shared_controls/theme/app_colors_extension.dart';
import 'package:thinky/shared_controls/theme/app_typography.dart';
import 'package:thinky/shared_controls/theme/app_dimens.dart';
import 'package:thinky/core_controls/routing/route_names.dart';
import 'package:thinky/shared_controls/widgets/buttons/primary_button.dart';
import 'package:thinky/shared_controls/widgets/inputs/app_text_field.dart';
import 'package:thinky/shared_controls/widgets/social_button.dart';
import 'package:thinky/shared_controls/widgets/or_divider.dart';
import 'package:thinky/shared_controls/widgets/error_message_banner.dart';
import 'package:thinky/shared_controls/assets/app_assets.dart';
import 'package:thinky/core_controls/services/app_state_service.dart';
import '../controllers/auth_controller.dart';

/// LoginPage - Refactored to use Riverpod for state management
/// UI remains identical to original design
class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(loginFormProvider);
    final formController = ref.read(loginFormProvider.notifier);
    final colors = context.appColors;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        foregroundColor: colors.textPrimary,
      ),
      backgroundColor: colors.background,
      body: Stack(
        children: [
          // Background image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              AppAssets.authLoginBackground,
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
                    style: AppTypography.h1.copyWith(color: colors.textPrimary),
                  ),
                  
                  const SizedBox(height: AppDimens.lg + 2),
                  
                  // Social login buttons
                  SocialButton(
                    icon: AppAssets.authFacebookIcon,
                    label: 'CONTINUE WITH FACEBOOK',
                    filled: true,
                    onPressed: () {},
                  ),
                  
                  const SizedBox(height: AppDimens.md),
                  
                  SocialButton(
                    icon: AppAssets.authGoogleIcon,
                    label: 'CONTINUE WITH GOOGLE',
                    onPressed: () {},
                  ),
                  
                  // OR divider
                  const OrDivider(text: 'OR LOG IN WITH EMAIL'),
                  
                  // Error message
                  if (formState.errorMessage != null)
                    ErrorMessageBanner(message: formState.errorMessage!),
                  
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
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.primaryPurpleLight
                              : AppColors.primaryPurple,
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
