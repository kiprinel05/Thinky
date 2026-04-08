import 'package:flutter_test/flutter_test.dart';
import 'package:thinky/core_controls/models/mission_models.dart';
import 'package:thinky/core_controls/models/auth_response.dart';

void main() {
  group('Mission Models', () {
    test('Mission json serialization', () {
      final json = {
        'id': 1,
        'title': 'T',
        'mission_path': 'p',
        'description': 'd',
        'order_index': 1,
        'background_color': 'b',
        'height': 1.0,
        'is_active': true,
        'created_at': DateTime(2023, 1, 1).toIso8601String(),
        'progress': {'mission_id': 1, 'is_completed': true},
        'is_locked': false
      };

      final mission = Mission.fromJson(json);
      expect(mission.id, 1);
      expect(mission.title, 'T');
      expect(mission.progress?.isCompleted, true);
      
      // We don't necessarily have toJson for check generally, but if we did we'd test it. 
      // Assuming deserialization is the key part for frontend.
    });

    test('MissionListResponse json serialization', () {
      final json = {
        'missions': [
          {
            'id': 1,
            'title': 'T',
            'mission_path': 'p',
            'description': 'd',
            'order_index': 1,
            'background_color': 'b',
            'height': 1.0,
            'is_active': true,
            'created_at': DateTime(2023, 1, 1).toIso8601String(),
            'progress': {'mission_id': 1, 'is_completed': true},
            'is_locked': false
          }
        ]
      };

      final response = MissionListResponse.fromJson(json);
      expect(response.missions.length, 1);
    });
  });

  group('Auth Models', () {
    test('AuthResponse json serialization', () {
      final json = {
        'access_token': 'token',
        'token_type': 'bearer',
        'user_id': 1,
        'username': 'u',
        'email': 'e',
        'is_guest': false
      };

      final response = AuthResponse.fromJson(json);
      expect(response.accessToken, 'token');
      expect(response.userId, 1);
    });
  });
}
