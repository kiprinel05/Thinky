/// Domain models for the Numbers Mission ("Învățăm numerele cu Pixy")

/// Pixy's AI model level
enum PixyModelLevel {
  junior,
  student,
  expert;

  String get displayName {
    switch (this) {
      case PixyModelLevel.junior:
        return 'Pixy Junior';
      case PixyModelLevel.student:
        return 'Pixy Student';
      case PixyModelLevel.expert:
        return 'Pixy Expert';
    }
  }

  String get emoji {
    switch (this) {
      case PixyModelLevel.junior:
        return '🐣';
      case PixyModelLevel.student:
        return '📚';
      case PixyModelLevel.expert:
        return '🌟';
    }
  }

  static PixyModelLevel fromString(String value) {
    switch (value) {
      case 'student':
        return PixyModelLevel.student;
      case 'expert':
        return PixyModelLevel.expert;
      default:
        return PixyModelLevel.junior;
    }
  }
}

/// An object displayed for counting
class NumberObject {
  final String emoji;
  final String objectType;

  const NumberObject({required this.emoji, required this.objectType});

  factory NumberObject.fromJson(Map<String, dynamic> json) {
    return NumberObject(
      emoji: json['emoji'] as String? ?? '🍎',
      objectType: json['object_type'] as String? ?? 'apple',
    );
  }
}

/// Data for starting a session
class NumbersSessionData {
  final int targetNumber;
  final List<NumberObject> objects;
  final PixyModelLevel modelLevel;
  final int currentPart;
  final String message;

  const NumbersSessionData({
    required this.targetNumber,
    required this.objects,
    required this.modelLevel,
    required this.currentPart,
    required this.message,
  });

  factory NumbersSessionData.fromJson(Map<String, dynamic> json) {
    return NumbersSessionData(
      targetNumber: json['target_number'] as int? ?? 1,
      objects: (json['objects'] as List? ?? [])
          .map((o) => NumberObject.fromJson(o))
          .toList(),
      modelLevel: PixyModelLevel.fromString(json['model_level'] as String? ?? 'junior'),
      currentPart: json['current_part'] as int? ?? 1,
      message: json['message'] as String? ?? '',
    );
  }
}

/// Data for a counting round including Pixy's guess
class NumbersRound {
  final int targetNumber;
  final List<NumberObject> objects;
  final int pixyGuess;
  final String pixyMessage;
  final String pixyConfidence;
  final PixyModelLevel modelLevel;
  final int currentPart;

  const NumbersRound({
    required this.targetNumber,
    required this.objects,
    required this.pixyGuess,
    required this.pixyMessage,
    required this.pixyConfidence,
    required this.modelLevel,
    required this.currentPart,
  });

  factory NumbersRound.fromJson(Map<String, dynamic> json) {
    return NumbersRound(
      targetNumber: json['target_number'] as int? ?? 1,
      objects: (json['objects'] as List? ?? [])
          .map((o) => NumberObject.fromJson(o))
          .toList(),
      pixyGuess: json['pixy_guess'] as int? ?? 1,
      pixyMessage: json['pixy_message'] as String? ?? '',
      pixyConfidence: json['pixy_confidence'] as String? ?? 'low',
      modelLevel: PixyModelLevel.fromString(json['model_level'] as String? ?? 'junior'),
      currentPart: json['current_part'] as int? ?? 1,
    );
  }
}

/// Result after submitting a counting answer
class CountingResult {
  final bool isCorrect;
  final int correctAnswer;
  final int pixyGuess;
  final String pixyMessage;
  final String pixyEmotion;
  final PixyModelLevel modelLevel;
  final int correctCount;
  final int confusionCount;
  final bool showProfessor;
  final String? professorMessage;
  final bool modelUpgraded;
  final PixyModelLevel? newModelLevel;
  final bool partCompleted;

  const CountingResult({
    required this.isCorrect,
    required this.correctAnswer,
    required this.pixyGuess,
    required this.pixyMessage,
    required this.pixyEmotion,
    required this.modelLevel,
    required this.correctCount,
    required this.confusionCount,
    required this.showProfessor,
    this.professorMessage,
    this.modelUpgraded = false,
    this.newModelLevel,
    this.partCompleted = false,
  });

