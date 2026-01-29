import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'local_storage.dart';

/// Provider for LocalStorage instance
/// Throws UnimplementedError by default to enforce override in main.dart
final localStorageProvider = Provider<LocalStorage>((ref) {
  throw UnimplementedError('LocalStorage must be overridden in ProviderScope');
});
