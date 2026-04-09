import 'package:thinky/core_controls/services/text_service.dart';

/// Accessors for 'Misc' texts
class Misc {
  static String get test => TextService.getString('Misc', 'test');
}

/// Accessors for 'Intro' texts
class Intro {
  static String get title => TextService.getString('Intro', 'title');
  static String get subtitle => TextService.getString('Intro', 'subtitle');
  static String get signUp => TextService.getString('Intro', 'signUp');
  static String get guest => TextService.getString('Intro', 'guest');
  static String get logIn => TextService.getString('Intro', 'logIn');
  static String get haveAccount => TextService.getString('Intro', 'haveAccount');
}

/// Accessors for 'Welcome' texts
class Welcome {
  static String get hi => TextService.getString('Welcome', 'hi');
  static String get title => TextService.getString('Welcome', 'title');
  static String get subtitle => TextService.getString('Welcome', 'subtitle'); // Kept for backward compat if used elsewhere
  static String get introMessage => TextService.getString('Welcome', 'introMessage');
  static String get nextButton => TextService.getString('Welcome', 'nextButton');
  static String get robotQuestion => TextService.getString('Welcome', 'robotQuestion');
  static String get robotAnswer => TextService.getString('Welcome', 'robotAnswer');
  static String get startButton => TextService.getString('Welcome', 'startButton');
}

/// Accessors for 'Auth' texts
class Auth {
  static String get loginButton => TextService.getString('Auth', 'loginButton');
  static String get registerButton => TextService.getString('Auth', 'registerButton');
  static String get welcomeBack => TextService.getString('Auth', 'welcomeBack');
  static String get continueFacebook => TextService.getString('Auth', 'continueFacebook');
  static String get continueGoogle => TextService.getString('Auth', 'continueGoogle');
  static String get orLoginEmail => TextService.getString('Auth', 'orLoginEmail');
  static String get emailHint => TextService.getString('Auth', 'emailHint');
  static String get passwordHint => TextService.getString('Auth', 'passwordHint');
  static String get emailRequired => TextService.getString('Auth', 'emailRequired');
  static String get emailInvalid => TextService.getString('Auth', 'emailInvalid');
  static String get passwordRequired => TextService.getString('Auth', 'passwordRequired');
  static String get forgotPassword => TextService.getString('Auth', 'forgotPassword');
  static String get createAccount => TextService.getString('Auth', 'createAccount');
  static String get usernameHint => TextService.getString('Auth', 'usernameHint');
  static String get usernameRequired => TextService.getString('Auth', 'usernameRequired');
  static String get usernameMinLength => TextService.getString('Auth', 'usernameMinLength');
  static String get usernameMaxLength => TextService.getString('Auth', 'usernameMaxLength');
  static String get passwordMinLength => TextService.getString('Auth', 'passwordMinLength');
  static String get confirmPasswordHint => TextService.getString('Auth', 'confirmPasswordHint');
  static String get confirmPasswordRequired => TextService.getString('Auth', 'confirmPasswordRequired');
  static String get passwordsMismatch => TextService.getString('Auth', 'passwordsMismatch');
  static String get getStarted => TextService.getString('Auth', 'getStarted');
  static String get alreadyHaveAccount => TextService.getString('Auth', 'alreadyHaveAccount');
  static String get continueGuest => TextService.getString('Auth', 'continueGuest');
  static String get guestNameSubtitle => TextService.getString('Auth', 'guestNameSubtitle');
  static String get guestNameHint => TextService.getString('Auth', 'guestNameHint');
  static String get nameRequired => TextService.getString('Auth', 'nameRequired');
  static String get nameMaxLength => TextService.getString('Auth', 'nameMaxLength');
  static String get continueAction => TextService.getString('Auth', 'continueAction');
  static String get loginFailed => TextService.getString('Auth', 'loginFailed');
  static String get registrationFailed =>
      TextService.getString('Auth', 'registrationFailed');
  static String get fillAllFields => TextService.getString('Auth', 'fillAllFields');
}

/// Localized user-facing error lines (see [UserFacingErrorMapper]).
class UserErrors {
  static String get wrongEmailOrPassword =>
      TextService.getString('UserErrors', 'wrongEmailOrPassword');
  static String get sessionExpiredMessage =>
      TextService.getString('UserErrors', 'sessionExpiredMessage');
  static String get somethingWentWrong =>
      TextService.getString('UserErrors', 'somethingWentWrong');
}

