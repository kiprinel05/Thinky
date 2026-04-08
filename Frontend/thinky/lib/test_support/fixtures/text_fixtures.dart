abstract class TextFixtures {
  static Map<String, dynamic> fullTextsMap() => {
        'Misc': {'test': 'test value from json'},
        'Intro': {
          'title': 'Learn and Teach',
          'subtitle': 'Thousands of people use AI',
          'signUp': 'SIGN UP',
          'guest': 'CONTINUE AS GUEST',
          'logIn': 'LOG IN',
          'haveAccount': 'ALREADY HAVE AN ACCOUNT? ',
        },
        'Auth': {
          'loginButton': 'Log In',
          'registerButton': 'Sign Up',
          'welcomeBack': 'Welcome Back!',
          'emailHint': 'Email address',
          'passwordHint': 'Password',
          'emailRequired': 'Email is required',
          'emailInvalid': 'Please enter a valid email',
          'passwordRequired': 'Password is required',
          'forgotPassword': 'Forgot Password?',
          'createAccount': 'Create your account',
        },
        'Common': {
          'retry': 'Retry',
          'tryAgain': 'Try Again',
          'close': 'Close',
          'cancel': 'Cancel',
          'loading': 'Loading...',
          'error': 'Error',
          'success': 'Success',
        },
        'Nav': {
          'missions': 'Missions',
          'workshop': 'Workshop',
          'profile': 'Profile',
        },
      };

  static Map<String, dynamic> minimalTextsMap() => {
        'Misc': {'test': 'test value'},
      };
}
