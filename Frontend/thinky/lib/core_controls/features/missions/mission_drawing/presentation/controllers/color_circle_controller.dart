import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:thinky/base_controls/base_controller.dart';
import 'package:thinky/base_controls/base_state.dart';
import 'package:thinky/core_controls/services/xp_service.dart';
import 'package:thinky/core_controls/storage/storage_provider.dart';
import 'package:thinky/core_controls/features/missions/mission_drawing/data/drawing_repository.dart';
import 'package:thinky/core_controls/features/missions/mission_drawing/data/drawing_models.dart';

/// State for the color circle mission
class ColorCircleState extends BaseState {
  final Color selectedColor;
  final bool hasDrawing;
  final bool isAnalyzing;
  final DrawingAnalysisResult? analysisResult;
  final String pixyEmotion;
  final bool showResult;
  final bool showLearning;

  const ColorCircleState({
    super.status = StateStatus.initial,
    super.errorMessage,
    this.selectedColor = const Color(0xFFF44336), // Red default
    this.hasDrawing = false,
    this.isAnalyzing = false,
    this.analysisResult,
    this.pixyEmotion = 'neutral',
    this.showResult = false,
    this.showLearning = false,
  });

  ColorCircleState copyWith({
    StateStatus? status,
    String? errorMessage,
    Color? selectedColor,
    bool? hasDrawing,
    bool? isAnalyzing,
    DrawingAnalysisResult? analysisResult,
    String? pixyEmotion,
    bool? showResult,
    bool? showLearning,
  }) {
    return ColorCircleState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
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

/// Controller for the color circle mission
class ColorCircleController extends BaseAsyncController<ColorCircleState> {
  final DrawingRepository _repository;

  ColorCircleController(this._repository) : super(const ColorCircleState());

  /// Update selected color
  void selectColor(Color color) {
    safeUpdate(state.copyWith(selectedColor: color));
  }

  /// Update whether canvas has drawing
  void setHasDrawing(bool hasDrawing) {
    safeUpdate(state.copyWith(hasDrawing: hasDrawing));
  }

  /// Analyze the drawing
  Future<void> analyzeDrawing(Uint8List imageBytes) async {
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
      targetShape: 'circle',
      targetColor: 'red',
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
        if (analysisResult.isCorrect) {
          XpService.awardXp('color_circle', 100.0);
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

  void openLearning() {
    safeUpdate(state.copyWith(showLearning: true));
  }

  void closeLearning() {
    safeUpdate(state.copyWith(showLearning: false));
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
    safeUpdate(const ColorCircleState());
  }
}

/// Provider for ColorCircleController
final colorCircleControllerProvider =
    StateNotifierProvider.autoDispose<ColorCircleController, ColorCircleState>((ref) {
  final storage = ref.watch(localStorageProvider);
  final repository = DrawingRepository(storage);
  return ColorCircleController(repository);
});
