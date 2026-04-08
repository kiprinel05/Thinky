import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thinky/shared_controls/theme/app_colors.dart';
import 'package:thinky/shared_controls/theme/app_colors_extension.dart';
import 'package:thinky/shared_controls/theme/app_dimens.dart';
import 'package:thinky/shared_controls/widgets/animations/animated_widgets.dart';
import 'package:thinky/core_controls/models/workshop_models.dart';
import 'package:thinky/core_controls/services/workshop_service.dart';
import 'package:thinky/core_controls/services/auth_service.dart';
import 'package:thinky/core/errors/error_logger.dart';
import 'package:thinky/core_controls/routing/route_names.dart';
import 'package:thinky/core_controls/constants/app_texts.dart';

class WorkshopBrowsePage extends StatefulWidget {
  const WorkshopBrowsePage({super.key});

  @override
  State<WorkshopBrowsePage> createState() => _WorkshopBrowsePageState();
}

class _WorkshopBrowsePageState extends State<WorkshopBrowsePage> {
  final _searchController = TextEditingController();
  List<WorkshopMission> _missions = [];
  bool _isLoading = true;
  bool _isGuest = true;
  String? _error;
  String _sortBy = 'recent';
  int _page = 1;
  int _total = 0;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final user = await AuthService.getCurrentUser();
    final isGuest = user?['isGuest'] ?? true;
    setState(() => _isGuest = isGuest);
    if (!isGuest) _loadMissions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMissions({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      _missions.clear();
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await WorkshopService.getMissions(
        search: _searchController.text.isEmpty ? null : _searchController.text,
        sortBy: _sortBy,
        page: _page,
      );
      setState(() {
        _missions.addAll(result.missions);
        _total = result.total;
        _hasMore = _missions.length < _total;
        _isLoading = false;
      });
    } catch (e, stack) {
      ErrorLogger().logError(e, stackTrace: stack);
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onSearch() {
    _loadMissions(refresh: true);
  }

  void _onSortChanged(String sort) {
    _sortBy = sort;
    _loadMissions(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    if (_isGuest) return _buildLockedState();

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildSortChips(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedState() {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    size: 36,
                    color: AppColors.primaryPurple,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  WorkshopTexts.title,
                  style: GoogleFonts.alata(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  WorkshopTexts.lockedSubtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.alata(
                    fontSize: 14,
                    color: colors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => context.go(RouteNames.login),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      WorkshopTexts.loginButton,
                      style: GoogleFonts.alata(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.go(RouteNames.register),
                  child: Text(
                    WorkshopTexts.createAccountButton,
                    style: GoogleFonts.alata(
                      fontSize: 14,
                      color: AppColors.primaryPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.lg, AppDimens.lg, AppDimens.lg, AppDimens.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeInWidget(
            child: Row(
              children: [
                Text(
                  WorkshopTexts.title,
                  style: GoogleFonts.alata(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => context.push('/workshop/create'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          WorkshopTexts.create,
                          style: GoogleFonts.alata(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          FadeInWidget(
            delay: const Duration(milliseconds: 100),
            child: Text(
              WorkshopTexts.discoverSubtitle,
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

  Widget _buildSearchBar() {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.lg,
        vertical: AppDimens.sm,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: colors.inputFill,
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        ),
        child: TextField(
          controller: _searchController,
          onSubmitted: (_) => _onSearch(),
          style: GoogleFonts.alata(fontSize: 14, color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: WorkshopTexts.searchMissions,
            hintStyle: GoogleFonts.alata(
              fontSize: 14,
              color: colors.textHint,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: colors.textHint,
              size: 20,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      _onSearch();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppDimens.md,
              vertical: AppDimens.sm + 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSortChips() {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.lg,
        vertical: AppDimens.xs,
      ),
      child: Row(
        children: [
          _buildChip(WorkshopTexts.recent, 'recent'),
          const SizedBox(width: AppDimens.sm),
          _buildChip(WorkshopTexts.popular, 'popular'),
          const Spacer(),
          Text(
            '$_total missions',
            style: GoogleFonts.alata(
              fontSize: 12,
              color: colors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, String value) {
    final colors = context.appColors;
    final isActive = _sortBy == value;
    return GestureDetector(
      onTap: () => _onSortChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.md,
          vertical: AppDimens.xs + 2,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primaryPurple
              : colors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusCircle),
        ),
        child: Text(
          label,
          style: GoogleFonts.alata(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? Colors.white : colors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final colors = context.appColors;
    if (_isLoading && _missions.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryPurple),
      );
    }

    if (_error != null && _missions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: colors.textHint),
            const SizedBox(height: AppDimens.md),
            Text(
              WorkshopTexts.couldNotLoad,
              style: GoogleFonts.alata(
                fontSize: 16,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimens.md),
            TextButton(
              onPressed: () => _loadMissions(refresh: true),
              child: Text(
                Common.tryAgain,
                style: GoogleFonts.alata(color: AppColors.primaryPurple),
              ),
            ),
          ],
        ),
      );
    }

    if (_missions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.extension_off_rounded, size: 48, color: colors.textHint),
            const SizedBox(height: AppDimens.md),
            Text(
              WorkshopTexts.noMissions,
              style: GoogleFonts.alata(
                fontSize: 16,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              WorkshopTexts.beFirst,
              style: GoogleFonts.alata(
                fontSize: 13,
                color: colors.textHint,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryPurple,
      onRefresh: () => _loadMissions(refresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppDimens.lg, AppDimens.sm, AppDimens.lg, 100,
        ),
        itemCount: _missions.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _missions.length) {
            _page++;
            _loadMissions();
            return const Padding(
              padding: EdgeInsets.all(AppDimens.lg),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primaryPurple),
              ),
            );
          }
          return FadeInWidget(
            delay: Duration(milliseconds: 50 * (index % 10)),
            child: _buildMissionCard(_missions[index]),
          );
        },
      ),
    );
  }

  Widget _buildMissionCard(WorkshopMission mission) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: () => context.push('/workshop/mission/${mission.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimens.md),
        padding: const EdgeInsets.all(AppDimens.md),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          border: Border.all(color: colors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              ),
              child: const Icon(
                Icons.quiz_rounded,
                color: AppColors.primaryPurple,
                size: 24,
              ),
            ),
            const SizedBox(width: AppDimens.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mission.title,
                    style: GoogleFonts.alata(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${WorkshopTexts.byAuthor} ${mission.authorName}',
                    style: GoogleFonts.alata(
                      fontSize: 12,
                      color: colors.textSecondary,
                    ),
                  ),
                  if (mission.tags.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      children: mission.tags.take(3).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tag,
                            style: GoogleFonts.alata(
                              fontSize: 10,
                              color: colors.textMuted,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              children: [
                Icon(
                  Icons.download_rounded,
                  size: 16,
                  color: colors.textHint,
                ),
                const SizedBox(height: 2),
                Text(
                  '${mission.downloadCount}',
                  style: GoogleFonts.alata(
                    fontSize: 11,
                    color: colors.textMuted,
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
