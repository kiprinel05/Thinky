import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thinky/core_controls/services/mission_service.dart';

void main() {
  group('MissionService', () {
    setUp(() {
      dotenv.testLoad(fileInput: 'API_BASE_URL=http://localhost:8000\nUSE_OFFLINE_MISSIONS=true\n');
    });

    test('getMissions returns offline missions when useOfflineMissions is true', () async {
      final response = await MissionService.getMissions();

      expect(response.missions.length, 10);
      expect(response.missions.first.id, -2);
      expect(response.missions.first.title, 'Quiz Time');
      expect(response.missions.first.isLocked, false);
    });

    test('offline missions all have negative IDs', () async {
      final response = await MissionService.getMissions();

      for (final mission in response.missions) {
        expect(mission.id, isNegative);
      }
    });

    test('offline missions are all unlocked', () async {
      final response = await MissionService.getMissions();

      for (final mission in response.missions) {
        expect(mission.isLocked, false);
      }
    });

    test('completeMission skips API for negative IDs', () async {
      await MissionService.completeMission(-2);
      await MissionService.completeMission(-1);
    });
  });
}
