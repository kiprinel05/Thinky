import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // --- Environment ---
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
  static String get apiBaseUrl => '$baseUrl/api/v1';

  // --- Debug flags (controlled via .env, off by default in production) ---
  static bool get isDebug =>
      kDebugMode || dotenv.env['DEBUG_MODE']?.toLowerCase() == 'true';

  static bool get useOfflineMissions =>
      dotenv.env['USE_OFFLINE_MISSIONS']?.toLowerCase() == 'true';

  // --- Auth endpoints ---
  static const String registerEndpoint = '/auth/register';
  static const String loginEndpoint = '/auth/login';
  static const String guestEndpoint = '/auth/guest';
  static const String meEndpoint = '/auth/me';
}
