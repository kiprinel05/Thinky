import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'package:thinky/core_controls/storage/local_storage.dart';
import 'package:thinky/core_controls/features/auth/presentation/controllers/auth_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
}