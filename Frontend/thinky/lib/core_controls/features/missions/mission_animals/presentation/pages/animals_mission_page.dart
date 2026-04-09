import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:thinky/core_controls/constants/app_texts.dart';
import 'package:thinky/core_controls/services/language_service.dart';
import 'package:thinky/shared_controls/theme/app_colors.dart';
import 'package:thinky/shared_controls/theme/app_colors_extension.dart';
import 'package:thinky/shared_controls/widgets/animations/animated_widgets.dart';
import 'package:thinky/shared_controls/assets/app_assets.dart';
import '../../data/animals_models.dart';
import '../../data/animals_repository.dart';
import '../controllers/animals_controller.dart';

/// Main page for the Animals Mission
/// "Teach Pixy to recognize animals"
class AnimalsMissionPage extends ConsumerStatefulWidget {
  const AnimalsMissionPage({super.key});

  @override
  ConsumerState<AnimalsMissionPage> createState() => _AnimalsMissionPageState();
}

class _AnimalsMissionPageState extends ConsumerState<AnimalsMissionPage>
    with SingleTickerProviderStateMixin {
  static const Color _primaryColor = AppColors.primaryPurple;
  static const Color _primaryLightColor = AppColors.primaryPurpleLight;

  late AnimationController _pixyAnimationController;
  late Animation<double> _pixyScaleAnimation;

  @override
  void initState() {
    super.initState();
    _pixyAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pixyScaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _pixyAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(animalsControllerProvider.notifier).startMission();
    });
  }

  @override
  void dispose() {
    _pixyAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(textRefreshProvider);
    final state = ref.watch(animalsControllerProvider);
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final gradientColors = isDark
        ? <Color>[
            AppColors.darkSurface,
            Color.lerp(AppColors.darkSurface, _primaryColor, 0.38)!,
          ]
        : <Color>[_primaryColor, _primaryLightColor];

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: gradientColors,
                ),
              ),
            ),
          ),
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            right: -40,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: isDark ? 0.04 : 0.06),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(state),
                Expanded(child: _buildContent(state, colors, isDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(AnimalsMissionState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Animals.missionTitle,
                  style: GoogleFonts.alata(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${Animals.roundShort} ${state.currentRound}/${state.totalRounds}',
                  style: GoogleFonts.alata(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          _buildProgressIndicator(state),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(AnimalsMissionState state) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(state.totalRounds, (index) {
        final isCompleted = index < state.currentRound - 1;
        final isCurrent = index == state.currentRound - 1;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          width: isCurrent ? 14 : 10,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? Colors.white
                : isCurrent
                    ? AppColors.missionYellow
                    : Colors.white.withValues(alpha: 0.35),
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: AppColors.missionYellow.withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }

  Widget _buildContent(
    AnimalsMissionState state,
    AppColorsExtension colors,
    bool isDark,
  ) {
    switch (state.phase) {
      case AnimalsMissionPhase.loading:
        return _buildLoading();
      case AnimalsMissionPhase.showImage:
        return _buildShowImage(state, colors);
      case AnimalsMissionPhase.guessResult:
        return _buildGuessResult(state, colors, isDark);
      case AnimalsMissionPhase.verifyFeedback:
        return _buildVerifyFeedback(state, colors, isDark);
      case AnimalsMissionPhase.teachingPhase:
        return _buildTeachingPhase(state, colors);
      case AnimalsMissionPhase.teachingResult:
        return _buildTeachingResult(state, colors);
      case AnimalsMissionPhase.roundComplete:
        return _buildRoundComplete(state, colors);
      case AnimalsMissionPhase.missionComplete:
        return _buildMissionComplete(colors);
      case AnimalsMissionPhase.error:
        return _buildError(state, colors);
    }
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleInWidget(
            delay: const Duration(milliseconds: 200),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 32),
          FadeInWidget(
            delay: const Duration(milliseconds: 400),
            child: Text(
              Animals.preparingMission,
              style: GoogleFonts.alata(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShowImage(AnimalsMissionState state, AppColorsExtension colors) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 80,
      ),
      child: Column(
        children: [
          // Pixy thinking card with glassmorphism
          FadeInWidget(
            delay: const Duration(milliseconds: 200),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      ScaleTransition(
                        scale: _pixyScaleAnimation,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              AppAssets.welcomePage2Thinking,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              Animals.pixyName,
                              style: GoogleFonts.alata(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              Animals.pixyThinkingShort,
                              style: GoogleFonts.alata(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (state.isLoading)
                        const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Instruction text
          FadeInWidget(
            delay: const Duration(milliseconds: 300),
            child: Text(
              Animals.lookAtImage,
              textAlign: TextAlign.center,
              style: GoogleFonts.alata(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.95),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Animal image card
          SlideUpWidget(
            delay: const Duration(milliseconds: 350),
            offset: 40,
            child: _buildAnimalImage(state.currentImage, colors),
          ),
          const SizedBox(height: 24),
          // Continue button
          SlideUpWidget(
            delay: const Duration(milliseconds: 450),
            offset: 30,
            child: GestureDetector(
              onTap: state.isLoading
                  ? null
                  : () => ref.read(animalsControllerProvider.notifier).makePixyGuess(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_primaryColor, _primaryLightColor],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryColor.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: state.isLoading
                    ? const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            Animals.continueAction,
                            style: GoogleFonts.alata(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 20,
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

  Widget _buildAnimalImage(AnimalImage? image, AppColorsExtension colors) {
    if (image == null) return const SizedBox();

    final imageUrl = AnimalsRepository.getImageUrl(image.url);

    return Container(
      constraints: const BoxConstraints(minHeight: 280, maxHeight: 400),
      decoration: BoxDecoration(
        color: colors.cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withValues(alpha: 0.2),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: colors.surface),
            Center(
              child: _buildImageWidget(imageUrl, colors),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(String imageUrl, AppColorsExtension colors) {
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.contain,
      );
    }
    return Image.network(
      imageUrl,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
            color: _primaryColor,
            strokeWidth: 2.5,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_rounded,
              size: 56,
              color: colors.textHint,
            ),
            const SizedBox(height: 12),
            Text(
              Animals.imageLoadError,
              style: GoogleFonts.alata(
                color: colors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGuessResult(
    AnimalsMissionState state,
    AppColorsExtension colors,
    bool isDark,
  ) {
    final guess = state.lastGuess;
    if (guess == null) return const SizedBox();

    final cardGradient = isDark
        ? [colors.cardColor, colors.surface]
        : [Colors.white.withValues(alpha: 0.95), Colors.white.withValues(alpha: 0.85)];

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 80,
      ),
      child: Column(
        children: [
          // Pixy's guess card - glassmorphism with gradient accent
          FadeInWidget(
            delay: const Duration(milliseconds: 150),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: cardGradient,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isDark ? colors.border : Colors.white.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryColor.withValues(alpha: 0.12),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      ScaleTransition(
                        scale: _pixyScaleAnimation,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [_primaryColor, _primaryLightColor],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _primaryColor.withValues(alpha: 0.45),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              AppAssets.welcomePage2Thinking,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        Animals.guessLeadIn,
                        style: GoogleFonts.alata(
                          fontSize: 15,
                          color: colors.textSecondary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Guess in gradient pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_primaryColor, _primaryLightColor],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: _primaryColor.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          guess.guess.toUpperCase(),
                          style: GoogleFonts.alata(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Confidence indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 16,
                            color: _primaryColor.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            Animals.guessConfidencePercent(
                              (guess.confidence * 100).toInt(),
                            ),
                            style: GoogleFonts.alata(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _primaryColor.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Verification section - stronger glassmorphism
          SlideUpWidget(
            delay: const Duration(milliseconds: 300),
            offset: 35,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.school_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              Animals.verifyQuestion,
                              style: GoogleFonts.alata(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildVerifyButton(
                              icon: Icons.check_rounded,
                              label: Animals.verifyYes,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF4CAF50),
                                  Color(0xFF66BB6A),
                                ],
                              ),
                              onTap: () => ref
                                  .read(animalsControllerProvider.notifier)
                                  .verifyGuess(true),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildVerifyButton(
                              icon: Icons.close_rounded,
                              label: Animals.verifyNo,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFFF7043),
                                  Color(0xFFE53935),
                                ],
                              ),
                              onTap: () => ref
                                  .read(animalsControllerProvider.notifier)
                                  .verifyGuess(false),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyButton({
    required IconData icon,
    required String label,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.alata(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerifyFeedback(
    AnimalsMissionState state,
    AppColorsExtension colors,
    bool isDark,
  ) {
    final response = state.verifyResponse;
    if (response == null) return const SizedBox();

    final wasCorrect = response.wasActuallyCorrect;
    final userWasRight = response.userWasRight;

    final feedbackCardGradient = isDark
        ? [colors.cardColor, colors.surface]
        : [
            Colors.white.withValues(alpha: 0.95),
            Colors.white.withValues(alpha: 0.88),
          ];

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).padding.bottom + 80,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Main feedback card - glassmorphism
            ScaleInWidget(
              delay: const Duration(milliseconds: 100),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: feedbackCardGradient,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: isDark ? colors.border : Colors.white.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryColor.withValues(alpha: 0.12),
                          blurRadius: 36,
                          offset: const Offset(0, 14),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon in gradient circle
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: userWasRight
                                  ? [
                                      AppColors.success,
                                      const Color(0xFF66BB6A),
                                    ]
                                  : [
                                      _primaryColor,
                                      _primaryLightColor,
                                    ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (userWasRight
                                        ? AppColors.success
                                        : _primaryColor)
                                    .withValues(alpha: 0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Icon(
                            userWasRight
                                ? Icons.check_circle_rounded
                                : Icons.school_rounded,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          response.message,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.alata(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            // CTA button
            SlideUpWidget(
              delay: const Duration(milliseconds: 250),
              offset: 30,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => ref
                      .read(animalsControllerProvider.notifier)
                      .continueAfterVerify(),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: wasCorrect
                            ? [
                                AppColors.success,
                                const Color(0xFF66BB6A),
                              ]
                            : [
                                _primaryColor,
                                _primaryLightColor,
                              ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: (wasCorrect ? AppColors.success : _primaryColor)
                            .withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          wasCorrect
                              ? Animals.nextRoundExcited
                              : Animals.teachPixy,
                          style: GoogleFonts.alata(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          wasCorrect
                              ? Icons.arrow_forward_rounded
                              : Icons.school_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeachingPhase(
    AnimalsMissionState state,
    AppColorsExtension colors,
  ) {
    final teachingData = state.teachingImages;
    if (teachingData == null) return const SizedBox();

    final canSubmit = state.selectedImageIds.isNotEmpty;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: FadeInWidget(
            delay: const Duration(milliseconds: 200),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Animals.teachPixy,
                          style: GoogleFonts.alata(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          Animals.selectAllTargetFor(
                            teachingData.targetAnimal.toUpperCase(),
                          ),
                          style: GoogleFonts.alata(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.0,
            ),
            itemCount: teachingData.images.length,
            itemBuilder: (context, index) {
              final image = teachingData.images[index];
              final isSelected = state.selectedImageIds.contains(image.id);
              return SlideUpWidget(
                delay: Duration(milliseconds: 200 + (index * 80)),
                offset: 30,
                child: _buildTeachingImageCard(image, isSelected, colors),
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(context).padding.bottom + 80,
          ),
          child: GestureDetector(
            onTap: canSubmit
                ? () => ref.read(animalsControllerProvider.notifier).submitTeaching()
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                gradient: canSubmit
                    ? const LinearGradient(
                        colors: [_primaryColor, _primaryLightColor],
                      )
                    : null,
                color: canSubmit ? null : colors.border,
                borderRadius: BorderRadius.circular(24),
                boxShadow: canSubmit
                    ? [
                        BoxShadow(
                          color: _primaryColor.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: canSubmit ? Colors.white : colors.textHint,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    Animals.submitTeachingCount(state.selectedImageIds.length),
                    style: GoogleFonts.alata(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: canSubmit ? Colors.white : colors.textHint,
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

  Widget _buildTeachingImageCard(
    AnimalImage image,
    bool isSelected,
    AppColorsExtension colors,
  ) {
    final imageUrl = AnimalsRepository.getImageUrl(image.url);

    return GestureDetector(
      onTap: () => ref
          .read(animalsControllerProvider.notifier)
          .toggleImageSelection(image.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: colors.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _primaryColor : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? _primaryColor.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.08),
              blurRadius: isSelected ? 16 : 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(17),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(color: colors.surface),
              Center(
                child: _buildImageWidget(imageUrl, colors),
              ),
              if (isSelected)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_primaryColor, _primaryLightColor],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _primaryColor.withValues(alpha: 0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeachingResult(
    AnimalsMissionState state,
    AppColorsExtension colors,
  ) {
    final result = state.teachingResult;
    if (result == null) return const SizedBox();

    final accentColor = result.isCorrect ? AppColors.success : AppColors.missionPeach;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).padding.bottom + 80,
        ),
        child: ScaleInWidget(
          delay: const Duration(milliseconds: 150),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: colors.cardColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: colors.border),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  result.isCorrect ? Icons.celebration_rounded : Icons.refresh_rounded,
                  size: 72,
                  color: accentColor,
                ),
                const SizedBox(height: 20),
                Text(
                  result.message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.alata(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    Animals.teachingScoreLine(
                      result.correctCount,
                      result.totalCorrect,
                    ),
                    style: GoogleFonts.alata(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => ref
                      .read(animalsControllerProvider.notifier)
                      .continueAfterTeaching(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 36,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: result.isCorrect
                            ? [AppColors.success, const Color(0xFF66BB6A)]
                            : [AppColors.missionPeach, const Color(0xFFFFCCBC)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Text(
                      result.isCorrect
                          ? Animals.continueShort
                          : Animals.retry,
                      style: GoogleFonts.alata(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoundComplete(
    AnimalsMissionState state,
    AppColorsExtension colors,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).padding.bottom + 80,
        ),
        child: ScaleInWidget(
          delay: const Duration(milliseconds: 150),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: colors.cardColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: colors.border),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withValues(alpha: 0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎉', style: TextStyle(fontSize: 72)),
                const SizedBox(height: 20),
                Text(
                  Animals.roundCompleteTitleFor(state.currentRound),
                  style: GoogleFonts.alata(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => ref
                      .read(animalsControllerProvider.notifier)
                      .nextRound(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 36,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_primaryColor, _primaryLightColor],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryColor.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Text(
                      Animals.nextRound,
                      style: GoogleFonts.alata(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMissionComplete(AppColorsExtension colors) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).padding.bottom + 80,
        ),
        child: ScaleInWidget(
          delay: const Duration(milliseconds: 150),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: colors.cardColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: colors.border),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withValues(alpha: 0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🏆', style: TextStyle(fontSize: 88)),
                const SizedBox(height: 20),
                Text(
                  Animals.missionCompleteTitle,
                  style: GoogleFonts.alata(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: _primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  Animals.missionCompleteBody,
                  style: GoogleFonts.alata(
                    fontSize: 16,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 28),
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 36,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_primaryColor, _primaryLightColor],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryColor.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          Animals.backToMissions,
                          style: GoogleFonts.alata(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError(AnimalsMissionState state, AppColorsExtension colors) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).padding.bottom + 80,
        ),
        child: ScaleInWidget(
          delay: const Duration(milliseconds: 150),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: colors.cardColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: colors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.error.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 72,
                  color: AppColors.error,
                ),
                const SizedBox(height: 20),
                Text(
                  Animals.oopsTitle,
                  style: GoogleFonts.alata(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  state.errorMessage ?? UserErrors.somethingWentWrong,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.alata(
                    fontSize: 15,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 28),
                GestureDetector(
                  onTap: () => ref
                      .read(animalsControllerProvider.notifier)
                      .startMission(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 36,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_primaryColor, _primaryLightColor],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryColor.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Text(
                      Animals.retry,
                      style: GoogleFonts.alata(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
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
