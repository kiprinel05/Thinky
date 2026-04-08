import 'package:flutter/material.dart';
import 'package:thinky/core/errors/exceptions.dart';
import 'package:thinky/shared_controls/theme/app_colors.dart';
import 'package:thinky/shared_controls/theme/app_colors_extension.dart';

class ErrorHandlerUI {
  static void showSuccess(BuildContext context, String message) {
    _showSnackBar(context, message, backgroundColor: AppColors.success);
  }

  static void showError(BuildContext context, String message) {
    _showSnackBar(context, message, backgroundColor: AppColors.error);
  }

  static void showWarning(BuildContext context, String message) {
    _showSnackBar(context, message, backgroundColor: AppColors.warning);
  }

  static void showInfo(BuildContext context, String message) {
    _showSnackBar(context, message,
        backgroundColor: context.appColors.textPrimary);
  }

  static void _showSnackBar(
    BuildContext context,
    String message, {
    required Color backgroundColor,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  static void showErrorDialog(
    BuildContext context,
    AppException exception, {
    VoidCallback? onRetry,
  }) {
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
