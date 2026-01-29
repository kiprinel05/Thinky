import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:thinky/app.dart';
import 'package:thinky/core_controls/storage/local_storage.dart';
import 'package:thinky/core_controls/storage/storage_provider.dart';
import 'package:thinky/core_controls/services/text_service.dart';
import 'package:thinky/core/errors/error_logger.dart';

void main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      ErrorLogger().logInfo('App Started');
      
      // Initialize services
      await TextService.init();

      // Global error handling for synchronous errors
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        ErrorLogger().logError(details.exception, stackTrace: details.stack);
      };

      // Global error handling for asynchronous errors
      PlatformDispatcher.instance.onError = (error, stack) {
        ErrorLogger().logError(error, stackTrace: stack);
        return true;
      };
      
      // Initialize local storage
      final localStorage = await LocalStorage.getInstance();
      
      runApp(
        ProviderScope(
          overrides: [
            // Override the localStorageProvider with the actual instance
            localStorageProvider.overrideWithValue(localStorage),
          ],
          child: const ThinkyApp(),
        ),
      );
    },
    (error, stack) {
      // Catch-all for underlying zone errors
      ErrorLogger().logError(error, stackTrace: stack);
    },
  );
}