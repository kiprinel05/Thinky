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
  static String get title => 'Group the Images';
  static String get subtitle => 'Sort items into the correct categories';
  static String get instruction => 'Drag each image into the correct category';
  static String get submit => 'Submit Sorting';
  static String get allSorted => 'All items sorted!';
  static String get missionComplete => 'Mission Complete!';
  static String get tryAgain => 'Try Again';
  static String get continueAction => 'Continue';
}

/// Accessors for 'Vocabulary' texts
class Vocabulary {
  static String get title => 'Word Match';
  static String get subtitle => 'Select the image that matches the word';
  static String get submitAnswer => 'Submit Answer';
  static String get nextWord => 'Next Word';
  static String get missionComplete => 'Mission Complete!';
  static String get tryAgain => 'Try Again';
  static String get seeResults => 'See Results';
}

class DescribeImage {
  static String get title => 'Describe It';
  static String get instruction => 'Press record and describe what you see';
  static String get tapToRecord => 'Tap to Record';
  static String get listening => 'Listening...';
  static String get processing => 'Processing...';
  static String get youSaid => 'You said:';
}

class PatternMission {
  static String get title => 'Complete the Pattern';
  static String get instruction => 'What comes next?';
  static String get chooseNext => 'Choose next:';
  static String get checkAnswer => 'Check Answer';
  static String get nextPattern => 'Next Pattern';
  static String get tryAgain => 'Try Again';
}

/// Accessors for 'Nav' texts (bottom navigation bar)
class Nav {
  static String get missions => TextService.getString('Nav', 'missions');
  static String get workshop => TextService.getString('Nav', 'workshop');
  static String get profile => TextService.getString('Nav', 'profile');
}
