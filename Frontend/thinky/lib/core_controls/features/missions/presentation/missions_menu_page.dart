import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:thinky/shared_controls/widgets/animations/animated_widgets.dart';
import 'package:thinky/core_controls/models/mission_models.dart';
import 'package:thinky/core_controls/models/workshop_models.dart';
import 'package:thinky/core_controls/services/mission_service.dart';
import 'package:thinky/core_controls/storage/workshop_storage.dart';
import 'package:thinky/core_controls/services/auth_service.dart';
import 'package:thinky/shared_controls/theme/app_colors.dart';
import 'package:thinky/shared_controls/theme/app_colors_extension.dart';
import 'package:thinky/core/errors/error_logger.dart';
import 'package:thinky/core_controls/network/user_facing_error_mapper.dart';
import 'package:thinky/shared_controls/widgets/error_handler_ui.dart';

import 'package:thinky/core_controls/routing/route_names.dart';
import 'package:thinky/core_controls/constants/app_texts.dart';
import 'package:thinky/core_controls/services/language_service.dart';
import 'package:thinky/core_controls/network/mission_network_guard.dart';
import 'package:thinky/shared_controls/assets/app_assets.dart';

class MissionsMenuPage extends ConsumerStatefulWidget {
  const MissionsMenuPage({super.key});

  @override
  ConsumerState<MissionsMenuPage> createState() => _MissionsMenuPageState();
}

