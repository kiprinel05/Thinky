import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thinky/core_controls/constants/app_texts.dart';
import 'package:thinky/core_controls/services/language_service.dart';
import 'package:thinky/shared_controls/theme/app_colors.dart';
import 'package:thinky/shared_controls/theme/app_colors_extension.dart';
import '../../data/vocabulary_models.dart';
import '../../data/vocabulary_repository.dart';
import '../controllers/vocabulary_controller.dart';

/// Main page for the Vocabulary Mission
/// "Select the image that matches the word"
class VocabularyMissionPage extends ConsumerStatefulWidget {
  const VocabularyMissionPage({super.key});

  @override
  ConsumerState<VocabularyMissionPage> createState() =>
      _VocabularyMissionPageState();
}

class _VocabularyMissionPageState extends ConsumerState<VocabularyMissionPage>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _wordBounceController;
  late AnimationController _feedbackController;
  late AnimationController _sparkleController;
  late AnimationController _encouragementController;

  late Animation<double> _wordScale;
  late Animation<double> _feedbackSlide;
  late Animation<double> _sparkleOpacity;
  late Animation<double> _encouragementOpacity;

  @override
  void initState() {
    super.initState();

    _wordBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _wordScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _wordBounceController, curve: Curves.elasticOut),
    );

    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _feedbackSlide = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _feedbackController, curve: Curves.easeOutBack),
    );

    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _sparkleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _sparkleController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
        reverseCurve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    _encouragementController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _encouragementOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _encouragementController, curve: Curves.easeOut),
    );

    // Start mission
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(vocabularyControllerProvider.notifier).startMission();
    });
  }

  @override
  void dispose() {
    _wordBounceController.dispose();
    _feedbackController.dispose();
    _sparkleController.dispose();
    _encouragementController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(textRefreshProvider);
    final colors = context.appColors;
    final state = ref.watch(vocabularyControllerProvider);

    // Listen for phase changes to trigger animations
    ref.listen<VocabMissionState>(vocabularyControllerProvider, (prev, next) {
      if (next.phase == VocabMissionPhase.question &&
          prev?.phase != VocabMissionPhase.question) {
        _wordBounceController.forward(from: 0.0);
      }
      if (next.phase == VocabMissionPhase.feedback) {
        _feedbackController.forward(from: 0.0);
        if (next.lastAnswer?.correct == true) {
          _sparkleController.forward(from: 0.0);
        }
        if (next.encouragement != null) {
          _encouragementController.forward(from: 0.0);
        }
      }
    });

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(state, colors),
            if (state.phase == VocabMissionPhase.question ||
                state.phase == VocabMissionPhase.feedback ||
                state.phase == VocabMissionPhase.submitting)
              _buildProgressDots(state, colors),
            Expanded(child: _buildContent(state, colors)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // APP BAR
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAppBar(VocabMissionState state, AppColorsExtension colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(true),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
              ),
              child: Icon(Icons.arrow_back, color: colors.textPrimary, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Vocabulary.title,
                  style: GoogleFonts.alata(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  Vocabulary.subtitle,
                  style: GoogleFonts.alata(
                    fontSize: 12,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (state.answeredCount > 0)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.25)),
              ),
              child: Text(
                '${state.correctCount}/${state.answeredCount}',
                style: GoogleFonts.alata(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryPurple,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PROGRESS DOTS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildProgressDots(VocabMissionState state, AppColorsExtension colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(state.totalQuestions, (index) {
          Color dotColor;
          double size;
          if (index < state.answeredCount) {
            dotColor = AppColors.correctGreen;
            size = 8;
          } else if (index == state.currentIndex) {
            dotColor = AppColors.primaryPurple;
            size = 12;
          } else {
            dotColor = colors.border;
            size = 8;
          }
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          );
        }),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONTENT ROUTER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildContent(VocabMissionState state, AppColorsExtension colors) {
    switch (state.phase) {
      case VocabMissionPhase.loading:
        return _buildLoading(colors, Vocabulary.loadingWords);
      case VocabMissionPhase.submitting:
        return _buildLoading(colors, Vocabulary.submittingShort);
      case VocabMissionPhase.question:
        return _buildQuestionPhase(state, colors);
      case VocabMissionPhase.feedback:
        return _buildFeedbackPhase(state, colors);
      case VocabMissionPhase.missionComplete:
        return _buildMissionComplete(state, colors);
      case VocabMissionPhase.error:
        return _buildError(state, colors);
    }
  }

  Widget _buildLoading(AppColorsExtension colors, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primaryPurple),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.alata(fontSize: 16, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // QUESTION PHASE — Word Card + Image Grid
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildQuestionPhase(VocabMissionState state, AppColorsExtension colors) {
    final question = state.currentQuestion;
    if (question == null) return _buildLoading(colors, Vocabulary.loadingWords);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 12),

          // Word card with bounce animation
          AnimatedBuilder(
            animation: _wordBounceController,
            builder: (context, child) {
              return Transform.scale(
                scale: _wordScale.value,
                child: child,
              );
            },
            child: _buildWordCard(question.word),
          ),

          const SizedBox(height: 24),

          // Image grid
          Expanded(
            child: _buildImageGrid(question, state.selectedImageId, colors),
          ),

          // Submit button
          if (state.hasSelection)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildSubmitButton(),
            ),
        ],
      ),
    );
  }

  Widget _buildWordCard(String word) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8E97FD), Color(0xFFA5AEFD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8E97FD).withAlpha(77),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '📖',
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(height: 8),
          Text(
            word,
            style: GoogleFonts.alata(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            Vocabulary.findMatchingImage,
            style: GoogleFonts.alata(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid(
    VocabQuestion question,
    int? selectedId,
    AppColorsExtension colors,
  ) {
    final images = question.images;
    // Use 2 columns
    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.0,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        return _buildImageOption(images[index], selectedId, colors);
      },
    );
  }

  Widget _buildImageOption(
    VocabImage image,
    int? selectedId,
    AppColorsExtension colors,
  ) {
    final isSelected = selectedId == image.id;
    final resolvedUrl = VocabularyRepository.getImageUrl(image.url);
    final controller = ref.read(vocabularyControllerProvider.notifier);

    return GestureDetector(
      onTap: () => controller.selectImage(image.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: colors.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.primaryPurple : colors.border,
            width: isSelected ? 3.0 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryPurple.withValues(alpha: 0.22),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ],
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _buildVocabImage(
                resolvedUrl: resolvedUrl,
                label: image.label,
                colors: colors,
              ),
            ),
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryPurple,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 18),
                ),
              ),
            if (isSelected)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primaryPurple.withValues(alpha: 0.35),
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVocabImage({
    required String resolvedUrl,
    required String label,
    required AppColorsExtension colors,
  }) {
    Widget fallback() => Container(
          color: colors.surface,
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              label.isNotEmpty ? label : Vocabulary.imageError,
              textAlign: TextAlign.center,
              style: GoogleFonts.alata(
                fontSize: 14,
                color: colors.textSecondary,
              ),
            ),
          ),
        );

    if (resolvedUrl.startsWith('assets/')) {
      return Image.asset(
        resolvedUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => fallback(),
      );
    }

    return Image.network(
      resolvedUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: colors.surface,
          alignment: Alignment.center,
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primaryPurple,
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded /
                      progress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => fallback(),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: () {
          ref.read(vocabularyControllerProvider.notifier).submitAnswer();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8E97FD),
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
        ),
        child: Text(
          Vocabulary.submitAnswer,
          style: GoogleFonts.alata(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FEEDBACK PHASE — Correct / Incorrect with animations
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildFeedbackPhase(VocabMissionState state, AppColorsExtension colors) {
    final answer = state.lastAnswer;
    if (answer == null) return _buildLoading(colors, Vocabulary.loadingWords);

    final isCorrect = answer.correct;
    final accentColor =
        isCorrect ? AppColors.correctGreen : AppColors.missionPeach;
    final question = state.currentQuestion;

    return Stack(
      children: [
        // Main feedback content
        AnimatedBuilder(
          animation: _feedbackController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _feedbackSlide.value),
              child: Opacity(
                opacity: _feedbackController.value,
                child: child,
              ),
            );
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Big result icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: accentColor.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      isCorrect ? '✅' : '💡',
                      style: const TextStyle(fontSize: 40),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Message
                Text(
                  answer.message,
                  style: GoogleFonts.alata(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Show correct answer image if incorrect
                if (!isCorrect && question != null) ...[
                  Text(
                    Vocabulary.correctImageCaption,
                    style: GoogleFonts.alata(
                      fontSize: 14,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildCorrectAnswerCard(question, answer.correctImageId, colors),
                  const SizedBox(height: 20),
                ],

                // Mascot encouragement bubble
                if (state.encouragement != null)
                  AnimatedBuilder(
                    animation: _encouragementController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _encouragementOpacity.value,
                        child: Transform.translate(
                          offset: Offset(
                              0, 10 * (1 - _encouragementOpacity.value)),
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primaryPurple.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🤖', style: TextStyle(fontSize: 22)),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              state.encouragement!,
                              style: GoogleFonts.alata(
                                fontSize: 14,
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 32),

                // Next button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      ref
                          .read(vocabularyControllerProvider.notifier)
                          .nextQuestion();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                    child: Text(
                      state.currentIndex + 1 >= state.totalQuestions
                          ? Vocabulary.seeResultsWithTrophy
                          : Vocabulary.nextWordArrow,
                      style: GoogleFonts.alata(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ✨ Sparkle animation on correct answer (UI Enhancement)
        if (isCorrect)
          AnimatedBuilder(
            animation: _sparkleController,
            builder: (context, _) {
              return Opacity(
                opacity: _sparkleOpacity.value * 0.7,
                child: IgnorePointer(
                  child: SizedBox.expand(
                    child: CustomPaint(
                      painter:
                          _SparklePainter(progress: _sparkleController.value),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildCorrectAnswerCard(
    VocabQuestion question,
    int correctId,
    AppColorsExtension colors,
  ) {
    final correctImage =
        question.images.where((img) => img.id == correctId).firstOrNull;
    if (correctImage == null) return const SizedBox.shrink();

    final imageUrl = VocabularyRepository.getImageUrl(correctImage.url);

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: colors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.correctGreen, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.correctGreen.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: _buildVocabImage(
          resolvedUrl: imageUrl,
          label: correctImage.label,
          colors: colors,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MISSION COMPLETE
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMissionComplete(VocabMissionState state, AppColorsExtension colors) {
    final accuracy = state.totalQuestions > 0
        ? (state.correctCount / state.totalQuestions * 100).toInt()
        : 0;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF66BB6A).withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🏆', style: TextStyle(fontSize: 50)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              Vocabulary.missionComplete,
              style: GoogleFonts.alata(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatBox(Vocabulary.statAccuracy, '$accuracy%',
                    accuracy >= 80 ? AppColors.correctGreen : AppColors.missionPeach, colors),
                _buildStatBox(Vocabulary.statCorrect, '${state.correctCount}/${state.totalQuestions}',
                    AppColors.primaryPurple, colors),
              ],
            ),
            const SizedBox(height: 20),

            Text(
              accuracy >= 90
                  ? Vocabulary.completeLineHigh
                  : accuracy >= 70
                      ? Vocabulary.completeLineMid
                      : Vocabulary.completeLineLow,
              style: GoogleFonts.alata(
                fontSize: 16,
                color: colors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8E97FD),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
                child: Text(
                  Common.backToMissions,
                  style: GoogleFonts.alata(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(
    String label,
    String value,
    Color color,
    AppColorsExtension colors,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.alata(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.alata(
                fontSize: 12, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ERROR
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildError(VocabMissionState state, AppColorsExtension colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              Common.error,
              style: GoogleFonts.alata(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.errorMessage ?? UserErrors.somethingWentWrong,
              style: GoogleFonts.alata(
                  fontSize: 14, color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(vocabularyControllerProvider.notifier)
                    .startMission();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                Vocabulary.tryAgain,
                style: GoogleFonts.alata(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SPARKLE PAINTER — Success animation on correct answer
// ═══════════════════════════════════════════════════════════════════════════

class _SparklePainter extends CustomPainter {
  final double progress;
  final Random _random = Random(42); // Fixed seed for consistent sparkles

  _SparklePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // Draw sparkles at random positions
    for (int i = 0; i < 12; i++) {
      final x = _random.nextDouble() * size.width;
      final y = _random.nextDouble() * size.height * 0.6;
      final sparkleSize = 4.0 + _random.nextDouble() * 8;
      final delay = _random.nextDouble() * 0.5;

      final adjustedProgress = ((progress - delay) * 2).clamp(0.0, 1.0);
      if (adjustedProgress <= 0) continue;

      final scale = adjustedProgress < 0.5
          ? adjustedProgress * 2
          : 2 - adjustedProgress * 2;

      final s = sparkleSize * scale;
      if (s <= 0) continue;

      paint.color = Color.lerp(
        const Color(0xFFFFD54F),
        const Color(0xFF8E97FD),
        _random.nextDouble(),
      )!
          .withAlpha((200 * scale).toInt());

      // Draw a small cross/star
      canvas.drawLine(Offset(x - s, y), Offset(x + s, y), paint);
      canvas.drawLine(Offset(x, y - s), Offset(x, y + s), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
