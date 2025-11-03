import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

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
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 0.2,
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
              backgroundColor: primaryPurple,
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

    InputDecoration inputDecoration(String hint, {Widget? suffix}) => InputDecoration(
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
                  'OR LOG IN WITH EMAIL',
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Create your account',
                    style: GoogleFonts.alata(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  socialButton(
                    leading: Image.asset('assets/auth/icons/facebook.png', height: 20, width: 20),
                    label: 'CONTINUE WITH FACEBOOK',
                    filled: true,
                  ),
                  const SizedBox(height: 14),
                  socialButton(
                    leading: Image.asset('assets/auth/icons/google.png', height: 20, width: 20),
                    label: 'CONTINUE WITH GOOGLE',
                    filled: false,
                  ),
                  orDivider(),
                  TextField(
                    decoration: inputDecoration('Username',
                        suffix: const Icon(Icons.check, color: Color(0xFF7EC18C))),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: inputDecoration('Email address',
                        suffix: const Icon(Icons.check, color: Color(0xFF7EC18C))),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: inputDecoration('Password',
                        suffix: const Icon(Icons.visibility, color: Color(0xFF60646D))),
                    obscureText: true,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'GET STARTED',
                        style: GoogleFonts.alata(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
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
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


