import 'package:flutter/foundation.dart';
import 'package:thinky/base_controls/base_state.dart';

/// Mission entity
@immutable
class Mission {
  final int id;
  final String name;
  final String imageUrl;
  final String color;
  final bool isLocked;
  final int order;
  final int? progress;
  final bool isCompleted;

  const Mission({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.color,
    required this.isLocked,
    required this.order,
    this.progress,
    this.isCompleted = false,
  });

  Mission copyWith({
    int? id,
    String? name,
    String? imageUrl,
    String? color,
    bool? isLocked,
    int? order,
    int? progress,
    bool? isCompleted,
  }) {
    return Mission(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      color: color ?? this.color,
      isLocked: isLocked ?? this.isLocked,
      order: order ?? this.order,
      progress: progress ?? this.progress,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  factory Mission.fromJson(Map<String, dynamic> json) {
    return Mission(
      id: json['id'] as int,
      name: json['name'] as String,
      imageUrl: json['image_url'] as String? ?? '',
      color: json['color'] as String? ?? '#8E97FD',
      isLocked: json['is_locked'] as bool? ?? false,
      order: json['order'] as int? ?? 0,
      progress: json['progress'] as int?,
      isCompleted: json['is_completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image_url': imageUrl,
      'color': color,
      'is_locked': isLocked,
      'order': order,
      'progress': progress,
      'is_completed': isCompleted,
    };
  }
}

/// Missions state
@immutable
class MissionsState extends BaseState {
  final List<Mission> missions;
  final int? unlockingMissionId;

  const MissionsState({
    super.status = StateStatus.initial,
    super.errorMessage,
    this.missions = const [],
    this.unlockingMissionId,
  });

  bool get isUnlocking => unlockingMissionId != null;

  MissionsState copyWith({
    StateStatus? status,
    String? errorMessage,
    List<Mission>? missions,
    int? unlockingMissionId,
    bool clearUnlocking = false,
  }) {
    return MissionsState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      missions: missions ?? this.missions,
      unlockingMissionId: clearUnlocking ? null : (unlockingMissionId ?? this.unlockingMissionId),
    );
  }

  factory MissionsState.initial() => const MissionsState();

  factory MissionsState.loading() => const MissionsState(status: StateStatus.loading);

  factory MissionsState.loaded(List<Mission> missions) {
    return MissionsState(
      status: StateStatus.success,
      missions: missions,
    );
  }

  factory MissionsState.error(String message) {
    return MissionsState(
      status: StateStatus.error,
      errorMessage: message,
    );
  }
}