/// Models for Animals Mission
/// 
/// Represents data structures for the "Teach Pixy Animals" mission
library;

class AnimalImage {
  final String id;
  final String url;
  final String label;

  AnimalImage({
    required this.id,
    required this.url,
    required this.label,
  });

  factory AnimalImage.fromJson(Map<String, dynamic> json) {
    return AnimalImage(
      id: json['id'] ?? '',
      url: json['url'] ?? '',
      label: json['label'] ?? '',
    );
  }
}

class RoundResponse {
  final int roundNumber;
  final int totalRounds;
  final AnimalImage image;

  RoundResponse({
    required this.roundNumber,
    required this.totalRounds,
    required this.image,
  });

  factory RoundResponse.fromJson(Map<String, dynamic> json) {
    return RoundResponse(
      roundNumber: json['round_number'] ?? 0,
      totalRounds: json['total_rounds'] ?? 5,
      image: AnimalImage.fromJson(json['image'] ?? {}),
    );
  }
}

class GuessResponse {
  final String guess;
  final double confidence;
  final String actualAnimal;
  final bool isCorrect;

  GuessResponse({
    required this.guess,
    required this.confidence,
    required this.actualAnimal,
    required this.isCorrect,
  });

  factory GuessResponse.fromJson(Map<String, dynamic> json) {
    return GuessResponse(
      guess: json['guess'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      actualAnimal: json['actual_animal'] ?? '',
      isCorrect: json['is_correct'] ?? false,
    );
  }
}

class VerifyGuessResponse {
  final bool wasActuallyCorrect;
  final bool userWasRight;
  final String message;

  VerifyGuessResponse({
    required this.wasActuallyCorrect,
    required this.userWasRight,
    required this.message,
  });

  factory VerifyGuessResponse.fromJson(Map<String, dynamic> json) {
    return VerifyGuessResponse(
      wasActuallyCorrect: json['was_actually_correct'] ?? false,
      userWasRight: json['user_was_right'] ?? false,
      message: json['message'] ?? '',
    );
  }
}

class TeachingImagesResponse {
  final String targetAnimal;
  final List<AnimalImage> images;
  final List<String> correctImageIds;

  TeachingImagesResponse({
    required this.targetAnimal,
    required this.images,
    required this.correctImageIds,
  });

  factory TeachingImagesResponse.fromJson(Map<String, dynamic> json) {
    return TeachingImagesResponse(
      targetAnimal: json['target_animal'] ?? '',
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => AnimalImage.fromJson(e))
              .toList() ??
          [],
      correctImageIds: (json['correct_image_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

class ValidateTeachingResponse {
  final bool isCorrect;
  final int correctCount;
  final int totalCorrect;
  final int missedCount;
  final int wrongCount;
  final String message;

  ValidateTeachingResponse({
    required this.isCorrect,
    required this.correctCount,
    required this.totalCorrect,
    required this.missedCount,
    required this.wrongCount,
    required this.message,
  });

  factory ValidateTeachingResponse.fromJson(Map<String, dynamic> json) {
    return ValidateTeachingResponse(
      isCorrect: json['is_correct'] ?? false,
      correctCount: json['correct_count'] ?? 0,
      totalCorrect: json['total_correct'] ?? 0,
      missedCount: json['missed_count'] ?? 0,
      wrongCount: json['wrong_count'] ?? 0,
      message: json['message'] ?? '',
    );
  }
}

class MissionProgressResponse {
  final int currentRound;
  final int totalRounds;
  final int completedRounds;
  final double pixyAccuracy;
  final bool isComplete;

  MissionProgressResponse({
    required this.currentRound,
    required this.totalRounds,
    required this.completedRounds,
    required this.pixyAccuracy,
    required this.isComplete,
  });

  factory MissionProgressResponse.fromJson(Map<String, dynamic> json) {
    return MissionProgressResponse(
      currentRound: json['current_round'] ?? 0,
      totalRounds: json['total_rounds'] ?? 5,
      completedRounds: json['completed_rounds'] ?? 0,
      pixyAccuracy: (json['pixy_accuracy'] ?? 0.0).toDouble(),
      isComplete: json['is_complete'] ?? false,
    );
  }
}
