import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/base/base_controller.dart';
import '../../../../core/base/base_state.dart';
import '../../data/missions_repository.dart';
import 'missions_state.dart';

// Import auth controller for LocalStorage provider
import '../../../auth/presentation/controllers/auth_controller.dart';

/// Provider for MissionsRepository
final missionsRepositoryProvider = Provider<MissionsRepository>((ref) {
  final storage = ref.watch(localStorageProvider);
  return MissionsRepository(storage);
});

/// Provider for missions state
final missionsStateProvider = StateNotifierProvider<MissionsController, MissionsState>((ref) {
  final repository = ref.watch(missionsRepositoryProvider);
  return MissionsController(repository);
});

/// Missions Controller - manages missions state using BaseAsyncController
class MissionsController extends BaseAsyncController<MissionsState> {
  final MissionsRepository _repository;

  MissionsController(this._repository) : super(MissionsState.initial());

  /// Load all missions
  Future<void> loadMissions() async {
    // If already loaded and success, maybe don't reload? Or silent reload.
    // For now standard load.
    
    await executeAsync<List<Mission>>(
      operation: () async {
        final result = await _repository.getMissions();
        final missions = result.getOrThrow();
        // Sort by order
        missions.sort((a, b) => a.order.compareTo(b.order));
        return missions;
      },
      loadingState: () => MissionsState.loading(),
      successState: (missions) => MissionsState.loaded(missions),
      errorState: (message) => MissionsState.error(message),
    );
  }

  /// Refresh missions
  Future<void> refresh() async {
    await executeSilent<List<Mission>>(
      operation: () async {
        final result = await _repository.getMissions();
        final missions = result.getOrThrow();
        missions.sort((a, b) => a.order.compareTo(b.order));
        return missions;
      },
      successState: (missions) => state.copyWith(
        status: StateStatus.success,
        missions: missions,
      ),
      errorState: (message) => state.copyWith(errorMessage: message),
    );
  }

  /// Start unlocking animation for a mission
  void startUnlocking(int missionId) {
    safeUpdate(state.copyWith(unlockingMissionId: missionId));
  }

  /// Stop unlocking animation
  void stopUnlocking() {
    safeUpdate(state.copyWith(clearUnlocking: true));
  }

  /// Complete a mission
  Future<bool> completeMission(int missionId) async {
    // Optimistic update or silent? 
    // We update local state manually after API success to enable unlocking next mission instantly.
    
    try {
      final result = await _repository.completeMission(missionId);
      
      if (result.isSuccess) {
         // Custom logic to update UI state (unlock next mission)
        final updatedMissions = state.missions.map((m) {
          if (m.id == missionId) {
            return m.copyWith(isCompleted: true);
          }
          // Unlock next mission
          if (m.order == state.missions.firstWhere((m) => m.id == missionId).order + 1) {
            return m.copyWith(isLocked: false);
          }
          return m;
        }).toList();

        safeUpdate(state.copyWith(missions: updatedMissions));
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get mission by ID
  Mission? getMissionById(int id) {
    try {
      return state.missions.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }
  
  // Base implementations
  @override
  void setLoading() => state = MissionsState.loading();
  
  @override
  void setError(String message) => state = MissionsState.error(message);
  
  @override
  void setSuccess() => state = state.copyWith(status: StateStatus.success);
  
  @override
  void clearError() {
    if (state.isError) {
      state = state.copyWith(status: StateStatus.initial, errorMessage: null);
    }
  }
  
  @override
  void reset() => state = MissionsState.initial();
}
