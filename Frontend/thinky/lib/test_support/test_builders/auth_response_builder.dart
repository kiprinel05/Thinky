import 'package:thinky/core_controls/models/auth_response.dart';

/// Builder pattern for constructing AuthResponse in tests
class AuthResponseBuilder {
  String _accessToken = 'test_token';
  String _tokenType = 'bearer';
  int _userId = 1;
  String? _username = 'testuser';
  String? _email = 'test@example.com';
  bool _isGuest = false;
  String? _guestName;

  AuthResponseBuilder withAccessToken(String token) {
    _accessToken = token;
    return this;
  }

  AuthResponseBuilder withTokenType(String type) {
    _tokenType = type;
    return this;
  }

  AuthResponseBuilder withUserId(int id) {
    _userId = id;
    return this;
  }

  AuthResponseBuilder withUsername(String? username) {
    _username = username;
    return this;
  }

  AuthResponseBuilder withEmail(String? email) {
    _email = email;
    return this;
  }

  AuthResponseBuilder asGuest({String name = 'Guest'}) {
    _isGuest = true;
    _guestName = name;
    _tokenType = 'guest';
    _email = null;
    return this;
  }

  AuthResponse build() => AuthResponse(
        accessToken: _accessToken,
        tokenType: _tokenType,
        userId: _userId,
        username: _username,
        email: _email,
        isGuest: _isGuest,
        guestName: _guestName,
      );
}
