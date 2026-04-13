import 'package:thinky/core_controls/features/missions/mission_numbers/domain/numbers_models.dart';
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
  static String get resultHelperTextHigh =>
      TextService.getString('Quiz', 'resultHelperTextHigh');
  static String get resultHelperTextMid =>
      TextService.getString('Quiz', 'resultHelperTextMid');
  static String get resultHelperTextLow =>
      TextService.getString('Quiz', 'resultHelperTextLow');
  static String get resultOutOf => TextService.getString('Quiz', 'resultOutOf');
  static String get resultCorrect => TextService.getString('Quiz', 'resultCorrect');
  static String get showDetailedResults => TextService.getString('Quiz', 'showDetailedResults');
  static String get continueToMissions => TextService.getString('Quiz', 'continueToMissions');
  static String get missionHintLine => TextService.getString('Quiz', 'missionHintLine');
  static String get reviewTitle => TextService.getString('Quiz', 'reviewTitle');
  static String get reviewSubtitle => TextService.getString('Quiz', 'reviewSubtitle');
  static String get yourAnswerLabel => TextService.getString('Quiz', 'yourAnswerLabel');
  static String get correctAnswerLabel => TextService.getString('Quiz', 'correctAnswerLabel');
  static String get backToSummary => TextService.getString('Quiz', 'backToSummary');
  static String get notAnsweredLabel => TextService.getString('Quiz', 'notAnsweredLabel');
  static String get reviewCorrectBadge =>
      TextService.getString('Quiz', 'reviewCorrectBadge');
  static String get reviewMissedBadge =>
      TextService.getString('Quiz', 'reviewMissedBadge');
  static String get startNextMission =>
      TextService.getString('Quiz', 'startNextMission');
  static String get badgeUnlockedSummary =>
      TextService.getString('Quiz', 'badgeUnlockedSummary');
  static String get summaryCorrectRow =>
      TextService.getString('Quiz', 'summaryCorrectRow');
  static String get summaryWrongRow =>
      TextService.getString('Quiz', 'summaryWrongRow');
  static String get keepImprovingSummary =>
      TextService.getString('Quiz', 'keepImprovingSummary');

  static String xpEarnedLine(int points) =>
      TextService.getString('Quiz', 'xpEarned').replaceAll('{points}', '$points');

  static String get lessonButton =>
      TextService.getString('Quiz', 'lessonButton');
  static String get lessonNext =>
      TextService.getString('Quiz', 'lessonNext');
  static String get lessonDone =>
      TextService.getString('Quiz', 'lessonDone');
  static String get lessonCard1Title =>
      TextService.getString('Quiz', 'lessonCard1Title');
  static String get lessonCard1Body =>
      TextService.getString('Quiz', 'lessonCard1Body');
  static String get lessonCard1Fact =>
      TextService.getString('Quiz', 'lessonCard1Fact');
  static String get lessonCard2Title =>
      TextService.getString('Quiz', 'lessonCard2Title');
  static String get lessonCard2Body =>
      TextService.getString('Quiz', 'lessonCard2Body');
  static String get lessonCard2Fact =>
      TextService.getString('Quiz', 'lessonCard2Fact');
  static String get lessonCard3Title =>
      TextService.getString('Quiz', 'lessonCard3Title');
  static String get lessonCard3Body =>
      TextService.getString('Quiz', 'lessonCard3Body');
  static String get lessonCard3Fact =>
      TextService.getString('Quiz', 'lessonCard3Fact');
  static String get lessonCard4Title =>
      TextService.getString('Quiz', 'lessonCard4Title');
  static String get lessonCard4Body =>
      TextService.getString('Quiz', 'lessonCard4Body');
  static String get lessonCard4Fact =>
      TextService.getString('Quiz', 'lessonCard4Fact');
  static String get lessonCard5Title =>
      TextService.getString('Quiz', 'lessonCard5Title');
  static String get lessonCard5Body =>
      TextService.getString('Quiz', 'lessonCard5Body');
  static String get lessonCard5Fact =>
      TextService.getString('Quiz', 'lessonCard5Fact');
  static String get lessonDidYouKnow =>
      TextService.getString('Quiz', 'lessonDidYouKnow');
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

  static String get lessonButton => TextService.getString('Animals', 'lessonButton');
  static String get lessonNext => TextService.getString('Animals', 'lessonNext');
  static String get lessonDidYouKnow => TextService.getString('Animals', 'lessonDidYouKnow');
  static String get backToResults => TextService.getString('Animals', 'backToResults');
  static String get lessonCard1Title => TextService.getString('Animals', 'lessonCard1Title');
  static String get lessonCard1Body => TextService.getString('Animals', 'lessonCard1Body');
  static String get lessonCard1Fact => TextService.getString('Animals', 'lessonCard1Fact');
  static String get lessonCard2Title => TextService.getString('Animals', 'lessonCard2Title');
  static String get lessonCard2Body => TextService.getString('Animals', 'lessonCard2Body');
  static String get lessonCard2Fact => TextService.getString('Animals', 'lessonCard2Fact');
  static String get lessonCard3Title => TextService.getString('Animals', 'lessonCard3Title');
  static String get lessonCard3Body => TextService.getString('Animals', 'lessonCard3Body');
  static String get lessonCard3Fact => TextService.getString('Animals', 'lessonCard3Fact');
  static String get lessonCard4Title => TextService.getString('Animals', 'lessonCard4Title');
  static String get lessonCard4Body => TextService.getString('Animals', 'lessonCard4Body');
  static String get lessonCard4Fact => TextService.getString('Animals', 'lessonCard4Fact');
  static String get lessonCard5Title => TextService.getString('Animals', 'lessonCard5Title');
  static String get lessonCard5Body => TextService.getString('Animals', 'lessonCard5Body');
  static String get lessonCard5Fact => TextService.getString('Animals', 'lessonCard5Fact');
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

  // Draw Shapes learning
  static String get shapesLessonButton => TextService.getString('Drawing', 'shapesLessonButton');
  static String get shapesLessonNext => TextService.getString('Drawing', 'shapesLessonNext');
  static String get shapesLessonDidYouKnow => TextService.getString('Drawing', 'shapesLessonDidYouKnow');
  static String get shapesBackToResults => TextService.getString('Drawing', 'shapesBackToResults');
  static String get shapesBackToMissions => TextService.getString('Drawing', 'shapesBackToMissions');
  static String get shapesLessonCard1Title => TextService.getString('Drawing', 'shapesLessonCard1Title');
  static String get shapesLessonCard1Body => TextService.getString('Drawing', 'shapesLessonCard1Body');
  static String get shapesLessonCard1Fact => TextService.getString('Drawing', 'shapesLessonCard1Fact');
  static String get shapesLessonCard2Title => TextService.getString('Drawing', 'shapesLessonCard2Title');
  static String get shapesLessonCard2Body => TextService.getString('Drawing', 'shapesLessonCard2Body');
  static String get shapesLessonCard2Fact => TextService.getString('Drawing', 'shapesLessonCard2Fact');
  static String get shapesLessonCard3Title => TextService.getString('Drawing', 'shapesLessonCard3Title');
  static String get shapesLessonCard3Body => TextService.getString('Drawing', 'shapesLessonCard3Body');
  static String get shapesLessonCard3Fact => TextService.getString('Drawing', 'shapesLessonCard3Fact');
  static String get shapesLessonCard4Title => TextService.getString('Drawing', 'shapesLessonCard4Title');
  static String get shapesLessonCard4Body => TextService.getString('Drawing', 'shapesLessonCard4Body');
  static String get shapesLessonCard4Fact => TextService.getString('Drawing', 'shapesLessonCard4Fact');
  static String get shapesLessonCard5Title => TextService.getString('Drawing', 'shapesLessonCard5Title');
  static String get shapesLessonCard5Body => TextService.getString('Drawing', 'shapesLessonCard5Body');
  static String get shapesLessonCard5Fact => TextService.getString('Drawing', 'shapesLessonCard5Fact');

  // Color Circle learning
  static String get colorLessonButton => TextService.getString('Drawing', 'colorLessonButton');
  static String get colorLessonNext => TextService.getString('Drawing', 'colorLessonNext');
  static String get colorLessonDidYouKnow => TextService.getString('Drawing', 'colorLessonDidYouKnow');
  static String get colorBackToResults => TextService.getString('Drawing', 'colorBackToResults');
  static String get colorBackToMissions => TextService.getString('Drawing', 'colorBackToMissions');
  static String get colorLessonCard1Title => TextService.getString('Drawing', 'colorLessonCard1Title');
  static String get colorLessonCard1Body => TextService.getString('Drawing', 'colorLessonCard1Body');
  static String get colorLessonCard1Fact => TextService.getString('Drawing', 'colorLessonCard1Fact');
  static String get colorLessonCard2Title => TextService.getString('Drawing', 'colorLessonCard2Title');
  static String get colorLessonCard2Body => TextService.getString('Drawing', 'colorLessonCard2Body');
  static String get colorLessonCard2Fact => TextService.getString('Drawing', 'colorLessonCard2Fact');
  static String get colorLessonCard3Title => TextService.getString('Drawing', 'colorLessonCard3Title');
  static String get colorLessonCard3Body => TextService.getString('Drawing', 'colorLessonCard3Body');
  static String get colorLessonCard3Fact => TextService.getString('Drawing', 'colorLessonCard3Fact');
  static String get colorLessonCard4Title => TextService.getString('Drawing', 'colorLessonCard4Title');
  static String get colorLessonCard4Body => TextService.getString('Drawing', 'colorLessonCard4Body');
  static String get colorLessonCard4Fact => TextService.getString('Drawing', 'colorLessonCard4Fact');
  static String get colorLessonCard5Title => TextService.getString('Drawing', 'colorLessonCard5Title');
  static String get colorLessonCard5Body => TextService.getString('Drawing', 'colorLessonCard5Body');
  static String get colorLessonCard5Fact => TextService.getString('Drawing', 'colorLessonCard5Fact');
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

  static String get lessonButton => TextService.getString('GroupingSorting', 'lessonButton');
  static String get lessonNext => TextService.getString('GroupingSorting', 'lessonNext');
  static String get lessonDidYouKnow => TextService.getString('GroupingSorting', 'lessonDidYouKnow');
  static String get backToResults => TextService.getString('GroupingSorting', 'backToResults');
  static String get lessonCard1Title => TextService.getString('GroupingSorting', 'lessonCard1Title');
  static String get lessonCard1Body => TextService.getString('GroupingSorting', 'lessonCard1Body');
  static String get lessonCard1Fact => TextService.getString('GroupingSorting', 'lessonCard1Fact');
  static String get lessonCard2Title => TextService.getString('GroupingSorting', 'lessonCard2Title');
  static String get lessonCard2Body => TextService.getString('GroupingSorting', 'lessonCard2Body');
  static String get lessonCard2Fact => TextService.getString('GroupingSorting', 'lessonCard2Fact');
  static String get lessonCard3Title => TextService.getString('GroupingSorting', 'lessonCard3Title');
  static String get lessonCard3Body => TextService.getString('GroupingSorting', 'lessonCard3Body');
  static String get lessonCard3Fact => TextService.getString('GroupingSorting', 'lessonCard3Fact');
  static String get lessonCard4Title => TextService.getString('GroupingSorting', 'lessonCard4Title');
  static String get lessonCard4Body => TextService.getString('GroupingSorting', 'lessonCard4Body');
  static String get lessonCard4Fact => TextService.getString('GroupingSorting', 'lessonCard4Fact');
  static String get lessonCard5Title => TextService.getString('GroupingSorting', 'lessonCard5Title');
  static String get lessonCard5Body => TextService.getString('GroupingSorting', 'lessonCard5Body');
  static String get lessonCard5Fact => TextService.getString('GroupingSorting', 'lessonCard5Fact');
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
  static String get loadingWords => TextService.getString('Vocabulary', 'loadingWords');
  static String get submittingShort => TextService.getString('Vocabulary', 'submittingShort');
  static String get findMatchingImage => TextService.getString('Vocabulary', 'findMatchingImage');
  static String get correctImageCaption => TextService.getString('Vocabulary', 'correctImageCaption');
  static String get statAccuracy => TextService.getString('Vocabulary', 'statAccuracy');
  static String get statCorrect => TextService.getString('Vocabulary', 'statCorrect');
  static String get completeLineHigh => TextService.getString('Vocabulary', 'completeLineHigh');
  static String get completeLineMid => TextService.getString('Vocabulary', 'completeLineMid');
  static String get completeLineLow => TextService.getString('Vocabulary', 'completeLineLow');
  static String get seeResultsWithTrophy => TextService.getString('Vocabulary', 'seeResultsWithTrophy');
  static String get nextWordArrow => TextService.getString('Vocabulary', 'nextWordArrow');
  static String get imageError => TextService.getString('Vocabulary', 'imageError');
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
  static String get loadingPattern => TextService.getString('PatternMission', 'loadingPattern');
  static String get missionCompleteTitle =>
      TextService.getString('PatternMission', 'missionCompleteTitle');
  static String get backToMenu => TextService.getString('PatternMission', 'backToMenu');
}