/// Accessors for 'Missions' texts
class Missions {
  static String get title => TextService.getString('Missions', 'title');
  static String get subtitle => TextService.getString('Missions', 'subtitle');
  static String get errorLoading => TextService.getString('Missions', 'errorLoading');
  static String get locked => TextService.getString('Missions', 'locked');
}

/// Accessors for 'Quiz' texts
class Quiz {
  static String get title => TextService.getString('Quiz', 'title');
  static String get introTitle => TextService.getString('Quiz', 'introTitle');
  static String get introSubtitle => TextService.getString('Quiz', 'introSubtitle');
  static String get startQuizButton => TextService.getString('Quiz', 'startQuizButton');
  static String get noQuestions => TextService.getString('Quiz', 'noQuestions');
  static String get questionLabel => TextService.getString('Quiz', 'questionLabel');
  static String get ofLabel => TextService.getString('Quiz', 'ofLabel');
  static String get previous => TextService.getString('Quiz', 'previous');
  static String get next => TextService.getString('Quiz', 'next');
  static String get seeResult => TextService.getString('Quiz', 'seeResult');
  static String get feedbackCorrectTitle => TextService.getString('Quiz', 'feedbackCorrectTitle');
  static String get feedbackIncorrectTitle => TextService.getString('Quiz', 'feedbackIncorrectTitle');
  static String get continueAction => TextService.getString('Quiz', 'continueAction');
  static String get completedTitle => TextService.getString('Quiz', 'completedTitle');
  static String get scoreLabel => TextService.getString('Quiz', 'scoreLabel');
  static String get completeMission => TextService.getString('Quiz', 'completeMission');
  static String get resultExcellent => TextService.getString('Quiz', 'resultExcellent');
  static String get resultGood => TextService.getString('Quiz', 'resultGood');
  static String get resultKeepLearning => TextService.getString('Quiz', 'resultKeepLearning');
  static String get resultHelperText => TextService.getString('Quiz', 'resultHelperText');
  static String get resultOutOf => TextService.getString('Quiz', 'resultOutOf');
  static String get resultCorrect => TextService.getString('Quiz', 'resultCorrect');
  static String get showDetailedResults => TextService.getString('Quiz', 'showDetailedResults');
  static String get continueToMissions => TextService.getString('Quiz', 'continueToMissions');
}

/// Accessors for 'Animals' texts
class Animals {
  static String get lookAtImage => TextService.getString('Animals', 'lookAtImage');
  static String get continueAction => TextService.getString('Animals', 'continueAction');
  static String get missionTitle => TextService.getString('Animals', 'missionTitle');
  static String get roundShort => TextService.getString('Animals', 'roundShort');
  static String get preparingMission => TextService.getString('Animals', 'preparingMission');
  static String get pixyName => TextService.getString('Animals', 'pixyName');
  static String get pixyThinkingShort => TextService.getString('Animals', 'pixyThinkingShort');
  static String get imageLoadError => TextService.getString('Animals', 'imageLoadError');
  static String get guessLeadIn => TextService.getString('Animals', 'guessLeadIn');
  static String get verifyQuestion => TextService.getString('Animals', 'verifyQuestion');
  static String get verifyYes => TextService.getString('Animals', 'verifyYes');
  static String get verifyNo => TextService.getString('Animals', 'verifyNo');
  static String get nextRoundExcited => TextService.getString('Animals', 'nextRoundExcited');
  static String get teachPixy => TextService.getString('Animals', 'teachPixy');
  static String get selectAllTarget => TextService.getString('Animals', 'selectAllTarget');
  static String get submitTeaching => TextService.getString('Animals', 'submitTeaching');
  static String get continueShort => TextService.getString('Animals', 'continueShort');
  static String get nextRound => TextService.getString('Animals', 'nextRound');
  static String get missionCompleteTitle => TextService.getString('Animals', 'missionCompleteTitle');
  static String get missionCompleteBody => TextService.getString('Animals', 'missionCompleteBody');
  static String get backToMissions => TextService.getString('Animals', 'backToMissions');
  static String get oopsTitle => TextService.getString('Animals', 'oopsTitle');
  static String get retry => TextService.getString('Animals', 'retry');

