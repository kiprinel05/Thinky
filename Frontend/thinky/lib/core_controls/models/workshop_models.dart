// Workshop data models for browsing, creating, and playing community missions.

class WorkshopAnswer {
  final String text;

  WorkshopAnswer({required this.text});

  factory WorkshopAnswer.fromJson(Map<String, dynamic> json) {
    return WorkshopAnswer(text: json['text']);
  }

  Map<String, dynamic> toJson() => {'text': text};
}

class WorkshopQuestion {
  final String text;
  final List<WorkshopAnswer> answers;
  final int correctAnswerIndex;

  WorkshopQuestion({
    required this.text,
    required this.answers,
    required this.correctAnswerIndex,
  });

  factory WorkshopQuestion.fromJson(Map<String, dynamic> json) {
    return WorkshopQuestion(
      text: json['text'],
      answers: (json['answers'] as List)
          .map((a) => WorkshopAnswer.fromJson(a))
          .toList(),
      correctAnswerIndex: json['correct_answer_index'],
    );
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        'answers': answers.map((a) => a.toJson()).toList(),
        'correct_answer_index': correctAnswerIndex,
      };
}

class WorkshopMission {
  final int id;
  final String title;
  final String? description;
  final String authorName;
  final String missionType;
  final int version;
  final List<String> tags;
  final int downloadCount;
  final DateTime createdAt;

  WorkshopMission({
    required this.id,
    required this.title,
    this.description,
    required this.authorName,
    required this.missionType,
    required this.version,
    required this.tags,
    required this.downloadCount,
    required this.createdAt,
  });

  factory WorkshopMission.fromJson(Map<String, dynamic> json) {
    return WorkshopMission(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      authorName: json['author_name'],
      missionType: json['mission_type'],
      version: json['version'],
      tags: List<String>.from(json['tags'] ?? []),
      downloadCount: json['download_count'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class WorkshopMissionDetail extends WorkshopMission {
  final List<WorkshopQuestion> questions;

  WorkshopMissionDetail({
    required super.id,
    required super.title,
    super.description,
    required super.authorName,
    required super.missionType,
    required super.version,
    required super.tags,
    required super.downloadCount,
    required super.createdAt,
    required this.questions,
  });

  factory WorkshopMissionDetail.fromJson(Map<String, dynamic> json) {
    return WorkshopMissionDetail(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      authorName: json['author_name'],
      missionType: json['mission_type'],
      version: json['version'],
      tags: List<String>.from(json['tags'] ?? []),
      downloadCount: json['download_count'],
      createdAt: DateTime.parse(json['created_at']),
      questions: (json['questions'] as List)
          .map((q) => WorkshopQuestion.fromJson(q))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'author_name': authorName,
        'mission_type': missionType,
        'version': version,
        'tags': tags,
        'download_count': downloadCount,
        'created_at': createdAt.toIso8601String(),
        'questions': questions.map((q) => q.toJson()).toList(),
      };
}

class WorkshopMissionList {
  final List<WorkshopMission> missions;
  final int total;

  WorkshopMissionList({required this.missions, required this.total});

  factory WorkshopMissionList.fromJson(Map<String, dynamic> json) {
    return WorkshopMissionList(
      missions: (json['missions'] as List)
          .map((m) => WorkshopMission.fromJson(m))
          .toList(),
      total: json['total'],
    );
  }
}
