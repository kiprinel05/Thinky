import 'package:thinky/core/errors/error_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thinky/core_controls/network/user_facing_error_mapper.dart';
import 'package:thinky/core_controls/services/mission_service.dart';
import 'package:thinky/core_controls/services/xp_service.dart';
import '../../data/animals_models.dart';
import '../../data/animals_repository.dart';

/// State for the Animals mission
enum AnimalsMissionPhase {
  loading,
  showImage,       // Display animal image, Pixy thinking
  guessResult,     // Show Pixy's guess, user confirms
  verifyFeedback,  // Show if user was right about verification
  teachingPhase,   // Grid of images for teaching
  teachingResult,  // Show teaching validation result
  roundComplete,   // Transition to next round
  missionComplete, // All rounds done
  error,
}

class AnimalsMissionState {
  final AnimalsMissionPhase phase;
  final int currentRound;
  final int totalRounds;
  final AnimalImage? currentImage;
  final GuessResponse? lastGuess;
  final VerifyGuessResponse? verifyResponse;
  final TeachingImagesResponse? teachingImages;
  final ValidateTeachingResponse? teachingResult;
  final Set<String> selectedImageIds;
  final String? errorMessage;
  final bool isLoading;
  final bool showLearning;

  const AnimalsMissionState({
    this.phase = AnimalsMissionPhase.loading,
    this.currentRound = 0,
    this.totalRounds = 5,
    this.currentImage,
    this.lastGuess,
    this.verifyResponse,
    this.teachingImages,
    this.teachingResult,
    this.selectedImageIds = const {},
    this.errorMessage,
    this.isLoading = false,
    this.showLearning = false,
  });

  AnimalsMissionState copyWith({
    AnimalsMissionPhase? phase,
    int? currentRound,
    int? totalRounds,
    AnimalImage? currentImage,
    GuessResponse? lastGuess,
    VerifyGuessResponse? verifyResponse,
    TeachingImagesResponse? teachingImages,
    ValidateTeachingResponse? teachingResult,
    Set<String>? selectedImageIds,
    String? errorMessage,
    bool? isLoading,
    bool? showLearning,
  }) {
    return AnimalsMissionState(
      phase: phase ?? this.phase,
      currentRound: currentRound ?? this.currentRound,
      totalRounds: totalRounds ?? this.totalRounds,
      currentImage: currentImage ?? this.currentImage,
      lastGuess: lastGuess ?? this.lastGuess,
      verifyResponse: verifyResponse ?? this.verifyResponse,
      teachingImages: teachingImages ?? this.teachingImages,
      teachingResult: teachingResult ?? this.teachingResult,
      selectedImageIds: selectedImageIds ?? this.selectedImageIds,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
      showLearning: showLearning ?? this.showLearning,
    );
  }
}

class AnimalsController extends StateNotifier<AnimalsMissionState> {
  AnimalsController() : super(const AnimalsMissionState());

  /// Start the mission
  Future<void> startMission() async {
    state = state.copyWith(phase: AnimalsMissionPhase.loading, isLoading: true);
    
    try {
      await AnimalsRepository.startMission();
      await _loadNextRound();
    } catch (e) {
      state = state.copyWith(
        phase: AnimalsMissionPhase.error,
        errorMessage: UserFacingErrorMapper.map(e),
        isLoading: false,
      );
    }
  }

  /// Load the next round
  Future<void> _loadNextRound() async {
    try {
      final roundData = await AnimalsRepository.getRound();
      
      state = state.copyWith(
        phase: AnimalsMissionPhase.showImage,
        currentRound: roundData.roundNumber,
        totalRounds: roundData.totalRounds,
        currentImage: roundData.image,
        lastGuess: null,
        verifyResponse: null,
        teachingImages: null,
        teachingResult: null,
        selectedImageIds: {},
        isLoading: false,
      );
    } catch (e) {
      // Check if mission is complete
      if (e.toString().contains('already complete')) {
        state = state.copyWith(
          phase: AnimalsMissionPhase.missionComplete,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          phase: AnimalsMissionPhase.error,
          errorMessage: UserFacingErrorMapper.map(e),
          isLoading: false,
        );
      }
    }
  }