  static String guessConfidencePercent(int percent) =>
      TextService.getString('Animals', 'guessConfidence')
          .replaceAll('{percent}', '$percent');

  static String teachingScoreLine(int correct, int total) =>
      TextService.getString('Animals', 'teachingScoreLine')
          .replaceAll('{correct}', '$correct')
          .replaceAll('{total}', '$total');

  static String selectAllTargetFor(String animal) =>
      TextService.getString('Animals', 'selectAllTarget')
          .replaceAll('{animal}', animal);

  static String submitTeachingCount(int n) =>
      TextService.getString('Animals', 'submitTeachingCount')
          .replaceAll('{count}', '$n');

  static String roundCompleteTitleFor(int round) =>
      TextService.getString('Animals', 'roundCompleteTitle')
          .replaceAll('{round}', '$round');
}

/// Accessors for 'Drawing' texts
class Drawing {
  static String get title => TextService.getString('Drawing', 'title');
  static String get subtitle => TextService.getString('Drawing', 'subtitle');
  static String get instruction => TextService.getString('Drawing', 'instruction');
  static String get thinking => TextService.getString('Drawing', 'thinking');
  static String get analyzingMessage => TextService.getString('Drawing', 'analyzingMessage');
  static String get clear => TextService.getString('Drawing', 'clear');
  static String get checkDrawing => TextService.getString('Drawing', 'checkDrawing');
  static String get successTitle => TextService.getString('Drawing', 'successTitle');
  static String get successEmoji => TextService.getString('Drawing', 'successEmoji');
  static String get successMessage => TextService.getString('Drawing', 'successMessage');
  static String get almostTitle => TextService.getString('Drawing', 'almostTitle');
  static String get wrongShapeHint => TextService.getString('Drawing', 'wrongShapeHint');
  static String get wrongColorHint => TextService.getString('Drawing', 'wrongColorHint');
  static String get tryAgain => TextService.getString('Drawing', 'tryAgain');
  static String get continueAction => TextService.getString('Drawing', 'continueAction');
  static String get drawFirst => TextService.getString('Drawing', 'drawFirst');
  static String get captureError => TextService.getString('Drawing', 'captureError');
  static String get checkDrawingSparkle =>
      TextService.getString('Drawing', 'checkDrawingSparkle');
  static String get missionDrawShapes =>
      TextService.getString('Drawing', 'missionDrawShapes');
  static String get roundCaption => TextService.getString('Drawing', 'roundCaption');
  static String get thinkingTitle => TextService.getString('Drawing', 'thinkingTitle');
  static String get nextRound => TextService.getString('Drawing', 'nextRound');
  static String get missionCompleteButton =>
      TextService.getString('Drawing', 'missionCompleteButton');
  static String get shapeTriangle => TextService.getString('Drawing', 'shapeTriangle');
  static String get shapeCircle => TextService.getString('Drawing', 'shapeCircle');
  static String get shapeSquare => TextService.getString('Drawing', 'shapeSquare');
  static String get colorNameBlue => TextService.getString('Drawing', 'colorNameBlue');
  static String get colorNameRed => TextService.getString('Drawing', 'colorNameRed');
  static String get colorNameGreen => TextService.getString('Drawing', 'colorNameGreen');
  static String get drawPromptPart1 => TextService.getString('Drawing', 'drawPromptPart1');
  static String get drawPromptPart2 => TextService.getString('Drawing', 'drawPromptPart2');
  static String get drawPromptPart3 => TextService.getString('Drawing', 'drawPromptPart3');
  static String get colorCircleTitle => TextService.getString('Drawing', 'colorCircleTitle');
  static String get colorCircleInstruction =>
      TextService.getString('Drawing', 'colorCircleInstruction');
  static String get colorCircleThinking =>
      TextService.getString('Drawing', 'colorCircleThinking');
  static String get colorCircleAnalyzingSub =>
      TextService.getString('Drawing', 'colorCircleAnalyzingSub');
  static String get pixyCheckingTitle =>
      TextService.getString('Drawing', 'pixyCheckingTitle');
  static String get checkColoringSparkle =>
      TextService.getString('Drawing', 'checkColoringSparkle');
  static String get resultPerfect => TextService.getString('Drawing', 'resultPerfect');
  static String get colorCircleFirst => TextService.getString('Drawing', 'colorCircleFirst');
}

