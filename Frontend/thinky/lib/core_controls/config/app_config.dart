import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // Loaded from .env file
  // Pentru Chrome/Web: http://localhost:8000
  // Pentru emulator Android: http://10.0.2.2:8000
  // Pentru telefon real: http://192.168.x.x:8000
  
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
  
  static String get apiBaseUrl => '$baseUrl/api/v1';
  
  static const String registerEndpoint = '/auth/register';
  static const String loginEndpoint = '/auth/login';
  static const String guestEndpoint = '/auth/guest';
  static const String meEndpoint = '/auth/me';
}
