import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:thinky/core_controls/constants/app_texts.dart';
import 'package:thinky/core_controls/features/missions/mission_animals/presentation/controllers/animals_controller.dart';
import 'package:thinky/core_controls/features/missions/mission_animals/presentation/pages/animals_learning_view.dart';
import 'package:thinky/core_controls/features/missions/mission_animals/presentation/widgets/animals_backdrop.dart';
import 'package:thinky/core_controls/features/missions/mission_animals/presentation/widgets/animals_mascots.dart';
import 'package:thinky/core_controls/features/missions/mission_animals/presentation/widgets/animals_play_view.dart';
import 'package:thinky/core_controls/services/language_service.dart';
import 'package:thinky/shared_controls/assets/app_assets.dart';
import 'package:thinky/shared_controls/theme/app_colors.dart';
import 'package:thinky/shared_controls/theme/app_colors_extension.dart';
import 'package:thinky/shared_controls/theme/app_dimens.dart';
import 'package:thinky/shared_controls/widgets/animations/animated_widgets.dart';
import 'package:thinky/shared_controls/widgets/buttons/primary_button.dart';

class AnimalsMissionPage extends ConsumerStatefulWidget {
  const AnimalsMissionPage({super.key});

  @override
  ConsumerState<AnimalsMissionPage> createState() => _AnimalsMissionPageState();
}

class _AnimalsMissionPageState extends ConsumerState<AnimalsMissionPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(animalsControllerProvider.notifier).startMission();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(textRefreshProvider);
    final state = ref.watch(animalsControllerProvider);
    final colors = context.appColors;

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: AnimalsBackdrop()),
          switch (state.phase) {
            AnimalsMissionPhase.loading => const _LoadingBody(),
            AnimalsMissionPhase.playing => const _PlayingBody(),
            AnimalsMissionPhase.missionComplete => state.showLearning
                ? AnimalsLearningView(
                    onDone: () => ref
                        .read(animalsControllerProvider.notifier)
                        .closeLearning(),
                  )
                : _CompletionBody(
                    colors: colors,
                    onLearn: () => ref
                        .read(animalsControllerProvider.notifier)
                        .openLearning(),
                    onBack: () => context.pop(),
                  ),
            AnimalsMissionPhase.error => _ErrorBody(
                colors: colors,
                message: state.errorMessage ?? UserErrors.somethingWentWrong,
                onRetry: () =>
                    ref.read(animalsControllerProvider.notifier).startMission(),
              ),
          },
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────── playing ──

class _PlayingBody extends StatelessWidget {
  const _PlayingBody();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 12, 0),
            child: Row(
              children: [
                _GlassIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                const Spacer(),
              ],
            ),
          ),
          const Expanded(child: AnimalsPlayView()),
        ],
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.32),
            ),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────── loading ──

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleInWidget(
              delay: const Duration(milliseconds: 160),
              child: const AnimalsMascotHead(
                kind: AnimalsMascotKind.pixy,
                width: 160,
                viewportHeight: 160,
              ),
            ),
            const SizedBox(height: 16),
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 20),
            FadeInWidget(
              delay: const Duration(milliseconds: 260),
              child: Text(
                Animals.preparingMission,
                style: GoogleFonts.alata(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────── completion ──

class _CompletionBody extends StatelessWidget {
  const _CompletionBody({
    required this.colors,
    required this.onLearn,
    required this.onBack,
  });

  final AppColorsExtension colors;
  final VoidCallback onLearn;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.pagePaddingHorizontal,
            vertical: 24,
          ),
          child: ScaleInWidget(
            delay: const Duration(milliseconds: 120),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxW = constraints.maxWidth.clamp(0.0, 420.0);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      AppAssets.welcomePage1Hello,
                      height: 150,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 8),
                    Material(
                      color: colors.cardColor,
                      elevation: isDark ? 14 : 10,
                      shadowColor: AppColors.primaryPurple.withValues(
                        alpha: 0.2,
                      ),
                      borderRadius: BorderRadius.circular(
                        AppDimens.cardRadius,
                      ),
                      child: Container(
                        width: maxW,
                        padding: const EdgeInsets.all(AppDimens.xl),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            AppDimens.cardRadius,
                          ),
                          border: Border.all(color: colors.border),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFFFFD95A),
                                    Color(0xFFFFC542),
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.emoji_events_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                            const SizedBox(height: AppDimens.md),
                            Text(
                              Animals.missionCompleteTitle,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.alata(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryPurple,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: AppDimens.sm),
                            Text(
                              Animals.missionCompleteBody,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.alata(
                                fontSize: 15,
                                color: colors.textSecondary,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: AppDimens.xl),
                            PrimaryButton(
                              text: Animals.lessonButton,
                              onPressed: onLearn,
                            ),
                            const SizedBox(height: AppDimens.sm),
                            TextButton(
                              onPressed: onBack,
                              child: Text(
                                Animals.backToMissions,
                                style: GoogleFonts.alata(
                                  fontWeight: FontWeight.w700,
                                  color: colors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────── error ──

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({
    required this.colors,
    required this.message,
    required this.onRetry,
  });

  final AppColorsExtension colors;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.pagePaddingHorizontal),
          child: Container(
            padding: const EdgeInsets.all(AppDimens.xl),
            decoration: BoxDecoration(
              color: colors.cardColor,
              borderRadius: BorderRadius.circular(AppDimens.cardRadius),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 56,
                  color: AppColors.error,
                ),
                const SizedBox(height: AppDimens.md),
                Text(
                  Animals.oopsTitle,
                  style: GoogleFonts.alata(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppDimens.sm),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.alata(
                    fontSize: 14,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppDimens.xl),
                PrimaryButton(text: Animals.retry, onPressed: onRetry),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
