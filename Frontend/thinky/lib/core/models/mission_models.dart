import 'package:flutter/material.dart';

class Mission {
  final int id;
  final String title;
  final String missionPath;
  final String? description;
  final int orderIndex;
  final String? backgroundColor;
  final double? height;
  final bool isActive;
  final DateTime createdAt;
  final MissionProgress? progress;
  final bool isLocked;

  Mission({
    required this.id,
    required this.title,
    required this.missionPath,
    this.description,
    required this.orderIndex,
    this.backgroundColor,
    this.height,
    required this.isActive,
    required this.createdAt,
    this.progress,
    required this.isLocked,
  });

  factory Mission.fromJson(Map<String, dynamic> json) {
    return Mission(
      id: json['id'],
      title: json['title'],
      missionPath: json['mission_path'],
      description: json['description'],
      orderIndex: json['order_index'],
      backgroundColor: json['background_color'],
      height: json['height']?.toDouble(),
      isActive: json['is_active'],
      createdAt: DateTime.parse(json['created_at']),
      progress: json['progress'] != null
          ? MissionProgress.fromJson(json['progress'])
          : null,
      isLocked: json['is_locked'] ?? true,
    );
  }

  Color get backgroundColorAsColor {
    if (backgroundColor == null) return const Color(0xFF8E97FD);
    try {
      return Color(int.parse(backgroundColor!.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF8E97FD);
    }
  }
}

class MissionProgress {
  final int missionId;
  final bool isCompleted;
  final DateTime? completedAt;
  final double? score;

  MissionProgress({
    required this.missionId,
    required this.isCompleted,
    this.completedAt,
    this.score,
  });

  factory MissionProgress.fromJson(Map<String, dynamic> json) {
    return MissionProgress(
      missionId: json['mission_id'],
      isCompleted: json['is_completed'],
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      score: json['score']?.toDouble(),
    );
  }
}

class MissionListResponse {
  final List<Mission> missions;

  MissionListResponse({required this.missions});

  factory MissionListResponse.fromJson(Map<String, dynamic> json) {
    return MissionListResponse(
      missions: (json['missions'] as List)
          .map((m) => Mission.fromJson(m))
          .toList(),
    );
  }
}

