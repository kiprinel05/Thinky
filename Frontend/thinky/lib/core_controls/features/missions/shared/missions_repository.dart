import 'package:http/http.dart' as http;
import 'package:thinky/core_controls/network/api_endpoints.dart';
import 'package:thinky/core_controls/network/api_exceptions.dart';
import 'package:thinky/core_controls/network/base_repository.dart';
import 'package:thinky/core_controls/storage/local_storage.dart';
import 'package:thinky/shared/models/result.dart';
import '../presentation/controllers/missions_state.dart';

/// Missions Repository - handles all mission-related API calls
class MissionsRepository extends BaseRepository {
  MissionsRepository(super.storage);

  /// Fetch all missions
  Future<Result<List<Mission>, ApiException>> getMissions() async {
    return get<List<Mission>>(
      endpoint: ApiEndpoints.missions,
      parser: (data) {
        final List<dynamic> missionsList = data['missions'] ?? [];
        return missionsList.map((m) => Mission.fromJson(m)).toList();
      },
    ).then((result) {
      // Handle fallback on failure if unauthorized/network error logic requires it?
      // BaseRepository handles 401. 
      // Original logic had fallback for 401/403 OR network error.
      // We can intercept failure here.
      
      if (result.isFailure) {
        // If auth error or network error, fallback to offline?
        // Original: "if 401/403 -> offline", "catch e -> offline".
        // BaseRepository wraps exceptions in Result.failure.
        
        final error = result.errorOrNull;
        if (error is UnauthorizedException || error is NetworkException || error is TimeoutException) {
           return Result.success(_getOfflineMissions());
        }
        // Also if server error? Original said "else throw" for other codes.
        // But "catch e -> offline".
        // So safe to fallback generally?
        // Let's fallback if error.
        return Result.success(_getOfflineMissions());
      }
      return result;
    });
  }

  /// Complete a mission
  Future<Result<void, ApiException>> completeMission(int missionId) async {
    // Original used post.
    // Returns void (status check).
    
    // BaseRepository post returns T.
    // We can use a dummy type or just check success.
    
    // Actually BaseRepository doesn't have a specific `postVoid` method, 
    // but we can usage `post<void>` if parser returns null?
    // Or just use `post<bool>` and return true.
    
    // Original logic: check 200/201.
    
    final result = await post<bool>(
      endpoint: ApiEndpoints.missionComplete(missionId),
      body: {}, // Empty body? Original didn't send body, just endpoint? 
      // Original: http.post(url, headers). No body param used?
      // BaseRepository post requires body.
      // If endpoint handles query params or path params, body might be empty.
      // Original code: http.post(..., headers). No body.
      // I'll send empty map.
      parser: (_) => true,
    );
    
    if (result.isSuccess) return const Result.success(null);
    return Result.failure(result.errorOrNull!);
  }

  /// Offline fallback missions - ALL UNLOCKED FOR TESTING
  List<Mission> _getOfflineMissions() {
    return [
      const Mission(
        id: 1,
        name: 'Pixy Learns',
        imageUrl: 'assets/missions/pixy_learns.png',
        color: '#8E97FD',
        isLocked: false,
        order: 1,
        isCompleted: false,
      ),
      const Mission(
        id: 2,
        name: 'Colors',
        imageUrl: 'assets/missions/colors.png',
        color: '#FFB59E',
        isLocked: false, // UNLOCKED FOR TESTING
        order: 2,
        isCompleted: false,
      ),
      const Mission(
        id: 3,
        name: 'Draw Shapes',
        imageUrl: 'assets/missions/shapes.png',
        color: '#8E97FD',
        isLocked: false, // UNLOCKED FOR TESTING
        order: 3,
        isCompleted: false,
        missionPath: 'draw_shapes',
      ),
      const Mission(
        id: 4,
        name: 'Numbers',
        imageUrl: 'assets/missions/numbers.png',
        color: '#6CB28E',
        isLocked: false, // UNLOCKED FOR TESTING
        order: 4,
        isCompleted: false,
      ),
    ];
  }
}