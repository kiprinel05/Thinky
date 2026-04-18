import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'package:thinky/core/errors/error_logger.dart';
import 'package:thinky/core_controls/constants/app_texts.dart';
import 'package:thinky/core_controls/network/user_facing_error_mapper.dart';
import 'package:thinky/core_controls/services/mission_service.dart';

import '../../data/describe_models.dart';
import '../../data/describe_repository.dart';

/// Phases of the Describe-It mission.
enum DescribeMissionPhase {
  intro,
  loading,
  viewing,
  recording,
  processing,
  feedback,
  missionComplete,
  error,
}

/// Pre-computed, localised message pair shown in the feedback phase.
class DescribeFeedbackMessage {
  final String message;
  final String encouragement;

  const DescribeFeedbackMessage({
    required this.message,
    required this.encouragement,
  });
}

class DescribeMissionState {
  final DescribeMissionPhase phase;
  final List<DescribeItem> questions;
  final int currentIndex;
  final int totalQuestions;
  final String? audioPath;
  final DescribeAnswerResponse? lastAnswer;
  final DescribeFeedbackMessage? lastFeedback;
  final int correctCount;
  final int answeredCount;
  final double accumulatedScore;
  final Duration recordingDuration;
  final String? errorMessage;

  const DescribeMissionState({
    this.phase = DescribeMissionPhase.intro,
    this.questions = const [],
    this.currentIndex = 0,
    this.totalQuestions = 0,
    this.audioPath,
    this.lastAnswer,
    this.lastFeedback,
    this.correctCount = 0,
    this.answeredCount = 0,
    this.accumulatedScore = 0.0,
    this.recordingDuration = Duration.zero,
    this.errorMessage,
  });

  DescribeItem? get currentQuestion {
    if (currentIndex >= 0 && currentIndex < questions.length) {
      return questions[currentIndex];
    }
    return null;
  }

  double get progress =>
      totalQuestions > 0 ? answeredCount / totalQuestions : 0.0;

  /// Average score (0..1) across answered rounds.
  double get averageScore =>
      answeredCount > 0 ? accumulatedScore / answeredCount : 0.0;

  DescribeMissionState copyWith({
    DescribeMissionPhase? phase,
    List<DescribeItem>? questions,
    int? currentIndex,
    int? totalQuestions,
    String? audioPath,
    bool clearAudio = false,
    DescribeAnswerResponse? lastAnswer,
    bool clearLastAnswer = false,
    DescribeFeedbackMessage? lastFeedback,
    bool clearLastFeedback = false,
    int? correctCount,
    int? answeredCount,
    double? accumulatedScore,
    Duration? recordingDuration,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DescribeMissionState(
      phase: phase ?? this.phase,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      audioPath: clearAudio ? null : (audioPath ?? this.audioPath),
      lastAnswer: clearLastAnswer ? null : (lastAnswer ?? this.lastAnswer),
      lastFeedback:
          clearLastFeedback ? null : (lastFeedback ?? this.lastFeedback),
      correctCount: correctCount ?? this.correctCount,
      answeredCount: answeredCount ?? this.answeredCount,
      accumulatedScore: accumulatedScore ?? this.accumulatedScore,
      recordingDuration: recordingDuration ?? this.recordingDuration,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class DescribeController extends StateNotifier<DescribeMissionState> {
  DescribeController() : super(const DescribeMissionState());

  final AudioRecorder _recorder = AudioRecorder();
  final Random _rng = Random();

  /// Move from the intro screen into loading the first question set.
  Future<void> startFromIntro() async {
    state = state.copyWith(phase: DescribeMissionPhase.loading);
    await _fetchQuestions();
  }

  /// Replay the mission from the completion screen.
  Future<void> restart() async {
    state = const DescribeMissionState(phase: DescribeMissionPhase.loading);
    await _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    try {
      final response = await DescribeRepository.startMission();
      state = state.copyWith(
        phase: DescribeMissionPhase.viewing,
        questions: response.questions,
        currentIndex: 0,
        totalQuestions: response.totalRounds,
        correctCount: 0,
        answeredCount: 0,
        accumulatedScore: 0.0,
        clearAudio: true,
        clearLastAnswer: true,
        clearLastFeedback: true,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        phase: DescribeMissionPhase.error,
        errorMessage: UserFacingErrorMapper.map(e),
      );
    }
  }

  /// Start recording audio for the current round.
  Future<void> startRecording() async {
    if (state.phase != DescribeMissionPhase.viewing) return;
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        state = state.copyWith(
          phase: DescribeMissionPhase.error,
          errorMessage: DescribeMission.microphonePermissionBody,
        );
        return;
      }

      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/describe_${DateTime.now().millisecondsSinceEpoch}.wav';

      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.wav),
        path: path,
      );

      state = state.copyWith(
        phase: DescribeMissionPhase.recording,
        audioPath: path,
        recordingDuration: Duration.zero,
      );
    } catch (e) {
      state = state.copyWith(
        phase: DescribeMissionPhase.error,
        errorMessage: UserFacingErrorMapper.map(e),
      );
    }
  }

