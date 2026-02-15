/// API Endpoints - All API endpoint paths centralized
/// Prevents hardcoded strings throughout the codebase
abstract class ApiEndpoints {
  // ══════════════════════════════════════════════════════════════════════════
  // AUTHENTICATION
  // ══════════════════════════════════════════════════════════════════════════
  
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String guest = '/auth/guest';
  static const String me = '/auth/me';
  static const String requestPasswordReset = '/auth/request-reset';
  static const String verifyResetCode = '/auth/verify-reset-code';
  static const String resetPassword = '/auth/reset-password';
  
  // ══════════════════════════════════════════════════════════════════════════
  // MISSIONS
  // ══════════════════════════════════════════════════════════════════════════
  
  static const String missions = '/missions';
  static String missionComplete(int missionId) => '/missions/$missionId/complete';
  static const String missionProgress = '/missions/progress';
  
  // ══════════════════════════════════════════════════════════════════════════
  // QUIZ
  // ══════════════════════════════════════════════════════════════════════════
  
  static const String quizQuestions = '/quiz/questions';
  static const String quizSubmit = '/quiz/submit';
  
  // ══════════════════════════════════════════════════════════════════════════
  // PIXY LEARNS
  // ══════════════════════════════════════════════════════════════════════════
  
  static const String pixyLearnUpload = '/pixy-learns/upload';
  static const String pixyLearnImages = '/pixy-learns/images';
  
  // ══════════════════════════════════════════════════════════════════════════
  // DRAWING
  // ══════════════════════════════════════════════════════════════════════════
  
  static const String drawingAnalyze = '/drawing/analyze';
  
  // ══════════════════════════════════════════════════════════════════════════
  // GROUPING
  // ══════════════════════════════════════════════════════════════════════════
  
  static const String groupingStart = '/grouping/start';
  static const String groupingRound = '/grouping/round';
  static const String groupingSubmit = '/grouping/submit';
}
