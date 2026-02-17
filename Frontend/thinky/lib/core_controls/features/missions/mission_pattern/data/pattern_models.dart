

class PatternItem {
  final String id;
  final String shape;
  final String color;

  PatternItem({
    required this.id,
    required this.shape,
    required this.color,
  });

  factory PatternItem.fromJson(Map<String, dynamic> json) {
    return PatternItem(
      id: json['id'] as String,
      shape: json['shape'] as String,
      color: json['color'] as String,
    );
  }
}

class PatternStartResponse {
  final int missionId;
  final List<PatternItem> sequence;
  final List<PatternItem> options;
  final int difficulty;
  final int round;
  final int totalRounds;
  final String instruction;

  PatternStartResponse({
    required this.missionId,
    required this.sequence,
    required this.options,
    required this.difficulty,
    required this.round,
    required this.totalRounds,
    required this.instruction,
  });

  factory PatternStartResponse.fromJson(Map<String, dynamic> json) {
    return PatternStartResponse(
      missionId: json['missionId'] as int,
      sequence: (json['sequence'] as List)
          .map((e) => PatternItem.fromJson(e))
          .toList(),
      options: (json['options'] as List)
          .map((e) => PatternItem.fromJson(e))
          .toList(),
      difficulty: json['difficulty'] as int,
      round: json['round'] as int,
      totalRounds: json['totalRounds'] as int,
      instruction: json['instruction'] as String,
    );
  }
}

class PatternResultResponse {
  final bool success;
  final bool correct;
  final String correctOptionId;
  final String message;
  final int newDifficulty;
  final double completionProgress;

  PatternResultResponse({
    required this.success,
    required this.correct,
    required this.correctOptionId,
    required this.message,
    required this.newDifficulty,
    required this.completionProgress,
  });

  factory PatternResultResponse.fromJson(Map<String, dynamic> json) {
    return PatternResultResponse(
      success: json['success'] as bool,
      correct: json['correct'] as bool,
      correctOptionId: json['correctOptionId'] as String,
      message: json['message'] as String,
      newDifficulty: json['newDifficulty'] as int,
      completionProgress: (json['completionProgress'] as num).toDouble(),
    );
  }
}
