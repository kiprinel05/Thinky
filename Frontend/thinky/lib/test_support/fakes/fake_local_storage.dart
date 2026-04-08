import 'package:thinky/core_controls/storage/local_storage.dart';

/// In-memory LocalStorage for tests — avoids SharedPreferences entirely.
class FakeLocalStorage extends LocalStorage {
  final Map<String, dynamic> _store = {};

  FakeLocalStorage() : super.forTesting();

  /// Create and inject into the singleton
  static FakeLocalStorage createAndInject() {
    final instance = FakeLocalStorage();
    LocalStorage.setInstanceForTesting(instance);
    return instance;
  }

  @override
  String? get authToken => _store['auth_token'] as String?;

  @override
  Future<void> setAuthToken(String token) async {
    _store['auth_token'] = token;
  }

  @override
  int? get userId => _store['user_id'] as int?;

  @override
  Future<void> setUserId(int id) async {
    _store['user_id'] = id;
  }

  @override
  String? get username => _store['username'] as String?;

  @override
  Future<void> setUsername(String username) async {
    _store['username'] = username;
  }

  @override
  String? get email => _store['email'] as String?;

  @override
  Future<void> setEmail(String email) async {
    _store['email'] = email;
  }

  @override
  bool get isGuest => _store['is_guest'] as bool? ?? false;

  @override
  Future<void> setIsGuest(bool isGuest) async {
    _store['is_guest'] = isGuest;
  }

  @override
  String? get guestName => _store['guest_name'] as String?;

  @override
  Future<void> setGuestName(String name) async {
    _store['guest_name'] = name;
  }

  @override
  bool get hasSeenWelcome => _store['has_seen_welcome'] as bool? ?? false;

  @override
  Future<void> setHasSeenWelcome(bool hasSeen) async {
    _store['has_seen_welcome'] = hasSeen;
  }

  @override
  String? get lastRoute => _store['last_route'] as String?;

  @override
  Future<void> setLastRoute(String route) async {
    _store['last_route'] = route;
  }

  @override
  Future<void> clearAuthData() async {
    _store.remove('auth_token');
    _store.remove('user_id');
    _store.remove('username');
    _store.remove('email');
    _store.remove('is_guest');
    _store.remove('guest_name');
  }

  @override
  Future<void> clearAppState() async {
    _store.remove('has_seen_welcome');
    _store.remove('last_route');
  }

  @override
  Future<void> clearAll() async {
    _store.clear();
  }

  @override
  bool get isAuthenticated {
    final token = authToken;
    return token != null && token.isNotEmpty;
  }
}
