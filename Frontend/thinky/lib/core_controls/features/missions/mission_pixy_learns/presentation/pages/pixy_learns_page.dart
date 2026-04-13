import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thinky/base_controls/base_state.dart';
import 'package:thinky/shared_controls/widgets/animations/animated_widgets.dart';
import 'package:thinky/shared_controls/theme/app_colors.dart';
import 'package:thinky/shared_controls/theme/app_colors_extension.dart';
import 'package:thinky/shared_controls/assets/app_assets.dart';
import 'package:thinky/core_controls/constants/app_texts.dart';
import 'package:thinky/core_controls/services/language_service.dart';
import '../controllers/pixy_learns_controller.dart';
import '../controllers/pixy_learns_state.dart';
import '../../data/pixy_learns_image_url.dart';
import '../../domain/pixy_learns_models.dart';
import 'pixy_learns_learning_view.dart';

/// Main page for Pixy Learns mission
class PixyLearnsPage extends ConsumerStatefulWidget {
  const PixyLearnsPage({super.key});

  @override
  ConsumerState<PixyLearnsPage> createState() => _PixyLearnsPageState();
}

class _PixyLearnsPageState extends ConsumerState<PixyLearnsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pixyAnimationController;
  late Animation<double> _pixyScaleAnimation;

  // Theme colors
  static const Color _primaryColor = AppColors.primaryPurple;
  static const Color _primaryLightColor = AppColors.primaryPurpleLight;
  static const Color _accentGreen = Color(0xFF4CAF50);

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

    // Load images on init
    Future.microtask(() => ref.read(pixyLearnsStateProvider.notifier).loadImages());
  }

  @override
  void dispose() {
    _pixyAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(textRefreshProvider);
    final state = ref.watch(pixyLearnsStateProvider);

    if (state.status == StateStatus.loading) {
      return _buildLoadingScreen();
    }

    if (state.showIntroduction) {
      return _buildIntroductionScreen(state);
    }

    if (state.showCompletion) {
      if (state.showLearning) {
        return Scaffold(
          body: PixyLearnsLearningView(
            onDone: () => ref.read(pixyLearnsStateProvider.notifier).closeLearning(),
          ),
        );
      }
      return _buildCompletionScreen(state);
    }

    return _buildMainScreen(state);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LOADING SCREEN
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_primaryColor, _primaryLightColor],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
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
                      const SizedBox(height: 32),
                      Text(
                        PixyLearnsTexts.preparingLessons,
                        style: GoogleFonts.alata(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
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
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // INTRODUCTION SCREEN
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildIntroductionScreen(PixyLearnsState state) {
    final controller = ref.read(pixyLearnsStateProvider.notifier);
    
    return Scaffold(
      backgroundColor: context.appColors.background,
      body: Stack(
        children: [
          // Purple gradient header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 320,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_primaryColor, _primaryLightColor],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        
                        // Pixy mascot
                        ScaleInWidget(
                          delay: const Duration(milliseconds: 200),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                            child: ScaleTransition(
                              scale: _pixyScaleAnimation,
                              child: Image.asset(
                                AppAssets.welcomePage2Thinking,
                                height: 140,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Title card
                        FadeInWidget(
                          delay: const Duration(milliseconds: 400),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: context.appColors.cardColor,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: context.appColors.border),
                              boxShadow: [
                                BoxShadow(
                                  color: _primaryColor.withValues(alpha: 0.15),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [_primaryColor, _primaryLightColor],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(
                                    Icons.psychology_rounded,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  PixyLearnsTexts.introTitle,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.alata(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    color: context.appColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  PixyLearnsTexts.introBody,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.alata(
                                    fontSize: 15,
                                    color: context.appColors.textSecondary,
                                    height: 1.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Feature pills
                        FadeInWidget(
                          delay: const Duration(milliseconds: 500),
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            alignment: WrapAlignment.center,
                            children: [
                              _buildFeaturePill(Icons.image_rounded, "${state.images.length} ${PixyLearnsTexts.pillImages}"),
                              _buildFeaturePill(Icons.category_rounded, "2 ${PixyLearnsTexts.pillCategories}"),
                              _buildFeaturePill(Icons.auto_awesome, PixyLearnsTexts.pillAi),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // Start button
                        FadeInWidget(
                          delay: const Duration(milliseconds: 600),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              gradient: const LinearGradient(
                                colors: [_primaryColor, _primaryLightColor],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _primaryColor.withValues(alpha: 0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: controller.startMission,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    PixyLearnsTexts.startTeaching,
                                    style: GoogleFonts.alata(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 17,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturePill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _primaryColor.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: _primaryColor),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.alata(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MAIN SCREEN (Image Labeling)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildMainScreen(PixyLearnsState state) {
    final controller = ref.read(pixyLearnsStateProvider.notifier);
    
    return Scaffold(
      backgroundColor: context.appColors.background,
      body: Stack(
        children: [
          // Gradient header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 200,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_primaryColor, _primaryLightColor],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                _buildProgressSection(state),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        _buildInstructions(),
                        const SizedBox(height: 24),
                        _buildImagesGrid(state, controller),
                        const SizedBox(height: 28),
                        _buildSubmitButton(state, controller),
                        // Extra padding so submit button is not covered by navbar when pushed from missions
                        SizedBox(height: MediaQuery.of(context).padding.bottom + 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.school_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  PixyLearnsTexts.chapter1,
                  style: GoogleFonts.alata(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(PixyLearnsState state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_graph_rounded, color: Colors.white.withValues(alpha: 0.9), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    PixyLearnsTexts.learningProgress,
                    style: GoogleFonts.alata(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${state.labels.length}/${state.images.length}',
                  style: GoogleFonts.alata(
                    color: _primaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  widthFactor: state.progress,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.white, Color(0xFFE3E7FF)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FadeInWidget(
      delay: const Duration(milliseconds: 300),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.lightbulb_rounded,
                color: _primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    PixyLearnsTexts.teachPixyHeader,
                    style: GoogleFonts.alata(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    PixyLearnsTexts.teachPixyHint,
                    style: GoogleFonts.alata(
                      fontSize: 13,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagesGrid(PixyLearnsState state, PixyLearnsController controller) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.78,
      ),
      itemCount: state.images.length,
      itemBuilder: (context, index) {
        final image = state.images[index];
        final selectedLabel = state.getLabel(image.id);
        return _buildImageCard(image, selectedLabel, index, controller);
      },
    );
  }

  Widget _buildImageCard(
    LearningImage image, 
    String? selectedLabel, 
    int index,
    PixyLearnsController controller,
  ) {
    final bool isLabeled = selectedLabel != null;
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ScaleInWidget(
      delay: Duration(milliseconds: 400 + (index * 80)),
      child: Container(
        decoration: BoxDecoration(
          color: colors.cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: isLabeled 
                  ? _primaryColor.withValues(alpha: 0.15) 
                  : Colors.black.withValues(alpha: isDark ? 0.28 : 0.06),
              blurRadius: isLabeled ? 20 : 15,
              offset: const Offset(0, 6),
            ),
          ],
          border: isLabeled
              ? Border.all(color: _primaryColor.withValues(alpha: 0.3), width: 2)
              : Border.all(color: colors.border),
        ),
        child: Column(
          children: [
            // Image container
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Center(
                        child: _buildImageDisplay(context, image.url),
                      ),
                    ),
                    if (isLabeled)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: _accentGreen,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Label buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
              child: Row(
                children: [
                  Expanded(
                    child: _buildLabelButton(
                      PixyLearnsTexts.labelApple,
                      'apple',
                      selectedLabel == 'apple',
                      () => controller.selectLabel(image.id, 'apple'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildLabelButton(
                      PixyLearnsTexts.labelCat,
                      'cat',
                      selectedLabel == 'cat',
                      () => controller.selectLabel(image.id, 'cat'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageLoadFailure(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_rounded,
            size: 48,
            color: colors.textHint,
          ),
          const SizedBox(height: 8),
          Text(
            PixyLearnsTexts.imageUnavailable,
            textAlign: TextAlign.center,
            style: GoogleFonts.alata(
              fontSize: 11,
              color: colors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageDisplay(BuildContext context, String imageUrl) {
    if (imageUrl.startsWith('emoji:')) {
      final emoji = imageUrl.substring(6);
      return Container(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 56),
          ),
        ),
      );
    }

    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildImageLoadFailure(context),
      );
    }

    final resolved = PixyLearnsImageUrl.resolve(imageUrl);
    if (resolved.isEmpty) {
      return _buildImageLoadFailure(context);
    }

    return Image.network(
      resolved,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
            color: _primaryColor,
            strokeWidth: 2,
          ),
        );
      },
      errorBuilder: (_, __, ___) => _buildImageLoadFailure(context),
    );
  }

  Widget _buildLabelButton(String label, String value, bool isSelected, VoidCallback onTap) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(colors: [_primaryColor, _primaryLightColor])
              : null,
          color: isSelected ? null : colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.transparent : colors.border,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.alata(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : colors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(PixyLearnsState state, PixyLearnsController controller) {
    final allLabeled = state.allLabeled;
    final colors = context.appColors;
    
    return FadeInWidget(
      delay: const Duration(milliseconds: 500),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: allLabeled
              ? const LinearGradient(colors: [_primaryColor, _primaryLightColor])
              : null,
          color: allLabeled ? null : colors.inputFill,
          border: Border.all(color: allLabeled ? Colors.transparent : colors.border),
          boxShadow: allLabeled
              ? [
                  BoxShadow(
                    color: _primaryColor.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: ElevatedButton(
          onPressed: allLabeled && !state.isSubmitting ? controller.submitLabels : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          child: state.isSubmitting
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: allLabeled ? Colors.white : colors.textHint,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      PixyLearnsTexts.teachPixyCta,
                      style: GoogleFonts.alata(
                        color: allLabeled ? Colors.white : colors.textHint,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // COMPLETION SCREEN
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildCompletionScreen(PixyLearnsState state) {
    final result = state.result;
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomGradient = isDark ? AppColors.darkBackground : const Color(0xFFF5F6FA);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_primaryColor, _primaryLightColor, bottomGradient],
            stops: const [0.0, 0.35, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      
                      ScaleInWidget(
                        delay: const Duration(milliseconds: 200),
                        child: Image.asset(
                          AppAssets.welcomePage1Hello,
                          height: 160,
                          fit: BoxFit.contain,
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      FadeInWidget(
                        delay: const Duration(milliseconds: 400),
                        child: Text(
                          PixyLearnsTexts.amazingJob,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.alata(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 28),
                      
                      // Stats card
                      FadeInWidget(
                        delay: const Duration(milliseconds: 500),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: colors.cardColor,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: colors.border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                                blurRadius: 30,
                                offset: const Offset(0, 15),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.emoji_events_rounded,
                                  color: Colors.white,
                                  size: 36,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                PixyLearnsTexts.learnedExamples(
                                  result?.learnedExamples ?? state.images.length,
                                ),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.alata(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: _primaryColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.category_rounded, color: _primaryColor, size: 20),
                                    const SizedBox(width: 10),
                                    Text(
                                      PixyLearnsTexts.categoriesLine(
                                        result?.categories.join(', ') ?? 'apple, cat',
                                      ),
                                      style: GoogleFonts.alata(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Explanation
                      FadeInWidget(
                        delay: const Duration(milliseconds: 600),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: colors.cardColor.withValues(alpha: isDark ? 0.95 : 0.92),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: colors.border.withValues(alpha: 0.6)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: _primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.info_outline_rounded,
                                  color: _primaryColor,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  PixyLearnsTexts.aiExplanation,
                                  style: GoogleFonts.alata(
                                    fontSize: 14,
                                    color: colors.textSecondary,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 28),
                      
                      // Learn with Pixy button (primary)
                      FadeInWidget(
                        delay: const Duration(milliseconds: 700),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: const LinearGradient(
                              colors: [_primaryColor, _primaryLightColor],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _primaryColor.withValues(alpha: 0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () => ref.read(pixyLearnsStateProvider.notifier).openLearning(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.auto_stories_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  PixyLearnsTexts.lessonButton,
                                  style: GoogleFonts.alata(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Continue to missions button (secondary)
                      FadeInWidget(
                        delay: const Duration(milliseconds: 800),
                        child: SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: TextButton.styleFrom(
                              foregroundColor: colors.textSecondary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  PixyLearnsTexts.continueMissions,
                                  style: GoogleFonts.alata(
                                    color: colors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: colors.textSecondary,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