/// Accessors for 'GroupingSorting' texts
class GroupingSorting {
  static String get title => TextService.getString('GroupingSorting', 'title');
  static String get subtitle => TextService.getString('GroupingSorting', 'subtitle');
  static String get instruction => TextService.getString('GroupingSorting', 'instruction');
  static String get submit => TextService.getString('GroupingSorting', 'submit');
  static String get submitWithCheck =>
      TextService.getString('GroupingSorting', 'submitWithCheck');
  static String get allSorted => TextService.getString('GroupingSorting', 'allSorted');
  static String get tapSubmitHint =>
      TextService.getString('GroupingSorting', 'tapSubmitHint');
  static String get missionComplete => TextService.getString('GroupingSorting', 'missionComplete');
  static String get tryAgain => TextService.getString('GroupingSorting', 'tryAgain');
  static String get continueAction => TextService.getString('GroupingSorting', 'continueAction');
  static String get continueExcited =>
      TextService.getString('GroupingSorting', 'continueExcited');
  static String get tryAgainStrong =>
      TextService.getString('GroupingSorting', 'tryAgainStrong');
  static String get loadingItems => TextService.getString('GroupingSorting', 'loadingItems');
  static String get dropHere => TextService.getString('GroupingSorting', 'dropHere');
  static String get itemsToSort => TextService.getString('GroupingSorting', 'itemsToSort');
  static String get statAccuracy => TextService.getString('GroupingSorting', 'statAccuracy');
  static String get statTime => TextService.getString('GroupingSorting', 'statTime');
  static String get statCorrect => TextService.getString('GroupingSorting', 'statCorrect');
  static String get masteredMessage =>
      TextService.getString('GroupingSorting', 'masteredMessage');
  static String get backToMissions =>
      TextService.getString('GroupingSorting', 'backToMissions');
  static String get errorTitle => TextService.getString('GroupingSorting', 'errorTitle');
  static String get unknownError => TextService.getString('GroupingSorting', 'unknownError');

  static String roundOf(int current, int total) =>
      TextService.getString('GroupingSorting', 'roundOf')
          .replaceAll('{current}', '$current')
          .replaceAll('{total}', '$total');

  static String sortedProgress(int current, int total) =>
      TextService.getString('GroupingSorting', 'sortedProgress')
          .replaceAll('{current}', '$current')
          .replaceAll('{total}', '$total');

  static String motivationalLine(int index) {
    final keys = ['moti1', 'moti2', 'moti3', 'moti4', 'moti5', 'moti6'];
    return TextService.getString('GroupingSorting', keys[index % keys.length]);
  }
}

/// Accessors for 'Vocabulary' texts
class Vocabulary {
  static String get title => TextService.getString('Vocabulary', 'title');
  static String get subtitle => TextService.getString('Vocabulary', 'subtitle');
  static String get submitAnswer => TextService.getString('Vocabulary', 'submitAnswer');
  static String get nextWord => TextService.getString('Vocabulary', 'nextWord');
  static String get missionComplete => TextService.getString('Vocabulary', 'missionComplete');
  static String get tryAgain => TextService.getString('Vocabulary', 'tryAgain');
  static String get seeResults => TextService.getString('Vocabulary', 'seeResults');
}

/// Accessors for 'DescribeImage' texts
class DescribeImage {
  static String get title => TextService.getString('DescribeImage', 'title');
  static String get instruction => TextService.getString('DescribeImage', 'instruction');
  static String get tapToRecord => TextService.getString('DescribeImage', 'tapToRecord');
  static String get listening => TextService.getString('DescribeImage', 'listening');
  static String get processing => TextService.getString('DescribeImage', 'processing');
  static String get youSaid => TextService.getString('DescribeImage', 'youSaid');
}

/// Accessors for 'PatternMission' texts
class PatternMission {
  static String get title => TextService.getString('PatternMission', 'title');
  static String get instruction => TextService.getString('PatternMission', 'instruction');
  static String get chooseNext => TextService.getString('PatternMission', 'chooseNext');
  static String get checkAnswer => TextService.getString('PatternMission', 'checkAnswer');
  static String get nextPattern => TextService.getString('PatternMission', 'nextPattern');
  static String get tryAgain => TextService.getString('PatternMission', 'tryAgain');
}

