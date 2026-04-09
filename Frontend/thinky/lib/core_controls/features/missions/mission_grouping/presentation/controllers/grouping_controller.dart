import 'package:thinky/core/errors/error_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thinky/core_controls/constants/app_texts.dart';
import 'package:thinky/core_controls/network/user_facing_error_mapper.dart';
import 'package:thinky/core_controls/services/mission_service.dart';
import '../../data/grouping_models.dart';
import '../../data/grouping_repository.dart';

/// Phases of the grouping mission
enum GroupingMissionPhase {
  loading,
  playing,        // User is dragging and dropping
  submitting,     // Waiting for backend validation
  results,        // Show round results
  roundComplete,  // Transition to next round
  missionComplete,
  error,
}

/// State for the Grouping mission
class GroupingMissionState {
  final GroupingMissionPhase phase;
  final int currentRound;
  final int totalRounds;
  final List<GroupingItem> items;
  final List<String> categories;
  final Map<String, String> assignments; // item_id -> category
  final GroupingSubmitResponse? lastResult;
  final DateTime? startTime;
  final String? errorMessage;
  final bool isLoading;
  final String? motivationalText; // Microcopy feedback

  const GroupingMissionState({
    this.phase = GroupingMissionPhase.loading,
    this.currentRound = 0,
    this.totalRounds = 3,
    this.items = const [],
    this.categories = const [],
    this.assignments = const {},
    this.lastResult,
    this.startTime,
    this.errorMessage,
    this.isLoading = false,
    this.motivationalText,
  });

  /// Items not yet assigned to a category
  List<GroupingItem> get unassignedItems {
    return items.where((item) => !assignments.containsKey(item.id)).toList();
  }

  /// Items assigned to a specific category
  List<GroupingItem> itemsInCategory(String category) {
    final itemIds = assignments.entries
        .where((e) => e.value == category)
        .map((e) => e.key)
        .toSet();
    return items.where((item) => itemIds.contains(item.id)).toList();
  }

  /// Whether all items are assigned
  bool get allAssigned => assignments.length == items.length && items.isNotEmpty;

  GroupingMissionState copyWith({
    GroupingMissionPhase? phase,
    int? currentRound,
    int? totalRounds,
    List<GroupingItem>? items,
    List<String>? categories,
    Map<String, String>? assignments,
    GroupingSubmitResponse? lastResult,
    DateTime? startTime,
    String? errorMessage,
    bool? isLoading,
    String? motivationalText,
  }) {
    return GroupingMissionState(
      phase: phase ?? this.phase,
      currentRound: currentRound ?? this.currentRound,
      totalRounds: totalRounds ?? this.totalRounds,
      items: items ?? this.items,
      categories: categories ?? this.categories,
      assignments: assignments ?? this.assignments,
      lastResult: lastResult ?? this.lastResult,
      startTime: startTime ?? this.startTime,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
      motivationalText: motivationalText,
    );
  }
}

class GroupingController extends StateNotifier<GroupingMissionState> {
  GroupingController() : super(const GroupingMissionState());

  int _messageIndex = 0;

  /// Start the mission
  Future<void> startMission() async {
    state = state.copyWith(phase: GroupingMissionPhase.loading, isLoading: true);

    try {
      await GroupingRepository.startMission();
      await _loadNextRound();
    } catch (e) {
      state = state.copyWith(
        phase: GroupingMissionPhase.error,
        errorMessage: UserFacingErrorMapper.map(e),
        isLoading: false,
      );
    }
  }

  /// Load the next round of items
  Future<void> _loadNextRound() async {
    try {
      final roundData = await GroupingRepository.getRound();

      state = state.copyWith(
        phase: GroupingMissionPhase.playing,
        currentRound: roundData.roundNumber,
        totalRounds: roundData.totalRounds,
        items: roundData.items,
        categories: roundData.categories,
        assignments: {},
        lastResult: null,
        startTime: DateTime.now(),
        isLoading: false,
        motivationalText: null,
      );
    } catch (e) {
      if (e.toString().contains('already complete')) {
        state = state.copyWith(
          phase: GroupingMissionPhase.missionComplete,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          phase: GroupingMissionPhase.error,
          errorMessage: UserFacingErrorMapper.map(e),
          isLoading: false,
        );
      }
    }
  }

  /// Assign an item to a category (drag & drop)
  void assignItem(String itemId, String category) {
    final newAssignments = Map<String, String>.from(state.assignments);
    newAssignments[itemId] = category;

    final message = GroupingSorting.motivationalLine(_messageIndex);
    _messageIndex++;

    state = state.copyWith(
      assignments: newAssignments,
      motivationalText: message,
    );
  }

  /// Remove an item from its category (put back in tray)
  void removeItem(String itemId) {
    final newAssignments = Map<String, String>.from(state.assignments);
    newAssignments.remove(itemId);

    state = state.copyWith(
      assignments: newAssignments,
      motivationalText: null,
    );
  }

  /// Submit the current grouping for validation
  Future<void> submitGrouping() async {
    if (!state.allAssigned) return;

    state = state.copyWith(
      phase: GroupingMissionPhase.submitting,
      isLoading: true,
    );

    try {
      final elapsed = DateTime.now().difference(state.startTime!).inMilliseconds / 1000.0;

      final result = await GroupingRepository.submitGrouping(
        assignments: state.assignments,
        timeSpent: elapsed,
      );

      state = state.copyWith(
        phase: GroupingMissionPhase.results,
        lastResult: result,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        phase: GroupingMissionPhase.error,
        errorMessage: UserFacingErrorMapper.map(e),
        isLoading: false,
      );
    }
  }

  /// Continue to next round or complete
  Future<void> continueAfterResults() async {
    if (state.currentRound >= state.totalRounds) {
      // Mark mission as complete
      try {
        await MissionService.completeMission(-6); // -6 = grouping mission
      } catch (e, stack) {
        ErrorLogger().logError(e, stackTrace: stack);
      }
      state = state.copyWith(phase: GroupingMissionPhase.missionComplete);
    } else {
      state = state.copyWith(
        phase: GroupingMissionPhase.loading,
        isLoading: true,
      );
      await _loadNextRound();
    }
  }

  /// Retry current round (after incorrect result)
  Future<void> retryRound() async {
    state = state.copyWith(
      phase: GroupingMissionPhase.loading,
      isLoading: true,
    );
    // Re-start to reset backend session, then load round
    try {
      await GroupingRepository.startMission();
      await _loadNextRound();
    } catch (e) {
      state = state.copyWith(
        phase: GroupingMissionPhase.error,
        errorMessage: UserFacingErrorMapper.map(e),
        isLoading: false,
      );
    }
  }

  /// Reset mission
  void reset() {
    _messageIndex = 0;
    state = const GroupingMissionState();
  }
}

/// Provider for GroupingController
final groupingControllerProvider =
    StateNotifierProvider<GroupingController, GroupingMissionState>((ref) {
  return GroupingController();
});
