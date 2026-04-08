import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:thinky/core_controls/services/auth_service.dart';
import 'package:thinky/core_controls/services/app_state_service.dart';
import 'package:thinky/core_controls/services/language_service.dart';
import 'package:thinky/core_controls/services/theme_service.dart';
import 'package:thinky/shared_controls/theme/app_colors.dart';
import 'package:thinky/shared_controls/theme/app_colors_extension.dart';
import 'package:thinky/shared_controls/theme/app_dimens.dart';
import 'package:thinky/shared_controls/widgets/animations/animated_widgets.dart';
import 'package:thinky/core_controls/routing/route_names.dart';
import 'package:thinky/core_controls/constants/app_texts.dart';

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
    final colors = context.appColors;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusXl),
        ),
        title: Text(
          ProfileTexts.logout,
          style: GoogleFonts.alata(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: colors.textPrimary,
          ),
        ),
        content: Text(
          ProfileTexts.logoutConfirm,
          style: GoogleFonts.alata(
            fontSize: 15,
            color: colors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              Common.cancel,
              style: GoogleFonts.alata(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              ProfileTexts.logout,
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
    final themeMode = ref.watch(themeModeProvider);
    ref.watch(textRefreshProvider);

    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
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
                    backgroundColor: colors.background,
                    elevation: 0,
                    title: Text(
                      ProfileTexts.title,
                      style: GoogleFonts.alata(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
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
                          _buildProfileHeader(colors),
                          const SizedBox(height: AppDimens.xl),
                          _buildSettingsSection(currentLocale, themeMode, colors),
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

  Widget _buildProfileHeader(AppColorsExtension colors) {
    final displayName =
        _userData?['username'] ?? _userData?['guestName'] ?? 'User';
    final isGuest = _userData?['isGuest'] == true;

    return FadeInWidget(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimens.xl),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusXl),
          border: Border.all(color: colors.border),
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
                color: colors.textPrimary,
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
                  color: colors.textSecondary,
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
                isGuest ? ProfileTexts.guest : ProfileTexts.user,
                style: GoogleFonts.alata(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isGuest
                      ? AppColors.darkGoldenrod
                      : AppColors.primaryPurple,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(
      Locale currentLocale, ThemeMode themeMode, AppColorsExtension colors) {
    return FadeInWidget(
      delay: const Duration(milliseconds: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: AppDimens.sm),
            child: Text(
              ProfileTexts.settings,
              style: GoogleFonts.alata(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
          ),
          _buildSettingCard(
            colors: colors,
            children: [
              _buildThemeRow(themeMode, colors),
              _buildDivider(colors),
              _buildLanguageRow(currentLocale, colors),
              _buildDivider(colors),
              _buildSettingTile(
                icon: Icons.info_outline_rounded,
                title: ProfileTexts.aboutThinky,
                colors: colors,
                onTap: () => context.push(RouteNames.about),
              ),
              _buildDivider(colors),
              _buildSettingTile(
                icon: Icons.help_outline_rounded,
                title: ProfileTexts.helpFaq,
                colors: colors,
                onTap: () => context.push(RouteNames.help),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard(
      {required List<Widget> children, required AppColorsExtension colors}) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(color: colors.border),
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

  Widget _buildThemeRow(ThemeMode themeMode, AppColorsExtension colors) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            child: Icon(
              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: AppColors.primaryPurple,
              size: 22,
            ),
          ),
          const SizedBox(width: AppDimens.md),
          Expanded(
            child: Text(
              ProfileTexts.darkMode,
              style: GoogleFonts.alata(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ),
          Switch.adaptive(
            value: themeMode == ThemeMode.dark,
            activeColor: AppColors.primaryPurple,
            onChanged: (_) {
              ref.read(themeModeProvider.notifier).toggleDarkMode();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageRow(Locale currentLocale, AppColorsExtension colors) {
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
              ProfileTexts.language,
              style: GoogleFonts.alata(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ),
          DropdownButton<String>(
            value: currentLocale.languageCode,
            underline: const SizedBox(),
            dropdownColor: colors.surface,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: colors.textHint,
            ),
            borderRadius: BorderRadius.circular(12),
            items: [
              DropdownMenuItem(
                value: 'en',
                child: Row(
                  children: [
                    const Text('🇺🇸 ', style: TextStyle(fontSize: 16)),
                    Text(
                      ProfileTexts.english,
                      style: GoogleFonts.alata(
                        color: colors.textPrimary,
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
                    const Text('🇷🇴 ', style: TextStyle(fontSize: 16)),
                    Text(
                      ProfileTexts.romanian,
                      style: GoogleFonts.alata(
                        color: colors.textPrimary,
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

  Widget _buildDivider(AppColorsExtension colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.lg),
      child: Divider(height: 1, color: colors.divider),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required AppColorsExtension colors,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.transparent,
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
                    color: colors.textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: colors.textHint,
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
        color: AppColors.transparent,
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
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.logout_rounded,
                  size: 20,
                  color: AppColors.error,
                ),
                const SizedBox(width: AppDimens.sm),
                Text(
                  ProfileTexts.logout.toUpperCase(),
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
