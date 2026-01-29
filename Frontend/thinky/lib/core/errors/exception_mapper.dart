import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:thinky/core/errors/exceptions.dart';

class ExceptionMapper {
  static AppException map(dynamic error) {
    if (error is AppException) {
      return error; // Already mapped
    }

    if (error is SocketException) {
      return const NetworkException('No Internet Connection. Please check your settings.');
    }

    if (error is HttpException) {
      return const NetworkException('Could not reach the server.');
    }

    if (error is FormatException) {
      return const ValidationException('Data format error. Please try again.');
    }

    if (error is TimeoutException) {
      return const TimeoutException('The connection timed out. Please try again.');
    }
    
    // Map http ClientException purely based on type if exposed, but http usually throws SocketException for network.
    if (error is http.ClientException) {
       return const NetworkException('Network client error.');
    }

    // Default fallback
    return UnknownException(
      'An unexpected error occurred.',
      stackTrace: error is Error ? error.stackTrace : null,
    );
  }
}
