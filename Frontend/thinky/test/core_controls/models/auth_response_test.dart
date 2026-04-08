import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:thinky/core_controls/models/auth_response.dart';
import 'package:thinky/test_support/fixtures/auth_fixtures.dart';

void main() {
  group('AuthResponse.fromJson', () {
    test('parses all fields', () {
      final json = jsonDecode(AuthFixtures.guestUserJson()) as Map<String, dynamic>;
      final r = AuthResponse.fromJson(json);

      expect(r.accessToken, 'guest_token_456');
      expect(r.tokenType, 'guest');
      expect(r.userId, 999);
      expect(r.username, 'Guest');
      expect(r.email, isNull);
      expect(r.isGuest, isTrue);
      expect(r.guestName, 'Test Guest');
    });

    test('parses minimal fields (nullables absent)', () {
      final json = <String, dynamic>{
        'access_token': 'tok',
        'user_id': 7,
      };
      final r = AuthResponse.fromJson(json);

      expect(r.accessToken, 'tok');
      expect(r.userId, 7);
      expect(r.tokenType, 'bearer');
      expect(r.username, isNull);
      expect(r.email, isNull);
      expect(r.isGuest, isFalse);
      expect(r.guestName, isNull);
    });

    test('defaults token_type to bearer when omitted', () {
      final json = <String, dynamic>{
        'access_token': 'a',
        'user_id': 1,
        'is_guest': false,
      };
      expect(AuthResponse.fromJson(json).tokenType, 'bearer');
    });

    test('defaults is_guest to false when omitted', () {
      final json = <String, dynamic>{
        'access_token': 'a',
        'user_id': 1,
        'token_type': 'bearer',
      };
      expect(AuthResponse.fromJson(json).isGuest, isFalse);
    });

    test('matches AuthFixtures.validUser via map', () {
      final r = AuthResponse.fromJson(AuthFixtures.validUserMap());
      final expected = AuthFixtures.validUser();
      expect(r.accessToken, expected.accessToken);
      expect(r.tokenType, expected.tokenType);
      expect(r.userId, expected.userId);
      expect(r.username, expected.username);
      expect(r.email, expected.email);
      expect(r.isGuest, expected.isGuest);
      expect(r.guestName, expected.guestName);
    });
  });

  group('AuthError', () {
    test('fromJson extracts detail', () {
      final json = jsonDecode(AuthFixtures.errorJson()) as Map<String, dynamic>;
      final e = AuthError.fromJson(json);
      expect(e.message, 'Invalid credentials');
      expect(e.statusCode, isNull);
    });

    test("fromJson defaults message when detail is missing", () {
      final e = AuthError.fromJson(<String, dynamic>{});
      expect(e.message, 'An error occurred');
    });

    test('fromString wraps message', () {
      final e = AuthError.fromString('Plain text error');
      expect(e.message, 'Plain text error');
      expect(e.statusCode, isNull);
    });
  });
}
