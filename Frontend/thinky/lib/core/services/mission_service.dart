import 'dart:convert';
import '../config/app_config.dart';
import '../models/mission_models.dart';
import 'api_client.dart';
import 'package:flutter/foundation.dart';

class MissionService {
  static Future<MissionListResponse> getMissions() async {
    try {
      final response = await ApiClient.get('/missions');
      if (response.statusCode == 200) {
        return MissionListResponse.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        debugPrint('MissionService: received ${response.statusCode}, using offline missions.');
        return _offlineMissions();
      } else {
        throw Exception('Failed to load missions: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('MissionService: error loading missions ($e). Falling back to offline list.');
      return _offlineMissions();
    }
  }

  static Future<void> completeMission(int missionId, {double? score}) async {
    try {
      final response = await ApiClient.post(
        '/missions/$missionId/complete',
        {'score': score},
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to complete mission: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error completing mission: $e');
    }
  }

  static MissionListResponse _offlineMissions() {
    final now = DateTime.now();
    return MissionListResponse(missions: [
      Mission(
        id: -1,
        title: 'Teach Pixy Colors',
        missionPath: 'pixy_learns',
        description: 'Intro mission to explain primary colors to Pixy.',
        orderIndex: 0,
        backgroundColor: '#8E97FD',
        height: 220,
        isActive: true,
        createdAt: now,
        progress: MissionProgress(
          missionId: -1,
          isCompleted: false,
        ),
        isLocked: false,
      ),
      Mission(
        id: -2,
        title: 'Shapes Explorer',
        missionPath: 'geometric_shapes',
        description: 'Help Pixy distinguish circles, squares and triangles.',
        orderIndex: 1,
        backgroundColor: '#FFB59E',
        height: 200,
        isActive: true,
        createdAt: now,
        progress: MissionProgress(
          missionId: -2,
          isCompleted: false,
        ),
        isLocked: true,
      ),
      Mission(
        id: -3,
        title: 'Quiz Time',
        missionPath: 'quiz',
        description: 'Quick recap quiz to test what Pixy learned.',
        orderIndex: 2,
        backgroundColor: '#FFC542',
        height: 180,
        isActive: true,
        createdAt: now,
        progress: MissionProgress(
          missionId: -3,
          isCompleted: false,
        ),
        isLocked: true,
      ),
    ]);
  }
}

