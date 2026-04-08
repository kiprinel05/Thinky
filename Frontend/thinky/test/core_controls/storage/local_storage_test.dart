import 'package:flutter_test/flutter_test.dart';
import 'package:thinky/test_support/fakes/fake_local_storage.dart';

void main() {
  group('LocalStorage (FakeLocalStorage)', () {
    late FakeLocalStorage storage;

    setUp(() {
      storage = FakeLocalStorage.createAndInject();
    });

    test('setAuthToken / authToken getter', () async {
      await storage.setAuthToken('token-abc');
      expect(storage.authToken, 'token-abc');
    });

    test('setUserId / userId getter', () async {
      await storage.setUserId(42);
      expect(storage.userId, 42);
    });

    test('setUsername / username getter', () async {
      await storage.setUsername('alice');
      expect(storage.username, 'alice');
    });

    test('setEmail / email getter', () async {
      await storage.setEmail('a@b.c');
      expect(storage.email, 'a@b.c');
    });

    test('setIsGuest / isGuest getter (defaults to false)', () async {
      expect(storage.isGuest, isFalse);
      await storage.setIsGuest(true);
      expect(storage.isGuest, isTrue);
    });

    test('setGuestName / guestName getter', () async {
      await storage.setGuestName('Guesty');
      expect(storage.guestName, 'Guesty');
    });

    test('setHasSeenWelcome / hasSeenWelcome (defaults to false)', () async {
      expect(storage.hasSeenWelcome, isFalse);
      await storage.setHasSeenWelcome(true);
      expect(storage.hasSeenWelcome, isTrue);
    });

    test('setLastRoute / lastRoute (defaults to null)', () async {
      expect(storage.lastRoute, isNull);
      await storage.setLastRoute('/home');
      expect(storage.lastRoute, '/home');
    });

    test('isAuthenticated returns false when no token', () {
      expect(storage.isAuthenticated, isFalse);
    });

    test('isAuthenticated returns true when token is set', () async {
      await storage.setAuthToken('secret');
      expect(storage.isAuthenticated, isTrue);
    });

    test('isAuthenticated returns false for empty token', () async {
      await storage.setAuthToken('');
      expect(storage.isAuthenticated, isFalse);
    });

    test('clearAuthData removes all auth keys but not app state', () async {
      await storage.setAuthToken('t');
      await storage.setUserId(1);
      await storage.setUsername('u');
      await storage.setEmail('e');
      await storage.setIsGuest(true);
      await storage.setGuestName('g');
      await storage.setHasSeenWelcome(true);
      await storage.setLastRoute('/route');

      await storage.clearAuthData();

      expect(storage.authToken, isNull);
      expect(storage.userId, isNull);
      expect(storage.username, isNull);
      expect(storage.email, isNull);
      expect(storage.isGuest, isFalse);
      expect(storage.guestName, isNull);
      expect(storage.hasSeenWelcome, isTrue);
      expect(storage.lastRoute, '/route');
    });

    test('clearAppState removes app state but not auth', () async {
      await storage.setAuthToken('t');
      await storage.setUserId(2);
      await storage.setHasSeenWelcome(true);
      await storage.setLastRoute('/x');

      await storage.clearAppState();

      expect(storage.authToken, 't');
      expect(storage.userId, 2);
      expect(storage.hasSeenWelcome, isFalse);
      expect(storage.lastRoute, isNull);
    });

    test('clearAll removes everything', () async {
      await storage.setAuthToken('t');
      await storage.setUserId(3);
      await storage.setUsername('u');
      await storage.setEmail('e');
      await storage.setIsGuest(true);
      await storage.setGuestName('g');
      await storage.setHasSeenWelcome(true);
      await storage.setLastRoute('/r');

      await storage.clearAll();

      expect(storage.authToken, isNull);
      expect(storage.userId, isNull);
      expect(storage.username, isNull);
      expect(storage.email, isNull);
      expect(storage.isGuest, isFalse);
      expect(storage.guestName, isNull);
      expect(storage.hasSeenWelcome, isFalse);
      expect(storage.lastRoute, isNull);
      expect(storage.isAuthenticated, isFalse);
    });
  });
}
