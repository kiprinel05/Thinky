import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
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

class _AnimalsMissionPageState extends ConsumerState<AnimalsMissionPage> {
  @override
  void initState() {
    super.initState();
    // Start mission when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(animalsControllerProvider.notifier).startMission();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(animalsControllerProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4CAF50), // Green
              Color(0xFF81C784),
              Color(0xFFA5D6A7),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(state),
              Expanded(child: _buildContent(state)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(AnimalsMissionState state) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Teach Pixy Animals',
                  style: GoogleFonts.alata(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Round ${state.currentRound}/${state.totalRounds}',
                  style: GoogleFonts.alata(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          // Progress indicator
          _buildProgressIndicator(state),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(AnimalsMissionState state) {
    return Row(
      children: List.generate(state.totalRounds, (index) {
        final isCompleted = index < state.currentRound - 1;
        final isCurrent = index == state.currentRound - 1;
        return Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? Colors.white
                : isCurrent
                    ? Colors.yellow
                    : Colors.white.withOpacity(0.3),
          ),
        );
      }),
    );
  }

  Widget _buildContent(AnimalsMissionState state) {
    switch (state.phase) {
      case AnimalsMissionPhase.loading:
        return _buildLoading();
      case AnimalsMissionPhase.showImage:
        return _buildShowImage(state);
      case AnimalsMissionPhase.guessResult:
        return _buildGuessResult(state);
      case AnimalsMissionPhase.verifyFeedback:
        return _buildVerifyFeedback(state);
      case AnimalsMissionPhase.teachingPhase:
        return _buildTeachingPhase(state);
      case AnimalsMissionPhase.teachingResult:
        return _buildTeachingResult(state);
      case AnimalsMissionPhase.roundComplete:
        return _buildRoundComplete(state);
      case AnimalsMissionPhase.missionComplete:
        return _buildMissionComplete();
      case AnimalsMissionPhase.error:
        return _buildError(state);
    }
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 24),
          Text(
            'Loading mission...',
            style: GoogleFonts.alata(fontSize: 18, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildShowImage(AnimalsMissionState state) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Pixy thinking
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                // Pixy avatar
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(Icons.smart_toy, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pixy',
                        style: GoogleFonts.alata(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Hmm, let me think... 🤔',
                        style: GoogleFonts.alata(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (state.isLoading)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Animal image
          Expanded(
            child: _buildAnimalImage(state.currentImage),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimalImage(AnimalImage? image) {
    if (image == null) return const SizedBox();

    final imageUrl = AnimalsRepository.getImageUrl(image.url);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 48, color: Colors.red),
                  const SizedBox(height: 8),
                  Text('Failed to load image', 
                    style: GoogleFonts.alata(color: Colors.grey)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGuessResult(AnimalsMissionState state) {
    final guess = state.lastGuess;
    if (guess == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Pixy's guess
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Icon(Icons.smart_toy, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 16),
                Text(
                  'I think this is a...',
                  style: GoogleFonts.alata(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  guess.guess.toUpperCase(),
                  style: GoogleFonts.alata(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(guess.confidence * 100).toInt()}% confident',
                  style: GoogleFonts.alata(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Professor verification
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  '📚 Is Pixy correct?',
                  style: GoogleFonts.alata(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildVerifyButton(
                        label: '✓ Yes, correct!',
                        color: const Color(0xFF4CAF50),
                        onTap: () => ref
                            .read(animalsControllerProvider.notifier)
                            .verifyGuess(true),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildVerifyButton(
                        label: '✗ No, wrong!',
                        color: const Color(0xFFE53935),
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
        ],
      ),
    );
  }

  Widget _buildVerifyButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.alata(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerifyFeedback(AnimalsMissionState state) {
    final response = state.verifyResponse;
    if (response == null) return const SizedBox();

    final wasCorrect = response.wasActuallyCorrect;
    final userWasRight = response.userWasRight;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Icon(
                  userWasRight ? Icons.check_circle : Icons.info,
                  size: 64,
                  color: userWasRight ? Colors.green : Colors.orange,
                ),
                const SizedBox(height: 16),
                Text(
                  response.message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.alata(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => ref
                      .read(animalsControllerProvider.notifier)
                      .continueAfterVerify(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: wasCorrect ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      wasCorrect ? 'Next Round!' : 'Teach Pixy!',
                      style: GoogleFonts.alata(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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

  Widget _buildTeachingPhase(AnimalsMissionState state) {
    final teachingData = state.teachingImages;
    if (teachingData == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  '🎓 Teach Pixy!',
                  style: GoogleFonts.alata(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select all the ${teachingData.targetAnimal.toUpperCase()}s',
                  style: GoogleFonts.alata(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Image grid
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemCount: teachingData.images.length,
              itemBuilder: (context, index) {
                final image = teachingData.images[index];
                final isSelected = state.selectedImageIds.contains(image.id);
                return _buildTeachingImageCard(image, isSelected);
              },
            ),
          ),
          const SizedBox(height: 16),
          // Submit button
          GestureDetector(
            onTap: state.selectedImageIds.isEmpty
                ? null
                : () => ref.read(animalsControllerProvider.notifier).submitTeaching(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: state.selectedImageIds.isEmpty
                    ? Colors.grey
                    : const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'Submit Teaching (${state.selectedImageIds.length} selected)',
                  style: GoogleFonts.alata(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeachingImageCard(AnimalImage image, bool isSelected) {
    final imageUrl = AnimalsRepository.getImageUrl(image.url);

    return GestureDetector(
      onTap: () => ref
          .read(animalsControllerProvider.notifier)
          .toggleImageSelection(image.id),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.transparent,
            width: 4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, size: 48, color: Colors.grey),
                  );
                },
              ),
            ),
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 20),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeachingResult(AnimalsMissionState state) {
    final result = state.teachingResult;
    if (result == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Icon(
                  result.isCorrect ? Icons.celebration : Icons.refresh,
                  size: 64,
                  color: result.isCorrect ? Colors.green : Colors.orange,
                ),
                const SizedBox(height: 16),
                Text(
                  result.message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.alata(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${result.correctCount}/${result.totalCorrect} correct',
                  style: GoogleFonts.alata(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => ref
                      .read(animalsControllerProvider.notifier)
                      .continueAfterTeaching(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: result.isCorrect ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      result.isCorrect ? 'Continue!' : 'Try Again',
                      style: GoogleFonts.alata(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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

  Widget _buildRoundComplete(AnimalsMissionState state) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                const Text('🎉', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                Text(
                  'Round ${state.currentRound} Complete!',
                  style: GoogleFonts.alata(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => ref
                      .read(animalsControllerProvider.notifier)
                      .nextRound(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Next Round',
                      style: GoogleFonts.alata(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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

  Widget _buildMissionComplete() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 80)),
                const SizedBox(height: 16),
                Text(
                  'Mission Complete!',
                  style: GoogleFonts.alata(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pixy now knows animals!',
                  style: GoogleFonts.alata(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Back to Missions',
                      style: GoogleFonts.alata(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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

  Widget _buildError(AnimalsMissionState state) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Oops!',
                  style: GoogleFonts.alata(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.errorMessage ?? 'Something went wrong',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.alata(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => ref
                      .read(animalsControllerProvider.notifier)
                      .startMission(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Retry',
                      style: GoogleFonts.alata(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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
}
