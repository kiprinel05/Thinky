import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thinky/base_controls/base_controller.dart';
import 'package:thinky/base_controls/base_state.dart';
import '../../data/quiz_repository.dart';
import 'package:thinky/core_controls/features/missions/mission_quiz/domain/quiz_models.dart';
import 'quiz_state.dart';

// Import local storage provider for repository DI
import 'package:thinky/core_controls/storage/storage_provider.dart';

/// Provider for QuizRepository
final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  final storage = ref.watch(localStorageProvider);
  return QuizRepository(storage);
});

/// Provider for QuizState
final quizStateProvider = StateNotifierProvider.autoDispose<QuizController, QuizState>((ref) {
  final repository = ref.watch(quizRepositoryProvider);
  return QuizController(repository);
});

class QuizController extends BaseAsyncController<QuizState> {
  final QuizRepository _repository;

  QuizController(this._repository) : super(const QuizState());

  /// Load quiz questions
  Future<void> loadQuestions() async {
    await executeAsync<List<Question>>(
      operation: () async {
        final result = await _repository.getQuestions();
        return result.getOrThrow();
      },
      loadingState: () => QuizState.loading(),
      successState: (questions) => state.copyWith(
        status: StateStatus.success,
        questions: questions,
        currentQuestionIndex: 0,
        selectedAnswers: {},
        quizResult: null,
      ),
      errorState: (message) => QuizState.error(message),
    );
  }

  /// Select answer for current question
  void selectAnswer(int answerId) {
    // Use local access to state
    final currentState = state;
    if (currentState.questions.isEmpty) return;
    
    final currentIndex = currentState.currentQuestionIndex;
    final currentQuestion = currentState.questions[currentIndex];

    // Update selected answer map
    final newSelectedAnswers = Map<int, int>.from(currentState.selectedAnswers);
    newSelectedAnswers[currentIndex] = answerId;

    safeUpdate(currentState.copyWith(
      selectedAnswers: newSelectedAnswers,
    ));
    
    // NOTE: Original UI logic immediately animated Pixy. 
    // Feedback was shown only after pressing "Next" or "Check".
  }

  /// Show feedback for current question
  void showFeedback() {
    final question = state.currentQuestion;
    if (question == null) return;
    
    final selectedAnswerId = state.selectedAnswers[state.currentQuestionIndex];
    if (selectedAnswerId == null) return; // Should not happen if validation works
    
    final isCorrect = selectedAnswerId == question.correctAnswerId;
    
    safeUpdate(state.copyWith(
      showFeedback: true,
      isLastAnswerCorrect: isCorrect,
      feedbackText: question.explanation,
    ));
  }

  /// Hide feedback and proceed
  void goToNextAfterFeedback() {
    safeUpdate(state.copyWith(showFeedback: false));
    
    if (!state.isLastQuestion) {
      safeUpdate(state.copyWith(
        currentQuestionIndex: state.currentQuestionIndex + 1,
      ));
    } else {
      submitQuiz();
    }
  }

  /// Go to previous question
  void previousQuestion() {
    if (state.currentQuestionIndex > 0) {
      safeUpdate(state.copyWith(
        currentQuestionIndex: state.currentQuestionIndex - 1,
      ));
    }
  }

  /// Submit quiz
  Future<void> submitQuiz() async {
    if (state.isSubmitting) return;

    safeUpdate(state.copyWith(isSubmitting: true));

    // Prepare answers list
    final answers = state.questions.asMap().entries.map((entry) {
      final index = entry.key;
      final question = entry.value;
      final answerId = state.selectedAnswers[index] ?? 0;
      return {'question_id': question.id, 'answer_id': answerId};
    }).toList();

    try {
      final result = await _repository.submitQuiz(answers);
      
      final quizResult = result.getOrThrow();
      
      safeUpdate(state.copyWith(
        quizResult: quizResult,
        isSubmitting: false,
      ));
      
      // Auto-complete mission logic (optional, moved to UI controller or service?)
      // Original code called MissionService.completeMission inside page.
      // We can do it here if we have access to MissionsController.
      // But keeping it decoupled is better. Page can observe quizResult and trigger mission completion.
      
    } catch (e) {
      safeUpdate(state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString(),
      ));
    }
  }
  
  // Base implementations
  @override
  void setLoading() => state = state.copyWith(status: StateStatus.loading);
  @override
  void setError(String message) => state = state.copyWith(status: StateStatus.error, errorMessage: message);
  @override
  void setSuccess() => state = state.copyWith(status: StateStatus.success);
  @override
  void clearError() => state = state.copyWith(status: StateStatus.initial, errorMessage: null);
  @override
  void reset() => state = const QuizState();
}