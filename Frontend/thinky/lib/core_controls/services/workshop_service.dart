import 'dart:convert';
import 'package:thinky/core/errors/error_logger.dart';
import '../models/workshop_models.dart';
import 'api_client.dart';

/// Service for interacting with the Workshop API endpoints.
class WorkshopService {
  /// Browse workshop missions with optional search, tags, sort, and pagination.
  static Future<WorkshopMissionList> getMissions({
    String? search,
    List<String>? tags,
    String sortBy = 'recent',
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, String>{
      'sort_by': sortBy,
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (tags != null && tags.isNotEmpty) params['tags'] = tags.join(',');

    final queryString = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');

    try {
      final response = await ApiClient.get('/workshop/missions?$queryString');
      if (response.statusCode == 200) {
        return WorkshopMissionList.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load workshop missions: ${response.statusCode}');
      }
    } catch (e, stack) {
      ErrorLogger().logError(e, stackTrace: stack);
      rethrow;
    }
  }

  /// Get full mission detail including quiz questions.
  static Future<WorkshopMissionDetail> getMissionDetail(int id) async {
    try {
      final response = await ApiClient.get('/workshop/missions/$id');
      if (response.statusCode == 200) {
        return WorkshopMissionDetail.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load mission detail: ${response.statusCode}');
      }
    } catch (e, stack) {
      ErrorLogger().logError(e, stackTrace: stack);
      rethrow;
    }
  }

  /// Upload a new mission to the workshop.
  static Future<WorkshopMission> uploadMission({
    required String title,
    String? description,
    String missionType = 'quiz',
    List<String> tags = const [],
    required List<WorkshopQuestion> questions,
  }) async {
    final body = {
      'title': title,
      'description': description,
      'mission_type': missionType,
      'tags': tags,
      'questions': questions.map((q) => q.toJson()).toList(),
    };

    try {
      final response = await ApiClient.post('/workshop/upload', body);
      if (response.statusCode == 201) {
        return WorkshopMission.fromJson(jsonDecode(response.body));
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Failed to upload mission');
      }
    } catch (e, stack) {
      ErrorLogger().logError(e, stackTrace: stack);
      rethrow;
    }
  }

  /// Download a mission (increments count, returns full quiz data).
  static Future<WorkshopMissionDetail> downloadMission(int id) async {
    try {
      final response = await ApiClient.post('/workshop/download/$id', {});
      if (response.statusCode == 200) {
        return WorkshopMissionDetail.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to download mission: ${response.statusCode}');
      }
    } catch (e, stack) {
      ErrorLogger().logError(e, stackTrace: stack);
      rethrow;
    }
  }

  /// Get missions created by the current user.
  static Future<WorkshopMissionList> getMyMissions() async {
    try {
      final response = await ApiClient.get('/workshop/my-missions');
      if (response.statusCode == 200) {
        return WorkshopMissionList.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load my missions: ${response.statusCode}');
      }
    } catch (e, stack) {
      ErrorLogger().logError(e, stackTrace: stack);
      rethrow;
    }
  }
}