/// Accessors for 'Common' texts (shared across features)
class Common {
  static String get retry => TextService.getString('Common', 'retry');
  static String get tryAgain => TextService.getString('Common', 'tryAgain');
  static String get close => TextService.getString('Common', 'close');
  static String get cancel => TextService.getString('Common', 'cancel');
  static String get confirm => TextService.getString('Common', 'confirm');
  static String get backToMissions => TextService.getString('Common', 'backToMissions');
  static String get loading => TextService.getString('Common', 'loading');
  static String get error => TextService.getString('Common', 'error');
  static String get success => TextService.getString('Common', 'success');
  static String get missionComplete => TextService.getString('Common', 'missionComplete');
  static String get comingSoon => TextService.getString('Common', 'comingSoon');
  static String get networkError => TextService.getString('Common', 'networkError');
  static String get connectionTimeout => TextService.getString('Common', 'connectionTimeout');
  static String get sessionExpired => TextService.getString('Common', 'sessionExpired');
  static String get serverError => TextService.getString('Common', 'serverError');
  static String get offlineMissionBody =>
      TextService.getString('Common', 'offlineMissionBody');
}

/// Accessors for 'Profile' texts
class ProfileTexts {
  static String get title => TextService.getString('Profile', 'title');
  static String get settings => TextService.getString('Profile', 'settings');
  static String get language => TextService.getString('Profile', 'language');
  static String get english => TextService.getString('Profile', 'english');
  static String get romanian => TextService.getString('Profile', 'romanian');
  static String get logout => TextService.getString('Profile', 'logout');
  static String get logoutConfirm => TextService.getString('Profile', 'logoutConfirm');
  static String get aboutThinky => TextService.getString('Profile', 'aboutThinky');
  static String get helpFaq => TextService.getString('Profile', 'helpFaq');
  static String get darkMode => TextService.getString('Profile', 'darkMode');
  static String get guest => TextService.getString('Profile', 'guest');
  static String get user => TextService.getString('Profile', 'user');
}

