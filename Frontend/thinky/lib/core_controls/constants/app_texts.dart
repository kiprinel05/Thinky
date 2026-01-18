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