  /// Cancel without validating (back to viewing).
  Future<void> cancelRecording() async {
    if (state.phase != DescribeMissionPhase.recording) return;
    try {
      await _recorder.stop();
    } catch (_) {
      // ignore — best-effort cancel
    }
    state = state.copyWith(
      phase: DescribeMissionPhase.viewing,
      clearAudio: true,
    );
  }

  /// Stop recording and send for transcription + validation.
  Future<void> stopRecording() async {
    if (state.phase != DescribeMissionPhase.recording) return;

    try {
      final path = await _recorder.stop();
      if (path == null || path.isEmpty) {
        state = state.copyWith(
          phase: DescribeMissionPhase.viewing,
          clearAudio: true,
        );
        return;
      }

      state = state.copyWith(
        phase: DescribeMissionPhase.processing,
        audioPath: path,
      );

      final result = await DescribeRepository.transcribeAudio(
        filePath: path,
        questionIndex: state.currentIndex,
      );

      final feedback = _buildFeedback(correct: result.correct);

      state = state.copyWith(
        phase: DescribeMissionPhase.feedback,
        lastAnswer: result,
        lastFeedback: feedback,
        correctCount: result.correct
            ? state.correctCount + 1
            : state.correctCount,
        answeredCount: state.answeredCount + 1,
        accumulatedScore:
            state.accumulatedScore + result.result.matchScore,
      );
    } catch (e) {
      state = state.copyWith(
        phase: DescribeMissionPhase.error,
        errorMessage: UserFacingErrorMapper.map(e),
      );
    }
  }

  /// Re-record the same round without advancing.
  void retryRecording() {
    if (state.phase != DescribeMissionPhase.feedback) return;
    // Undo the last round's counters so the retry doesn't double-count.
    final undo = state.copyWith(
      phase: DescribeMissionPhase.viewing,
      answeredCount:
          state.answeredCount > 0 ? state.answeredCount - 1 : 0,
      correctCount: (state.lastAnswer?.correct ?? false)
          ? (state.correctCount > 0 ? state.correctCount - 1 : 0)
          : state.correctCount,
      accumulatedScore: (state.accumulatedScore -
              (state.lastAnswer?.result.matchScore ?? 0.0))
          .clamp(0.0, double.infinity)
          .toDouble(),
      clearLastAnswer: true,
      clearLastFeedback: true,
      clearAudio: true,
    );
    state = undo;
  }

  /// Advance to next round or complete the mission.
  Future<void> nextQuestion() async {
    final nextIndex = state.currentIndex + 1;

    if (nextIndex >= state.totalQuestions) {
      try {
        await MissionService.completeMission(-8);
      } catch (e, stack) {
        ErrorLogger().logError(e, stackTrace: stack);
      }
      state = state.copyWith(phase: DescribeMissionPhase.missionComplete);
      return;
    }

    state = state.copyWith(
      phase: DescribeMissionPhase.viewing,
      currentIndex: nextIndex,
      clearAudio: true,
      clearLastAnswer: true,
      clearLastFeedback: true,
    );
  }

  void reset() {
    state = const DescribeMissionState();
  }

  // ────────────────────────────────────────────────────────────────────
  // Localised feedback builder — picks a random line from the bundle.
  // ────────────────────────────────────────────────────────────────────

  DescribeFeedbackMessage _buildFeedback({required bool correct}) {
    final variant = _rng.nextInt(4) + 1;
    return DescribeFeedbackMessage(
      message: correct
          ? DescribeMission.feedbackCorrect(variant)
          : DescribeMission.feedbackIncorrect(variant),
      encouragement: correct
          ? DescribeMission.encourageCorrect(variant)
          : DescribeMission.encourageIncorrect(variant),
    );
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }
}

final describeControllerProvider =
    StateNotifierProvider<DescribeController, DescribeMissionState>((ref) {
  return DescribeController();
});
