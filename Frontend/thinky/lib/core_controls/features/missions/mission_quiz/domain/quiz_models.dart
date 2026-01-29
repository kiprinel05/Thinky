import 'package:flutter/foundation.dart';

@immutable
class Question {
  final int id;
  final String question;
  final List<AnswerOption> options;
  final int correctAnswerId;
  final String explanation;

  const Question({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswerId,
    required this.explanation,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as int,
      question: json['question'] as String,
      options: (json['options'] as List)
          .map((o) => AnswerOption.fromJson(o))
          .toList(),
      correctAnswerId: json['correct_answer_id'] as int,
      explanation: json['explanation'] as String,
    );
  }
}

@immutable
class AnswerOption {
  final int id;
  final String text;

  const AnswerOption({
    required this.id,
    required this.text,
  });

  factory AnswerOption.fromJson(Map<String, dynamic> json) {
    return AnswerOption(
      id: json['id'] as int,
      text: json['text'] as String,
    );
  }
}

@immutable
class QuizResult {
  final int score;
  final int totalQuestions;
  final double percentage;
  final int correctAnswers;
  final int incorrectAnswers;

  const QuizResult({
    required this.score,
    required this.totalQuestions,
    required this.percentage,
    required this.correctAnswers,
    required this.incorrectAnswers,
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      score: json['score'] as int,
      totalQuestions: json['total_questions'] as int,
      percentage: (json['percentage'] as num).toDouble(),
      correctAnswers: json['correct_answers'] as int,
      incorrectAnswers: json['incorrect_answers'] as int,
    );
  }
}