/// Accessors for 'NumbersMission' texts
class NumbersMission {
  static String get loadingPreparing =>
      TextService.getString('NumbersMission', 'loadingPreparing');
  static String get introTitle => TextService.getString('NumbersMission', 'introTitle');
  static String get introBody => TextService.getString('NumbersMission', 'introBody');
  static String get featureNumbers => TextService.getString('NumbersMission', 'featureNumbers');
  static String get featureDraw => TextService.getString('NumbersMission', 'featureDraw');
  static String get featureLevels => TextService.getString('NumbersMission', 'featureLevels');
  static String get startAdventure => TextService.getString('NumbersMission', 'startAdventure');
  static String get appBarTitle => TextService.getString('NumbersMission', 'appBarTitle');
  static String get completionCongrats =>
      TextService.getString('NumbersMission', 'completionCongrats');
  static String get completionTitle => TextService.getString('NumbersMission', 'completionTitle');
  static String get completionBody => TextService.getString('NumbersMission', 'completionBody');
  static String get badgeJunior => TextService.getString('NumbersMission', 'badgeJunior');
  static String get badgeStudent => TextService.getString('NumbersMission', 'badgeStudent');
  static String get badgeExpert => TextService.getString('NumbersMission', 'badgeExpert');
  static String get backToMissionsCaps =>
      TextService.getString('NumbersMission', 'backToMissionsCaps');
  static String get part1Title => TextService.getString('NumbersMission', 'part1Title');
  static String get part2Title => TextService.getString('NumbersMission', 'part2Title');
  static String get howManyObjects => TextService.getString('NumbersMission', 'howManyObjects');
  static String get chooseCorrectNumber =>
      TextService.getString('NumbersMission', 'chooseCorrectNumber');
  static String get confirmPixy => TextService.getString('NumbersMission', 'confirmPixy');
  static String get send => TextService.getString('NumbersMission', 'send');
  static String get resultCorrect => TextService.getString('NumbersMission', 'resultCorrect');
  static String get nextRound => TextService.getString('NumbersMission', 'nextRound');
  static String get transitionTitle => TextService.getString('NumbersMission', 'transitionTitle');
  static String get transitionSubtitle =>
      TextService.getString('NumbersMission', 'transitionSubtitle');
  static String get goToDrawing => TextService.getString('NumbersMission', 'goToDrawing');
  static String get professorSays => TextService.getString('NumbersMission', 'professorSays');
  static String get professorUnderstood =>
      TextService.getString('NumbersMission', 'professorUnderstood');
  static String get upgradeTitle => TextService.getString('NumbersMission', 'upgradeTitle');
  static String get upgradeSubtitle => TextService.getString('NumbersMission', 'upgradeSubtitle');
  static String get continueCaps => TextService.getString('NumbersMission', 'continueCaps');
  static String get drawDigitHint => TextService.getString('NumbersMission', 'drawDigitHint');
  static String get pixyDrawPrompt => TextService.getString('NumbersMission', 'pixyDrawPrompt');
  static String get clear => TextService.getString('NumbersMission', 'clear');
  static String get analyzing => TextService.getString('NumbersMission', 'analyzing');
  static String get sendToPixy => TextService.getString('NumbersMission', 'sendToPixy');
  static String get drawingRecognized =>
      TextService.getString('NumbersMission', 'drawingRecognized');
  static String get nextDigit => TextService.getString('NumbersMission', 'nextDigit');
  static String get upgradeDrawingSubtitle =>
      TextService.getString('NumbersMission', 'upgradeDrawingSubtitle');
  static String get levelJunior => TextService.getString('NumbersMission', 'levelJunior');
  static String get levelStudent => TextService.getString('NumbersMission', 'levelStudent');
  static String get levelExpert => TextService.getString('NumbersMission', 'levelExpert');

