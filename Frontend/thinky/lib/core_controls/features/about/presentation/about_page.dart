import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thinky/shared_controls/theme/app_colors.dart';
import 'package:thinky/shared_controls/theme/app_dimens.dart';
import 'package:thinky/shared_controls/widgets/animated_widgets.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            backgroundColor: AppColors.backgroundWhite,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.backgroundGrey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 18, color: AppColors.textPrimary),
              ),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
              title: Text(
                'About Thinky',
                style: GoogleFonts.alata(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroSection(context),
                  const SizedBox(height: AppDimens.xl),
                  _buildMissionSection(context),
                  const SizedBox(height: AppDimens.xl),
                  _buildObjectivesSection(context),
                  const SizedBox(height: AppDimens.xl),
                  _buildFeaturesSection(context),
                  const SizedBox(height: AppDimens.xl),
                  _buildFooter(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
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
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryPurple.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                size: 44,
                color: AppColors.primaryPurple,
              ),
            ),
            const SizedBox(height: AppDimens.lg),
            Text(
              'Thinky',
              style: GoogleFonts.alata(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Learn AI with Pixy',
              style: GoogleFonts.alata(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionSection(BuildContext context) {
    return FadeInWidget(
      delay: const Duration(milliseconds: 100),
      child: _buildSectionCard(
        icon: Icons.rocket_launch_rounded,
        title: 'Our Mission',
        content:
            'Thinky este o aplicație interactivă, educativă și gamificată, destinată copiilor cu vârsta între 7 și 12 ani. Prin jocuri și interacțiuni cu mascota digitală Pixy, copiii învață conceptele de bază din inteligența artificială. Pe parcurs, mascota este „antrenată” de copil, simulând procesul real de învățare al unui model de IA.',
      ),
    );
  }

  Widget _buildObjectivesSection(BuildContext context) {
    return FadeInWidget(
      delay: const Duration(milliseconds: 200),
      child: _buildSectionCard(
        icon: Icons.flag_rounded,
        title: 'Obiective principale',
        content: '',
        children: [
          _buildObjectiveItem(
            'Introducerea notiunilor de IA într-un mod prietenos și intuitiv.',
          ),
          const SizedBox(height: AppDimens.sm),
          _buildObjectiveItem(
            'Simularea unui model simplu de IA care „învață” în timp real din interacțiunile copilului.',
          ),
          const SizedBox(height: AppDimens.sm),
          _buildObjectiveItem(
            'Utilizarea unei mascote animate care servește drept ghid, partener și model de învățare.',
          ),
        ],
      ),
    );
  }

  Widget _buildObjectiveItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppColors.primaryPurple,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppDimens.md),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.alata(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesSection(BuildContext context) {
    final features = [
      ('Misiuni interactive', Icons.gamepad_rounded),
      ('Workshop creativ', Icons.extension_rounded),
      ('Leaderboard gamificat', Icons.leaderboard_rounded),
      ('Chat cu Pixy', Icons.chat_bubble_rounded),
    ];

    return FadeInWidget(
      delay: const Duration(milliseconds: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ce oferim',
            style: GoogleFonts.alata(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimens.lg),
          ...features.asMap().entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppDimens.sm),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.lg,
                  vertical: AppDimens.md,
                ),
                decoration: BoxDecoration(
                  color: AppColors.backgroundGrey,
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  border: Border.all(
                    color: AppColors.borderLight,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurple.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        e.value.$2,
                        size: 22,
                        color: AppColors.primaryPurple,
                      ),
                    ),
                    const SizedBox(width: AppDimens.md),
                    Text(
                      e.value.$1,
                      style: GoogleFonts.alata(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return FadeInWidget(
      delay: const Duration(milliseconds: 400),
      child: Center(
        child: Column(
          children: [
            Text(
              'Made with ❤️ for curious minds',
              style: GoogleFonts.alata(
                fontSize: 13,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Thinky © 2025',
              style: GoogleFonts.alata(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required String content,
    List<Widget>? children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.lg),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: AppColors.primaryPurple),
              ),
              const SizedBox(width: AppDimens.md),
              Text(
                title,
                style: GoogleFonts.alata(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          if (content.isNotEmpty) ...[
            const SizedBox(height: AppDimens.md),
            Text(
              content,
              style: GoogleFonts.alata(
                fontSize: 14,
                height: 1.6,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (children != null && children.isNotEmpty) ...[
            const SizedBox(height: AppDimens.md),
            ...children,
          ],
        ],
      ),
    );
  }
}
