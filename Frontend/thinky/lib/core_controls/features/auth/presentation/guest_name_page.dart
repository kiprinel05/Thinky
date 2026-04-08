import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import 'package:thinky/core_controls/routing/route_names.dart';
import 'package:thinky/base_controls/base_page.dart';
import 'package:thinky/core_controls/features/auth/presentation/controllers/auth_controller.dart';
import 'package:thinky/core_controls/features/auth/presentation/controllers/auth_state.dart';
import 'package:thinky/core_controls/constants/app_texts.dart';
import 'package:thinky/core_controls/services/language_service.dart';
import 'package:thinky/shared_controls/theme/app_colors.dart';
import 'package:thinky/shared_controls/theme/app_colors_extension.dart';
import 'package:thinky/shared_controls/widgets/error_handler_ui.dart';

class GuestNamePage extends BasePage {
  const GuestNamePage({super.key});

  @override
  Widget buildBody(BuildContext context, WidgetRef ref) {
    return const _GuestNameForm();
  }

  @override
  Widget? buildAppBar(BuildContext context) => AppBar(
    backgroundColor: context.appColors.background,
    elevation: 0,
    foregroundColor: context.appColors.textPrimary,
  );

  @override
  Color get backgroundColor => AppColors.backgroundWhite;
}

class _GuestNameForm extends ConsumerStatefulWidget {
  const _GuestNameForm();

  @override
  ConsumerState<_GuestNameForm> createState() => _GuestNameFormState();
}

class _GuestNameFormState extends ConsumerState<_GuestNameForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    final controller = ref.read(authStateProvider.notifier);

    final success = await controller.registerGuest(
      name: _nameController.text.trim(),
    );

    if (success && mounted) {
      context.go(RouteNames.welcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(textRefreshProvider);
    final colors = context.appColors;
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.isLoading;

    ref.listen<AuthState>(authStateProvider, (previous, next) {
      final error = next.errorMessage;
      if (next.isError && error != null) {
        ErrorHandlerUI.showError(context, error);
      }
    });

    InputDecoration inputDecoration(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.alata(
        color: colors.textHint,
        fontSize: 14,
      ),
      filled: true,
      fillColor: colors.inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.primaryPurple),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );

    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Image.asset(
            'assets/auth/guest/background.png',
            fit: BoxFit.cover,
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    Auth.continueGuest,
                    style: GoogleFonts.alata(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    Auth.guestNameSubtitle,
                    style: GoogleFonts.alata(
                      color: colors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: inputDecoration(Auth.guestNameHint),
                    style: TextStyle(color: colors.textPrimary),
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleContinue(),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return Auth.nameRequired;
                      }
                      if (value.trim().length > 100) {
                        return Auth.nameMaxLength;
                      }
                      return null;
                    },
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _handleContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              Auth.continueAction,
                              style: GoogleFonts.alata(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
