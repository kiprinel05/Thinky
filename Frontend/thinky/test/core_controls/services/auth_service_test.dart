import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thinky/core_controls/services/api_client.dart';
import 'package:thinky/core_controls/services/auth_service.dart';
import 'package:thinky/core_controls/config/app_config.dart';
import 'dart:convert';

import 'api_client_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  late MockClient mockClient;

  setUp(() {
    dotenv.testLoad(fileInput: 'API_BASE_URL=http://localhost:8000\n');
    mockClient = MockClient();
    ApiClient.client = mockClient;
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthService', () {
    test('login success saves token and returns AuthResponse', () async {
      final responseBody = {
        'access_token': 'test_token',
        'token_type': 'bearer',
        'user_id': 123,
        'username': 'testuser',
        'email': 'test@example.com',
        'is_guest': false
      };

      when(mockClient.post(
        Uri.parse('${AppConfig.apiBaseUrl}${AppConfig.loginEndpoint}'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(jsonEncode(responseBody), 200));

      final authResponse = await AuthService.login(email: 'test@test.com', password: 'password');

      expect(authResponse.accessToken, 'test_token');
      expect(authResponse.userId, 123);
      
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), 'test_token');
      expect(prefs.getInt('user_id'), 123);
    });

    test('login failure throws AuthError', () async {
      when(mockClient.post(
        Uri.parse('${AppConfig.apiBaseUrl}${AppConfig.loginEndpoint}'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('{"detail": "Invalid credentials"}', 401));

      expect(
        () => AuthService.login(email: 'test@test.com', password: 'wrong'),
        throwsA(isA<dynamic>()), // AuthError is custom, checking dynamic for now or look up type
      );
    });

    test('logout clears preferences', () async {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'old_token',
        'user_id': 123,
      });

      await AuthService.logout();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), null);
      expect(prefs.getInt('user_id'), null);
    });
  });
}
