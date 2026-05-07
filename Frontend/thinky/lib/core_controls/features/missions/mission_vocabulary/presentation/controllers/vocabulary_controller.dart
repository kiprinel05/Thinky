import 'package:thinky/core/errors/error_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thinky/core_controls/services/mission_service.dart';
import '../../data/vocabulary_models.dart';
import '../../data/vocabulary_repository.dart';

/// Phases of the vocabulary mission
enum VocabMissionPhase {
  intro,        // Presentation / intro screen
  loading,
  question,     // Showing a word + image options
  submitting,   // Waiting for backend validation
  feedback,     // Showing correct/incorrect
  missionComplete,
  error,
}

/// State for the Vocabulary mission
class VocabMissionState {
  final VocabMissionPhase phase;
  final List<VocabQuestion> questions;
  final int currentIndex;
  final int totalQuestions;
  final int? selectedImageId;
  final VocabAnswerResponse? lastAnswer;
  final int correctCount;
  final int answeredCount;
  final String? errorMessage;
  final String? encouragement;
  final int questionTimeSeconds;

  const VocabMissionState({
    this.phase = VocabMissionPhase.intro,
    this.questions = const [],
    this.currentIndex = 0,
    this.totalQuestions = 0,
    this.selectedImageId,
    this.lastAnswer,
    this.correctCount = 0,
    this.answeredCount = 0,
    this.errorMessage,
    this.encouragement,
    this.questionTimeSeconds = 0,
  });

  VocabQuestion? get currentQuestion {
    if (currentIndex >= 0 && currentIndex < questions.length) {
      return questions[currentIndex];
    }
    return null;
  }

  bool get hasSelection => selectedImageId != null;

  double get progress =>
      totalQuestions > 0 ? answeredCount / totalQuestions : 0.0;

  VocabMissionState copyWith({
    VocabMissionPhase? phase,
    List<VocabQuestion>? questions,
    int? currentIndex,
    int? totalQuestions,
    int? selectedImageId,
    bool clearSelection = false,
    VocabAnswerResponse? lastAnswer,
    int? correctCount,
    int? answeredCount,
    String? errorMessage,
    String? encouragement,
    bool clearEncouragement = false,
    int? questionTimeSeconds,
  }) {
    return VocabMissionState(
      phase: phase ?? this.phase,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      selectedImageId: clearSelection ? null : (selectedImageId ?? this.selectedImageId),
      lastAnswer: lastAnswer ?? this.lastAnswer,
      correctCount: correctCount ?? this.correctCount,
      answeredCount: answeredCount ?? this.answeredCount,
      errorMessage: errorMessage,
      encouragement: clearEncouragement ? null : (encouragement ?? this.encouragement),
      questionTimeSeconds: questionTimeSeconds ?? this.questionTimeSeconds,
    );
  }
}

class VocabularyController extends StateNotifier<VocabMissionState> {
  VocabularyController() : super(const VocabMissionState());

  /// Start from intro — transition to loading and fetch questions
  Future<void> startFromIntro() async {
    await startMission();
  }

  /// Start the mission — load all questions from backend
  Future<void> startMission() async {
    state = state.copyWith(phase: VocabMissionPhase.loading);

    try {
      final response = await VocabularyRepository.startMission();

      state = state.copyWith(
        phase: VocabMissionPhase.question,
        questions: response.questions,
        currentIndex: 0,
        totalQuestions: response.totalQuestions,
        correctCount: 0,
        answeredCount: 0,
        clearSelection: true,
        clearEncouragement: true,
        questionTimeSeconds: 0,
      );
    } catch (e) {
      state = state.copyWith(
        phase: VocabMissionPhase.error,
        errorMessage: 'Failed to start mission: $e',
      );
    }
  }

  /// Select an image for the current question
  void selectImage(int imageId) {
    if (state.phase != VocabMissionPhase.question) return;
    state = state.copyWith(selectedImageId: imageId);
  }

  /// Increment timer
  void tickTimer() {
    if (state.phase == VocabMissionPhase.question) {
      state = state.copyWith(
        questionTimeSeconds: state.questionTimeSeconds + 1,
      );
    }
  }

  /// Submit the selected answer
  Future<void> submitAnswer() async {
    if (!state.hasSelection || state.currentQuestion == null) return;

    state = state.copyWith(phase: VocabMissionPhase.submitting);

    try {
      final answer = await VocabularyRepository.submitAnswer(
        questionIndex: state.currentIndex,
        selectedImageId: state.selectedImageId!,
      );

      state = state.copyWith(
        phase: VocabMissionPhase.feedback,
        lastAnswer: answer,
        correctCount: answer.correct
            ? state.correctCount + 1
            : state.correctCount,
        answeredCount: state.answeredCount + 1,
        encouragement: answer.encouragement,
      );
    } catch (e) {
      state = state.copyWith(
        phase: VocabMissionPhase.error,
        errorMessage: 'Failed to submit answer: $e',
      );
    }
  }

  /// Continue to next question or complete mission
  Future<void> nextQuestion() async {
    final nextIndex = state.currentIndex + 1;

    if (nextIndex >= state.totalQuestions) {
      try {
        await MissionService.completeMission(-7);
      } catch (e, stack) {
        ErrorLogger().logError(e, stackTrace: stack);
      }
      state = state.copyWith(phase: VocabMissionPhase.missionComplete);
    } else {
      state = state.copyWith(
        phase: VocabMissionPhase.question,
        currentIndex: nextIndex,
        clearSelection: true,
        lastAnswer: null,
        clearEncouragement: true,
        questionTimeSeconds: 0,
      );
    }
  }

  /// Reset the mission
  void reset() {
    state = const VocabMissionState();
  }
}

/// Provider for VocabularyController — autoDispose ensures fresh state on re-entry
final vocabularyControllerProvider =
    StateNotifierProvider.autoDispose<VocabularyController, VocabMissionState>((ref) {
  return VocabularyController();
});
