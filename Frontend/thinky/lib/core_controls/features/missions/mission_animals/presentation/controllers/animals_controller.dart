import 'package:thinky/core/errors/error_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thinky/core_controls/network/user_facing_error_mapper.dart';
import 'package:thinky/core_controls/services/mission_service.dart';
import 'package:thinky/core_controls/services/xp_service.dart';
import '../../data/animals_models.dart';
import '../../data/animals_repository.dart';

/// Top-level mission container.
enum AnimalsMissionPhase {
  loading,
  playing,
  missionComplete,
  error,
}

/// Step inside an active round (single-screen flow).
enum AnimalsPlayStep {
  /// Image visible; user asks Pixy for a guess.
  pendingGuess,
  /// Pixy's guess + Yes / No.
  guessShown,
  /// Inline feedback after verify API (banner); then [proceedAfterVerify].
  verifyFeedback,
  /// Select images to teach Pixy.
  teaching,
  /// Submitted teaching — show per-tile outcome.
  teachingFeedback,
}

class AnimalsMissionState {
  final AnimalsMissionPhase phase;
  final AnimalsPlayStep playStep;

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
  final bool isLoadingTeaching;
  final bool showLearning;

  const AnimalsMissionState({
    this.phase = AnimalsMissionPhase.loading,
    this.playStep = AnimalsPlayStep.pendingGuess,
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
    this.isLoadingTeaching = false,
    this.showLearning = false,
  });

  AnimalsMissionState copyWith({
    AnimalsMissionPhase? phase,
    AnimalsPlayStep? playStep,
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
    bool? isLoadingTeaching,
    bool? showLearning,
    bool clearVerifyResponse = false,
    bool clearTeaching = false,
    bool clearGuess = false,
    bool clearTeachingResult = false,
  }) {
    return AnimalsMissionState(
      phase: phase ?? this.phase,
      playStep: playStep ?? this.playStep,
      currentRound: currentRound ?? this.currentRound,
      totalRounds: totalRounds ?? this.totalRounds,
      currentImage: currentImage ?? this.currentImage,
      lastGuess: clearGuess ? null : (lastGuess ?? this.lastGuess),
      verifyResponse:
          clearVerifyResponse ? null : (verifyResponse ?? this.verifyResponse),
      teachingImages:
          clearTeaching ? null : (teachingImages ?? this.teachingImages),
      teachingResult: clearTeaching || clearTeachingResult
          ? null
          : (teachingResult ?? this.teachingResult),
      selectedImageIds: selectedImageIds ?? this.selectedImageIds,
      errorMessage: errorMessage ?? this.errorMessage,
      isLoading: isLoading ?? this.isLoading,
      isLoadingTeaching: isLoadingTeaching ?? this.isLoadingTeaching,
      showLearning: showLearning ?? this.showLearning,
    );
  }
}

class AnimalsController extends StateNotifier<AnimalsMissionState> {
  AnimalsController() : super(const AnimalsMissionState());

