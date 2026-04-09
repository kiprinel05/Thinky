import 'dart:convert';
import '../models/mission_models.dart';
import 'api_client.dart';
import 'package:thinky/core/errors/error_logger.dart';

class MissionService {
  // Set to true to force offline missions (all unlocked for testing)
  static const bool USE_OFFLINE_MISSIONS = true; // ENABLED for testing - all missions unlocked
  
  static Future<MissionListResponse> getMissions() async {
    // Force offline mode for testing
    if (USE_OFFLINE_MISSIONS) {
      ErrorLogger().logInfo('MissionService: Using offline missions (forced for testing)');
      return _offlineMissions();
    }
    
    try {
      final response = await ApiClient.get('/missions');
      if (response.statusCode == 200) {
        return MissionListResponse.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        ErrorLogger().logInfo('MissionService: received ${response.statusCode}, using offline missions.');
        return _offlineMissions();
      } else {
        throw Exception('Failed to load missions: ${response.statusCode}');
      }
    } catch (e, stack) {
      ErrorLogger().logError(e, stackTrace: stack);
      return _offlineMissions();
    }
  }

  static Future<void> completeMission(int missionId, {double? score}) async {
    // Skip API call for offline missions (negative IDs)
    if (missionId < 0) {
      ErrorLogger().logInfo('MissionService: Offline mission $missionId completed locally');
      return;
    }
    
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
        id: -2,
        title: 'Quiz Time',
        missionPath: 'quiz',
        description: 'Quick recap quiz to test what Pixy learned.',
        orderIndex: 0,
        backgroundColor: '#FFB59E',
        height: 200,
        isActive: true,
        createdAt: now,
        progress: MissionProgress(
          missionId: -2,
          isCompleted: false,
        ),
        isLocked: false,
      ),
      Mission(
        id: -1,
        title: 'Apple vs Cat',
        missionPath: 'pixy_learns',
        description: 'Teach Pixy to recognize apples and cats by labeling images.',
        orderIndex: 1,
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
        id: -5,
        title: 'Select All Animals',
        missionPath: 'animals',
        description: 'Teach Pixy to recognize animals!',
        orderIndex: 2,
        backgroundColor: '#4CAF50',
        height: 220,
        isActive: true,
        createdAt: now,
        progress: MissionProgress(
          missionId: -5,
          isCompleted: false,
        ),
        isLocked: false, // UNLOCKED FOR TESTING
      ),
      Mission(
        id: -3,
        title: 'Draw Shapes',
        missionPath: 'draw_shapes',
        description: '3 rounds: draw a triangle, a circle, and a square!',
        orderIndex: 3,
        backgroundColor: '#8E97FD',
        height: 200,
        isActive: true,
        createdAt: now,
        progress: MissionProgress(
          missionId: -3,
          isCompleted: false,
        ),
        isLocked: false,
      ),
      Mission(
        id: -4,
        title: 'Color the Circle',
        missionPath: 'color_circle',
        description: 'Color the circle in red and let Pixy check!',
        orderIndex: 4,
        backgroundColor: '#FF5722',
        height: 200,
        isActive: true,
        createdAt: now,
        progress: MissionProgress(
          missionId: -4,
          isCompleted: false,
        ),
        isLocked: false, // UNLOCKED FOR TESTING
      ),
      Mission(
        id: -6,
        title: 'Group the Images',
        missionPath: 'group_sorting',
        description: 'Sort images into fruits, vegetables, and toys!',
        orderIndex: 5,
        backgroundColor: '#FF8A65',
        height: 220,
        isActive: true,
        createdAt: now,
        progress: MissionProgress(
          missionId: -6,
          isCompleted: false,
        ),
        isLocked: false, // UNLOCKED FOR TESTING
      ),
      Mission(
        id: -7,
        title: 'Word Match',
        missionPath: 'vocabulary',
        description: 'Match words to their images and build vocabulary!',
        orderIndex: 6,
        backgroundColor: '#42A5F5',
        height: 200,
        isActive: true,
        createdAt: now,
        progress: MissionProgress(
          missionId: -7,
          isCompleted: false,
        ),
        isLocked: false, // UNLOCKED FOR TESTING
      ),
      Mission(
        id: -8,
        title: 'Describe It',
        missionPath: 'describe_image',
        description: 'Describe what you see in the image using your voice!',
        orderIndex: 9,
        backgroundColor: '#FF7043',
        height: 220,
        isActive: true,
        createdAt: now,
        progress: MissionProgress(
          missionId: -8,
          isCompleted: false,
        ),
        isLocked: false, // UNLOCKED FOR TESTING
      ),
      Mission(
        id: -9,
        title: 'Complete the Pattern',
        missionPath: 'pattern',
        description: 'Look at the shapes and colors. What comes next?',
        orderIndex: 8,
        backgroundColor: '#9C27B0',
        height: 220,
        isActive: true,
        createdAt: now,
        progress: MissionProgress(
          missionId: -9,
          isCompleted: false,
        ),
        isLocked: false, // UNLOCKED FOR TESTING
      ),
      Mission(
        id: -10,
        title: 'Învățăm numerele cu Pixy',
        missionPath: 'numbers',
        description: 'Ajută-l pe Pixy să recunoască numerele de la 1 la 5!',
        orderIndex: 9,
        backgroundColor: '#FF9A5C',
        height: 220,
        isActive: true,
        createdAt: now,
        progress: MissionProgress(
          missionId: -10,
          isCompleted: false,
        ),
        isLocked: false, // UNLOCKED FOR TESTING
      ),
    ]);
  }
}