class _MissionsMenuPageState extends ConsumerState<MissionsMenuPage>
    with TickerProviderStateMixin {
  List<Mission> _missions = [];
  List<WorkshopMissionDetail> _workshopMissions = [];
  bool _isLoading = true;
  bool _isGuest = true;
  int _selectedTab = 0; // 0 = Default, 1 = Workshop
  final Set<int> _unlockedMissions = {};
  late AnimationController _unlockAnimationController;

  @override
  void initState() {
    super.initState();
    _unlockAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadMissions();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final user = await AuthService.getCurrentUser();
    final isGuest = user?['isGuest'] ?? true;
    setState(() => _isGuest = isGuest);
    if (!isGuest) _loadWorkshopMissions();
  }

  Future<void> _loadWorkshopMissions() async {
    try {
      final missions = await WorkshopStorage.getDownloadedMissions();
      setState(() => _workshopMissions = missions);
    } catch (e) {
      ErrorLogger().logDebug('Failed to load workshop missions: $e');
    }
  }

  @override
  void dispose() {
    _unlockAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadMissions() async {
    try {
      final response = await MissionService.getMissions();
      setState(() {
        _missions = response.missions;
        _isLoading = false;
        // Check for newly unlocked missions and trigger animation
        final previouslyLocked = _unlockedMissions;
        _unlockedMissions.clear();
        for (var mission in _missions) {
          if (!mission.isLocked && mission.progress?.isCompleted != true) {
            _unlockedMissions.add(mission.id);
            // If mission was previously locked and now unlocked, animate
            if (!previouslyLocked.contains(mission.id) && _missions.length > 1) {
              _unlockAnimationController.forward(from: 0.0);
            }
          }
        }
      });
    } catch (e, stack) {
      ErrorLogger().logError(e, stackTrace: stack);
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ErrorHandlerUI.showError(
          context,
          '${Missions.errorLoading}${UserFacingErrorMapper.map(e)}',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(textRefreshProvider);
    final colors = context.appColors;
    final themeBrightness = Theme.of(context).brightness;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Background decorative element (cloud-like shape in top right)
            Positioned(
              top: 0,
              right: 0,
              child: Opacity(
                opacity: 0.1,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade300,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Image.asset(
                AppAssets.missionsMenuUnion(themeBrightness),
                key: ValueKey(themeBrightness),
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // Header with title
                  FadeInWidget(
                    delay: const Duration(milliseconds: 200),
                    child: Text(
                      Missions.title,
                      style: GoogleFonts.alata(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FadeInWidget(
                    delay: const Duration(milliseconds: 300),
                    child: Text(
                      Missions.subtitle,
                      style: GoogleFonts.alata(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTabToggle(colors),
                  const SizedBox(height: 24),
                  _selectedTab == 0
                      ? (_isLoading
                          ? _buildMissionsGridSkeleton(context)
                          : _buildMissionsGrid(context))
                      : _buildWorkshopGrid(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionsGridSkeleton(BuildContext context) {
    final colors = context.appColors;
    Widget skel(double h) => Container(
          height: h,
          decoration: BoxDecoration(
            color: colors.shimmer,
            borderRadius: BorderRadius.circular(20),
          ),
        );
    return SizedBox(
      height: 420,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: [
                skel(200),
                const SizedBox(height: 16),
                skel(180),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: [
                skel(220),
                const SizedBox(height: 16),
                skel(160),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionsGrid(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = 24.0;
    final spacing = 16.0;
    final cardWidth = (screenWidth - horizontalPadding * 2 - spacing) / 2;

    final List<Map<String, double>> positions = [];
    final List<double> columnHeights = [0.0, 0.0];

    final double gap = spacing;

    for (int i = 0; i < _missions.length; i++) {
      final mission = _missions[i];
      final height = mission.height ?? 200.0;

      final columnIndex = columnHeights[0] <= columnHeights[1] ? 0 : 1;

      final x = columnIndex == 0 ? 0.0 : cardWidth + gap;
      final y = columnHeights[columnIndex];

      positions.add({'x': x, 'y': y, 'width': cardWidth, 'height': height});

      columnHeights[columnIndex] = y + height + gap;
    }

    final totalHeight = columnHeights[0] > columnHeights[1]
        ? columnHeights[0]
        : columnHeights[1];

    return SizedBox(
      height: totalHeight,
      child: Stack(
        children: List.generate(_missions.length, (index) {
          final mission = _missions[index];
          final position = positions[index];
          final isNewlyUnlocked = _unlockedMissions.contains(mission.id);

          return Positioned(
            left: position['x'],
            top: position['y'],
            width: position['width'],
            height: position['height'],
            child: _buildMissionCard(
              context: context,
              mission: mission,
              isLocked: mission.isLocked,
              isNewlyUnlocked: isNewlyUnlocked,
              onTap: mission.isLocked
                  ? null
                  : () async {
                      final ok = await MissionNetworkGuard.ensureOnlineForMission(
                        context,
                        mission.missionPath,
                      );
                      if (!ok || !context.mounted) return;

                      if (mission.missionPath == 'quiz') {
                        context.push(RouteNames.quiz);
                      } else if (mission.missionPath == 'pixy_learns') {
                        context.push(RouteNames.pixyLearns);
                      } else if (mission.missionPath == 'draw_shapes' ||
                          mission.missionPath == 'draw_triangle') {
                        context.push(RouteNames.drawShapes);
                      } else if (mission.missionPath == 'color_circle') {
                        context.push(RouteNames.colorCircle);
                      } else if (mission.missionPath == 'animals') {
                        context.push(RouteNames.animalsMission);
                      } else if (mission.missionPath == 'group_sorting') {
                        context.push(RouteNames.groupingMission);
                      } else if (mission.missionPath == 'vocabulary') {
                        context.push(RouteNames.vocabularyMission);
                      } else if (mission.missionPath == 'describe_image') {
                        context.push(RouteNames.describeMission);
                      } else if (mission.missionPath == 'pattern') {
                        context.push(RouteNames.patternMission);
                      } else if (mission.missionPath == 'numbers') {
                        context.push(RouteNames.numbersMission);
                      } else {
                        ErrorHandlerUI.showInfo(
                          context,
                          '${Common.comingSoon} (${mission.missionPath})',
                        );
                      }
                    },
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMissionCard({
    required BuildContext context,
    required Mission mission,
    required bool isLocked,
    required bool isNewlyUnlocked,
    VoidCallback? onTap,
  }) {
    final backgroundColor = mission.backgroundColorAsColor;
    final missionPath = mission.missionPath;
    final assetPath =
        missionPath == 'draw_triangle' ? 'draw_shapes' : missionPath;
    
    Widget cardWidget = ScaleInWidget(
      delay: Duration(milliseconds: 400 + (mission.orderIndex * 100)),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: backgroundColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background image
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    AppAssets.missionBackground(assetPath),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
              // Vector decorations
              Positioned(
                top: 10,
                left: 10,
                child: Opacity(
                  opacity: 0.3,
                  child: Image.asset(
                    AppAssets.missionVector1(assetPath),
                    width: 60,
                    height: 60,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                right: 10,
                child: Opacity(
                  opacity: 0.3,
                  child: Image.asset(
                    AppAssets.missionVector2(assetPath),
                    width: 50,
                    height: 50,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
              // Main illustration
              Positioned.fill(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Image.asset(
                      missionPath == 'quiz'
                          ? AppAssets.missionQuizCard
                          : AppAssets.missionCardDrawing(assetPath),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.extension_rounded,
                        size: 48,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ),
              ),
              // Title at the bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: backgroundColor.withOpacity(0.9),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Text(
                    MissionTitles.forPath(mission.missionPath, mission.title),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.alata(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              // Locked overlay
              if (isLocked)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock, size: 40, color: Colors.white),
                          const SizedBox(height: 8),
                          Text(
                            Missions.locked,
                            style: GoogleFonts.alata(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    
    // Add unlock animation if mission is newly unlocked
    if (isNewlyUnlocked) {
      return AnimatedBuilder(
        animation: _unlockAnimationController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_unlockAnimationController.value * 0.15),
            child: child,
          );
        },
        child: cardWidget,
      );
    }
    
    return cardWidget;
  }

  Widget _buildPlaceholderCard({
    required String title,
    required Color backgroundColor,
    required bool isLocked,
  }) {
    return ScaleInWidget(
      delay: const Duration(milliseconds: 500),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.alata(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            // Locked overlay
            if (isLocked)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock, size: 40, color: Colors.white),
                        const SizedBox(height: 8),
                        Text(
                          Missions.locked,
                          style: GoogleFonts.alata(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabToggle(AppColorsExtension colors) {
    return FadeInWidget(
      delay: const Duration(milliseconds: 350),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(23),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryPurple.withValues(alpha: 0.12),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            _buildToggleOption(Nav.missionsTab, 0, Icons.grid_view_rounded, colors),
            _buildToggleOption(Nav.workshop, 1, Icons.extension_rounded, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleOption(String label, int index, IconData icon, AppColorsExtension colors) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedTab = index);
          if (index == 1) _loadWorkshopMissions();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryPurple.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(19),
          ),
          child: Center(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: isSelected ? 19 : 20,
                    color: isSelected
                        ? AppColors.primaryPurple
                        : colors.textHint,
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: GoogleFonts.alata(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryPurple,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkshopGrid() {
    if (_workshopMissions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Column(
            children: [
              Icon(Icons.extension_off_rounded, size: 48, color: context.appColors.textHint),
              const SizedBox(height: 12),
              Text(
                WorkshopTexts.noDownloaded,
                style: GoogleFonts.alata(
                  fontSize: 16,
                  color: context.appColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                WorkshopTexts.browseWorkshop,
                style: GoogleFonts.alata(
                  fontSize: 13,
                  color: context.appColors.textHint,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _workshopMissions.asMap().entries.map((entry) {
        final index = entry.key;
        final mission = entry.value;
        return FadeInWidget(
          delay: Duration(milliseconds: 50 * index),
          child: _buildWorkshopMissionCard(mission),
        );
      }).toList(),
    );
  }

  Widget _buildWorkshopMissionCard(WorkshopMissionDetail mission) {
    return GestureDetector(
      onTap: () => context.push('/workshop-play/${mission.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
        color: context.appColors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.border),
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
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.quiz_rounded,
                color: AppColors.primaryPurple,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mission.title,
                    style: GoogleFonts.alata(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: context.appColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${WorkshopTexts.byAuthor} ${mission.authorName} · ${mission.questions.length} ${WorkshopTexts.questionsCount}',
                    style: GoogleFonts.alata(
                      fontSize: 12,
                      color: context.appColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Play icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryPurple,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}