/// Models for the Describe Mission
///
/// Represents data structures for "Describe what you see in the image."

class DescribeImageInfo {
  final String imageId;
  final String imageUrl;
  final List<String> expectedKeywords;
  final String hint;

  DescribeImageInfo({
    required this.imageId,
    required this.imageUrl,
    required this.expectedKeywords,
    required this.hint,
  });

  factory DescribeImageInfo.fromJson(Map<String, dynamic> json) {
    return DescribeImageInfo(
      imageId: json['imageId'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      expectedKeywords: (json['expectedKeywords'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      hint: json['hint'] ?? '',
    );
  }
}

class DescribeStartResponse {
  final int missionId;
  final DescribeImageInfo image;
  final String instruction;
  final int round;
  final int totalRounds;

  DescribeStartResponse({
    required this.missionId,
    required this.image,
    required this.instruction,
    required this.round,
    required this.totalRounds,
  });

  factory DescribeStartResponse.fromJson(Map<String, dynamic> json) {
    return DescribeStartResponse(
      missionId: json['missionId'] ?? 0,
      image: DescribeImageInfo.fromJson(json['image'] ?? {}),
      instruction: json['instruction'] ?? '',
      round: json['round'] ?? 0,
      totalRounds: json['totalRounds'] ?? 0,
    );
  }
}

class TranscriptionResponse {
  final bool success;
  final String transcription;
  final double matchScore;
  final List<String> matchedKeywords;
  final List<String> missingKeywords;
  final String message;
  final String encouragement;

  TranscriptionResponse({
    required this.success,
    required this.transcription,
    required this.matchScore,
    required this.matchedKeywords,
    required this.missingKeywords,
    required this.message,
    required this.encouragement,
  });

  factory TranscriptionResponse.fromJson(Map<String, dynamic> json) {
    return TranscriptionResponse(
      success: json['success'] ?? false,
      transcription: json['transcription'] ?? '',
      matchScore: (json['matchScore'] ?? 0.0).toDouble(),
      matchedKeywords: (json['matchedKeywords'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      missingKeywords: (json['missingKeywords'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      message: json['message'] ?? '',
      encouragement: json['encouragement'] ?? '',
    );
  }
}
