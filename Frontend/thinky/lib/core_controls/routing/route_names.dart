/// RouteNames - All route path constants
/// Centralized navigation paths for go_router
abstract class RouteNames {
  // ══════════════════════════════════════════════════════════════════════════
  // ROOT ROUTES
  // ══════════════════════════════════════════════════════════════════════════
  
  static const String splash = '/';
  static const String intro = '/intro';
  
  // ══════════════════════════════════════════════════════════════════════════
  // AUTHENTICATION ROUTES
  // ══════════════════════════════════════════════════════════════════════════
  
  static const String login = '/login';
  static const String register = '/register';
  static const String guestName = '/guest-name';
  static const String forgotPassword = '/forgot-password';
  static const String verifyCode = '/verify-code';
  static const String resetPassword = '/reset-password';
  static const String profile = '/profile';
  
  // ══════════════════════════════════════════════════════════════════════════
  // MAIN APP ROUTES
  // ══════════════════════════════════════════════════════════════════════════
  
  static const String welcome = '/welcome';
  static const String missions = '/missions';
  
  // ══════════════════════════════════════════════════════════════════════════
  // MISSION ROUTES
  // ══════════════════════════════════════════════════════════════════════════
  
  static const String quiz = '/quiz';
  static const String quizIntro = '/quiz/intro';
  static const String quizResult = '/quiz/result';
  static const String pixyLearns = '/pixy-learns';
  static const String drawTriangle = '/draw-triangle';
  static const String colorCircle = '/color-circle';
  static const String animalsMission = '/animals-mission';
  static const String groupingMission = '/grouping-mission';
  static const String vocabularyMission = '/vocabulary-mission';
  static const String describeMission = '/describe-mission';
  static const String patternMission = '/pattern-mission';
}
