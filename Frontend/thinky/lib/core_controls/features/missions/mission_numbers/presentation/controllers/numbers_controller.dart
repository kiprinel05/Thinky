import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thinky/base_controls/base_controller.dart';
import 'package:thinky/base_controls/base_state.dart';
import 'package:thinky/core_controls/storage/storage_provider.dart';
import '../../data/numbers_repository.dart';
import '../../domain/numbers_models.dart';
import 'numbers_state.dart';

/// Provider for NumbersRepository
final numbersRepositoryProvider = Provider<NumbersRepository>((ref) {
  final storage = ref.watch(localStorageProvider);
  return NumbersRepository(storage);
});

/// Provider for NumbersState
final numbersStateProvider =
    StateNotifierProvider.autoDispose<NumbersController, NumbersState>((ref) {
  final repository = ref.watch(numbersRepositoryProvider);
  return NumbersController(repository);
});

/// Controller for the Numbers Mission
class NumbersController extends BaseAsyncController<NumbersState> {
  final NumbersRepository _repository;

  NumbersController(this._repository) : super(const NumbersState());

  /// Start a new session
  Future<void> startSession() async {
    await executeAsync<NumbersSessionData>(
      operation: () async {
        final result = await _repository.startSession();
        return result.getOrThrow();
      },
      loadingState: () => NumbersState.loading(),
      successState: (session) => state.copyWith(
        status: StateStatus.success,
        phase: NumbersPhase.counting,
        currentPart: session.currentPart,
        modelLevel: session.modelLevel,
      ),
      errorState: (message) => state.copyWith(
        status: StateStatus.success,
        phase: NumbersPhase.counting,
        modelLevel: PixyModelLevel.junior,
      ),
    );
    // Immediately load the first round
    await loadRound();
  }

  /// Load current round data
  Future<void> loadRound() async {
    await executeSilent<NumbersRound>(
      operation: () async {
        final result = await _repository.getRound();
        return result.getOrThrow();
      },
      successState: (round) => state.copyWith(
        round: round,
        modelLevel: round.modelLevel,
        clearSelectedAnswer: true,
        phase: state.currentPart == 1 ? NumbersPhase.counting : NumbersPhase.drawing,
      ),
      errorState: (error) {
        // Fallback: generate local round
        return state.copyWith(
          round: _generateLocalRound(),
          clearSelectedAnswer: true,
          phase: state.currentPart == 1 ? NumbersPhase.counting : NumbersPhase.drawing,
        );
      },
    );
  }

  /// Select an answer number (Part 1)
  void selectAnswer(int answer) {
    safeUpdate(state.copyWith(selectedAnswer: answer));
  }

  /// Submit the counting answer (Part 1)
  Future<void> submitCount({bool confirmed = false}) async {
    final answer = confirmed ? (state.round?.pixyGuess ?? 1) : (state.selectedAnswer ?? 1);
    if (state.isSubmitting) return;

    safeUpdate(state.copyWith(isSubmitting: true));

    try {
      final result = await _repository.submitCount(
        answer: answer,
        confirmed: confirmed,
      );

      result.fold(
        onSuccess: (countResult) {
          _handleCountingResult(countResult);
        },
        onFailure: (error) {
          // Fallback: simulate result locally
          _handleCountingResultLocal(answer, confirmed);
        },
      );
    } catch (e) {
      _handleCountingResultLocal(answer, confirmed);
    }
  }

  void _handleCountingResult(CountingResult result) {
    NumbersPhase nextPhase;

    if (result.showProfessor) {
      nextPhase = NumbersPhase.professorIntervention;
    } else if (result.modelUpgraded) {
      nextPhase = NumbersPhase.modelUpgrade;
    } else if (result.partCompleted) {
      if (state.currentPart == 1) {
        nextPhase = NumbersPhase.transitionToPart2;
      } else {
        nextPhase = NumbersPhase.completion;
      }
    } else {
      nextPhase = NumbersPhase.pixyGuessing;
    }

    safeUpdate(state.copyWith(
      isSubmitting: false,
      countingResult: result,
      phase: nextPhase,
      modelLevel: result.newModelLevel ?? result.modelLevel,
      correctCount: result.correctCount,
      confusionCount: result.confusionCount,
      currentPart: state.currentPart,
    ));
  }