  factory CountingResult.fromJson(Map<String, dynamic> json) {
    return CountingResult(
      isCorrect: json['is_correct'] as bool? ?? false,
      correctAnswer: json['correct_answer'] as int? ?? 0,
      pixyGuess: json['pixy_guess'] as int? ?? 0,
      pixyMessage: json['pixy_message'] as String? ?? '',
      pixyEmotion: json['pixy_emotion'] as String? ?? 'neutral',
      modelLevel: PixyModelLevel.fromString(json['model_level'] as String? ?? 'junior'),
      correctCount: json['correct_count'] as int? ?? 0,
      confusionCount: json['confusion_count'] as int? ?? 0,
      showProfessor: json['show_professor'] as bool? ?? false,
      professorMessage: json['professor_message'] as String?,
      modelUpgraded: json['model_upgraded'] as bool? ?? false,
      newModelLevel: json['new_model_level'] != null
          ? PixyModelLevel.fromString(json['new_model_level'] as String)
          : null,
      partCompleted: json['part_completed'] as bool? ?? false,
    );
  }
}

/// Result after submitting a digit drawing
class DrawingResult {
  final int? guessedDigit;
  final double confidence;
  final bool isCorrect;
  final int targetDigit;
  final String pixyMessage;
  final String pixyEmotion;
  final PixyModelLevel modelLevel;
  final int correctCount;
  final int confusionCount;
  final bool showProfessor;
  final String? professorMessage;
  final String? professorHint;
  final bool modelUpgraded;
  final PixyModelLevel? newModelLevel;
  final bool partCompleted;

  const DrawingResult({
    this.guessedDigit,
    required this.confidence,
    required this.isCorrect,
    required this.targetDigit,
    required this.pixyMessage,
    required this.pixyEmotion,
    required this.modelLevel,
    required this.correctCount,
    required this.confusionCount,
    required this.showProfessor,
    this.professorMessage,
    this.professorHint,
    this.modelUpgraded = false,
    this.newModelLevel,
    this.partCompleted = false,
  });

  factory DrawingResult.fromJson(Map<String, dynamic> json) {
    return DrawingResult(
      guessedDigit: json['guessed_digit'] as int?,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      isCorrect: json['is_correct'] as bool? ?? false,
      targetDigit: json['target_digit'] as int? ?? 1,
      pixyMessage: json['pixy_message'] as String? ?? '',
      pixyEmotion: json['pixy_emotion'] as String? ?? 'neutral',
      modelLevel: PixyModelLevel.fromString(json['model_level'] as String? ?? 'junior'),
      correctCount: json['correct_count'] as int? ?? 0,
      confusionCount: json['confusion_count'] as int? ?? 0,
      showProfessor: json['show_professor'] as bool? ?? false,
      professorMessage: json['professor_message'] as String?,
      professorHint: json['professor_hint'] as String?,
      modelUpgraded: json['model_upgraded'] as bool? ?? false,
      newModelLevel: json['new_model_level'] != null
          ? PixyModelLevel.fromString(json['new_model_level'] as String)
          : null,
      partCompleted: json['part_completed'] as bool? ?? false,
    );
  }
}

/// Overall mission progress
class NumbersProgress {
  final int currentPart;
  final PixyModelLevel modelLevel;
  final int correctCount;
  final int confusionCount;
  final int roundsCompleted;
  final bool isComplete;
  final double score;

  const NumbersProgress({
    required this.currentPart,
    required this.modelLevel,
    required this.correctCount,
    required this.confusionCount,
    required this.roundsCompleted,
    this.isComplete = false,
    this.score = 0.0,
  });

  factory NumbersProgress.fromJson(Map<String, dynamic> json) {
    return NumbersProgress(
      currentPart: json['current_part'] as int? ?? 1,
      modelLevel: PixyModelLevel.fromString(json['model_level'] as String? ?? 'junior'),
      correctCount: json['correct_count'] as int? ?? 0,
      confusionCount: json['confusion_count'] as int? ?? 0,
      roundsCompleted: json['rounds_completed'] as int? ?? 0,
      isComplete: json['is_complete'] as bool? ?? false,
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
