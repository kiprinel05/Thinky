import 'dart:convert';
import 'package:thinky/core_controls/config/app_config.dart';
import '../models/mission_models.dart';
import 'api_client.dart';
import 'package:flutter/foundation.dart';

class MissionService {
  // Set to true to force offline missions (all unlocked for testing)
  static const bool USE_OFFLINE_MISSIONS = false; // Changed to false for API testing
  
  static Future<MissionListResponse> getMissions() async {
    // Force offline mode for testing
    if (USE_OFFLINE_MISSIONS) {
      debugPrint('MissionService: Using offline missions (forced for testing)');
      return _offlineMissions();
    }
    
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

  // ALL UNLOCKED FOR TESTING
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
        title: 'Quiz Time',
        missionPath: 'quiz',
        description: 'Quick recap quiz to test what Pixy learned.',
        orderIndex: 1,
        backgroundColor: '#FFB59E',
        height: 200,
        isActive: true,
        createdAt: now,
        progress: MissionProgress(
          missionId: -2,
          isCompleted: false,
        ),
        isLocked: false, // UNLOCKED FOR TESTING
      ),
      Mission(
        id: -3,
        title: 'Draw a Blue Triangle',
        missionPath: 'draw_triangle',
        description: 'Draw a blue triangle on the canvas and let Pixy guess!',
        orderIndex: 2,
        backgroundColor: '#8E97FD',
        height: 200,
        isActive: true,
        createdAt: now,
        progress: MissionProgress(
          missionId: -3,
          isCompleted: false,
        ),
        isLocked: false, // UNLOCKED FOR TESTING
      ),
    ]);
  }
}

