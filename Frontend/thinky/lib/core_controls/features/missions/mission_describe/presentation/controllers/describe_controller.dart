import 'dart:io';
import 'package:thinky/core/errors/error_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:thinky/core_controls/services/mission_service.dart';
import '../../data/describe_models.dart';
import '../../data/describe_repository.dart';

/// Phases of the describe mission
enum DescribeMissionPhase {
  loading,
  viewing,     // Viewing the image, ready to record
  recording,   // Actively recording audio
  processing,  // Sending audio to backend for transcription
  feedback,    // Showing transcription + keyword match results
  missionComplete,
  error,
}

/// State for the Describe mission
class DescribeMissionState {
  final DescribeMissionPhase phase;
  final DescribeStartResponse? roundData;
  final TranscriptionResponse? lastResult;
  final int currentRound;
  final int totalRounds;
  final int correctRounds; // Rounds with score >= 0.5
  final String? audioPath;
  final String? errorMessage;
  final String? encouragement;
  final Duration recordingDuration;

  const DescribeMissionState({
    this.phase = DescribeMissionPhase.loading,
    this.roundData,
    this.lastResult,
    this.currentRound = 0,
    this.totalRounds = 5,
    this.correctRounds = 0,
    this.audioPath,
    this.errorMessage,
    this.encouragement,
    this.recordingDuration = Duration.zero,
  });

  double get progress =>
      totalRounds > 0 ? currentRound / totalRounds : 0.0;

  DescribeMissionState copyWith({
    DescribeMissionPhase? phase,
    DescribeStartResponse? roundData,
    TranscriptionResponse? lastResult,
    bool clearResult = false,
    int? currentRound,
    int? totalRounds,
    int? correctRounds,
    String? audioPath,
    bool clearAudio = false,
    String? errorMessage,
    String? encouragement,
    bool clearEncouragement = false,
    Duration? recordingDuration,
  }) {
    return DescribeMissionState(
      phase: phase ?? this.phase,
      roundData: roundData ?? this.roundData,
      lastResult: clearResult ? null : (lastResult ?? this.lastResult),
      currentRound: currentRound ?? this.currentRound,
      totalRounds: totalRounds ?? this.totalRounds,
      correctRounds: correctRounds ?? this.correctRounds,
      audioPath: clearAudio ? null : (audioPath ?? this.audioPath),
      errorMessage: errorMessage,
      encouragement: clearEncouragement
          ? null
          : (encouragement ?? this.encouragement),
      recordingDuration: recordingDuration ?? this.recordingDuration,
    );
  }
}

class DescribeController extends StateNotifier<DescribeMissionState> {
  DescribeController() : super(const DescribeMissionState());

  final AudioRecorder _recorder = AudioRecorder();

  /// Start the mission — load the first image
  Future<void> startMission() async {
    state = state.copyWith(phase: DescribeMissionPhase.loading);

    try {
      final response = await DescribeRepository.startMission();

      state = state.copyWith(
        phase: DescribeMissionPhase.viewing,
        roundData: response,
        currentRound: response.round,
        totalRounds: response.totalRounds,
        clearResult: true,
        clearAudio: true,
        clearEncouragement: true,
      );
    } catch (e) {
      state = state.copyWith(
        phase: DescribeMissionPhase.error,
        errorMessage: 'Failed to start mission: $e',
      );
    }
  }

  /// Start recording audio
  Future<void> startRecording() async {
    if (state.phase != DescribeMissionPhase.viewing) return;

    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        state = state.copyWith(
          phase: DescribeMissionPhase.error,
          errorMessage: 'Microphone permission denied.',
        );
        return;
      }

      // Get temp directory for audio file
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/describe_recording.wav';

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
        errorMessage: 'Failed to start recording: $e',
      );
    }
  }

  /// Stop recording and send for transcription
  Future<void> stopRecording() async {
    if (state.phase != DescribeMissionPhase.recording) return;

    try {
      final path = await _recorder.stop();

      if (path == null || path.isEmpty) {
        state = state.copyWith(
          phase: DescribeMissionPhase.error,
          errorMessage: 'No audio recorded.',
        );
        return;
      }

      state = state.copyWith(
        phase: DescribeMissionPhase.processing,
        audioPath: path,
      );

      // Send to backend for transcription
      final result = await DescribeRepository.transcribeAudio(path);

      state = state.copyWith(
        phase: DescribeMissionPhase.feedback,
        lastResult: result,
        encouragement: result.encouragement,
        correctRounds: result.matchScore >= 0.5
            ? state.correctRounds + 1
            : state.correctRounds,
      );
    } catch (e) {
      state = state.copyWith(
        phase: DescribeMissionPhase.error,
        errorMessage: 'Failed to process audio: $e',
      );
    }
  }

  /// Advance to next round or complete mission
  Future<void> nextRound() async {
    if (state.currentRound >= state.totalRounds) {
      // Mission complete
      try {
        await MissionService.completeMission(-8);
      } catch (e, stack) {
        ErrorLogger().logError(e, stackTrace: stack);
      }
      state = state.copyWith(phase: DescribeMissionPhase.missionComplete);
      return;
    }

    state = state.copyWith(phase: DescribeMissionPhase.loading);

    try {
      final response = await DescribeRepository.nextRound();

      state = state.copyWith(
        phase: DescribeMissionPhase.viewing,
        roundData: response,
        currentRound: response.round,
        clearResult: true,
        clearAudio: true,
        clearEncouragement: true,
      );
    } catch (e) {
      state = state.copyWith(
        phase: DescribeMissionPhase.error,
        errorMessage: 'Failed to load next round: $e',
      );
    }
  }

  /// Reset mission
  void reset() {
    state = const DescribeMissionState();
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }
}

/// Provider
final describeControllerProvider =
    StateNotifierProvider<DescribeController, DescribeMissionState>((ref) {
  return DescribeController();
});
