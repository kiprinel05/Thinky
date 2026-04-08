import 'dart:convert';
import 'package:thinky/core_controls/models/auth_response.dart';

abstract class AuthFixtures {
  static AuthResponse validUser() => AuthResponse(
        accessToken: 'test_token_123',
        tokenType: 'bearer',
        userId: 1,
        username: 'testuser',
        email: 'test@example.com',
        isGuest: false,
      );

  static AuthResponse guestUser() => AuthResponse(
        accessToken: 'guest_token_456',
        tokenType: 'guest',
        userId: 999,
        username: 'Guest',
        email: null,
        isGuest: true,
        guestName: 'Test Guest',
      );

  static String validUserJson() => jsonEncode({
        'access_token': 'test_token_123',
        'token_type': 'bearer',
        'user_id': 1,
        'username': 'testuser',
        'email': 'test@example.com',
        'is_guest': false,
      });

  static String guestUserJson() => jsonEncode({
        'access_token': 'guest_token_456',
        'token_type': 'guest',
        'user_id': 999,
        'username': 'Guest',
        'email': null,
        'is_guest': true,
        'guest_name': 'Test Guest',
      });

  static String errorJson({String detail = 'Invalid credentials'}) => jsonEncode({
        'detail': detail,
      });

  static Map<String, dynamic> validUserMap() => {
        'access_token': 'test_token_123',
        'token_type': 'bearer',
        'user_id': 1,
        'username': 'testuser',
        'email': 'test@example.com',
        'is_guest': false,
      };
}
