import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GuestNamePage extends StatefulWidget {
  const GuestNamePage({super.key});

  @override
  State<GuestNamePage> createState() => _GuestNamePageState();
}

class _GuestNamePageState extends State<GuestNamePage> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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
              'assets/auth/guest/background.png',
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
                    'Continue as guest',
                    style: GoogleFonts.alata(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Tell us your name. You can change it later.',
                    style: GoogleFonts.alata(
                      color: const Color(0xFF8A8A8F),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    decoration: inputDecoration('Your name'),
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        final name = _nameController.text.trim();
                        if (name.isEmpty) return;
                        Navigator.of(context).pop(name);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'CONTINUE',
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
        ],
      ),
    );
  }
}