/// Accessors for 'Workshop' texts
class WorkshopTexts {
  static String get title => TextService.getString('Workshop', 'title');
  static String get myMissions => TextService.getString('Workshop', 'myMissions');
  static String get createMission => TextService.getString('Workshop', 'createMission');
  static String get missionPublished => TextService.getString('Workshop', 'missionPublished');
  static String get searchMissions => TextService.getString('Workshop', 'searchMissions');
  static String get downloadSuccess => TextService.getString('Workshop', 'downloadSuccess');
  static String get downloadFailed => TextService.getString('Workshop', 'downloadFailed');
  static String get lockedSubtitle => TextService.getString('Workshop', 'lockedSubtitle');
  static String get loginButton => TextService.getString('Workshop', 'loginButton');
  static String get createAccountButton => TextService.getString('Workshop', 'createAccountButton');
  static String get create => TextService.getString('Workshop', 'create');
  static String get discoverSubtitle => TextService.getString('Workshop', 'discoverSubtitle');
  static String get couldNotLoad => TextService.getString('Workshop', 'couldNotLoad');
  static String get couldNotLoadMission => TextService.getString('Workshop', 'couldNotLoadMission');
  static String get noMissions => TextService.getString('Workshop', 'noMissions');
  static String get beFirst => TextService.getString('Workshop', 'beFirst');
  static String get recent => TextService.getString('Workshop', 'recent');
  static String get popular => TextService.getString('Workshop', 'popular');
  static String get missionNotFound => TextService.getString('Workshop', 'missionNotFound');
  static String get seeResults => TextService.getString('Workshop', 'seeResults');
  static String get nextQuestion => TextService.getString('Workshop', 'nextQuestion');
  static String get playAgain => TextService.getString('Workshop', 'playAgain');
  static String get perfect => TextService.getString('Workshop', 'perfect');
  static String get quizComplete => TextService.getString('Workshop', 'quizComplete');
  static String get downloading => TextService.getString('Workshop', 'downloading');
  static String get playQuiz => TextService.getString('Workshop', 'playQuiz');
  static String get downloadMissionButton => TextService.getString('Workshop', 'downloadMissionButton');
  static String get questionsCount => TextService.getString('Workshop', 'questionsCount');
  static String get questionLabel => TextService.getString('Workshop', 'questionLabel');
  static String get byAuthor => TextService.getString('Workshop', 'byAuthor');
  static String get correct => TextService.getString('Workshop', 'correct');
  static String get couldNotLoadYourMissions => TextService.getString('Workshop', 'couldNotLoadYourMissions');
  static String get noMissionsCreated => TextService.getString('Workshop', 'noMissionsCreated');
  static String get createFirstMission => TextService.getString('Workshop', 'createFirstMission');
  static String get questionTextEmpty => TextService.getString('Workshop', 'questionTextEmpty');
  static String get questionNeedsAnswers => TextService.getString('Workshop', 'questionNeedsAnswers');
  static String get questionSelectCorrect => TextService.getString('Workshop', 'questionSelectCorrect');
  static String get missionTitle => TextService.getString('Workshop', 'missionTitle');
  static String get missionTitleHint => TextService.getString('Workshop', 'missionTitleHint');
  static String get missionTitleError => TextService.getString('Workshop', 'missionTitleError');
  static String get description => TextService.getString('Workshop', 'description');
  static String get descriptionHint => TextService.getString('Workshop', 'descriptionHint');
  static String get tags => TextService.getString('Workshop', 'tags');
  static String get tagsHint => TextService.getString('Workshop', 'tagsHint');
  static String get questions => TextService.getString('Workshop', 'questions');
  static String get addQuestion => TextService.getString('Workshop', 'addQuestion');
  static String get publishing => TextService.getString('Workshop', 'publishing');
  static String get publishButton => TextService.getString('Workshop', 'publishButton');
  static String get questionHint => TextService.getString('Workshop', 'questionHint');
  static String get answersLabel => TextService.getString('Workshop', 'answersLabel');
  static String get answerHint => TextService.getString('Workshop', 'answerHint');
  static String get addAnswer => TextService.getString('Workshop', 'addAnswer');
  static String get missionPublishedMsg => TextService.getString('Workshop', 'missionPublished');
  static String get noDownloaded => TextService.getString('Workshop', 'noDownloaded');
  static String get browseWorkshop => TextService.getString('Workshop', 'browseWorkshop');
}

/// Accessors for 'Nav' texts (bottom navigation bar)
class Nav {
  static String get missions => TextService.getString('Nav', 'missions');
  static String get workshop => TextService.getString('Nav', 'workshop');
  static String get profile => TextService.getString('Nav', 'profile');
  static String get missionsTab => TextService.getString('Nav', 'missionsTab');
  static String get leaderboard => TextService.getString('Nav', 'leaderboard');
  static String get mascotChat => TextService.getString('Nav', 'mascotChat');
}

/// Localized display titles for missions menu cards (by API `mission_path`).
class MissionTitles {
  static String forPath(String? path, String apiFallback) {
    if (path == null || path.isEmpty) return apiFallback;
    final v = TextService.getString('MissionTitles', path);
    if (v.startsWith('MissionTitles.')) return apiFallback;
    return v;
  }
}

class LeaderboardTexts {
  static String get title => TextService.getString('Leaderboard', 'title');
  static String get subtitle => TextService.getString('Leaderboard', 'subtitle');
  static String get includeWorkshop =>
      TextService.getString('Leaderboard', 'includeWorkshop');
  static String get noPlayers => TextService.getString('Leaderboard', 'noPlayers');
  static String get noPlayersSubtitle =>
      TextService.getString('Leaderboard', 'noPlayersSubtitle');
  static String get couldNotLoad =>
      TextService.getString('Leaderboard', 'couldNotLoad');
  static String get globalStats =>
      TextService.getString('Leaderboard', 'globalStats');
  static String get players => TextService.getString('Leaderboard', 'players');
  static String get avgPoints => TextService.getString('Leaderboard', 'avgPoints');
  static String get min => TextService.getString('Leaderboard', 'min');
  static String get avg => TextService.getString('Leaderboard', 'avg');
  static String get max => TextService.getString('Leaderboard', 'max');
  static String get missionsLabel =>
      TextService.getString('Leaderboard', 'missionsLabel');
  static String get workshopLabel =>
      TextService.getString('Leaderboard', 'workshopLabel');
  static String get pointsGuideTitle =>
      TextService.getString('Leaderboard', 'pointsGuideTitle');
  static String get pointsGuideBody =>
      TextService.getString('Leaderboard', 'pointsGuideBody');
  static String get ptsSuffix => TextService.getString('Leaderboard', 'ptsSuffix');
}

