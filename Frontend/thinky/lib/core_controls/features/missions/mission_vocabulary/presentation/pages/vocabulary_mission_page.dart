import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(state),
            if (state.phase == VocabMissionPhase.question ||
                state.phase == VocabMissionPhase.feedback ||
                state.phase == VocabMissionPhase.submitting)
              _buildProgressDots(state),
            Expanded(child: _buildContent(state)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // APP BAR
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAppBar(VocabMissionState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(true),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F3F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back,
                  color: Color(0xFF222222), size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Word Match',
                  style: GoogleFonts.alata(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF222222),
                  ),
                ),
                Text(
                  'Select the image that matches the word',
                  style: GoogleFonts.alata(
                    fontSize: 12,
                    color: const Color(0xFF8A8A8F),
                  ),
                ),
              ],
            ),
          ),
          // Score badge
          if (state.answeredCount > 0)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF8E97FD).withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${state.correctCount}/${state.answeredCount}',
                style: GoogleFonts.alata(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF8E97FD),
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

  Widget _buildProgressDots(VocabMissionState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(state.totalQuestions, (index) {
          Color dotColor;
          double size;
          if (index < state.answeredCount) {
            dotColor = const Color(0xFF66BB6A); // Completed
            size = 8;
          } else if (index == state.currentIndex) {
            dotColor = const Color(0xFF8E97FD); // Current
            size = 12;
          } else {
            dotColor = const Color(0xFFE0E0E0); // Future
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

  Widget _buildContent(VocabMissionState state) {
    switch (state.phase) {
      case VocabMissionPhase.loading:
      case VocabMissionPhase.submitting:
        return _buildLoading();
      case VocabMissionPhase.question:
        return _buildQuestionPhase(state);
      case VocabMissionPhase.feedback:
        return _buildFeedbackPhase(state);
      case VocabMissionPhase.missionComplete:
        return _buildMissionComplete(state);
      case VocabMissionPhase.error:
        return _buildError(state);
    }
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFF8E97FD)),
          const SizedBox(height: 16),
          Text(
            'Loading words...',
            style: GoogleFonts.alata(
                fontSize: 16, color: const Color(0xFF8A8A8F)),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // QUESTION PHASE — Word Card + Image Grid
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildQuestionPhase(VocabMissionState state) {
    final question = state.currentQuestion;
    if (question == null) return _buildLoading();

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
            child: _buildImageGrid(question, state.selectedImageId),
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
            'Find the matching image',
            style: GoogleFonts.alata(
              fontSize: 13,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid(VocabQuestion question, int? selectedId) {
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
        return _buildImageOption(images[index], selectedId);
      },
    );
  }

  Widget _buildImageOption(VocabImage image, int? selectedId) {
    final isSelected = selectedId == image.id;
    final imageUrl = VocabularyRepository.getImageUrl(image.url);
    final controller = ref.read(vocabularyControllerProvider.notifier);

    return GestureDetector(
      onTap: () => controller.selectImage(image.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF8E97FD)
                : const Color(0xFFE8E8ED),
            width: isSelected ? 3.0 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF8E97FD).withAlpha(51),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ],
        ),
        child: Stack(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFF2F3F7),
                  child: Center(
                    child: Text(
                      image.label,
                      style: GoogleFonts.alata(
                        fontSize: 14,
                        color: const Color(0xFF8A8A8F),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Selection checkmark
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Color(0xFF8E97FD),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 18),
                ),
              ),

            // Hover effect border overlay
            if (isSelected)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF8E97FD).withAlpha(51),
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
          'Submit Answer',
          style: GoogleFonts.alata(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FEEDBACK PHASE — Correct / Incorrect with animations
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildFeedbackPhase(VocabMissionState state) {
    final answer = state.lastAnswer;
    if (answer == null) return _buildLoading();

    final isCorrect = answer.correct;
    final accentColor =
        isCorrect ? const Color(0xFF66BB6A) : const Color(0xFFFF8A65);
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
                    color: const Color(0xFF222222),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Show correct answer image if incorrect
                if (!isCorrect && question != null) ...[
                  Text(
                    'The correct image:',
                    style: GoogleFonts.alata(
                      fontSize: 14,
                      color: const Color(0xFF8A8A8F),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildCorrectAnswerCard(question, answer.correctImageId),
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
                        color: const Color(0xFF8E97FD).withAlpha(25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF8E97FD).withAlpha(51),
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
                                color: const Color(0xFF666666),
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
                          ? 'See Results 🏆'
                          : 'Next Word →',
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

  Widget _buildCorrectAnswerCard(VocabQuestion question, int correctId) {
    final correctImage =
        question.images.where((img) => img.id == correctId).firstOrNull;
    if (correctImage == null) return const SizedBox.shrink();

    final imageUrl = VocabularyRepository.getImageUrl(correctImage.url);

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF66BB6A), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF66BB6A).withAlpha(51),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Center(
            child: Text(
              correctImage.label,
              style: GoogleFonts.alata(
                  fontSize: 14, color: const Color(0xFF8A8A8F)),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MISSION COMPLETE
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMissionComplete(VocabMissionState state) {
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
              'Mission Complete!',
              style: GoogleFonts.alata(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF222222),
              ),
            ),
            const SizedBox(height: 16),

            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatBox('Accuracy', '$accuracy%',
                    accuracy >= 80 ? const Color(0xFF66BB6A) : const Color(0xFFFF8A65)),
                _buildStatBox('Correct', '${state.correctCount}/${state.totalQuestions}',
                    const Color(0xFF8E97FD)),
              ],
            ),
            const SizedBox(height: 20),

            Text(
              accuracy >= 90
                  ? 'Amazing vocabulary skills! 🌟'
                  : accuracy >= 70
                      ? 'Great work! Keep practicing! 💪'
                      : 'Good effort! Try again to improve! 📚',
              style: GoogleFonts.alata(
                fontSize: 16,
                color: const Color(0xFF8A8A8F),
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
                  'Back to Missions',
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

  Widget _buildStatBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(51)),
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
                fontSize: 12, color: const Color(0xFF8A8A8F)),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ERROR
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildError(VocabMissionState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 60, color: Color(0xFFFF5252)),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: GoogleFonts.alata(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF222222),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.errorMessage ?? 'Unknown error',
              style: GoogleFonts.alata(
                  fontSize: 14, color: const Color(0xFF8A8A8F)),
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
                backgroundColor: const Color(0xFF8E97FD),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                'Try Again',
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
