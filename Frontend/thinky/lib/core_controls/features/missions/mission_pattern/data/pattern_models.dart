/// Models for the Complete-the-Pattern mission.
///
/// The backend preloads all 5 rounds when the player starts the mission.
/// Each item is an emoji with bilingual labels — identical style to the
/// Word Match mission.
library;

class PatternItem {
  final int id;
  final String emoji;
  final String labelEn;
  final String labelRo;

  const PatternItem({
    required this.id,
    required this.emoji,
    required this.labelEn,
    required this.labelRo,
  });

  factory PatternItem.fromJson(Map<String, dynamic> json) {
    return PatternItem(
      id: json['id'] as int,
      emoji: (json['emoji'] ?? '') as String,
      labelEn: (json['labelEn'] ?? '') as String,
      labelRo: (json['labelRo'] ?? '') as String,
    );
  }

  String labelFor(String lang) =>
      lang.toLowerCase().startsWith('ro') ? labelRo : labelEn;
}

class PatternQuestion {
  final int index;
  final String theme;
  final String rule;
  final int difficulty;
  final List<PatternItem> sequence;
  final List<PatternItem> options;

  const PatternQuestion({
    required this.index,
    required this.theme,
    required this.rule,
    required this.difficulty,
    required this.sequence,
    required this.options,
  });

  factory PatternQuestion.fromJson(Map<String, dynamic> json) {
    return PatternQuestion(
      index: json['index'] as int,
      theme: (json['theme'] ?? '') as String,
      rule: (json['rule'] ?? '') as String,
      difficulty: (json['difficulty'] ?? 1) as int,
      sequence: (json['sequence'] as List<dynamic>? ?? [])
          .map((e) => PatternItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      options: (json['options'] as List<dynamic>? ?? [])
          .map((e) => PatternItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PatternStartResponse {
  final int missionId;
  final int totalRounds;
  final List<PatternQuestion> questions;

  const PatternStartResponse({
    required this.missionId,
    required this.totalRounds,
    required this.questions,
  });

  factory PatternStartResponse.fromJson(Map<String, dynamic> json) {
    return PatternStartResponse(
      missionId: json['missionId'] as int,
      totalRounds: json['totalRounds'] as int,
      questions: (json['questions'] as List<dynamic>? ?? [])
          .map((e) => PatternQuestion.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PatternAnswerResponse {
  final bool success;
  final bool correct;
  final int correctOptionId;
  final int completed;
  final int total;

  const PatternAnswerResponse({
    required this.success,
    required this.correct,
    required this.correctOptionId,
    required this.completed,
    required this.total,
  });

  factory PatternAnswerResponse.fromJson(Map<String, dynamic> json) {
    final progress = (json['progress'] as Map<String, dynamic>?) ?? const {};
    return PatternAnswerResponse(
      success: (json['success'] ?? false) as bool,
      correct: (json['correct'] ?? false) as bool,
      correctOptionId: (json['correctOptionId'] ?? -1) as int,
      completed: (progress['completed'] ?? 0) as int,
      total: (progress['total'] ?? 0) as int,
    );
  }
}

class PatternProgressResponse {
  final int completed;
  final int total;
  final int correctCount;
  final double accuracy;

  const PatternProgressResponse({
    required this.completed,
    required this.total,
    required this.correctCount,
    required this.accuracy,
  });

  factory PatternProgressResponse.fromJson(Map<String, dynamic> json) {
    return PatternProgressResponse(
      completed: (json['completed'] ?? 0) as int,
      total: (json['total'] ?? 0) as int,
      correctCount: (json['correctCount'] ?? 0) as int,
      accuracy: ((json['accuracy'] ?? 0.0) as num).toDouble(),
    );
  }
}
