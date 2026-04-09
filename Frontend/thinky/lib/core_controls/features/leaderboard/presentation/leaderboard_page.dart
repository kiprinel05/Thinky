import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thinky/shared_controls/theme/app_colors.dart';
import 'package:thinky/shared_controls/theme/app_colors_extension.dart';
import 'package:thinky/shared_controls/theme/app_dimens.dart';
import 'package:thinky/shared_controls/widgets/animations/animated_widgets.dart';
import 'package:thinky/shared_controls/widgets/states/app_content_skeletons.dart';
import 'package:thinky/core_controls/services/api_client.dart';
import 'package:thinky/core_controls/constants/app_texts.dart';
import 'package:thinky/core_controls/services/language_service.dart';
import 'package:thinky/core/errors/error_logger.dart';

/// Per-mission breakdown when API provides it (future / optional).
/// Backend contract idea: `mission_points: [{ "mission_id": "quiz", "points": 12.5 }, ...]`.
class LeaderboardMissionPointsModel {
  final String missionId;
  final double points;

  const LeaderboardMissionPointsModel({
    required this.missionId,
    required this.points,
  });

  factory LeaderboardMissionPointsModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardMissionPointsModel(
      missionId: json['mission_id'] as String? ?? json['missionId'] as String? ?? '',
      points: (json['points'] as num?)?.toDouble() ?? 0,
    );
  }
}

class LeaderboardEntryModel {
  final int userId;
  final String username;
  final double points;
  final int missionsCompleted;
  final int workshopMissionsCompleted;
  /// Present when API sends `mission_points` (or `missionPoints`) per row.
  final List<LeaderboardMissionPointsModel> missionPoints;

  LeaderboardEntryModel({
    required this.userId,
    required this.username,
    required this.points,
    required this.missionsCompleted,
    required this.workshopMissionsCompleted,
    this.missionPoints = const [],
  });

  factory LeaderboardEntryModel.fromJson(Map<String, dynamic> json) {
    final raw = json['mission_points'] ?? json['missionPoints'];
    List<LeaderboardMissionPointsModel> mp = const [];
    if (raw is List) {
      mp = raw
          .map((e) => LeaderboardMissionPointsModel.fromJson(
                e as Map<String, dynamic>,
              ))
          .toList();
    }
    return LeaderboardEntryModel(
      userId: json['user_id'] as int,
      username: json['username'] as String,
      points: (json['points'] as num).toDouble(),
      missionsCompleted: json['missions_completed'] as int,
      workshopMissionsCompleted: json['workshop_missions_completed'] as int,
      missionPoints: mp,
    );
  }
}

class LeaderboardStatsModel {
  final int totalPlayers;
  final double averagePoints;
  final double maxPoints;
  final double minPoints;

  LeaderboardStatsModel({
    required this.totalPlayers,
    required this.averagePoints,
    required this.maxPoints,
    required this.minPoints,
  });

  factory LeaderboardStatsModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardStatsModel(
      totalPlayers: json['total_players'] as int,
      averagePoints: (json['average_points'] as num).toDouble(),
      maxPoints: (json['max_points'] as num).toDouble(),
      minPoints: (json['min_points'] as num).toDouble(),
    );
  }
}

class LeaderboardResponseModel {
  final List<LeaderboardEntryModel> entries;
  final LeaderboardStatsModel stats;

  LeaderboardResponseModel({required this.entries, required this.stats});

  factory LeaderboardResponseModel.fromJson(Map<String, dynamic> json) {
    final entriesJson = json['entries'] as List<dynamic>? ?? [];
    final entries = entriesJson
        .map((e) => LeaderboardEntryModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final stats =
        LeaderboardStatsModel.fromJson(json['stats'] as Map<String, dynamic>);
    return LeaderboardResponseModel(entries: entries, stats: stats);
  }
}

class LeaderboardPage extends ConsumerStatefulWidget {
  const LeaderboardPage({super.key});

