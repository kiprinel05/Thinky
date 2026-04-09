import 'dart:convert';
import 'package:thinky/core/errors/error_logger.dart';
import 'package:thinky/core_controls/services/api_client.dart';
import 'package:thinky/core_controls/config/app_config.dart';
import 'package:thinky/shared_controls/assets/app_assets.dart';
import 'grouping_models.dart';

/// Repository for Grouping Mission API calls
class GroupingRepository {
  static const String _basePath = '/grouping';

  /// Start a new grouping mission
  static Future<GroupingStartResponse> startMission() async {
    try {
      final response = await ApiClient.get('$_basePath/start');
      if (response.statusCode == 200) {
        return GroupingStartResponse.fromJson(jsonDecode(response.body));
      }
      throw Exception('Failed to start mission: ${response.statusCode}');
    } catch (e, stack) {
      ErrorLogger().logError(e, stackTrace: stack);
      rethrow;
    }
  }

  /// Get current round's items to sort
  static Future<GroupingRoundResponse> getRound() async {
    try {
      final response = await ApiClient.get('$_basePath/round');
      if (response.statusCode == 200) {
        return GroupingRoundResponse.fromJson(jsonDecode(response.body));
      }
      throw Exception('Failed to get round: ${response.statusCode}');
    } catch (e, stack) {
      ErrorLogger().logError(e, stackTrace: stack);
      rethrow;
    }
  }

  /// Submit user's grouping assignments
  static Future<GroupingSubmitResponse> submitGrouping({
    required Map<String, String> assignments,
    required double timeSpent,
  }) async {
    try {
      final response = await ApiClient.post('$_basePath/submit', {
        'assignments': assignments,
        'time_spent': timeSpent,
      });
      if (response.statusCode == 200) {
        return GroupingSubmitResponse.fromJson(jsonDecode(response.body));
      }
      throw Exception('Failed to submit grouping: ${response.statusCode}');
    } catch (e, stack) {
      ErrorLogger().logError(e, stackTrace: stack);
      rethrow;
    }
  }

  /// Build full image URL from relative path (for network loading)
  static String getImageUrl(String relativePath) {
    return '${AppConfig.apiBaseUrl}$relativePath';
  }

  /// Get local asset path from API url (e.g. /grouping/image/fruits/apple.png)
  /// Returns assets/missions/group_sorting/images/fruits/apple.png
  static String? getAssetPath(String url) {
    final parts = url.split('/');
    if (parts.length >= 2) {
      final category = parts[parts.length - 2];
      final filename = parts[parts.length - 1];
      return AppAssets.groupSortingImage(category, filename);
    }
    return null;
  }
}
