/// Canonical paths under `assets/`. Register new directories in [pubspec.yaml].
/// Prefer these constants (and helpers) over raw strings so new files land in one place.
library;

import 'dart:ui' show Brightness;

abstract final class AppAssets {
  AppAssets._();

  static const String _missions = 'assets/missions';

  // —— i18n ——
  static const String i18nTexts = 'assets/i18n/texts.json';
  static const String i18nTextsRo = 'assets/i18n/texts_ro.json';

  // —— Branding & onboarding (intro: login / register) ——
  static const String logoLight = 'assets/logos/logo.png';
  static const String logoDark = 'assets/logos/logo_dark.png';

  static const String onboardingBackgroundLight =
      'assets/backgrounds/background.png';
  static const String onboardingBackgroundDark =
      'assets/backgrounds/background_dark.png';

  static String logoFor(Brightness brightness) =>
      brightness == Brightness.dark ? logoDark : logoLight;

  static String onboardingBackgroundFor(Brightness brightness) =>
      brightness == Brightness.dark
          ? onboardingBackgroundDark
          : onboardingBackgroundLight;

  static const String onboardingIllustration =
      'assets/illustrations/first_page_image.png';

  // —— Auth ——
  static const String authLoginBackground = 'assets/auth/login/background.png';
  static const String authRegisterBackground =
      'assets/auth/register/background.png';
  static const String authGuestBackground = 'assets/auth/guest/background.png';
  static const String authFacebookIcon = 'assets/auth/icons/facebook.png';
  static const String authGoogleIcon = 'assets/auth/icons/google.png';

  // —— Welcome / mascot ——
  static const String welcomePage1Background =
      'assets/welcome/page1/background_welcome.png';
  static const String welcomePage1Hello = 'assets/welcome/page1/hello.png';
  static const String welcomePage2Background =
      'assets/welcome/page2/background_welcome.png';
  static const String welcomePage2Thinking =
      'assets/welcome/page2/thinking.png';

  // —— Missions (shared) ——

  /// Decorative asset behind the missions menu header (light / dark theme).
  static const String missionsMenuUnionLight =
      '$_missions/shell/Union_light.png';
  static const String missionsMenuUnionDark = '$_missions/shell/Union_dark.png';

  static String missionsMenuUnion(Brightness brightness) =>
      brightness == Brightness.dark
          ? missionsMenuUnionDark
          : missionsMenuUnionLight;

  static const String missionQuizCard = '$_missions/quiz/quiz.png';
  static const String missionQuizHappy = '$_missions/quiz/happy.png';

  /// List / card thumbnails (e.g. offline API fallback). Files live in `assets/missions/catalog/`.
  static const String missionCatalogPixyLearns =
      '$_missions/catalog/pixy_learns.png';
  static const String missionCatalogColors = '$_missions/catalog/colors.png';
  static const String missionCatalogShapes = '$_missions/catalog/shapes.png';
  static const String missionCatalogNumbers = '$_missions/catalog/numbers.png';

  static String missionBackground(String missionPath) =>
      '$_missions/$missionPath/background.png';

  static String missionVector1(String missionPath) =>
      '$_missions/$missionPath/vector1.png';

  static String missionVector2(String missionPath) =>
      '$_missions/$missionPath/vector2.png';

  static String missionCardDrawing(String missionPath) =>
      '$_missions/$missionPath/card_drawing.png';

  /// `category` e.g. fruits, vegetables, toys; `filename` e.g. apple.png
  static String groupSortingImage(String category, String filename) =>
      '$_missions/group_sorting/images/$category/$filename';

  /// Word Match / vocabulary mission images (`assets/missions/vocabulary/`).
  static String vocabularyImage(String filename) => '$_missions/vocabulary/$filename';

  /// Pixy Learns (Apple vs Cat) training images under `assets/missions/pixy_learns/images/`.
  static String pixyLearnsImage(String filename) => '$_missions/pixy_learns/images/$filename';
}
