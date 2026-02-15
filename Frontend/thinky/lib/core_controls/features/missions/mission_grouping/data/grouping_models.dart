/// Models for Grouping Mission
/// 
/// Represents data structures for the "Group Images" mission

class GroupingItem {
  final String id;
  final String url;
  final String label;  // Actual category
  final String name;   // Display name

  GroupingItem({
    required this.id,
    required this.url,
    required this.label,
    required this.name,
  });

  factory GroupingItem.fromJson(Map<String, dynamic> json) {
    return GroupingItem(
      id: json['id'] ?? '',
      url: json['url'] ?? '',
      label: json['label'] ?? '',
      name: json['name'] ?? '',
    );
  }
}

class GroupingStartResponse {
  final int currentRound;
  final int totalRounds;
  final List<String> categories;
  final String message;

  GroupingStartResponse({
    required this.currentRound,
    required this.totalRounds,
    required this.categories,
    required this.message,
  });

  factory GroupingStartResponse.fromJson(Map<String, dynamic> json) {
    return GroupingStartResponse(
      currentRound: json['current_round'] ?? 1,
      totalRounds: json['total_rounds'] ?? 3,
      categories: (json['categories'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      message: json['message'] ?? '',
    );
  }
}

class GroupingRoundResponse {
  final int roundNumber;
  final int totalRounds;
  final List<GroupingItem> items;
  final List<String> categories;

  GroupingRoundResponse({
    required this.roundNumber,
    required this.totalRounds,
    required this.items,
    required this.categories,
  });

  factory GroupingRoundResponse.fromJson(Map<String, dynamic> json) {
    return GroupingRoundResponse(
      roundNumber: json['round_number'] ?? 1,
      totalRounds: json['total_rounds'] ?? 3,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => GroupingItem.fromJson(e))
              .toList() ??
          [],
      categories: (json['categories'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

class GroupingItemResult {
  final String itemId;
  final String itemName;
  final String userCategory;
  final String correctCategory;
  final bool isCorrect;

  GroupingItemResult({
    required this.itemId,
    required this.itemName,
    required this.userCategory,
    required this.correctCategory,
    required this.isCorrect,
  });

  factory GroupingItemResult.fromJson(Map<String, dynamic> json) {
    return GroupingItemResult(
      itemId: json['item_id'] ?? '',
      itemName: json['item_name'] ?? '',
      userCategory: json['user_category'] ?? '',
      correctCategory: json['correct_category'] ?? '',
      isCorrect: json['is_correct'] ?? false,
    );
  }
}

class GroupingSubmitResponse {
  final bool isCorrect;
  final double accuracy;
  final double timeSpent;
  final int correctCount;
  final int totalCount;
  final List<GroupingItemResult> details;
  final String message;
  final String pixyEmotion;
  final int difficultyLevel;

  GroupingSubmitResponse({
    required this.isCorrect,
    required this.accuracy,
    required this.timeSpent,
    required this.correctCount,
    required this.totalCount,
    required this.details,
    required this.message,
    required this.pixyEmotion,
    required this.difficultyLevel,
  });

  factory GroupingSubmitResponse.fromJson(Map<String, dynamic> json) {
    return GroupingSubmitResponse(
      isCorrect: json['is_correct'] ?? false,
      accuracy: (json['accuracy'] ?? 0.0).toDouble(),
      timeSpent: (json['time_spent'] ?? 0.0).toDouble(),
      correctCount: json['correct_count'] ?? 0,
      totalCount: json['total_count'] ?? 0,
      details: (json['details'] as List<dynamic>?)
              ?.map((e) => GroupingItemResult.fromJson(e))
              .toList() ??
          [],
      message: json['message'] ?? '',
      pixyEmotion: json['pixy_emotion'] ?? 'neutral',
      difficultyLevel: json['difficulty_level'] ?? 1,
    );
  }
}
