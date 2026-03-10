import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thinky/shared_controls/theme/app_colors.dart';
import 'package:thinky/shared_controls/theme/app_dimens.dart';
import 'package:thinky/shared_controls/widgets/animated_widgets.dart';
import 'package:thinky/core_controls/services/api_client.dart';

class LeaderboardEntryModel {
  final int userId;
  final String username;
  final double points;
  final int missionsCompleted;
  final int workshopMissionsCompleted;

  LeaderboardEntryModel({
    required this.userId,
    required this.username,
    required this.points,
    required this.missionsCompleted,
    required this.workshopMissionsCompleted,
  });

  factory LeaderboardEntryModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntryModel(
      userId: json['user_id'] as int,
      username: json['username'] as String,
      points: (json['points'] as num).toDouble(),
      missionsCompleted: json['missions_completed'] as int,
      workshopMissionsCompleted: json['workshop_missions_completed'] as int,
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

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
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
                  'Leaderboard',
                  style: GoogleFonts.alata(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
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
              'See how you compare with other players',
              style: GoogleFonts.alata(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.lg,
        vertical: AppDimens.sm,
      ),
      child: Row(
        children: [
          Text(
            'Include Workshop missions',
            style: GoogleFonts.alata(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Switch(
            value: _includeWorkshop,
            activeColor: AppColors.primaryPurple,
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
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryPurple),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 40, color: AppColors.textHint),
            const SizedBox(height: AppDimens.md),
            Text(
              'Could not load leaderboard',
              style: GoogleFonts.alata(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimens.sm),
            TextButton(
              onPressed: _loadLeaderboard,
              child: Text(
                'Try again',
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
            const Icon(Icons.leaderboard_outlined,
                size: 40, color: AppColors.textHint),
            const SizedBox(height: AppDimens.md),
            Text(
              'No players yet',
              style: GoogleFonts.alata(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Complete some missions to appear here.',
              style: GoogleFonts.alata(
                fontSize: 13,
                color: AppColors.textHint,
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
          color: AppColors.backgroundGrey,
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Global stats',
              style: GoogleFonts.alata(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimens.sm),
            Row(
              children: [
                _buildStatChip(
                  label: 'Players',
                  value: stats.totalPlayers.toString(),
                  icon: Icons.group_rounded,
                ),
                const SizedBox(width: AppDimens.sm),
                _buildStatChip(
                  label: 'Avg points',
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
                    label: 'Min',
                    value: stats.minPoints,
                    maxValue: maxValue,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(width: AppDimens.sm),
                  _buildBar(
                    label: 'Avg',
                    value: stats.averagePoints,
                    maxValue: maxValue,
                    color: AppColors.primaryPurple,
                  ),
                  const SizedBox(width: AppDimens.sm),
                  _buildBar(
                    label: 'Max',
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
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.md,
        vertical: AppDimens.xs + 2,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
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
              color: AppColors.textSecondary,
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
                      color.withOpacity(0.9),
                      color.withOpacity(0.6),
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
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryTile(int index, LeaderboardEntryModel entry) {
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
        badgeColor = AppColors.backgroundGrey;
    }

    return FadeInWidget(
      delay: Duration(milliseconds: 40 * (index % 10)),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimens.sm),
        padding: const EdgeInsets.all(AppDimens.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          border: Border.all(color: AppColors.borderLight, width: 1),
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
                          color: AppColors.textPrimary,
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
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${entry.missionsCompleted} missions • ${entry.workshopMissionsCompleted} workshop',
                    style: GoogleFonts.alata(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimens.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${entry.points.toStringAsFixed(0)} pts',
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

