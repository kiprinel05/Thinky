import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thinky/core/errors/error_logger.dart';
import 'package:thinky/core_controls/services/api_client.dart';

class XpService {
  static const String _basePath = '/xp';

  /// Award XP for completing a mission.
  /// Returns the XP earned (0 for guests or on error).
  static Future<int> awardXp(String missionSlug, double scorePercentage) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return 0;

      final response = await ApiClient.post('$_basePath/award', {
        'mission_slug': missionSlug,
        'score_percentage': scorePercentage.clamp(0.0, 100.0),
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['xp_earned'] as int? ?? 0;
      }
      return 0;
    } catch (e, stack) {
      ErrorLogger().logError(e, stackTrace: stack);
      return 0;
    }
  }
}