class AboutTexts {
  static String get title => TextService.getString('About', 'title');
  static String get appName => TextService.getString('About', 'appName');
  static String get tagline => TextService.getString('About', 'tagline');
  static String get missionTitle => TextService.getString('About', 'missionTitle');
  static String get missionBody => TextService.getString('About', 'missionBody');
  static String get objectivesTitle =>
      TextService.getString('About', 'objectivesTitle');
  static String get objective1 => TextService.getString('About', 'objective1');
  static String get objective2 => TextService.getString('About', 'objective2');
  static String get objective3 => TextService.getString('About', 'objective3');
  static String get featuresTitle =>
      TextService.getString('About', 'featuresTitle');
  static String get feature1 => TextService.getString('About', 'feature1');
  static String get feature2 => TextService.getString('About', 'feature2');
  static String get feature3 => TextService.getString('About', 'feature3');
  static String get feature4 => TextService.getString('About', 'feature4');
  static String get madeWith => TextService.getString('About', 'madeWith');
  static String get copyright => TextService.getString('About', 'copyright');
}

class HelpTexts {
  static String get title => TextService.getString('Help', 'title');
  static String get faqTitle => TextService.getString('Help', 'faqTitle');
  static String get faqSubtitle => TextService.getString('Help', 'faqSubtitle');
  static String faqQuestion(int i) => TextService.getString('Help', 'faq${i}Q');
  static String faqAnswer(int i) => TextService.getString('Help', 'faq${i}A');
}

class PixyLearnsTexts {
  static String get preparingLessons =>
      TextService.getString('PixyLearns', 'preparingLessons');
  static String get introTitle => TextService.getString('PixyLearns', 'introTitle');
  static String get introBody => TextService.getString('PixyLearns', 'introBody');
  static String get pillImages => TextService.getString('PixyLearns', 'pillImages');
  static String get pillCategories =>
      TextService.getString('PixyLearns', 'pillCategories');
  static String get pillAi => TextService.getString('PixyLearns', 'pillAi');
  static String get startTeaching =>
      TextService.getString('PixyLearns', 'startTeaching');
  static String get chapter1 => TextService.getString('PixyLearns', 'chapter1');
  static String get learningProgress =>
      TextService.getString('PixyLearns', 'learningProgress');
  static String get teachPixyHeader =>
      TextService.getString('PixyLearns', 'teachPixyHeader');
  static String get teachPixyHint =>
      TextService.getString('PixyLearns', 'teachPixyHint');
  static String get labelApple => TextService.getString('PixyLearns', 'labelApple');
  static String get labelCat => TextService.getString('PixyLearns', 'labelCat');
  static String get imageUnavailable =>
      TextService.getString('PixyLearns', 'imageUnavailable');
  static String get teachPixyCta =>
      TextService.getString('PixyLearns', 'teachPixyCta');
  static String get amazingJob => TextService.getString('PixyLearns', 'amazingJob');
  static String learnedExamples(int count) => TextService.getString(
        'PixyLearns',
        'learnedExamples',
      ).replaceAll('{count}', '$count');
  static String categoriesLine(String list) => TextService.getString(
        'PixyLearns',
        'categoriesLine',
      ).replaceAll('{list}', list);
  static String get aiExplanation =>
      TextService.getString('PixyLearns', 'aiExplanation');
  static String get continueMissions =>
      TextService.getString('PixyLearns', 'continueMissions');
}

class MascotTexts {
  static String get inputHint => TextService.getString('Mascot', 'inputHint');
  static String get greeting => TextService.getString('Mascot', 'greeting');
  static String get title => TextService.getString('Mascot', 'title');
  static String get subtitle => TextService.getString('Mascot', 'subtitle');
  static String get typing => TextService.getString('Mascot', 'typing');
  static String get suggest1 => TextService.getString('Mascot', 'suggest1');
  static String get suggest2 => TextService.getString('Mascot', 'suggest2');
  static String get suggest3 => TextService.getString('Mascot', 'suggest3');
}
