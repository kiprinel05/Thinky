/// Models for Word Match mission.
///
/// The backend returns questions bilingually (EN + RO) and uses emoji
/// instead of bitmap images. The UI picks the active language from
/// [LanguageService].
library;

class VocabImage {
  final int id;
  final String emoji;
  final String labelEn;
  final String labelRo;

  VocabImage({
    required this.id,
    required this.emoji,
    required this.labelEn,
    required this.labelRo,
  });

  factory VocabImage.fromJson(Map<String, dynamic> json) {
    return VocabImage(
      id: json['id'] ?? 0,
      emoji: (json['emoji'] ?? '') as String,
      labelEn: (json['labelEn'] ?? '') as String,
      labelRo: (json['labelRo'] ?? '') as String,
    );
  }

  String labelFor(String lang) =>
      lang.toLowerCase().startsWith('ro') ? labelRo : labelEn;
}

class VocabQuestion {
  final String wordEn;
  final String wordRo;
  final String category;
  final List<VocabImage> images;
  final int correctImageId;

  VocabQuestion({
    required this.wordEn,
    required this.wordRo,
    required this.category,
    required this.images,
    required this.correctImageId,
  });

  factory VocabQuestion.fromJson(Map<String, dynamic> json) {
    return VocabQuestion(
      wordEn: (json['wordEn'] ?? '') as String,
      wordRo: (json['wordRo'] ?? '') as String,
      category: (json['category'] ?? '') as String,
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => VocabImage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      correctImageId: json['correctImageId'] ?? 0,
    );
  }

  String wordFor(String lang) =>
      lang.toLowerCase().startsWith('ro') ? wordRo : wordEn;
}

class VocabStartResponse {
  final int missionId;
  final List<VocabQuestion> questions;
  final int totalQuestions;

  VocabStartResponse({
    required this.missionId,
    required this.questions,
    required this.totalQuestions,
  });

  factory VocabStartResponse.fromJson(Map<String, dynamic> json) {
    return VocabStartResponse(
      missionId: json['missionId'] ?? 0,
      questions: (json['questions'] as List<dynamic>?)
              ?.map((e) => VocabQuestion.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      totalQuestions: json['totalQuestions'] ?? 0,
    );
  }
}

class VocabAnswerResponse {
  final bool success;
  final bool correct;
  final int correctImageId;
  final int completed;
  final int total;

  VocabAnswerResponse({
    required this.success,
    required this.correct,
    required this.correctImageId,
    required this.completed,
    required this.total,
  });

  factory VocabAnswerResponse.fromJson(Map<String, dynamic> json) {
    final progress = (json['progress'] as Map<String, dynamic>?) ?? const {};
    return VocabAnswerResponse(
      success: json['success'] ?? false,
      correct: json['correct'] ?? false,
      correctImageId: json['correctImageId'] ?? 0,
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
  final List<String> incorrectWordsEn;

  VocabProgressResponse({
    required this.completed,
    required this.total,
    required this.correctCount,
    required this.accuracy,
    required this.masteryScore,
    required this.incorrectWordsEn,
  });

  factory VocabProgressResponse.fromJson(Map<String, dynamic> json) {
    return VocabProgressResponse(
      completed: json['completed'] ?? 0,
      total: json['total'] ?? 0,
      correctCount: json['correctCount'] ?? 0,
      accuracy: (json['accuracy'] ?? 0.0).toDouble(),
      masteryScore: (json['masteryScore'] ?? 0.0).toDouble(),
      incorrectWordsEn: (json['incorrectWordsEn'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}
