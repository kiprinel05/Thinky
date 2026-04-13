import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thinky/base_controls/base_controller.dart';
import 'package:thinky/base_controls/base_state.dart';
import 'package:thinky/core_controls/storage/storage_provider.dart';
import '../../data/pixy_learns_repository.dart';
import '../../domain/pixy_learns_models.dart';
import 'pixy_learns_state.dart';

/// Provider for PixyLearnsRepository
final pixyLearnsRepositoryProvider = Provider<PixyLearnsRepository>((ref) {
  final storage = ref.watch(localStorageProvider);
  return PixyLearnsRepository(storage);
});

/// Provider for PixyLearnsState
final pixyLearnsStateProvider = 
    StateNotifierProvider.autoDispose<PixyLearnsController, PixyLearnsState>((ref) {
  final repository = ref.watch(pixyLearnsRepositoryProvider);
  return PixyLearnsController(repository);
});

/// Controller for Pixy Learns mission
class PixyLearnsController extends BaseAsyncController<PixyLearnsState> {
  final PixyLearnsRepository _repository;

  PixyLearnsController(this._repository) : super(const PixyLearnsState());

  /// Load images from API
  Future<void> loadImages() async {
    await executeAsync<List<LearningImage>>(
      operation: () async {
        final result = await _repository.getImages();
        return result.getOrThrow();
      },
      loadingState: () => PixyLearnsState.loading(),
      successState: (images) => state.copyWith(
        status: StateStatus.success,
        images: images.isNotEmpty ? images : _getLocalImages(),
        showIntroduction: true,
      ),
      errorState: (message) => state.copyWith(
        status: StateStatus.success,
        images: _getLocalImages(),
        showIntroduction: true,
      ),
    );
  }

  /// Get local images for offline mode
  List<LearningImage> _getLocalImages() {
    return const [
      LearningImage(id: 'apple1', url: 'emoji:🍎', correctLabel: 'apple'),
      LearningImage(id: 'cat1', url: 'emoji:🐱', correctLabel: 'cat'),
      LearningImage(id: 'apple2', url: 'emoji:🍏', correctLabel: 'apple'),
      LearningImage(id: 'cat2', url: 'emoji:😺', correctLabel: 'cat'),
      LearningImage(id: 'apple3', url: 'emoji:🍎', correctLabel: 'apple'),
      LearningImage(id: 'cat3', url: 'emoji:🐱', correctLabel: 'cat'),
    ];
  }

  /// Start the mission (hide introduction)
  void startMission() {
    safeUpdate(state.copyWith(showIntroduction: false));
  }

  /// Select a label for an image
  void selectLabel(String imageId, String label) {
    final newLabels = Map<String, String>.from(state.labels);
    newLabels[imageId] = label;
    safeUpdate(state.copyWith(labels: newLabels));
  }

  /// Submit all labels
  Future<void> submitLabels() async {
    if (!state.allLabeled || state.isSubmitting) return;

    safeUpdate(state.copyWith(isSubmitting: true));

    try {
      final result = await _repository.submitLabels(state.labels);
      
      result.fold(
        onSuccess: (pixyResult) {
          safeUpdate(state.copyWith(
            isSubmitting: false,
            result: pixyResult,
            showCompletion: true,
          ));
        },
        onFailure: (error) {
          // Show completion anyway with local result
          safeUpdate(state.copyWith(
            isSubmitting: false,
            result: PixyLearnsResult(
              learnedExamples: state.images.length,
              progressPercentage: 100.0,
              categories: ['apple', 'cat'],
              isComplete: true,
            ),
            showCompletion: true,
          ));
        },
      );
    } catch (e) {
      safeUpdate(state.copyWith(
        isSubmitting: false,
        result: PixyLearnsResult(
          learnedExamples: state.images.length,
          progressPercentage: 100.0,
          categories: ['apple', 'cat'],
          isComplete: true,
        ),
        showCompletion: true,
      ));
    }
  }

  void openLearning() {
    safeUpdate(state.copyWith(showLearning: true));
  }

  void closeLearning() {
    safeUpdate(state.copyWith(showLearning: false));
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
  void reset() => state = const PixyLearnsState();
}