  static String levelLine(String levelName, String emoji) =>
      TextService.getString('NumbersMission', 'levelLine')
          .replaceAll('{level}', levelName)
          .replaceAll('{emoji}', emoji);

  static String progressUpgrade(int correct) =>
      TextService.getString('NumbersMission', 'progressUpgrade')
          .replaceAll('{correct}', '$correct');

  static String resultWrongAnswer(String answer) =>
      TextService.getString('NumbersMission', 'resultWrong').replaceAll('{answer}', answer);

  static String drawTheDigit(int n) =>
      TextService.getString('NumbersMission', 'drawTheDigit').replaceAll('{n}', '$n');

  static String drawingGuessed(String digit) =>
      TextService.getString('NumbersMission', 'drawingGuessed').replaceAll('{digit}', digit);

  static String confidencePercent(int percent) =>
      TextService.getString('NumbersMission', 'confidencePercent')
          .replaceAll('{percent}', '$percent');

  static String upgradeLevelLine(String emoji, String level) =>
      TextService.getString('NumbersMission', 'upgradeLevel')
          .replaceAll('{emoji}', emoji)
          .replaceAll('{level}', level);

  static String modelLevelName(PixyModelLevel level) {
    switch (level) {
      case PixyModelLevel.junior:
        return levelJunior;
      case PixyModelLevel.student:
        return levelStudent;
      case PixyModelLevel.expert:
        return levelExpert;
    }
  }
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
  static String get totalXp => TextService.getString('Profile', 'totalXp');
  static String get rank => TextService.getString('Profile', 'rank');
  static String get outOf => TextService.getString('Profile', 'outOf');
  static String get noXpYet => TextService.getString('Profile', 'noXpYet');
  static String get xpBreakdown => TextService.getString('Profile', 'xpBreakdown');
  static String get missionPixyLearns => TextService.getString('Profile', 'missionPixyLearns');
  static String get missionAnimals => TextService.getString('Profile', 'missionAnimals');
  static String get missionDrawShapes => TextService.getString('Profile', 'missionDrawShapes');
  static String get missionColorCircle => TextService.getString('Profile', 'missionColorCircle');
  static String get missionGroupImages => TextService.getString('Profile', 'missionGroupImages');
  static String get missionWorkshop => TextService.getString('Profile', 'missionWorkshop');
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
  static String get verifiedBadge => TextService.getString('Workshop', 'verifiedBadge');
  static String get verifiedHint => TextService.getString('Workshop', 'verifiedHint');
  static String get adminMarkVerified =>
      TextService.getString('Workshop', 'adminMarkVerified');
  static String get verificationUpdated =>
      TextService.getString('Workshop', 'verificationUpdated');
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
  static String get avgXp => TextService.getString('Leaderboard', 'avgXp');
  static String get min => TextService.getString('Leaderboard', 'min');
  static String get avg => TextService.getString('Leaderboard', 'avg');
  static String get max => TextService.getString('Leaderboard', 'max');
  static String get missionsLabel =>
      TextService.getString('Leaderboard', 'missionsLabel');
  static String get workshopLabel =>
      TextService.getString('Leaderboard', 'workshopLabel');
  static String get xpGuideTitle =>
      TextService.getString('Leaderboard', 'xpGuideTitle');
  static String get xpGuideBody =>
      TextService.getString('Leaderboard', 'xpGuideBody');
  static String get xpSuffix => TextService.getString('Leaderboard', 'xpSuffix');
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
  static String get lessonButton =>
      TextService.getString('PixyLearns', 'lessonButton');
  static String get lessonNext =>
      TextService.getString('PixyLearns', 'lessonNext');
  static String get lessonDidYouKnow =>
      TextService.getString('PixyLearns', 'lessonDidYouKnow');
  static String get backToResults =>
      TextService.getString('PixyLearns', 'backToResults');
  static String get lessonCard1Title =>
      TextService.getString('PixyLearns', 'lessonCard1Title');
  static String get lessonCard1Body =>
      TextService.getString('PixyLearns', 'lessonCard1Body');
  static String get lessonCard1Fact =>
      TextService.getString('PixyLearns', 'lessonCard1Fact');
  static String get lessonCard2Title =>
      TextService.getString('PixyLearns', 'lessonCard2Title');
  static String get lessonCard2Body =>
      TextService.getString('PixyLearns', 'lessonCard2Body');
  static String get lessonCard2Fact =>
      TextService.getString('PixyLearns', 'lessonCard2Fact');
  static String get lessonCard3Title =>
      TextService.getString('PixyLearns', 'lessonCard3Title');
  static String get lessonCard3Body =>
      TextService.getString('PixyLearns', 'lessonCard3Body');
  static String get lessonCard3Fact =>
      TextService.getString('PixyLearns', 'lessonCard3Fact');
  static String get lessonCard4Title =>
      TextService.getString('PixyLearns', 'lessonCard4Title');
  static String get lessonCard4Body =>
      TextService.getString('PixyLearns', 'lessonCard4Body');
  static String get lessonCard4Fact =>
      TextService.getString('PixyLearns', 'lessonCard4Fact');
  static String get lessonCard5Title =>
      TextService.getString('PixyLearns', 'lessonCard5Title');
  static String get lessonCard5Body =>
      TextService.getString('PixyLearns', 'lessonCard5Body');
  static String get lessonCard5Fact =>
      TextService.getString('PixyLearns', 'lessonCard5Fact');
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
