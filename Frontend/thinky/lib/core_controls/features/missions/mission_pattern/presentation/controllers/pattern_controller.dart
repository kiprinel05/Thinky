import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:thinky/core/errors/error_logger.dart';
import 'package:thinky/core_controls/constants/app_texts.dart';
import 'package:thinky/core_controls/network/user_facing_error_mapper.dart';
import 'package:thinky/core_controls/services/mission_service.dart';
import 'package:thinky/core_controls/services/xp_service.dart';

import '../../data/pattern_models.dart';
import '../../data/pattern_repository.dart';

/// Phases of the Complete-the-Pattern mission.
enum PatternPhase {
  intro,
  loading,
  question,
  submitting,
  feedback,
  missionComplete,
  error,
}

/// Pre-computed, localized message pair shown in the feedback phase.
class PatternFeedbackMessage {
  final String message;
  final String encouragement;

  const PatternFeedbackMessage({
    required this.message,
    required this.encouragement,
  });
}

class PatternMissionState {
  final PatternPhase phase;
  final List<PatternQuestion> questions;
  final int currentIndex;
  final int totalQuestions;
  final int? selectedOptionId;
  final PatternAnswerResponse? lastAnswer;
  final PatternFeedbackMessage? lastFeedback;
  final int correctCount;
  final int answeredCount;
  final String? errorMessage;

  const PatternMissionState({
    this.phase = PatternPhase.intro,
    this.questions = const [],
    this.currentIndex = 0,
    this.totalQuestions = 0,
    this.selectedOptionId,
    this.lastAnswer,
    this.lastFeedback,
    this.correctCount = 0,
    this.answeredCount = 0,
    this.errorMessage,
  });

  PatternQuestion? get currentQuestion {
    if (currentIndex >= 0 && currentIndex < questions.length) {
      return questions[currentIndex];
    }
    return null;
  }

  bool get hasSelection => selectedOptionId != null;

  double get progress =>
      totalQuestions > 0 ? answeredCount / totalQuestions : 0.0;

  PatternMissionState copyWith({
    PatternPhase? phase,
    List<PatternQuestion>? questions,
    int? currentIndex,
    int? totalQuestions,
    int? selectedOptionId,
    bool clearSelection = false,
    PatternAnswerResponse? lastAnswer,
    bool clearLastAnswer = false,
    PatternFeedbackMessage? lastFeedback,
    bool clearLastFeedback = false,
    int? correctCount,
    int? answeredCount,
    String? errorMessage,
  }) {
    return PatternMissionState(
      phase: phase ?? this.phase,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      selectedOptionId: clearSelection
          ? null
          : (selectedOptionId ?? this.selectedOptionId),
      lastAnswer: clearLastAnswer ? null : (lastAnswer ?? this.lastAnswer),
      lastFeedback:
          clearLastFeedback ? null : (lastFeedback ?? this.lastFeedback),
      correctCount: correctCount ?? this.correctCount,
      answeredCount: answeredCount ?? this.answeredCount,
      errorMessage: errorMessage,
    );
  }
}

class PatternController extends StateNotifier<PatternMissionState> {
  PatternController() : super(const PatternMissionState());

  final Random _rng = Random();

  /// Move from the intro screen into loading the first question set.
  Future<void> startFromIntro() async {
    state = state.copyWith(phase: PatternPhase.loading);
    await _fetchQuestions();
  }

  /// Replay the mission from the completion screen.
  Future<void> restart() async {
    state = const PatternMissionState(phase: PatternPhase.loading);
    await _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    try {
      final response = await PatternRepository.startMission();
      state = state.copyWith(
        phase: PatternPhase.question,
        questions: response.questions,
        currentIndex: 0,
        totalQuestions: response.totalRounds,
        correctCount: 0,
        answeredCount: 0,
        clearSelection: true,
        clearLastAnswer: true,
        clearLastFeedback: true,
      );
    } catch (e) {
      state = state.copyWith(
        phase: PatternPhase.error,
        errorMessage: UserFacingErrorMapper.map(e),
      );
    }
  }

  void selectOption(int optionId) {
    if (state.phase != PatternPhase.question) return;
    state = state.copyWith(selectedOptionId: optionId);
  }

  Future<void> submitAnswer() async {
    final question = state.currentQuestion;
    if (!state.hasSelection || question == null) return;

    state = state.copyWith(phase: PatternPhase.submitting);

    try {
      final answer = await PatternRepository.submitAnswer(
        questionIndex: state.currentIndex,
        selectedOptionId: state.selectedOptionId!,
      );

      final feedback = _buildFeedback(correct: answer.correct);

      state = state.copyWith(
        phase: PatternPhase.feedback,
        lastAnswer: answer,
        lastFeedback: feedback,
        correctCount: answer.correct
            ? state.correctCount + 1
            : state.correctCount,
        answeredCount: state.answeredCount + 1,
      );
    } catch (e) {
      state = state.copyWith(
        phase: PatternPhase.error,
        errorMessage: UserFacingErrorMapper.map(e),
      );
    }
  }

  Future<void> nextQuestion() async {
    final nextIndex = state.currentIndex + 1;

    if (nextIndex >= state.totalQuestions) {
      try {
        await MissionService.completeMission(-9);
      } catch (e, stack) {
        ErrorLogger().logError(e, stackTrace: stack);
      }
      final pct = state.totalQuestions > 0
          ? (state.correctCount / state.totalQuestions) * 100.0
          : 0.0;
      XpService.awardXp('pattern', pct);
      state = state.copyWith(phase: PatternPhase.missionComplete);
      return;
    }

    state = state.copyWith(
      phase: PatternPhase.question,
      currentIndex: nextIndex,
      clearSelection: true,
      clearLastAnswer: true,
      clearLastFeedback: true,
    );
  }

  void reset() {
    state = const PatternMissionState();
  }

  // ────────────────────────────────────────────────────────────────────
  // Localized feedback builder — picks a random line from the bundle.
  // ────────────────────────────────────────────────────────────────────

  PatternFeedbackMessage _buildFeedback({required bool correct}) {
    final variant = _rng.nextInt(4) + 1; // 1..4

    final message = correct
        ? PatternMission.feedbackCorrect(variant)
        : PatternMission.feedbackIncorrect(variant);
    final encouragement = correct
        ? PatternMission.encourageCorrect(variant)
        : PatternMission.encourageIncorrect(variant);

    return PatternFeedbackMessage(
      message: message,
      encouragement: encouragement,
    );
  }
}

final patternControllerProvider =
    StateNotifierProvider<PatternController, PatternMissionState>((ref) {
  return PatternController();
});
