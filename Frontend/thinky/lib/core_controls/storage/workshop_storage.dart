import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workshop_models.dart';

/// Local storage for downloaded workshop missions.
/// Uses SharedPreferences to persist missions as JSON strings.
class WorkshopStorage {
  static const _downloadedKey = 'workshop_downloaded_missions';

  /// Save a downloaded mission to local storage.
  static Future<void> saveDownloadedMission(WorkshopMissionDetail mission) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getDownloadedMissions();

    // Remove old version if already downloaded
    existing.removeWhere((m) => m.id == mission.id);
    existing.add(mission);

    final jsonList = existing.map((m) => jsonEncode(m.toJson())).toList();
    await prefs.setStringList(_downloadedKey, jsonList);
  }

  /// Get all downloaded missions from local storage.
  static Future<List<WorkshopMissionDetail>> getDownloadedMissions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_downloadedKey) ?? [];

    return jsonList.map((jsonStr) {
      return WorkshopMissionDetail.fromJson(jsonDecode(jsonStr));
    }).toList();
  }

  /// Check if a mission has been downloaded.
  static Future<bool> isDownloaded(int missionId) async {
    final missions = await getDownloadedMissions();
    return missions.any((m) => m.id == missionId);
  }

  /// Delete a downloaded mission from local storage.
  static Future<void> deleteDownloadedMission(int missionId) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getDownloadedMissions();
    existing.removeWhere((m) => m.id == missionId);

    final jsonList = existing.map((m) => jsonEncode(m.toJson())).toList();
    await prefs.setStringList(_downloadedKey, jsonList);
  }
}
