import 'package:flutter/foundation.dart';
import 'package:thinky/base_controls/base_state.dart';
import '../../domain/numbers_models.dart';

/// Current phase of the Numbers Mission UI
enum NumbersPhase {
  intro,
  counting,
  pixyGuessing,
  professorIntervention,
  modelUpgrade,
  transitionToPart2,
  drawing,
  drawingResult,
  completion,
}

/// State for the Numbers Mission
@immutable
class NumbersState extends BaseState {
  final NumbersPhase phase;
  final int currentPart; // 1 = counting, 2 = drawing
  final PixyModelLevel modelLevel;
  final NumbersRound? round;
  final CountingResult? countingResult;
  final DrawingResult? drawingResult;
  final int? selectedAnswer;
  final int correctCount;
  final int confusionCount;
  final int roundsCompleted;
  final bool isSubmitting;

  const NumbersState({
    super.status = StateStatus.initial,
    super.errorMessage,
    this.phase = NumbersPhase.intro,
    this.currentPart = 1,
    this.modelLevel = PixyModelLevel.junior,
    this.round,
    this.countingResult,
    this.drawingResult,
    this.selectedAnswer,
    this.correctCount = 0,
    this.confusionCount = 0,
    this.roundsCompleted = 0,
    this.isSubmitting = false,
  });

  /// Progress towards model upgrade (0.0 - 1.0)
  double get upgradeProgress => correctCount / 3.0;

  NumbersState copyWith({
    StateStatus? status,
    String? errorMessage,
    NumbersPhase? phase,
    int? currentPart,
    PixyModelLevel? modelLevel,
    NumbersRound? round,
    CountingResult? countingResult,
    DrawingResult? drawingResult,
    int? selectedAnswer,
    bool clearSelectedAnswer = false,
    int? correctCount,
    int? confusionCount,
    int? roundsCompleted,
    bool? isSubmitting,
  }) {
    return NumbersState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      phase: phase ?? this.phase,
      currentPart: currentPart ?? this.currentPart,
      modelLevel: modelLevel ?? this.modelLevel,
      round: round ?? this.round,
      countingResult: countingResult ?? this.countingResult,
      drawingResult: drawingResult ?? this.drawingResult,
      selectedAnswer: clearSelectedAnswer ? null : (selectedAnswer ?? this.selectedAnswer),
      correctCount: correctCount ?? this.correctCount,
      confusionCount: confusionCount ?? this.confusionCount,
      roundsCompleted: roundsCompleted ?? this.roundsCompleted,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  factory NumbersState.loading() =>
      const NumbersState(status: StateStatus.loading);

  factory NumbersState.error(String message) =>
      NumbersState(status: StateStatus.error, errorMessage: message);
}
