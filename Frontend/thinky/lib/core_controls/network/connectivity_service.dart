import 'package:connectivity_plus/connectivity_plus.dart';

/// Lightweight reachability check before opening missions that need the API.
class ConnectivityService {
  ConnectivityService._();

  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _connectivity = Connectivity();

  /// True when any non-none connectivity is reported (Wi‑Fi, mobile, ethernet, VPN, etc.).
  Future<bool> get hasConnection async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }
}
