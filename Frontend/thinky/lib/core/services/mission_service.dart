import 'dart:convert';
import '../config/app_config.dart';
import '../models/mission_models.dart';
import 'api_client.dart';

class MissionService {
  static Future<MissionListResponse> getMissions() async {
    try {
      final response = await ApiClient.get('/missions');
      if (response.statusCode == 200) {
        return MissionListResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load missions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading missions: $e');
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
}

