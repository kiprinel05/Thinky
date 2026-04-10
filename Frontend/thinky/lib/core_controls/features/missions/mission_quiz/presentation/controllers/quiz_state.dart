import 'package:flutter/foundation.dart';
import 'package:thinky/base_controls/base_state.dart';
import 'package:thinky/core_controls/features/missions/mission_quiz/domain/quiz_models.dart';

@immutable
class QuizState extends BaseState {
  final List<Question> questions;
  final int currentQuestionIndex;
  final Map<int, int> selectedAnswers; // QuestionId -> AnswerId or Index -> AnswerId? Page used Index -> AnswerId.
  // Page logic: _selectedAnswers[_currentQuestionIndex] = answerId.
  // Using Index is simpler for tracking progress.
  
  final QuizResult? quizResult;
  final bool isSubmitting;
  
  // Feedback state
  final bool showFeedback;
  final bool isLastAnswerCorrect;
  final String feedbackText;
  /// After submit: full question-by-question review (vs. score summary).
  final bool showAnswerReview;
  /// After submit: swipeable lesson cards with the professor.
  final bool showLearning;

  const QuizState({
    super.status = StateStatus.initial,
    super.errorMessage,
    this.questions = const [],
    this.currentQuestionIndex = 0,
    this.selectedAnswers = const {},
    this.quizResult,
    this.isSubmitting = false,
    this.showFeedback = false,
    this.isLastAnswerCorrect = false,
    this.feedbackText = '',
    this.showAnswerReview = false,
    this.showLearning = false,
  });

  Question? get currentQuestion {
    if (questions.isEmpty || currentQuestionIndex >= questions.length) return null;
    return questions[currentQuestionIndex];
  }

  bool get isLastQuestion => currentQuestionIndex == questions.length - 1;

  int? get currentSelectedAnswerId => selectedAnswers[currentQuestionIndex];
  
  bool get hasSelectedAnswer => currentSelectedAnswerId != null;

  QuizState copyWith({
    StateStatus? status,
    String? errorMessage,
    List<Question>? questions,
    int? currentQuestionIndex,
    Map<int, int>? selectedAnswers,
    QuizResult? quizResult,
    bool? isSubmitting,
    bool? showFeedback,
    bool? isLastAnswerCorrect,
    String? feedbackText,
    bool? showAnswerReview,
    bool? showLearning,
  }) {
    return QuizState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      questions: questions ?? this.questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
      quizResult: quizResult ?? this.quizResult,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      showFeedback: showFeedback ?? this.showFeedback,
      isLastAnswerCorrect: isLastAnswerCorrect ?? this.isLastAnswerCorrect,
      feedbackText: feedbackText ?? this.feedbackText,
      showAnswerReview: showAnswerReview ?? this.showAnswerReview,
      showLearning: showLearning ?? this.showLearning,
    );
  }
  
  // Factory for loading
  factory QuizState.loading() => const QuizState(status: StateStatus.loading);
  
  // Factory for error
  factory QuizState.error(String message) => QuizState(status: StateStatus.error, errorMessage: message);
}