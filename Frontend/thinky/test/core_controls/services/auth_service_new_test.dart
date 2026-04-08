import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thinky/core_controls/services/auth_service.dart';
import 'package:thinky/core_controls/services/api_client.dart';
import 'package:thinky/core_controls/models/auth_response.dart';
import 'package:thinky/test_support/fixtures/auth_fixtures.dart';
import 'package:thinky/test_support/helpers/test_helpers.dart';

import 'auth_service_new_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  late MockClient mockClient;

  setUp(() async {
    dotenv.testLoad(fileInput: 'API_BASE_URL=http://localhost:8000\n');
    SharedPreferences.setMockInitialValues({});
    await initTestPrefs();
    mockClient = MockClient();
    injectMockHttpClient(mockClient);
  });

  tearDown(() {
    ApiClient.client = http.Client();
  });

  group('AuthService persistence', () {
    test('saveAuthData stores all fields in SharedPreferences', () async {
      final response = AuthResponse(
        accessToken: 'tok_full',
        tokenType: 'bearer',
        userId: 42,
        username: 'user42',
        email: 'user42@example.com',
        isGuest: true,
        guestName: 'Local Guest',
      );

      await AuthService.saveAuthData(response);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), 'tok_full');
      expect(prefs.getInt('user_id'), 42);
      expect(prefs.getString('username'), 'user42');
      expect(prefs.getString('email'), 'user42@example.com');
      expect(prefs.getBool('is_guest'), true);
      expect(prefs.getString('guest_name'), 'Local Guest');
    });

    test('getToken returns stored token', () async {
      SharedPreferences.setMockInitialValues({'auth_token': 'stored_token'});
      await initTestPrefs({'auth_token': 'stored_token'});

      expect(await AuthService.getToken(), 'stored_token');
    });

    test('getToken returns null when no token', () async {
      expect(await AuthService.getToken(), isNull);
    });

    test('isAuthenticated returns true when token exists', () async {
      SharedPreferences.setMockInitialValues({'auth_token': 'abc'});
      await initTestPrefs({'auth_token': 'abc'});

      expect(await AuthService.isAuthenticated(), isTrue);
    });

    test('isAuthenticated returns false when no token', () async {
      expect(await AuthService.isAuthenticated(), isFalse);
    });

    test('getCurrentUser returns user map when authenticated', () async {
      await AuthService.saveAuthData(AuthFixtures.validUser());

      final user = await AuthService.getCurrentUser();
      expect(user, isNotNull);
      expect(user!['userId'], 1);
      expect(user['username'], 'testuser');
      expect(user['email'], 'test@example.com');
      expect(user['isGuest'], false);
      expect(user['guestName'], isNull);
    });

    test('getCurrentUser returns null when no token', () async {
      SharedPreferences.setMockInitialValues({
        'user_id': 1,
        'username': 'orphan',
      });
      await initTestPrefs({
        'user_id': 1,
        'username': 'orphan',
      });

      expect(await AuthService.getCurrentUser(), isNull);
    });

    test('logout removes all auth keys', () async {
      SharedPreferences.setMockInitialValues({
        'auth_token': 't',
        'user_id': 1,
        'username': 'u',
        'email': 'e@e.com',
        'is_guest': true,
        'guest_name': 'g',
      });
      await initTestPrefs({
        'auth_token': 't',
        'user_id': 1,
        'username': 'u',
        'email': 'e@e.com',
        'is_guest': true,
        'guest_name': 'g',
      });

      await AuthService.logout();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), isNull);
      expect(prefs.getInt('user_id'), isNull);
      expect(prefs.getString('username'), isNull);
      expect(prefs.getString('email'), isNull);
      expect(prefs.getBool('is_guest'), isNull);
      expect(prefs.getString('guest_name'), isNull);
    });
  });

  group('AuthService login', () {
    test('login success returns AuthResponse and saves data', () async {
      when(
        mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        ),
      ).thenAnswer(
        (_) async => successResponse(AuthFixtures.validUserJson(), statusCode: 200),
      );

      final result = await AuthService.login(
        email: 'test@example.com',
        password: 'secret',
      );

      expect(result.accessToken, 'test_token_123');
      expect(result.userId, 1);
      expect(result.username, 'testuser');
      expect(result.email, 'test@example.com');
      expect(result.isGuest, false);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), 'test_token_123');
      expect(prefs.getInt('user_id'), 1);
      expect(prefs.getString('username'), 'testuser');
      expect(prefs.getString('email'), 'test@example.com');
      expect(prefs.getBool('is_guest'), false);
    });

    test('login failure on non-200 throws AuthError', () async {
      when(
        mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        ),
      ).thenAnswer(
        (_) async => errorResponse(statusCode: 401, detail: 'Invalid credentials'),
      );

      expect(
        () => AuthService.login(email: 'a@b.com', password: 'wrong'),
        throwsA(
          isA<AuthError>().having((e) => e.message, 'message', 'Invalid credentials'),
        ),
      );
    });

    test('login network error wraps in AuthError', () async {
      when(
        mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        ),
      ).thenThrow(Exception('connection refused'));

      expect(
        () => AuthService.login(email: 'a@b.com', password: 'p'),
        throwsA(
          isA<AuthError>().having(
            (e) => e.message,
            'message',
            contains('Network error'),
          ),
        ),
      );
    });
  });

  group('AuthService register', () {
    test('register success on status 201 returns AuthResponse and saves', () async {
      when(
        mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        ),
      ).thenAnswer(
        (_) async => successResponse(AuthFixtures.validUserJson(), statusCode: 201),
      );

      final result = await AuthService.register(
        username: 'testuser',
        email: 'test@example.com',
        password: 'p',
        confirmPassword: 'p',
      );

      expect(result.accessToken, 'test_token_123');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), 'test_token_123');
    });
  });

  group('AuthService guest', () {
    test('registerGuest success on status 201 returns AuthResponse and saves', () async {
      when(
        mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        ),
      ).thenAnswer(
        (_) async => successResponse(AuthFixtures.guestUserJson(), statusCode: 201),
      );

      final result = await AuthService.registerGuest(name: 'Guest');

      expect(result.isGuest, isTrue);
      expect(result.guestName, 'Test Guest');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), 'guest_token_456');
      expect(prefs.getBool('is_guest'), true);
    });

    test('registerGuestOffline creates local guest profile', () async {
      final result = await AuthService.registerGuestOffline(name: 'Offline Name');

      expect(result.isGuest, isTrue);
      expect(result.username, 'Offline Name');
      expect(result.guestName, 'Offline Name');
      expect(result.email, isNull);
      expect(result.accessToken, startsWith('guest_local_token_'));
      expect(result.tokenType, 'guest');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), result.accessToken);
      expect(prefs.getBool('is_guest'), true);
      expect(prefs.getString('guest_name'), 'Offline Name');
    });
  });
}
