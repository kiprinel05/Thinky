import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import 'package:thinky/core_controls/routing/route_names.dart';
import 'package:thinky/base_controls/base_page.dart';
import 'package:thinky/core_controls/features/auth/presentation/controllers/auth_controller.dart';
import 'package:thinky/core_controls/features/auth/presentation/controllers/auth_state.dart';
import 'package:thinky/core_controls/constants/app_texts.dart';
import 'package:thinky/shared_controls/widgets/error_handler_ui.dart';

class GuestNamePage extends BasePage {
  const GuestNamePage({super.key});

  @override
  Widget buildBody(BuildContext context, WidgetRef ref) {
    return const _GuestNameForm();
  }
  
  @override
  // Hide standard BasePage loading/error overlay to use custom UI?
  // Actually BasePage is Stateless, so we can just use buildBody.
  // But we want to handle state changes here.
  // Let's implement _GuestNameForm as ConsumerStatefulWidget
  Widget? buildAppBar(BuildContext context) => AppBar(
    backgroundColor: Colors.white,
    elevation: 0,
    foregroundColor: Colors.black,
  );
  
  @override
  Color get backgroundColor => Colors.white;
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
    
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    final controller = ref.read(authStateProvider.notifier);
    
    final success = await controller.registerGuest(
      name: _nameController.text.trim(),
    );

    if (success && mounted) {
      // Navigate to Welcome
      context.go(RouteNames.welcome);
    }
    // Error is handled by AuthController state, monitored in build (if we used BasePage listener)
    // Here we can show a snackbar if error exists in state? 
    // Ideally BaseController handles showing error if we watch state.
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryPurple = Color(0xFF8E97FD);
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.isLoading;

    // Listen for error changes to show snackbar manually if not using BasePage's auto error
    ref.listen<AuthState>(authStateProvider, (previous, next) {
      final error = next.errorMessage;
      if (next.isError && error != null) {
        ErrorHandlerUI.showError(context, error);
      }
    });

    InputDecoration inputDecoration(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.alata(
        color: const Color(0xFFB7BAC3),
        fontSize: 14,
      ),
      filled: true,
      fillColor: const Color(0xFFF2F3F7),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.transparent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.transparent),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
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
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    Auth.guestNameSubtitle,
                    style: GoogleFonts.alata(
                      color: const Color(0xFF8A8A8F),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Form Fields
                  TextFormField(
                    controller: _nameController,
                    decoration: inputDecoration(Auth.guestNameHint),
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
                        backgroundColor: primaryPurple,
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