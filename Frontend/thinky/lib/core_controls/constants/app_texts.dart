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
}

/// Accessors for 'GroupingSorting' texts
class GroupingSorting {
  static String get title => TextService.getString('GroupingSorting', 'title');
  static String get subtitle => TextService.getString('GroupingSorting', 'subtitle');
  static String get instruction => TextService.getString('GroupingSorting', 'instruction');
  static String get submit => TextService.getString('GroupingSorting', 'submit');
  static String get allSorted => TextService.getString('GroupingSorting', 'allSorted');
  static String get missionComplete => TextService.getString('GroupingSorting', 'missionComplete');
  static String get tryAgain => TextService.getString('GroupingSorting', 'tryAgain');
  static String get continueAction => TextService.getString('GroupingSorting', 'continueAction');
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
}

/// Accessors for 'Nav' texts (bottom navigation bar)
class Nav {
  static String get missions => TextService.getString('Nav', 'missions');
  static String get workshop => TextService.getString('Nav', 'workshop');
  static String get profile => TextService.getString('Nav', 'profile');
}
