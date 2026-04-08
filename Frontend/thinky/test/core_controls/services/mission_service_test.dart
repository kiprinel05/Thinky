import 'package:flutter_test/flutter_test.dart';
import 'package:thinky/core_controls/services/mission_service.dart';

void main() {
  group('MissionService', () {
    test('getMissions returns offline missions when USE_OFFLINE_MISSIONS is true', () async {
      // Arrange - no setup needed since USE_OFFLINE_MISSIONS = true

      // Act
      final response = await MissionService.getMissions();

      // Assert
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
      // Should not throw — offline missions silently complete
      await MissionService.completeMission(-2);
      await MissionService.completeMission(-1);
    });
  });
}
