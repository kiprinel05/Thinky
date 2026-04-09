import 'package:flutter/material.dart';
import 'package:thinky/core/errors/exceptions.dart';
import 'package:thinky/core_controls/constants/app_texts.dart';
import 'package:thinky/core_controls/network/api_exceptions.dart' as api;
import 'package:thinky/core_controls/network/user_facing_error_mapper.dart';
import 'package:thinky/core_controls/services/text_service.dart';
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
        content: Text(UserFacingErrorMapper.map(exception)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(Common.close),
          ),
          if (onRetry != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: Text(Common.retry),
            ),
        ],
      ),
    );
  }

  static String _getTitle(AppException exception) {
    if (exception is api.AuthException) return Common.error;
    if (exception is api.NetworkException) return Common.networkError;
    if (exception is api.TimeoutException) return Common.connectionTimeout;
    if (exception is api.UnauthorizedException) return Common.sessionExpired;
    if (exception is api.ServerException) return Common.serverError;
    if (exception is NetworkException) {
      return TextService.getString('Common', 'networkError');
    }
    if (exception is TimeoutException) {
      return TextService.getString('Common', 'connectionTimeout');
    }
    if (exception is UnauthorizedException) {
      return TextService.getString('Common', 'sessionExpired');
    }
    if (exception is ServerException) {
      return TextService.getString('Common', 'serverError');
    }
    return Common.error;
  }
}
