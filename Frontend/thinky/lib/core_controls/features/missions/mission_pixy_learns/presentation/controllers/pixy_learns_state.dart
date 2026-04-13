import 'package:flutter/foundation.dart';
import 'package:thinky/base_controls/base_state.dart';
import '../../domain/pixy_learns_models.dart';

/// State for the Pixy Learns mission
@immutable
class PixyLearnsState extends BaseState {
  final List<LearningImage> images;
  final Map<String, String> labels; // imageId -> label
  final bool showIntroduction;
  final bool showCompletion;
  final bool showLearning;
  final PixyLearnsResult? result;
  final bool isSubmitting;

  const PixyLearnsState({
    super.status = StateStatus.initial,
    super.errorMessage,
    this.images = const [],
    this.labels = const {},
    this.showIntroduction = true,
    this.showCompletion = false,
    this.showLearning = false,
    this.result,
    this.isSubmitting = false,
  });

  /// Check if all images have been labeled
  bool get allLabeled => images.isNotEmpty && labels.length == images.length;

  /// Get progress as a fraction (0.0 - 1.0)
  double get progress => images.isEmpty ? 0.0 : labels.length / images.length;

  /// Get the label for a specific image
  String? getLabel(String imageId) => labels[imageId];

  PixyLearnsState copyWith({
    StateStatus? status,
    String? errorMessage,
    List<LearningImage>? images,
    Map<String, String>? labels,
    bool? showIntroduction,
    bool? showCompletion,
    bool? showLearning,
    PixyLearnsResult? result,
    bool? isSubmitting,
  }) {
    return PixyLearnsState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      images: images ?? this.images,
      labels: labels ?? this.labels,
      showIntroduction: showIntroduction ?? this.showIntroduction,
      showCompletion: showCompletion ?? this.showCompletion,
      showLearning: showLearning ?? this.showLearning,
      result: result ?? this.result,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  factory PixyLearnsState.loading() => 
      const PixyLearnsState(status: StateStatus.loading);

  factory PixyLearnsState.error(String message) => 
      PixyLearnsState(status: StateStatus.error, errorMessage: message);
}