  @override
  ConsumerState<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends ConsumerState<LeaderboardPage> {
  bool _includeWorkshop = true;
  bool _isLoading = true;
  String? _error;
  LeaderboardResponseModel? _data;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final query = _includeWorkshop ? 'true' : 'false';
      final response = await ApiClient.get('/leaderboard?include_workshop=$query');
      if (!mounted) return;
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (!mounted) return;
        setState(() {
          _data = LeaderboardResponseModel.fromJson(body);
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _error = 'Failed to load leaderboard';
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      ErrorLogger().logError(e, stackTrace: stack);
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(textRefreshProvider);
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildFilters(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.lg,
        AppDimens.lg,
        AppDimens.lg,
        AppDimens.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeInWidget(
            child: Row(
              children: [
                Text(
                  LeaderboardTexts.title,
                  style: GoogleFonts.alata(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(width: AppDimens.sm),
                const Icon(Icons.leaderboard_rounded,
                    color: AppColors.primaryPurple, size: 24),
              ],
            ),
          ),
          const SizedBox(height: 4),
          FadeInWidget(
            delay: const Duration(milliseconds: 120),
            child: Text(
              LeaderboardTexts.subtitle,
              style: GoogleFonts.alata(
                fontSize: 14,
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.lg,
        vertical: AppDimens.sm,
      ),
      child: Row(
        children: [
          Text(
            LeaderboardTexts.includeWorkshop,
            style: GoogleFonts.alata(
              fontSize: 13,
              color: colors.textSecondary,
            ),
          ),
          const Spacer(),
          Switch(
            value: _includeWorkshop,
            activeThumbColor: AppColors.primaryPurple,
            onChanged: (value) {
              setState(() => _includeWorkshop = value);
              _loadLeaderboard();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final colors = context.appColors;
    if (_isLoading) {
      return AppContentSkeletons.leaderboardList(context);
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 40, color: colors.textHint),
            const SizedBox(height: AppDimens.md),
            Text(
              LeaderboardTexts.couldNotLoad,
              style: GoogleFonts.alata(
                fontSize: 16,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimens.sm),
            TextButton(
              onPressed: _loadLeaderboard,
              child: Text(
                Common.tryAgain,
                style: GoogleFonts.alata(color: AppColors.primaryPurple),
              ),
            ),
          ],
        ),
      );
    }

    if (_data == null || _data!.entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.leaderboard_outlined,
                size: 40, color: colors.textHint),
            const SizedBox(height: AppDimens.md),
            Text(
              LeaderboardTexts.noPlayers,
              style: GoogleFonts.alata(
                fontSize: 16,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              LeaderboardTexts.noPlayersSubtitle,
              style: GoogleFonts.alata(
                fontSize: 13,
                color: colors.textHint,
              ),
            ),
          ],
        ),
      );
    }

    final stats = _data!.stats;

    return RefreshIndicator(
      color: AppColors.primaryPurple,
      onRefresh: _loadLeaderboard,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppDimens.lg,
          AppDimens.sm,
          AppDimens.lg,
          AppDimens.xxl,
        ),
        children: [
          _buildStatsCard(stats),
          const SizedBox(height: AppDimens.lg),
          ..._data!.entries.asMap().entries.map(
                (entry) => _buildEntryTile(entry.key, entry.value),
              ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(LeaderboardStatsModel stats) {
    final colors = context.appColors;
    final values = [
      stats.minPoints,
      stats.averagePoints,
      stats.maxPoints,
    ];

    double maxValue =
        values.where((v) => v > 0).fold<double>(0, (prev, v) => v > prev ? v : prev);
    if (maxValue <= 0) maxValue = 1;

    return FadeInWidget(
      child: Container(
        padding: const EdgeInsets.all(AppDimens.md),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LeaderboardTexts.globalStats,
              style: GoogleFonts.alata(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimens.xs),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: AppDimens.sm),
                title: Text(
                  LeaderboardTexts.pointsGuideTitle,
                  style: GoogleFonts.alata(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryPurple,
                  ),
                ),
                children: [
                  Text(
                    LeaderboardTexts.pointsGuideBody,
                    style: GoogleFonts.alata(
                      fontSize: 12,
                      height: 1.45,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.sm),
            Row(
              children: [
                _buildStatChip(
                  label: LeaderboardTexts.players,
                  value: stats.totalPlayers.toString(),
                  icon: Icons.group_rounded,
                ),
                const SizedBox(width: AppDimens.sm),
                _buildStatChip(
                  label: LeaderboardTexts.avgPoints,
                  value: stats.averagePoints.toStringAsFixed(1),
                  icon: Icons.star_half_rounded,
                ),
              ],
            ),
            const SizedBox(height: AppDimens.md),
            SizedBox(
              height: 80,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildBar(
                    label: LeaderboardTexts.min,
                    value: stats.minPoints,
                    maxValue: maxValue,
                    color: colors.textHint,
                  ),
                  const SizedBox(width: AppDimens.sm),
                  _buildBar(
                    label: LeaderboardTexts.avg,
                    value: stats.averagePoints,
                    maxValue: maxValue,
                    color: AppColors.primaryPurple,
                  ),
                  const SizedBox(width: AppDimens.sm),
                  _buildBar(
                    label: LeaderboardTexts.max,
                    value: stats.maxPoints,
                    maxValue: maxValue,
                    color: const Color(0xFFFFA726),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.md,
        vertical: AppDimens.xs + 2,
      ),
      decoration: BoxDecoration(
        color: colors.cardColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primaryPurple),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: GoogleFonts.alata(
              fontSize: 12,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar({
    required String label,
    required double value,
    required double maxValue,
    required Color color,
  }) {
    final colors = context.appColors;
    final heightFactor = maxValue > 0 ? (value / maxValue).clamp(0.1, 1.0) : 0.1;
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: 18,
                height: 60 * heightFactor,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      color.withValues(alpha: 0.9),
                      color.withValues(alpha: 0.6),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.alata(
              fontSize: 11,
              color: colors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryTile(int index, LeaderboardEntryModel entry) {
    final colors = context.appColors;
    final rank = index + 1;
    final isTop3 = rank <= 3;
    Color badgeColor;
    IconData? badgeIcon;

    switch (rank) {
      case 1:
        badgeColor = const Color(0xFFFFD54F);
        badgeIcon = Icons.emoji_events_rounded;
        break;
      case 2:
        badgeColor = const Color(0xFFB0BEC5);
        badgeIcon = Icons.emoji_events_rounded;
        break;
      case 3:
        badgeColor = const Color(0xFFFFAB91);
        badgeIcon = Icons.emoji_events_rounded;
        break;
      default:
        badgeColor = colors.surface;
    }

    return FadeInWidget(
      delay: Duration(milliseconds: 40 * (index % 10)),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimens.sm),
        padding: const EdgeInsets.all(AppDimens.md),
        decoration: BoxDecoration(
          color: colors.cardColor,
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          border: Border.all(color: colors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: badgeIcon != null
                    ? Icon(badgeIcon,
                        size: 20,
                        color:
                            rank == 1 ? const Color(0xFFF57F17) : Colors.white)
                    : Text(
                        '$rank',
                        style: GoogleFonts.alata(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: AppDimens.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.username,
                    style: GoogleFonts.alata(
                      fontSize: 15,
                      fontWeight:
                          isTop3 ? FontWeight.w700 : FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${entry.missionsCompleted} ${LeaderboardTexts.missionsLabel} · ${entry.workshopMissionsCompleted} ${LeaderboardTexts.workshopLabel}',
                    style: GoogleFonts.alata(
                      fontSize: 12,
                      color: colors.textSecondary,
                    ),
                  ),
                  if (entry.missionPoints.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      entry.missionPoints
                          .map(
                            (m) =>
                                '${MissionTitles.forPath(m.missionId, m.missionId)}: ${m.points.toStringAsFixed(0)} ${LeaderboardTexts.ptsSuffix}',
                          )
                          .join(' · '),
                      style: GoogleFonts.alata(
                        fontSize: 11,
                        height: 1.35,
                        color: colors.textHint,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppDimens.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${entry.points.toStringAsFixed(0)} ${LeaderboardTexts.ptsSuffix}',
                  style: GoogleFonts.alata(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryPurple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
