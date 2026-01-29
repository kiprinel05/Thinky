/// Domain models for Pixy Learns mission

/// Represents an image to be labeled
class LearningImage {
  final String id;
  final String url;
  final String? correctLabel;

  const LearningImage({
    required this.id,
    required this.url,
    this.correctLabel,
  });

  factory LearningImage.fromJson(Map<String, dynamic> json) {
    return LearningImage(
      id: json['id'] as String,
      url: json['url'] as String,
      correctLabel: json['correct_label'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'url': url,
    if (correctLabel != null) 'correct_label': correctLabel,
  };
}

/// Result after submitting labels
class PixyLearnsResult {
  final int learnedExamples;
  final double progressPercentage;
  final List<String> categories;
  final bool isComplete;

  const PixyLearnsResult({
    required this.learnedExamples,
    required this.progressPercentage,
    required this.categories,
    this.isComplete = false,
  });

  factory PixyLearnsResult.fromJson(Map<String, dynamic> json) {
    return PixyLearnsResult(
      learnedExamples: json['learned_examples'] as int? ?? 0,
      progressPercentage: (json['progress_percentage'] as num?)?.toDouble() ?? 0.0,
      categories: List<String>.from(json['categories'] as List? ?? []),
      isComplete: json['is_complete'] as bool? ?? false,
    );
  }
}
