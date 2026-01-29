import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

class ErrorLogger {
  static Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.dateAndTime,
    ),
  );

  @visibleForTesting
  static set logger(Logger logger) {
    _logger = logger;
  }

  ErrorLogger._internal();
  static final ErrorLogger _instance = ErrorLogger._internal();
  factory ErrorLogger() => _instance;

  void logError(dynamic error, {StackTrace? stackTrace}) {
    if (kDebugMode) {
      _logger.e('ERROR: $error', error: error, stackTrace: stackTrace);
    } else {
      // TODO: Integrate Firebase Crashlytics / Sentry here
      // Crashlytics.instance.recordError(error, stackTrace);
    }
  }

  void logInfo(String message) {
    if (kDebugMode) {
      _logger.i(message);
    }
  }

  void logDebug(String message) {
    if (kDebugMode) {
      _logger.d(message);
    }
  }
}
