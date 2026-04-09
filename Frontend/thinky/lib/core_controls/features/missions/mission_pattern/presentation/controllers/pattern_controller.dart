import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thinky/core_controls/network/user_facing_error_mapper.dart';
import '../../data/pattern_models.dart';
import '../../data/pattern_repository.dart';

enum PatternPhase { loading, playing, submitting, feedback, missionComplete, error }

class PatternState {
  final PatternPhase phase;
  final PatternStartResponse? currentRound;
  final String? selectedOptionId;
  final PatternResultResponse? lastResult;
  final String? errorMessage;
  final bool isCorrect; 

  PatternState({
    required this.phase,
    this.currentRound,
    this.selectedOptionId,
    this.lastResult,
    this.errorMessage,
    this.isCorrect = false,
  });

  PatternState copyWith({
    PatternPhase? phase,
    PatternStartResponse? currentRound,
    String? selectedOptionId,
    PatternResultResponse? lastResult,
    String? errorMessage,
    bool? isCorrect,
  }) {
    return PatternState(
      phase: phase ?? this.phase,
      currentRound: currentRound ?? this.currentRound,
      selectedOptionId: selectedOptionId ?? this.selectedOptionId,
      lastResult: lastResult ?? this.lastResult,
      errorMessage: errorMessage ?? this.errorMessage,
      isCorrect: isCorrect ?? this.isCorrect,
    );
  }
}

class PatternController extends StateNotifier<PatternState> {
  PatternController() : super(PatternState(phase: PatternPhase.loading)) {
    startMission();
  }

  Future<void> startMission() async {
    try {
      state = state.copyWith(phase: PatternPhase.loading, errorMessage: null);
      final response = await PatternRepository.startMission();
      state = state.copyWith(
        phase: PatternPhase.playing,
        currentRound: response,
        selectedOptionId: null, 
        isCorrect: false,
      );
    } catch (e) {
      state = state.copyWith(
        phase: PatternPhase.error,
        errorMessage: UserFacingErrorMapper.map(e),
      );
    }
  }

  void selectOption(String optionId) {
    if (state.phase != PatternPhase.playing) return;
    state = state.copyWith(selectedOptionId: optionId);
  }

  Future<void> submitAnswer() async {
    if (state.selectedOptionId == null) return;
    if (state.phase != PatternPhase.playing) return;

    try {
      state = state.copyWith(phase: PatternPhase.submitting);
      
      final result = await PatternRepository.submitAnswer(state.selectedOptionId!);
      
      state = state.copyWith(
        phase: PatternPhase.feedback,
        lastResult: result,
        isCorrect: result.correct,
      );
      
    } catch (e) {
      state = state.copyWith(
        phase: PatternPhase.error,
        errorMessage: UserFacingErrorMapper.map(e),
      );
    }
  }

  Future<void> nextRound() async {
    if (state.lastResult != null && state.lastResult!.completionProgress >= 1.0) {
      state = state.copyWith(phase: PatternPhase.missionComplete);
      return;
    }

    try {
      state = state.copyWith(phase: PatternPhase.loading);
      final response = await PatternRepository.nextRound();
      
      state = state.copyWith(
        phase: PatternPhase.playing,
        currentRound: response,
        selectedOptionId: null,
        isCorrect: false,
        lastResult: null,
      );
    } catch (e) {
      state = state.copyWith(
        phase: PatternPhase.error,
        errorMessage: UserFacingErrorMapper.map(e),
      );
    }
  }
}

final patternControllerProvider =
    StateNotifierProvider.autoDispose<PatternController, PatternState>((ref) {
  return PatternController();
});
