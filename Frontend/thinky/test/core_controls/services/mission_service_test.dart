import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'package:thinky/core_controls/services/api_client.dart';
import 'package:thinky/core_controls/services/mission_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thinky/core_controls/config/app_config.dart';
import 'dart:convert';

import 'mission_service_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  late MockClient mockClient;

  setUp(() {
    mockClient = MockClient();
    ApiClient.client = mockClient;
    SharedPreferences.setMockInitialValues({});
  });

  group('MissionService', () {
    test('getMissions returns list when successful', () async {
      final responseBody = {
        'missions': [
          {
            'id': 1,
            'title': 'Test Mission',
            'mission_path': 'path',
            'description': 'Description',
            'order_index': 1,
            'background_color': '#FFFFFF',
            'height': 100,
            'is_active': true,
            'created_at': DateTime.now().toIso8601String(),
            'progress': {'mission_id': 1, 'is_completed': false},
            'is_locked': false
          }
        ]
      };

      when(mockClient.get(
        any,
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response(jsonEncode(responseBody), 200));

      final response = await MissionService.getMissions();

      expect(response.missions.length, 1);
      expect(response.missions.first.title, 'Test Mission');
    });

    test('getMissions returns offline missions on 401/403', () async {
      when(mockClient.get(
        any,
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response('Unauthorized', 401));

      final response = await MissionService.getMissions();

      expect(response.missions.isNotEmpty, true);
      expect(response.missions.first.id, -1); // Offline mission ID
    });



  });
}
