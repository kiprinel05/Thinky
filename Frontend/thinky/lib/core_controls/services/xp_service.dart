import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thinky/core/errors/error_logger.dart';
import 'package:thinky/core_controls/services/api_client.dart';

class XpService {
  static const String _basePath = '/xp';
  static const String _tokenKey = 'auth_token';
  static const String _isGuestKey = 'is_guest';

  /// Award XP for completing a mission.
  ///
  /// Returns the XP earned. Returns 0 without contacting the backend when:
  ///   - no auth token is present,
  ///   - the current user is a guest (guests don't earn XP),
  ///   - the backend rejects the token (401 → token cleared).
  ///
  /// Only registered (non-guest) users accumulate XP and appear on the
  /// leaderboard. The backend enforces the same rule authoritatively.
  static Future<int> awardXp(String missionSlug, double scorePercentage) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      if (token == null) return 0;

      // Short-circuit for guests to avoid a pointless round-trip. The backend
      // would also reject this with `is_guest=true` and xp=0 as a safety net.
      final isGuest = prefs.getBool(_isGuestKey) ?? false;
      if (isGuest) return 0;

      final response = await ApiClient.post('$_basePath/award', {
        'mission_slug': missionSlug,
        'score_percentage': scorePercentage.clamp(0.0, 100.0),
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['xp_earned'] as int? ?? 0;
      }

      // 401 = token expired or invalid → drop it so future calls short-circuit
      // with `token == null` instead of spamming the backend. The user will be
      // prompted to log in again on the next auth-gated screen.
      if (response.statusCode == 401) {
        await prefs.remove(_tokenKey);
        return 0;
      }

      return 0;
    } catch (e, stack) {
      ErrorLogger().logError(e, stackTrace: stack);
      return 0;
    }
  }
}
