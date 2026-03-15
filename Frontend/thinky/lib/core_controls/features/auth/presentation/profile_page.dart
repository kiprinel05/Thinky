import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:thinky/core_controls/services/auth_service.dart';
import 'package:thinky/core_controls/services/app_state_service.dart';
import 'package:thinky/core_controls/services/language_service.dart';
import 'package:thinky/shared_controls/theme/app_colors.dart';
import 'package:thinky/shared_controls/theme/app_dimens.dart';
import 'package:thinky/shared_controls/widgets/animated_widgets.dart';
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
        backgroundColor: AppColors.backgroundWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusXl),
        ),
        title: Text(
          'Logout',
          style: GoogleFonts.alata(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: GoogleFonts.alata(
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.alata(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Logout',
              style: GoogleFonts.alata(
                color: AppColors.primaryPurple,
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
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryPurple),
            )
          : RefreshIndicator(
              color: AppColors.primaryPurple,
              onRefresh: _loadUserData,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    expandedHeight: 0,
                    floating: true,
                    pinned: true,
                    backgroundColor: AppColors.backgroundWhite,
                    elevation: 0,
                    title: Text(
                      'Profile',
                      style: GoogleFonts.alata(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    centerTitle: true,
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppDimens.lg,
                        AppDimens.sm,
                        AppDimens.lg,
                        AppDimens.xxl,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildProfileHeader(),
                          const SizedBox(height: AppDimens.xl),
                          _buildSettingsSection(currentLocale),
                          const SizedBox(height: AppDimens.xl),
                          _buildLogoutButton(),
                          const SizedBox(height: AppDimens.xl),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    final displayName = _userData?['username'] ??
        _userData?['guestName'] ??
        'User';
    final isGuest = _userData?['isGuest'] == true;

    return FadeInWidget(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimens.xl),
        decoration: BoxDecoration(
          color: AppColors.backgroundGrey,
          borderRadius: BorderRadius.circular(AppDimens.radiusXl),
          border: Border.all(color: AppColors.borderLight, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryPurple.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryPurple.withValues(alpha: 0.1),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryPurple.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 48,
                color: AppColors.primaryPurple,
              ),
            ),
            const SizedBox(height: AppDimens.lg),
            Text(
              displayName,
              style: GoogleFonts.alata(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            if (_userData?['email'] != null) ...[
              const SizedBox(height: 4),
              Text(
                _userData!['email'],
                style: GoogleFonts.alata(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: AppDimens.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.md,
                vertical: AppDimens.xs + 2,
              ),
              decoration: BoxDecoration(
                color: isGuest
                    ? AppColors.missionYellow.withValues(alpha: 0.15)
                    : AppColors.primaryPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                isGuest ? 'Guest' : 'User',
                style: GoogleFonts.alata(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isGuest
                      ? const Color(0xFFB8860B)
                      : AppColors.primaryPurple,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(Locale currentLocale) {
    return FadeInWidget(
      delay: const Duration(milliseconds: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: AppDimens.sm),
            child: Text(
              'Settings',
              style: GoogleFonts.alata(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          _buildSettingCard(
            children: [
              _buildLanguageRow(currentLocale),
              _buildDivider(),
              _buildSettingTile(
                icon: Icons.info_outline_rounded,
                title: 'About Thinky',
                onTap: () => context.push(RouteNames.about),
              ),
              _buildDivider(),
              _buildSettingTile(
                icon: Icons.help_outline_rounded,
                title: 'Help & FAQ',
                onTap: () => context.push(RouteNames.help),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundGrey,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(color: AppColors.borderLight, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildLanguageRow(Locale currentLocale) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.lg,
        vertical: AppDimens.md,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.language_rounded,
              color: AppColors.primaryPurple,
              size: 22,
            ),
          ),
          const SizedBox(width: AppDimens.md),
          Expanded(
            child: Text(
              'Language',
              style: GoogleFonts.alata(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          DropdownButton<String>(
            value: currentLocale.languageCode,
            underline: const SizedBox(),
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textHint,
            ),
            borderRadius: BorderRadius.circular(12),
            items: [
              DropdownMenuItem(
                value: 'en',
                child: Row(
                  children: [
                    Text('🇺🇸 ', style: TextStyle(fontSize: 16)),
                    Text(
                      'English',
                      style: GoogleFonts.alata(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'ro',
                child: Row(
                  children: [
                    Text('🇷🇴 ', style: TextStyle(fontSize: 16)),
                    Text(
                      'Română',
                      style: GoogleFonts.alata(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.lg),
      child: Divider(
        height: 1,
        color: AppColors.borderLight,
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.lg,
            vertical: AppDimens.md,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primaryPurple, size: 22),
              ),
              const SizedBox(width: AppDimens.md),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.alata(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return FadeInWidget(
      delay: const Duration(milliseconds: 200),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleLogout,
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.lg,
              vertical: AppDimens.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppDimens.radiusLg),
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.logout_rounded,
                  size: 20,
                  color: AppColors.error,
                ),
                const SizedBox(width: AppDimens.sm),
                Text(
                  'LOGOUT',
                  style: GoogleFonts.alata(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
