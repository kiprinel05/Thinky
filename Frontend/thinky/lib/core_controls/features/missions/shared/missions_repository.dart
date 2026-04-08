import 'package:thinky/core_controls/network/api_endpoints.dart';
import 'package:thinky/core_controls/network/api_exceptions.dart';
import 'package:thinky/core_controls/network/base_repository.dart';
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
      if (result.isFailure) {
        final error = result.errorOrNull;
        if (error is UnauthorizedException ||
            error is NetworkException ||
            error is TimeoutException) {
          return Result.success(_getOfflineMissions());
        }
        return result;
      }
      return result;
    });
  }

  /// Complete a mission
  Future<Result<void, ApiException>> completeMission(int missionId) async {
    final result = await post<bool>(
      endpoint: ApiEndpoints.missionComplete(missionId),
      body: {},
      parser: (_) => true,
    );

    if (result.isSuccess) return const Result.success(null);
    return Result.failure(result.errorOrNull!);
  }

  /// Offline fallback missions used when the API is unreachable
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
        isLocked: true,
        order: 2,
        isCompleted: false,
      ),
      const Mission(
        id: 3,
        name: 'Draw Shapes',
        imageUrl: 'assets/missions/shapes.png',
        color: '#8E97FD',
        isLocked: true,
        order: 3,
        isCompleted: false,
        missionPath: 'draw_shapes',
      ),
      const Mission(
        id: 4,
        name: 'Numbers',
        imageUrl: 'assets/missions/numbers.png',
        color: '#6CB28E',
        isLocked: true,
        order: 4,
        isCompleted: false,
      ),
    ];
  }
}