  /// Pixy makes a guess
  Future<void> makePixyGuess() async {
    if (state.currentImage == null) return;
    
    state = state.copyWith(isLoading: true);
    
    try {
      final guess = await AnimalsRepository.makeGuess(state.currentImage!.id);
      
      state = state.copyWith(
        phase: AnimalsMissionPhase.guessResult,
        lastGuess: guess,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        phase: AnimalsMissionPhase.error,
        errorMessage: UserFacingErrorMapper.map(e),
        isLoading: false,
      );
    }
  }

  /// User confirms if Pixy's guess is correct
  Future<void> verifyGuess(bool userSaysCorrect) async {
    if (state.currentImage == null || state.lastGuess == null) return;
    
    state = state.copyWith(isLoading: true);
    
    try {
      final response = await AnimalsRepository.verifyGuess(
        imageId: state.currentImage!.id,
        pixyGuess: state.lastGuess!.guess,
        userSaysCorrect: userSaysCorrect,
      );
      
      state = state.copyWith(
        phase: AnimalsMissionPhase.verifyFeedback,
        verifyResponse: response,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        phase: AnimalsMissionPhase.error,
        errorMessage: UserFacingErrorMapper.map(e),
        isLoading: false,
      );
    }
  }

  /// Continue after verification feedback
  Future<void> continueAfterVerify() async {
    if (state.verifyResponse == null) return;
    
    final wasCorrect = state.verifyResponse!.wasActuallyCorrect;
    
    if (wasCorrect) {
      // Pixy was right, move to next round
      await _handleRoundComplete();
    } else {
      // Pixy was wrong, go to teaching phase
      await _loadTeachingImages();
    }
  }

  /// Load teaching images
  Future<void> _loadTeachingImages() async {
    if (state.currentImage == null) return;
    
    state = state.copyWith(isLoading: true);
    
    try {
      final images = await AnimalsRepository.getTeachingImages(
        state.currentImage!.label,
      );
      
      state = state.copyWith(
        phase: AnimalsMissionPhase.teachingPhase,
        teachingImages: images,
        selectedImageIds: {},
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        phase: AnimalsMissionPhase.error,
        errorMessage: UserFacingErrorMapper.map(e),
        isLoading: false,
      );
    }
  }

  /// Toggle image selection in teaching phase
  void toggleImageSelection(String imageId) {
    final newSelection = Set<String>.from(state.selectedImageIds);
    if (newSelection.contains(imageId)) {
      newSelection.remove(imageId);
    } else {
      newSelection.add(imageId);
    }
    state = state.copyWith(selectedImageIds: newSelection);
  }

  /// Submit teaching selections
  Future<void> submitTeaching() async {
    if (state.teachingImages == null) return;
    
    state = state.copyWith(isLoading: true);
    
    try {
      final result = await AnimalsRepository.validateTeaching(
        targetAnimal: state.teachingImages!.targetAnimal,
        selectedImageIds: state.selectedImageIds.toList(),
      );
      
      state = state.copyWith(
        phase: AnimalsMissionPhase.teachingResult,
        teachingResult: result,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        phase: AnimalsMissionPhase.error,
        errorMessage: UserFacingErrorMapper.map(e),
        isLoading: false,
      );
    }
  }

  /// Continue after teaching result
  Future<void> continueAfterTeaching() async {
    if (state.teachingResult != null && !state.teachingResult!.isCorrect) {
      // If incorrect, let them try again
      state = state.copyWith(
        phase: AnimalsMissionPhase.teachingPhase,
        selectedImageIds: {},
      );
      return;
    }
    
    await _handleRoundComplete();
  }

  /// Handle round completion
  Future<void> _handleRoundComplete() async {
    if (state.currentRound >= state.totalRounds) {
      // Mark mission as complete
      try {
        await MissionService.completeMission(-5);
      } catch (e, stack) {
        ErrorLogger().logError(e, stackTrace: stack);
      }
      XpService.awardXp('animals', 100.0);
      state = state.copyWith(phase: AnimalsMissionPhase.missionComplete);
    } else {
      state = state.copyWith(phase: AnimalsMissionPhase.roundComplete);
    }
  }

  /// Start next round
  Future<void> nextRound() async {
    await _loadNextRound();
  }

  void openLearning() {
    state = state.copyWith(showLearning: true);
  }

  void closeLearning() {
    state = state.copyWith(showLearning: false);
  }

  /// Reset mission
  void reset() {
    state = const AnimalsMissionState();
  }
}

/// Provider for AnimalsController
final animalsControllerProvider = 
    StateNotifierProvider<AnimalsController, AnimalsMissionState>((ref) {
  return AnimalsController();
});
