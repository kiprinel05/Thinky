import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:thinky/core/errors/error_logger.dart';

/// Centralized connectivity service. Check network state before API calls
/// or listen for changes to update UI.
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._();
  factory ConnectivityService() => _instance;
  ConnectivityService._();

  final Connectivity _connectivity = Connectivity();

  /// Returns true if the device has any active network connection.
  Future<bool> get isConnected async {
    try {
      final results = await _connectivity.checkConnectivity();
      return !results.contains(ConnectivityResult.none);
    } catch (e) {
      ErrorLogger().logDebug('ConnectivityService.isConnected error: $e');
      return true;
    }
  }

  /// Stream of connectivity changes.
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map((results) {
      return !results.contains(ConnectivityResult.none);
    });
  }
}
