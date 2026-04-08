import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thinky/core_controls/services/app_state_service.dart';
import 'package:thinky/test_support/helpers/test_helpers.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await initTestPrefs();
  });

  group('AppStateService', () {
    test('hasSeenWelcome defaults to false', () async {
      expect(await AppStateService.hasSeenWelcome(), isFalse);
    });

    test('setHasSeenWelcome and hasSeenWelcome round trip', () async {
      await AppStateService.setHasSeenWelcome(true);
      expect(await AppStateService.hasSeenWelcome(), isTrue);

      await AppStateService.setHasSeenWelcome(false);
      expect(await AppStateService.hasSeenWelcome(), isFalse);
    });

    test('getLastRoute returns null by default', () async {
      expect(await AppStateService.getLastRoute(), isNull);
    });

    test('setLastRoute and getLastRoute round trip', () async {
      await AppStateService.setLastRoute('/missions');
      expect(await AppStateService.getLastRoute(), '/missions');

      await AppStateService.setLastRoute('/home');
      expect(await AppStateService.getLastRoute(), '/home');
    });

    test('clearAppState removes only app state keys', () async {
      await AppStateService.setHasSeenWelcome(true);
      await AppStateService.setLastRoute('/home');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('other_key', 'value');

      await AppStateService.clearAppState();

      expect(await AppStateService.hasSeenWelcome(), isFalse);
      expect(await AppStateService.getLastRoute(), isNull);
      expect(prefs.getString('other_key'), 'value');
    });

    test('clearAll removes everything', () async {
      await AppStateService.setHasSeenWelcome(true);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('other_key', 'value');

      await AppStateService.clearAll();

      expect(await AppStateService.hasSeenWelcome(), isFalse);
      expect(prefs.containsKey('other_key'), isFalse);
    });
  });
}
