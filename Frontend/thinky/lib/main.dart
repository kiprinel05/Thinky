import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'package:thinky/core_controls/storage/local_storage.dart';
import 'package:thinky/core_controls/features/auth/presentation/controllers/auth_controller.dart';
import 'package:thinky/core_controls/services/logger_service.dart';
import 'package:thinky/core_controls/services/text_service.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    LoggerService.i('App Started');
    
    // Initialize services
    await TextService.init();

    // Catch Flutter errors
    FlutterError.onError = (FlutterErrorDetails details) {
      LoggerService.e('Flutter Error: ${details.exception}', details.exception, details.stack);
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
  }, (error, stack) {
    LoggerService.wtf('Unhandled Error: $error', error, stack);
  });
}