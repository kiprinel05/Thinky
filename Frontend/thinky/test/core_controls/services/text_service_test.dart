import 'package:flutter_test/flutter_test.dart';
import 'package:thinky/core_controls/services/text_service.dart';
import 'package:thinky/test_support/fixtures/text_fixtures.dart';

void main() {
  group('TextService', () {
    setUp(TextService.resetForTesting);

    test('getString returns correct value after loadFromMap', () {
      TextService.loadFromMap(TextFixtures.fullTextsMap());

      expect(TextService.getString('Misc', 'test'), 'test value from json');
      expect(TextService.getString('Auth', 'loginButton'), 'Log In');
      expect(TextService.getString('Nav', 'missions'), 'Missions');
    });

    test('getString returns fallback for missing category', () {
      TextService.loadFromMap(TextFixtures.minimalTextsMap());

      expect(
        TextService.getString('MissingCategory', 'anyKey'),
        'MissingCategory.anyKey',
      );
    });

    test('getString returns fallback for missing key', () {
      TextService.loadFromMap(TextFixtures.minimalTextsMap());

      expect(TextService.getString('Misc', 'noSuchKey'), 'Misc.noSuchKey');
    });

    test('getString returns category.key fallback when not initialized', () {
      expect(TextService.getString('Foo', 'bar'), 'Foo.bar');
    });

    test('loadFromMap sets initialized so getString resolves nested keys', () {
      TextService.resetForTesting();
      expect(TextService.getString('Intro', 'title'), 'Intro.title');

      TextService.loadFromMap(TextFixtures.fullTextsMap());
      expect(TextService.getString('Intro', 'title'), 'Learn and Teach');
    });

    test('getString reads nested category map entries', () {
      TextService.loadFromMap(TextFixtures.fullTextsMap());

      expect(TextService.getString('Intro', 'subtitle'), 'Thousands of people use AI');
      expect(TextService.getString('Common', 'retry'), 'Retry');
    });
  });
}
