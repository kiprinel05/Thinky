import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thinky/base_controls/base_controller.dart';
import 'package:thinky/base_controls/base_state.dart';
import 'package:thinky/core_controls/constants/app_texts.dart';
import 'package:thinky/core_controls/services/xp_service.dart';
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

  /// Load current round data.
  ///
  /// In Part 2 (drawing) the child is free to draw any digit, so we don't
  /// fetch a round from the server — we just reset the drawing canvas state.
  Future<void> loadRound() async {
    if (state.currentPart == 2) {
      safeUpdate(state.copyWith(
        phase: NumbersPhase.drawing,
        clearDrawingGuess: true,
        clearDrawingResult: true,
      ));
      return;
    }

    await executeSilent<NumbersRound>(
      operation: () async {
        final result = await _repository.getRound();
        return result.getOrThrow();
      },
      successState: (round) => state.copyWith(
        round: round,
        modelLevel: round.modelLevel,
        clearSelectedAnswer: true,
        phase: NumbersPhase.counting,
      ),
      errorState: (error) {
        // Fallback: generate local round
        return state.copyWith(
          round: _generateLocalRound(),
          clearSelectedAnswer: true,
          phase: NumbersPhase.counting,
        );
      },
    );
  }

  /// Select an answer number (Part 1)
  void selectAnswer(int answer) {
    safeUpdate(state.copyWith(selectedAnswer: answer));
  }

  /// Submit the counting answer (Part 1).
  ///
  /// New unified flow: the user always picks a number from the grid; if it
  /// matches Pixy's guess, we infer that they "confirmed" Pixy. There is no
  /// longer a separate Confirm/Send button pair on the UI.
  Future<void> submitCount() async {
    final answer = state.selectedAnswer;
    if (answer == null || state.isSubmitting) return;

    final pixyGuess = state.round?.pixyGuess ?? -1;
    final confirmed = answer == pixyGuess;

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

    _awardXpIfComplete(nextPhase);
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
        pixyMessage: isCorrect
            ? NumbersMission.pixyLocalCorrect
            : NumbersMission.pixyLocalWrong,
        pixyEmotion: isCorrect ? 'happy' : 'sad',
        modelLevel: newModelLevel ?? state.modelLevel,
        correctCount: newCorrectCount,
        confusionCount: newConfusionCount,
        showProfessor: showProfessor,
        professorMessage:
            showProfessor ? NumbersMission.professorLocalHint : null,
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

  // ─── Drawing flow (Part 2) ────────────────────────────────────────────────
  //
  // Step 1 — child draws → submitDrawing(): Pixy proposes a guess.
  // Step 2 — child confirms / corrects → confirmPixyGuess() / correctPixyGuess(int).
  //
  // The session handles the "AI learning" simulation: each accepted example
  // raises the displayed confidence, and after enough confirmed examples the
  // model levels up. If the recognizer was confident but the child claims a
  // very different digit, the professor intervenes (cheating detection).

  /// Step 1: child has drawn a digit; ask Pixy what it thinks.
  Future<void> submitDrawing(Uint8List imageBytes) async {
    if (state.isSubmitting) return;

    safeUpdate(state.copyWith(isSubmitting: true));

    try {
      final result = await _repository.submitDrawing(imageBytes);

      result.fold(
        onSuccess: (guess) {
          safeUpdate(state.copyWith(
            isSubmitting: false,
            drawingGuess: guess,
            phase: NumbersPhase.drawingAwaitingConfirmation,
            modelLevel: guess.modelLevel,
            examplesTaught: guess.examplesTaught,
          ));
        },
        onFailure: (error) {
          // Local fallback: pretend Pixy guessed something so the kid can still
          // play the loop offline. Pick a random 1-5 guess.
          final fallbackGuess = (1 + (DateTime.now().millisecondsSinceEpoch % 5));
          safeUpdate(state.copyWith(
            isSubmitting: false,
            drawingGuess: DrawingGuess(
              guessedDigit: fallbackGuess,
              confidence: 0.30 + 0.18 * state.examplesTaught,
              pixyMessage: NumbersMission.pixyDrawingFailedFallback,
              pixyEmotion: 'thinking',
              modelLevel: state.modelLevel,
              examplesTaught: state.examplesTaught,
            ),
            phase: NumbersPhase.drawingAwaitingConfirmation,
          ));
        },
      );
    } catch (e) {
      safeUpdate(state.copyWith(isSubmitting: false));
    }
  }

  /// Step 2a: child confirms Pixy's guess was right.
  Future<void> confirmPixyGuess() async {
    final guess = state.drawingGuess;
    if (guess == null || guess.guessedDigit == null) return;
    await _teach(guess.guessedDigit!);
  }

  /// Switch the UI to the digit-picker so the child can correct Pixy.
  void startCorrection() {
    safeUpdate(state.copyWith(phase: NumbersPhase.drawingPickCorrection));
  }

  /// Cancel the in-progress correction and go back to the confirmation buttons.
  void cancelCorrection() {
    safeUpdate(state.copyWith(phase: NumbersPhase.drawingAwaitingConfirmation));
  }

  /// Step 2b: child says "no, it was actually [claimedDigit]".
  Future<void> correctPixyGuess(int claimedDigit) async {
    await _teach(claimedDigit);
  }

  Future<void> _teach(int claimedDigit) async {
    if (state.isSubmitting) return;
    safeUpdate(state.copyWith(isSubmitting: true));

    try {
      final result = await _repository.teachDrawing(claimedDigit: claimedDigit);

      result.fold(
        onSuccess: (teachResult) {
          _handleTeachResult(teachResult);
        },
        onFailure: (error) {
          // Offline fallback: assume the claim is correct, increment progress.
          final guess = state.drawingGuess;
          final wasPixyCorrect = guess?.guessedDigit == claimedDigit;
          _handleTeachResult(TeachDrawingResult(
            wasPixyCorrect: wasPixyCorrect,
            isLying: false,
            claimedDigit: claimedDigit,
            recognizedDigit: guess?.guessedDigit,
            pixyMessage: NumbersMission.drawingTeachThanks,
            pixyEmotion: 'happy',
            modelLevel: state.modelLevel,
            correctCount: wasPixyCorrect
                ? state.correctCount + 1
                : state.correctCount,
            confusionCount: 0,
            examplesTaught: state.examplesTaught + 1,
            showProfessor: false,
          ));
        },
      );
    } catch (e) {
      safeUpdate(state.copyWith(isSubmitting: false));
    }
  }

  void _handleTeachResult(TeachDrawingResult result) {
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
      examplesTaught: result.examplesTaught,
    ));

    _awardXpIfComplete(nextPhase);
  }

  /// Local guard so the same playthrough can't double-fire the (already
  /// idempotent) backend XP grant — keeps client logs cleaner.
  bool _xpAwarded = false;

  /// Grants XP the first time we land on [NumbersPhase.completion]. The
  /// score is binary (100%) — same convention as Animals/Drawing — because
  /// the Numbers mission gates completion on actual correct answers, so
  /// reaching the end already implies success.
  void _awardXpIfComplete(NumbersPhase phase) {
    if (phase != NumbersPhase.completion || _xpAwarded) return;
    _xpAwarded = true;
    XpService.awardXp('numbers', 100.0);
  }

  /// Proceed to next round
  Future<void> nextRound() async {
    safeUpdate(state.copyWith(
      clearSelectedAnswer: true,
      countingResult: null,
      clearDrawingGuess: true,
      clearDrawingResult: true,
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
      examplesTaught: 0,
      clearSelectedAnswer: true,
      countingResult: null,
      clearDrawingGuess: true,
      clearDrawingResult: true,
    ));
    await loadRound();
  }

  /// Dismiss professor overlay and continue.
  ///
  /// In Part 2 we keep the canvas blank for a fresh attempt; we do NOT auto-
  /// teach the model anything — the lesson was about not teaching wrong
  /// labels.
  Future<void> dismissProfessor() async {
    if (state.currentPart == 2) {
      safeUpdate(state.copyWith(
        phase: NumbersPhase.drawing,
        clearDrawingGuess: true,
        clearDrawingResult: true,
      ));
      return;
    }
    safeUpdate(state.copyWith(phase: NumbersPhase.counting));
    await nextRound();
  }

  /// Dismiss model upgrade celebration and continue
  Future<void> dismissUpgrade() async {
    await nextRound();
  }

  /// Restart the entire mission from the intro screen.
  Future<void> restart() async {
    state = const NumbersState();
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
      pixyMessage: NumbersMission.pixyLocalGuess(target),
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
