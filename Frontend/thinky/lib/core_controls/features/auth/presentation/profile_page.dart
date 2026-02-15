import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:thinky/core_controls/services/auth_service.dart';
import 'package:thinky/core_controls/services/app_state_service.dart';
import 'package:thinky/core_controls/services/language_service.dart';
import 'package:thinky/shared_controls/widgets/animated_widgets.dart';
import 'package:thinky/core_controls/features/onboarding/presentation/intro_page.dart';
import 'package:thinky/core_controls/routing/route_names.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await AuthService.getCurrentUser();
    setState(() {
      _userData = user;
      _isLoading = false;
    });
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Logout',
          style: GoogleFonts.alata(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: GoogleFonts.alata(),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.alata(
                color: const Color(0xFF8A8A8F),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Logout',
              style: GoogleFonts.alata(
                color: const Color(0xFF8E97FD),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await AuthService.logout();
      await AppStateService.clearAppState();
      if (mounted) {
        // Use go_router instead of Navigator to avoid lock conflicts
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryPurple = Color(0xFF8E97FD);
    final currentLocale = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: Text(
          'Profile',
          style: GoogleFonts.alata(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  // Profile Header
                  FadeInWidget(
                    delay: const Duration(milliseconds: 100),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F3F7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primaryPurple.withOpacity(0.2),
                            ),
                            child: Icon(
                              Icons.person,
                              size: 40,
                              color: primaryPurple,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _userData?['username'] ??
                                _userData?['guestName'] ??
                                'User',
                            style: GoogleFonts.alata(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF222222),
                            ),
                          ),
                          if (_userData?['email'] != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _userData!['email'],
                              style: GoogleFonts.alata(
                                fontSize: 14,
                                color: const Color(0xFF8A8A8F),
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _userData?['isGuest'] == true
                                  ? Colors.orange.shade100
                                  : primaryPurple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _userData?['isGuest'] == true ? 'Guest' : 'User',
                              style: GoogleFonts.alata(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _userData?['isGuest'] == true
                                    ? Colors.orange.shade800
                                    : primaryPurple,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Settings Section
                  FadeInWidget(
                    delay: const Duration(milliseconds: 200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Settings',
                          style: GoogleFonts.alata(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF222222),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Language Selector
                        _buildLanguageSelector(currentLocale),
                        const SizedBox(height: 12),
                        
                        _buildSettingItem(
                          icon: Icons.info_outline,
                          title: 'About Thinky',
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(
                                  'About Thinky',
                                  style: GoogleFonts.alata(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                content: Text(
                                  'Thinky is an educational app that helps you learn about AI through interaction with Pixy.',
                                  style: GoogleFonts.alata(),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: Text(
                                      'OK',
                                      style: GoogleFonts.alata(
                                        color: primaryPurple,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildSettingItem(
                          icon: Icons.help_outline,
                          title: 'Help',
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(
                                  'Help',
                                  style: GoogleFonts.alata(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                content: Text(
                                  'TBI Soon',
                                  style: GoogleFonts.alata(),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: Text(
                                      'OK',
                                      style: GoogleFonts.alata(
                                        color: primaryPurple,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Logout Button
                  FadeInWidget(
                    delay: const Duration(milliseconds: 300),
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _handleLogout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          foregroundColor: Colors.red.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'LOGOUT',
                              style: GoogleFonts.alata(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildLanguageSelector(Locale currentLocale) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3F7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.language, color: Color(0xFF8E97FD), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Language',
              style: GoogleFonts.alata(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF222222),
              ),
            ),
          ),
          DropdownButton<String>(
            value: currentLocale.languageCode,
            underline: const SizedBox(),
            icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF8A8A8F)),
            items: [
              DropdownMenuItem(
                value: 'en',
                child: Row(
                  children: [
                    Text('🇺🇸 ', style: TextStyle(fontSize: 16)),
                    Text('English', style: GoogleFonts.alata(color: Color(0xFF222222))),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'ro',
                child: Row(
                  children: [
                    Text('🇷🇴 ', style: TextStyle(fontSize: 16)),
                    Text('Română', style: GoogleFonts.alata(color: Color(0xFF222222))),
                  ],
                ),
              ),
            ],
            onChanged: (String? newValue) {
              if (newValue != null) {
                ref.read(languageProvider.notifier).setLanguage(Locale(newValue));
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F3F7),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF8E97FD), size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.alata(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF222222),
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: const Color(0xFF8A8A8F)),
          ],
        ),
      ),
    );
  }
}