  Future<void> startMission() async {
    state = state.copyWith(
      phase: AnimalsMissionPhase.loading,
      isLoading: true,
      errorMessage: null,
    );

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

  Future<void> _loadNextRound() async {
    try {
      final roundData = await AnimalsRepository.getRound();

      state = state.copyWith(
        phase: AnimalsMissionPhase.playing,
        playStep: AnimalsPlayStep.pendingGuess,
        currentRound: roundData.roundNumber,
        totalRounds: roundData.totalRounds,
        currentImage: roundData.image,
        clearGuess: true,
        clearVerifyResponse: true,
        clearTeaching: true,
        selectedImageIds: {},
        isLoading: false,
        isLoadingTeaching: false,
      );
    } catch (e) {
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

  Future<void> makePixyGuess() async {
    if (state.currentImage == null || state.playStep != AnimalsPlayStep.pendingGuess) {
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final guess = await AnimalsRepository.makeGuess(state.currentImage!.id);

      state = state.copyWith(
        playStep: AnimalsPlayStep.guessShown,
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

  Future<void> verifyGuess(bool userSaysCorrect) async {
    if (state.currentImage == null ||
        state.lastGuess == null ||
        state.playStep != AnimalsPlayStep.guessShown) {
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final response = await AnimalsRepository.verifyGuess(
        imageId: state.currentImage!.id,
        pixyGuess: state.lastGuess!.guess,
        userSaysCorrect: userSaysCorrect,
      );

      state = state.copyWith(
        playStep: AnimalsPlayStep.verifyFeedback,
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

  /// Called after inline verify banner is shown (optionally delayed in UI).
  Future<void> proceedAfterVerify() async {
    if (state.phase != AnimalsMissionPhase.playing ||
        state.playStep != AnimalsPlayStep.verifyFeedback ||
        state.verifyResponse == null) {
      return;
    }

    final wasPixyActuallyCorrect = state.verifyResponse!.wasActuallyCorrect;

    if (wasPixyActuallyCorrect) {
      state = state.copyWith(isLoading: true);
      await _handleRoundComplete();
      return;
    }

    state = state.copyWith(isLoadingTeaching: true);
    await _loadTeachingImages();
  }

  Future<void> _loadTeachingImages() async {
    if (state.currentImage == null) return;

    try {
      final images = await AnimalsRepository.getTeachingImages(
        state.currentImage!.label,
      );

      state = state.copyWith(
        playStep: AnimalsPlayStep.teaching,
        teachingImages: images,
        selectedImageIds: {},
        clearVerifyResponse: true,
        isLoadingTeaching: false,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        phase: AnimalsMissionPhase.error,
        errorMessage: UserFacingErrorMapper.map(e),
        isLoadingTeaching: false,
        isLoading: false,
      );
    }
  }

  void toggleImageSelection(String imageId) {
    if (state.playStep != AnimalsPlayStep.teaching) return;

    final next = Set<String>.from(state.selectedImageIds);
    if (next.contains(imageId)) {
      next.remove(imageId);
    } else {
      next.add(imageId);
    }
    state = state.copyWith(selectedImageIds: next);
  }

  Future<void> submitTeaching() async {
    if (state.teachingImages == null || state.playStep != AnimalsPlayStep.teaching) {
      return;
    }
    if (state.selectedImageIds.isEmpty) return;

    state = state.copyWith(isLoading: true);

    try {
      final result = await AnimalsRepository.validateTeaching(
        targetAnimal: state.teachingImages!.targetAnimal,
        selectedImageIds: state.selectedImageIds.toList(),
      );

      state = state.copyWith(
        playStep: AnimalsPlayStep.teachingFeedback,
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

  void retryTeaching() {
    if (state.playStep != AnimalsPlayStep.teachingFeedback) return;
    state = state.copyWith(
      playStep: AnimalsPlayStep.teaching,
      clearTeachingResult: true,
      selectedImageIds: {},
    );
  }

  /// User dismisses the teaching-success overlay → advance to next round.
  Future<void> continueAfterTeaching() async {
    if (state.playStep != AnimalsPlayStep.teachingFeedback ||
        state.teachingResult == null ||
        !state.teachingResult!.isCorrect) {
      return;
    }
    state = state.copyWith(isLoading: true);
    await _handleRoundComplete();
  }

  Future<void> _handleRoundComplete() async {
    if (state.currentRound >= state.totalRounds) {
      try {
        await MissionService.completeMission(-5);
      } catch (e, stack) {
        ErrorLogger().logError(e, stackTrace: stack);
      }
      XpService.awardXp('animals', 100.0);
      state = state.copyWith(
        phase: AnimalsMissionPhase.missionComplete,
        isLoading: false,
        isLoadingTeaching: false,
      );
    } else {
      await _loadNextRound();
    }
  }

  void openLearning() {
    state = state.copyWith(showLearning: true);
  }

  void closeLearning() {
    state = state.copyWith(showLearning: false);
  }

  void reset() {
    state = const AnimalsMissionState();
  }
}

final animalsControllerProvider =
    StateNotifierProvider<AnimalsController, AnimalsMissionState>((ref) {
  return AnimalsController();
});
