class AppConfig {
  // For Chrome/Web: http://localhost:8000
  // For Android emulator: http://10.0.2.2:8000
  static const String baseUrl = 'http://localhost:8000';
  
  static const String apiBaseUrl = '$baseUrl/api/v1';
  
  static const String registerEndpoint = '/auth/register';
  static const String loginEndpoint = '/auth/login';
  static const String guestEndpoint = '/auth/guest';
  static const String meEndpoint = '/auth/me';
}