  void _handleCountingResultLocal(int answer, bool confirmed) {
    final target = state.round?.targetNumber ?? 1;
    final isCorrect = answer == target;

    final newCorrectCount = isCorrect ? state.correctCount + 1 : state.correctCount;
    final newConfusionCount = isCorrect ? 0 : state.confusionCount + 1;

    // Determine model upgrade (after 3 correct answers at current level)
    bool modelUpgraded = false;
    PixyModelLevel? newModelLevel;
    if (isCorrect && newCorrectCount % 3 == 0) {
      if (state.modelLevel == PixyModelLevel.junior) {
        modelUpgraded = true;
        newModelLevel = PixyModelLevel.student;
      } else if (state.modelLevel == PixyModelLevel.student) {
        modelUpgraded = true;
        newModelLevel = PixyModelLevel.expert;
      }
    }

    // Part completed after 5 correct answers
    final partCompleted = newCorrectCount >= 5;

    // Professor intervention after 2+ consecutive wrong answers
    final showProfessor = !isCorrect && newConfusionCount >= 2;

    // Determine next phase
    NumbersPhase nextPhase;
    if (showProfessor) {
      nextPhase = NumbersPhase.professorIntervention;
    } else if (modelUpgraded) {
      nextPhase = NumbersPhase.modelUpgrade;
    } else if (partCompleted) {
      if (state.currentPart == 1) {
        nextPhase = NumbersPhase.transitionToPart2;
      } else {
        nextPhase = NumbersPhase.completion;
      }
    } else {
      nextPhase = NumbersPhase.pixyGuessing;
    }

    safeUpdate(state.copyWith(
      isSubmitting: false,
      countingResult: CountingResult(
        isCorrect: isCorrect,
        correctAnswer: target,
        pixyGuess: state.round?.pixyGuess ?? 1,
        pixyMessage: isCorrect ? 'Super! Am ghicit! 😊' : 'Oh nu, am greșit... 😢',
        pixyEmotion: isCorrect ? 'happy' : 'sad',
        modelLevel: newModelLevel ?? state.modelLevel,
        correctCount: newCorrectCount,
        confusionCount: newConfusionCount,
        showProfessor: showProfessor,
        professorMessage: showProfessor ? 'Numără obiectele cu atenție și alege numărul corect!' : null,
        modelUpgraded: modelUpgraded,
        newModelLevel: newModelLevel,
        partCompleted: partCompleted,
      ),
      phase: nextPhase,
      modelLevel: newModelLevel ?? state.modelLevel,
      correctCount: newCorrectCount,
      confusionCount: newConfusionCount,
      currentPart: state.currentPart,
    ));
  }

  /// Submit a digit drawing (Part 2)
  Future<void> submitDrawing(Uint8List imageBytes) async {
    if (state.isSubmitting) return;

    safeUpdate(state.copyWith(isSubmitting: true));

    try {
      final result = await _repository.submitDrawing(imageBytes);

      result.fold(
        onSuccess: (drawResult) {
          _handleDrawingResult(drawResult);
        },
        onFailure: (error) {
          safeUpdate(state.copyWith(
            isSubmitting: false,
            drawingResult: DrawingResult(
              guessedDigit: null,
              confidence: 0.0,
              isCorrect: false,
              targetDigit: state.round?.targetNumber ?? 1,
              pixyMessage: 'Hmm, nu am putut vedea desenul... Încearcă din nou! 🤔',
              pixyEmotion: 'thinking',
              modelLevel: state.modelLevel,
              correctCount: state.correctCount,
              confusionCount: state.confusionCount,
              showProfessor: false,
            ),
            phase: NumbersPhase.drawingResult,
          ));
        },
      );
    } catch (e) {
      safeUpdate(state.copyWith(isSubmitting: false));
    }
  }

  void _handleDrawingResult(DrawingResult result) {
    NumbersPhase nextPhase;

    if (result.showProfessor) {
      nextPhase = NumbersPhase.professorIntervention;
    } else if (result.modelUpgraded) {
      nextPhase = NumbersPhase.modelUpgrade;
    } else if (result.partCompleted) {
      nextPhase = NumbersPhase.completion;
    } else {
      nextPhase = NumbersPhase.drawingResult;
    }

    safeUpdate(state.copyWith(
      isSubmitting: false,
      drawingResult: result,
      phase: nextPhase,
      modelLevel: result.newModelLevel ?? result.modelLevel,
      correctCount: result.correctCount,
      confusionCount: result.confusionCount,
    ));
  }

  /// Proceed to next round
  Future<void> nextRound() async {
    safeUpdate(state.copyWith(
      clearSelectedAnswer: true,
      countingResult: null,
      drawingResult: null,
    ));
    await loadRound();
  }

  /// Transition from Part 1 to Part 2
  Future<void> switchToPart2() async {
    safeUpdate(state.copyWith(
      currentPart: 2,
      phase: NumbersPhase.drawing,
      modelLevel: PixyModelLevel.junior,
      correctCount: 0,
      confusionCount: 0,
      clearSelectedAnswer: true,
      countingResult: null,
    ));
    await loadRound();
  }

  /// Dismiss professor overlay and continue
  Future<void> dismissProfessor() async {
    safeUpdate(state.copyWith(
      phase: state.currentPart == 1 ? NumbersPhase.counting : NumbersPhase.drawing,
    ));
    await nextRound();
  }

  /// Dismiss model upgrade celebration and continue
  Future<void> dismissUpgrade() async {
    await nextRound();
  }

  /// Generate a local fallback round
  NumbersRound _generateLocalRound() {
    final numbers = [1, 2, 3, 4, 5];
    numbers.shuffle();
    final target = numbers.first;
    final emojis = ['🍎', '🎈', '⭐'];
    emojis.shuffle();

    return NumbersRound(
      targetNumber: target,
      objects: List.generate(
        target,
        (_) => NumberObject(emoji: emojis.first, objectType: 'apple'),
      ),
      pixyGuess: target, // Simplified for offline
      pixyMessage: 'Hmm… cred că sunt $target? 🤔',
      pixyConfidence: 'low',
      modelLevel: state.modelLevel,
      currentPart: state.currentPart,
    );
  }

  @override
  void setLoading() => state = state.copyWith(status: StateStatus.loading);

  @override
  void setError(String message) =>
      state = state.copyWith(status: StateStatus.error, errorMessage: message);

  @override
  void setSuccess() => state = state.copyWith(status: StateStatus.success);

  @override
  void clearError() =>
      state = state.copyWith(status: StateStatus.initial, errorMessage: null);

  @override
  void reset() => state = const NumbersState();
}
