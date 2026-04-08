import 'package:go_router/go_router.dart';
import 'package:thinky/core_controls/storage/workshop_storage.dart';
import 'package:thinky/core/errors/error_logger.dart';

/// Collects current app context to send alongside mascot chat messages.
class ContextCollector {
  /// Gathers app state: current page, installed/created workshop missions.
  static Future<Map<String, dynamic>> collect(GoRouter router) async {
    // Current page from router
    String currentPage = 'Unknown';
    try {
      final location = router.routerDelegate.currentConfiguration.last.matchedLocation;
      currentPage = _readablePageName(location);
    } catch (e) {
      ErrorLogger().logDebug('Context collection failed: $e');
    }

    // Workshop missions
    int installedMissions = 0;
    try {
      final missions = await WorkshopStorage.getDownloadedMissions();
      installedMissions = missions.length;
    } catch (e) {
      ErrorLogger().logDebug('Context collection failed: $e');
    }

    return {
      'current_page': currentPage,
      'installed_missions': installedMissions,
      'created_missions': 0, // TODO: track from backend if needed
    };
  }

  static String _readablePageName(String path) {
    const map = {
      '/missions': 'Missions Menu',
      '/workshop': 'Workshop Browse',
      '/profile': 'Profile',
      '/workshop/create': 'Create Mission',
      '/workshop/my-missions': 'My Missions',
    };
    return map[path] ?? path;
  }
}
