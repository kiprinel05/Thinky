import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:thinky/core/errors/error_logger.dart';
import 'package:thinky/core_controls/constants/app_texts.dart';
import 'package:thinky/core_controls/network/user_facing_error_mapper.dart';
import 'package:thinky/core_controls/services/mission_service.dart';

import '../../data/vocabulary_models.dart';
import '../../data/vocabulary_repository.dart';

/// Phases of the Word Match mission.
enum VocabMissionPhase {
  intro,           // Welcome screen with mascot + CTA
  loading,         // Fetching questions
  question,        // Showing a word + emoji options
  submitting,      // Waiting for backend validation
  feedback,        // Showing correct / incorrect
  missionComplete, // Stats & next-step CTAs
  error,
}

/// Pre-computed, localized messages for the feedback phase.
class VocabFeedbackMessage {
  final String message;
  final String encouragement;

  const VocabFeedbackMessage({
    required this.message,
    required this.encouragement,
  });
}

class VocabMissionState {
  final VocabMissionPhase phase;
  final List<VocabQuestion> questions;
  final int currentIndex;
  final int totalQuestions;
  final int? selectedImageId;
  final VocabAnswerResponse? lastAnswer;
  final VocabFeedbackMessage? lastFeedback;
  final int correctCount;
  final int answeredCount;
  final String? errorMessage;

  const VocabMissionState({
    this.phase = VocabMissionPhase.intro,
    this.questions = const [],
    this.currentIndex = 0,
    this.totalQuestions = 0,
    this.selectedImageId,
    this.lastAnswer,
    this.lastFeedback,
    this.correctCount = 0,
    this.answeredCount = 0,
    this.errorMessage,
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
    bool clearLastAnswer = false,
    VocabFeedbackMessage? lastFeedback,
    bool clearLastFeedback = false,
    int? correctCount,
    int? answeredCount,
    String? errorMessage,
  }) {
    return VocabMissionState(
      phase: phase ?? this.phase,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      selectedImageId: clearSelection
          ? null
          : (selectedImageId ?? this.selectedImageId),
      lastAnswer: clearLastAnswer ? null : (lastAnswer ?? this.lastAnswer),
      lastFeedback:
          clearLastFeedback ? null : (lastFeedback ?? this.lastFeedback),
      correctCount: correctCount ?? this.correctCount,
      answeredCount: answeredCount ?? this.answeredCount,
      errorMessage: errorMessage,
    );
  }
}

class VocabularyController extends StateNotifier<VocabMissionState> {
  VocabularyController() : super(const VocabMissionState());

  final Random _rng = Random();

  /// Move from intro screen into loading the first question set.
  Future<void> startFromIntro() async {
    state = state.copyWith(phase: VocabMissionPhase.loading);
    await _fetchQuestions();
  }

  /// Replay the mission from the complete screen.
  Future<void> restart() async {
    state = const VocabMissionState(phase: VocabMissionPhase.loading);
    await _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
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
        clearLastAnswer: true,
        clearLastFeedback: true,
      );
    } catch (e) {
      state = state.copyWith(
        phase: VocabMissionPhase.error,
        errorMessage: UserFacingErrorMapper.map(e),
      );
    }
  }

  void selectImage(int imageId) {
    if (state.phase != VocabMissionPhase.question) return;
    state = state.copyWith(selectedImageId: imageId);
  }

  Future<void> submitAnswer({required String languageCode}) async {
    final question = state.currentQuestion;
    if (!state.hasSelection || question == null) return;

    state = state.copyWith(phase: VocabMissionPhase.submitting);

    try {
      final answer = await VocabularyRepository.submitAnswer(
        questionIndex: state.currentIndex,
        selectedImageId: state.selectedImageId!,
      );

      final word = question.wordFor(languageCode);
      final feedback = _buildFeedback(
        correct: answer.correct,
        word: word,
      );

      state = state.copyWith(
        phase: VocabMissionPhase.feedback,
        lastAnswer: answer,
        lastFeedback: feedback,
        correctCount: answer.correct
            ? state.correctCount + 1
            : state.correctCount,
        answeredCount: state.answeredCount + 1,
      );
    } catch (e) {
      state = state.copyWith(
        phase: VocabMissionPhase.error,
        errorMessage: UserFacingErrorMapper.map(e),
      );
    }
  }

  Future<void> nextQuestion() async {
    final nextIndex = state.currentIndex + 1;

    if (nextIndex >= state.totalQuestions) {
      try {
        await MissionService.completeMission(-7);
      } catch (e, stack) {
        ErrorLogger().logError(e, stackTrace: stack);
      }
      state = state.copyWith(phase: VocabMissionPhase.missionComplete);
      return;
    }

    state = state.copyWith(
      phase: VocabMissionPhase.question,
      currentIndex: nextIndex,
      clearSelection: true,
      clearLastAnswer: true,
      clearLastFeedback: true,
    );
  }

  void reset() {
    state = const VocabMissionState();
  }

  // ────────────────────────────────────────────────────────────────────
  // Localized feedback builder — picks a random line from the bundle.
  // ────────────────────────────────────────────────────────────────────

  VocabFeedbackMessage _buildFeedback({
    required bool correct,
    required String word,
  }) {
    final variant = _rng.nextInt(4) + 1; // 1..4

    final rawMessage = correct
        ? Vocabulary.feedbackCorrect(variant)
        : Vocabulary.feedbackIncorrect(variant);
    final encouragement = correct
        ? Vocabulary.encourageCorrect(variant)
        : Vocabulary.encourageIncorrect(variant);

    final message = rawMessage.replaceAll('{{word}}', word);
    return VocabFeedbackMessage(
      message: message,
      encouragement: encouragement,
    );
  }
}

final vocabularyControllerProvider =
    StateNotifierProvider<VocabularyController, VocabMissionState>((ref) {
  return VocabularyController();
});
