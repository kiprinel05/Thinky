import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thinky/core_controls/services/auth_service.dart';
import 'package:thinky/core_controls/models/auth_response.dart';
import 'package:thinky/shared_controls/widgets/animated_widgets.dart';
import 'package:thinky/core_controls/features/welcome/presentation/welcome_page.dart';
import 'package:thinky/core_controls/constants/app_texts.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await AuthService.register(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
      );

      if (mounted) {
        // Navigate to welcome page
        Navigator.of(context).pushAndRemoveUntil(
          SlidePageRoute(
            page: WelcomePage(),
            direction: SlideDirection.right,
          ),
          (route) => false,
        );
      }
    } on AuthError catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryPurple = Color(0xFF8E97FD);
    const double buttonHeight = 56;

    Widget socialButton({
      required Widget leading,
      required String label,
      required bool filled,
    }) {
      final BorderRadius radius = BorderRadius.circular(28);
      final Widget content = Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 18),
              child: leading,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.alata(
              color: filled ? Colors.white : const Color(0xFF60646D),
              fontWeight: FontWeight.w600,
              fontSize: 12,
              letterSpacing: 0.7,
            ),
          ),
        ],
      );

      if (filled) {
        return SizedBox(
          height: buttonHeight,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Color.fromRGBO(117, 131, 202, 1),
              shape: RoundedRectangleBorder(borderRadius: radius),
              elevation: 0,
            ),
            child: content,
          ),
        );
      }
      return SizedBox(
        height: buttonHeight,
        child: OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF60646D),
            side: const BorderSide(color: Color(0xFFE6E7EB)),
            shape: RoundedRectangleBorder(borderRadius: radius),
          ),
          child: content,
        ),
      );
    }

    InputDecoration inputDecoration(String hint, {Widget? suffix}) =>
        InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.alata(
            color: const Color(0xFFB7BAC3),
            fontSize: 14,
          ),
          filled: true,
          fillColor: const Color(0xFFF2F3F7),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
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
          suffixIcon: suffix,
        );

    Widget orDivider() => Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(
            child: Divider(color: Color(0xFFE6E7EB), thickness: 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              Auth.orLoginEmail,
              style: GoogleFonts.alata(
                color: const Color(0xFFA3A6AD),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const Expanded(
            child: Divider(color: Color(0xFFE6E7EB), thickness: 1),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      backgroundColor: Colors.white,
      body: Stack(
        children: [
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
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      Auth.createAccount,
                      style: GoogleFonts.aleo(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Color.fromRGBO(63, 64, 78, 1),
                      ),
                    ),
                    const SizedBox(height: 18),
                    socialButton(
                      leading: Image.asset(
                        'assets/auth/icons/facebook.png',
                        height: 20,
                        width: 20,
                      ),
                      label: Auth.continueFacebook,
                      filled: true,
                    ),
                    const SizedBox(height: 14),
                    socialButton(
                      leading: Image.asset(
                        'assets/auth/icons/google.png',
                        height: 20,
                        width: 20,
                      ),
                      label: Auth.continueGoogle,
                      filled: false,
                    ),
                    orDivider(),
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: GoogleFonts.alata(
                                  color: Colors.red.shade700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    TextFormField(
                      controller: _usernameController,
                      decoration: inputDecoration(
                        Auth.usernameHint,
                        suffix: _usernameController.text.isNotEmpty
                            ? const Icon(Icons.check, color: Color(0xFF7EC18C))
                            : null,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return Auth.usernameRequired;
                        }
                        if (value.trim().length < 3) {
                          return Auth.usernameMinLength;
                        }
                        if (value.trim().length > 50) {
                          return Auth.usernameMaxLength;
                        }
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: inputDecoration(
                        Auth.emailHint,
                        suffix: _emailController.text.isNotEmpty &&
                                _emailController.text.contains('@')
                            ? const Icon(Icons.check, color: Color(0xFF7EC18C))
                            : null,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return Auth.emailRequired;
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return Auth.emailInvalid;
                        }
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: inputDecoration(
                        Auth.passwordHint,
                        suffix: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: const Color(0xFF60646D),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscurePassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return Auth.passwordRequired;
                        }
                        if (value.length < 6) {
                          return Auth.passwordMinLength;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: inputDecoration(
                        Auth.confirmPasswordHint,
                        suffix: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: const Color(0xFF60646D),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscureConfirmPassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return Auth.confirmPasswordRequired;
                        }
                        if (value != _passwordController.text) {
                          return Auth.passwordsMismatch;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 50),
                    SizedBox(
                      height: 56,
                      width: 500,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                Auth.getStarted,
                                style: GoogleFonts.alata(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 50),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          Auth.alreadyHaveAccount,
                          style: GoogleFonts.alata(
                            fontSize: 12,
                            color: const Color(0xFF8A8A8F),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            Auth.loginButton,
                            style: GoogleFonts.alata(
                              color: primaryPurple,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}