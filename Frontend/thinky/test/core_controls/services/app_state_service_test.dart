import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thinky/core_controls/services/app_state_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppStateService', () {
    test('HasSeenWelcome persists value', () async {
      expect(await AppStateService.hasSeenWelcome(), false);

      await AppStateService.setHasSeenWelcome(true);
      expect(await AppStateService.hasSeenWelcome(), true);

      // Verify persistent storage
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('has_seen_welcome'), true);
    });

    test('LastRoute persists value', () async {
      expect(await AppStateService.getLastRoute(), null);

      await AppStateService.setLastRoute('/home');
      expect(await AppStateService.getLastRoute(), '/home');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('last_route'), '/home');
    });

    test('clearAppState removes specific keys', () async {
      await AppStateService.setHasSeenWelcome(true);
      await AppStateService.setLastRoute('/home');
      
      // Simulate another unrelated key
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('other_key', 'value');

      await AppStateService.clearAppState();

      expect(await AppStateService.hasSeenWelcome(), false);
      expect(await AppStateService.getLastRoute(), null);
      
      // Other keys should remain (unless we use clearAll)
      // Actually clearAppState only removes specific keys.
      expect(prefs.getString('other_key'), 'value');
    });

    test('clearAll removes everything', () async {
       await AppStateService.setHasSeenWelcome(true);
       final prefs = await SharedPreferences.getInstance();
       await prefs.setString('other_key', 'value');

       await AppStateService.clearAll();

       expect(await AppStateService.hasSeenWelcome(), false);
       expect(prefs.containsKey('other_key'), false);
    });
  });
}
