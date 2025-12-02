import 'package:flutter/material.dart';

class Question {
  final int id;
  final String question;
  final List<AnswerOption> options;
  final int correctAnswerId;
  final String explanation;

  Question({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswerId,
    required this.explanation,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      question: json['question'],
      options: (json['options'] as List)
          .map((o) => AnswerOption.fromJson(o))
          .toList(),
      correctAnswerId: json['correct_answer_id'],
      explanation: json['explanation'],
    );
  }
}

class AnswerOption {
  final int id;
  final String text;

  AnswerOption({required this.id, required this.text});

  factory AnswerOption.fromJson(Map<String, dynamic> json) {
    return AnswerOption(id: json['id'], text: json['text']);
  }
}

class QuizResult {
  final int score;
  final int totalQuestions;
  final double percentage;
  final int correctAnswers;
  final int incorrectAnswers;

  QuizResult({
    required this.score,
    required this.totalQuestions,
    required this.percentage,
    required this.correctAnswers,
    required this.incorrectAnswers,
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      score: json['score'],
      totalQuestions: json['total_questions'],
      percentage: json['percentage'].toDouble(),
      correctAnswers: json['correct_answers'],
      incorrectAnswers: json['incorrect_answers'],
    );
  }
}


