import 'package:flutter/material.dart';
import 'package:thinky/core/errors/exceptions.dart';

class ErrorHandlerUI {
  static void showSnackBar(BuildContext context, String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void showErrorDialog(BuildContext context, AppException exception, {VoidCallback? onRetry}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getTitle(exception)),
        content: Text(exception.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (onRetry != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  static String _getTitle(AppException exception) {
    if (exception is NetworkException) return 'Network Error';
    if (exception is TimeoutException) return 'Connection Timeout';
    if (exception is UnauthorizedException) return 'Session Expired';
    if (exception is ServerException) return 'Server Error';
    return 'Error';
  }
}
