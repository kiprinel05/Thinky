import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:thinky/base_controls/base_controller.dart';
import 'package:thinky/base_controls/base_state.dart';
import 'package:thinky/core_controls/services/xp_service.dart';
import 'package:thinky/core_controls/storage/storage_provider.dart';
import 'package:thinky/core_controls/features/missions/mission_drawing/data/drawing_repository.dart';
import 'package:thinky/core_controls/features/missions/mission_drawing/data/drawing_models.dart';

/// Round config: shape + color for each round
class DrawingRoundConfig {
  final String shape;
  final String color;

  const DrawingRoundConfig({required this.shape, required this.color});
}

/// State for the drawing mission (3 rounds: triangle, circle, square)
class DrawingState extends BaseState {
  final int currentRound;
  final int totalRounds;
  final Color selectedColor;
  final bool hasDrawing;
  final bool isAnalyzing;
  final DrawingAnalysisResult? analysisResult;
  final String pixyEmotion;
  final bool showResult;
  final bool showLearning;

  static const List<DrawingRoundConfig> roundConfigs = [
    DrawingRoundConfig(shape: 'triangle', color: 'blue'),
    DrawingRoundConfig(shape: 'circle', color: 'red'),
    DrawingRoundConfig(shape: 'square', color: 'green'),
  ];

  const DrawingState({
    super.status = StateStatus.initial,
    super.errorMessage,
    this.currentRound = 1,
    this.totalRounds = 3,
    this.selectedColor = const Color(0xFF2196F3),
    this.hasDrawing = false,
    this.isAnalyzing = false,
    this.analysisResult,
    this.pixyEmotion = 'neutral',
    this.showResult = false,
    this.showLearning = false,
  });

  DrawingRoundConfig get currentRoundConfig =>
      roundConfigs[currentRound - 1];

  bool get isMissionComplete => currentRound > totalRounds;

  DrawingState copyWith({
    StateStatus? status,
    String? errorMessage,
    int? currentRound,
    int? totalRounds,
    Color? selectedColor,
    bool? hasDrawing,
    bool? isAnalyzing,
    DrawingAnalysisResult? analysisResult,
    String? pixyEmotion,
    bool? showResult,
    bool? showLearning,
  }) {
    return DrawingState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      currentRound: currentRound ?? this.currentRound,
      totalRounds: totalRounds ?? this.totalRounds,
      selectedColor: selectedColor ?? this.selectedColor,
      hasDrawing: hasDrawing ?? this.hasDrawing,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      analysisResult: analysisResult ?? this.analysisResult,
      pixyEmotion: pixyEmotion ?? this.pixyEmotion,
      showResult: showResult ?? this.showResult,
      showLearning: showLearning ?? this.showLearning,
    );
  }
}

/// Controller for the drawing mission
class DrawingController extends BaseAsyncController<DrawingState> {
  final DrawingRepository _repository;

  DrawingController(this._repository) : super(const DrawingState());

  /// Update selected color
  void selectColor(Color color) {
    safeUpdate(state.copyWith(selectedColor: color));
  }

  /// Update whether canvas has drawing
  void setHasDrawing(bool hasDrawing) {
    safeUpdate(state.copyWith(hasDrawing: hasDrawing));
  }

  /// Analyze the drawing for current round
  Future<void> analyzeDrawing(Uint8List imageBytes) async {
    final config = state.currentRoundConfig;
    // Start analysis - show Pixy thinking
    safeUpdate(state.copyWith(
      isAnalyzing: true,
      pixyEmotion: 'thinking',
      showResult: false,
    ));

    // Simulate a small delay for the "thinking" animation to be visible
    await Future.delayed(const Duration(milliseconds: 1500));

    final result = await _repository.analyzeDrawing(
      imageBytes: imageBytes,
      targetShape: config.shape,
      targetColor: config.color,
      requireFill: false,
    );

    result.fold(
      onSuccess: (analysisResult) {
        safeUpdate(state.copyWith(
          isAnalyzing: false,
          analysisResult: analysisResult,
          pixyEmotion: analysisResult.pixyEmotion,
          showResult: true,
          status: StateStatus.success,
        ));
        if (analysisResult.isCorrect && state.currentRound >= state.totalRounds) {
          XpService.awardXp('draw_shapes', 100.0);
        }
      },
      onFailure: (error) {
        safeUpdate(state.copyWith(
          isAnalyzing: false,
          pixyEmotion: 'encouraging',
          status: StateStatus.error,
          errorMessage: error.message,
        ));
      },
    );
  }

  /// Reset for trying again
  void resetForRetry() {
    safeUpdate(state.copyWith(
      showResult: false,
      analysisResult: null,
      pixyEmotion: 'neutral',
      status: StateStatus.initial,
    ));
  }

  /// Clear canvas state
  void clearCanvas() {
    safeUpdate(state.copyWith(
      hasDrawing: false,
      showResult: false,
      analysisResult: null,
      pixyEmotion: 'neutral',
    ));
  }

  void openLearning() {
    safeUpdate(state.copyWith(showLearning: true));
  }

  void closeLearning() {
    safeUpdate(state.copyWith(showLearning: false));
  }

  /// Advance to next round (after correct drawing)
  void nextRound() {
    if (state.currentRound >= state.totalRounds) return;
    safeUpdate(state.copyWith(
      currentRound: state.currentRound + 1,
      hasDrawing: false,
      showResult: false,
      analysisResult: null,
      pixyEmotion: 'neutral',
    ));
  }

  @override
  void setLoading() {
    safeUpdate(state.copyWith(status: StateStatus.loading));
  }

  @override
  void setError(String message) {
    safeUpdate(state.copyWith(status: StateStatus.error, errorMessage: message));
  }

  @override
  void setSuccess() {
    safeUpdate(state.copyWith(status: StateStatus.success));
  }

  @override
  void clearError() {
    safeUpdate(state.copyWith(errorMessage: null));
  }

  @override
  void reset() {
    safeUpdate(const DrawingState());
  }
}

/// Provider for DrawingController
final drawingControllerProvider =
    StateNotifierProvider.autoDispose<DrawingController, DrawingState>((ref) {
  final storage = ref.watch(localStorageProvider);
  final repository = DrawingRepository(storage);
  return DrawingController(repository);
});
