import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thinky/core_controls/services/api_client.dart';
import 'package:thinky/core/errors/error_logger.dart';
import 'verify_code_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _isEmailSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiClient.post('/auth/forgot-password/request', {
        'email': _emailController.text.trim(),
      });

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isEmailSent = true;
          });
        }
      }
    } catch (e, stack) {
      ErrorLogger().logError(e, stackTrace: stack);
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _navigateToVerifyCode() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => VerifyCodePage(email: _emailController.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryPurple = Color(0xFF8E97FD);

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
              'assets/auth/login/background.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _isEmailSent
                  ? _buildSuccessState(primaryPurple)
                  : Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 16),
                          Text(
                            'Forgot Password?',
                            style: GoogleFonts.alata(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Don\'t worry! Enter your email address and we\'ll send you a 6-digit code to reset your password.',
                            style: GoogleFonts.alata(
                              fontSize: 14,
                              color: const Color(0xFF8A8A8F),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 32),
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
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.red.shade700,
                                  ),
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
                            controller: _emailController,
                            decoration: inputDecoration('Email address'),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Email is required';
                              }
                              if (!value.contains('@') ||
                                  !value.contains('.')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : _handleResetPassword,
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
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      'SEND CODE',
                                      style: GoogleFonts.alata(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Remember your password? ',
                                style: GoogleFonts.alata(
                                  fontSize: 12,
                                  color: const Color(0xFF8A8A8F),
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text(
                                  'LOG IN',
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

  Widget _buildSuccessState(Color primaryPurple) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle_outline,
            size: 50,
            color: Colors.green.shade600,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Check your email',
          style: GoogleFonts.alata(fontSize: 26, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
                          Text(
                            'We\'ve sent a 6-digit code to\n${_emailController.text}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.alata(
                              fontSize: 14,
                              color: const Color(0xFF8A8A8F),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 40),
                          SizedBox(
                            height: 56,
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _navigateToVerifyCode,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryPurple,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'ENTER CODE',
                                style: GoogleFonts.alata(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isEmailSent = false;
                                _emailController.clear();
                              });
                            },
                            child: Text(
                              'Didn\'t receive the code?',
                              style: GoogleFonts.alata(
                                color: primaryPurple,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
      ],
    );
  }
}