/// Models for Vocabulary Mission
///
/// Represents data structures for the "Word-Image Matching" mission.

class VocabImage {
  final int id;
  final String url;
  final String label;

  VocabImage({required this.id, required this.url, required this.label});

  factory VocabImage.fromJson(Map<String, dynamic> json) {
    return VocabImage(
      id: json['id'] ?? 0,
      url: json['url'] ?? '',
      label: json['label'] ?? '',
    );
  }
}

class VocabQuestion {
  final String word;
  final List<VocabImage> images;
  final int correctImageId;

  VocabQuestion({
    required this.word,
    required this.images,
    required this.correctImageId,
  });

  factory VocabQuestion.fromJson(Map<String, dynamic> json) {
    return VocabQuestion(
      word: json['word'] ?? '',
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => VocabImage.fromJson(e))
              .toList() ??
          [],
      correctImageId: json['correctImageId'] ?? 0,
    );
  }
}

class VocabStartResponse {
  final int missionId;
  final List<VocabQuestion> questions;
  final int totalQuestions;
  final String message;

  VocabStartResponse({
    required this.missionId,
    required this.questions,
    required this.totalQuestions,
    required this.message,
  });

  factory VocabStartResponse.fromJson(Map<String, dynamic> json) {
    return VocabStartResponse(
      missionId: json['missionId'] ?? 0,
      questions: (json['questions'] as List<dynamic>?)
              ?.map((e) => VocabQuestion.fromJson(e))
              .toList() ??
          [],
      totalQuestions: json['totalQuestions'] ?? 0,
      message: json['message'] ?? '',
    );
  }
}

class VocabAnswerResponse {
  final bool success;
  final bool correct;
  final int correctImageId;
  final String message;
  final String encouragement;
  final int completed;
  final int total;

  VocabAnswerResponse({
    required this.success,
    required this.correct,
    required this.correctImageId,
    required this.message,
    required this.encouragement,
    required this.completed,
    required this.total,
  });

  factory VocabAnswerResponse.fromJson(Map<String, dynamic> json) {
    final progress = json['progress'] as Map<String, dynamic>? ?? {};
    return VocabAnswerResponse(
      success: json['success'] ?? false,
      correct: json['correct'] ?? false,
      correctImageId: json['correctImageId'] ?? 0,
      message: json['message'] ?? '',
      encouragement: json['encouragement'] ?? '',
      completed: progress['completed'] ?? 0,
      total: progress['total'] ?? 0,
    );
  }
}

class VocabProgressResponse {
  final int completed;
  final int total;
  final int correctCount;
  final double accuracy;
  final double masteryScore;
  final List<String> incorrectWords;

  VocabProgressResponse({
    required this.completed,
    required this.total,
    required this.correctCount,
    required this.accuracy,
    required this.masteryScore,
    required this.incorrectWords,
  });

  factory VocabProgressResponse.fromJson(Map<String, dynamic> json) {
    return VocabProgressResponse(
      completed: json['completed'] ?? 0,
      total: json['total'] ?? 0,
      correctCount: json['correctCount'] ?? 0,
      accuracy: (json['accuracy'] ?? 0.0).toDouble(),
      masteryScore: (json['masteryScore'] ?? 0.0).toDouble(),
      incorrectWords: (json['incorrectWords'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}
