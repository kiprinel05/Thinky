import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:thinky/shared_controls/widgets/animated_widgets.dart';
import 'package:thinky/core_controls/models/mission_models.dart';
import 'package:thinky/core_controls/services/mission_service.dart';
import 'package:thinky/core_controls/services/app_state_service.dart';
import 'package:thinky/core_controls/features/auth/presentation/profile_page.dart';
import '../mission_quiz/quiz_page.dart';
import '../mission_pixy_learns/presentation/pages/pixy_learns_page.dart';
import 'package:thinky/core_controls/constants/app_texts.dart';
import '../mission_drawing/presentation/draw_triangle_page.dart';

class MissionsMenuPage extends StatefulWidget {
  const MissionsMenuPage({super.key});

  @override
  State<MissionsMenuPage> createState() => _MissionsMenuPageState();
}

class _MissionsMenuPageState extends State<MissionsMenuPage> with TickerProviderStateMixin {
  List<Mission> _missions = [];
  bool _isLoading = true;
  Set<int> _unlockedMissions = {}; // Track newly unlocked missions for animation
  late AnimationController _unlockAnimationController;

  @override
  void initState() {
    super.initState();
    _unlockAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadMissions();
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
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${Missions.errorLoading} $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                'missions/missions/presentation/Union.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // Header with title and profile button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FadeInWidget(
                              delay: const Duration(milliseconds: 200),
                              child: Text(
                                Missions.title,
                                style: GoogleFonts.alata(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF222222),
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
                                  color: const Color(0xFF8A8A8F),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      FadeInWidget(
                        delay: const Duration(milliseconds: 400),
                        child: IconButton(
                          onPressed: () async {
                            await AppStateService.setLastRoute('missions');
                            if (mounted) {
                              Navigator.of(context).push(
                                SlidePageRoute(
                                  page: const ProfilePage(),
                                  direction: SlideDirection.left,
                                ),
                              );
                            }
                          },
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F3F7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Color(0xFF8E97FD),
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : _buildMissionsGrid(context),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
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
                  : () {
                      if (mission.missionPath == 'quiz') {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const QuizPage(),
                          ),
                        ).then((_) {
                          // Reload missions when returning from quiz
                          _loadMissions();
                        });
                      } else if (mission.missionPath == 'pixy_learns') {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PixyLearnsPage(),
                          ),
                        ).then((shouldReload) {
                          if (shouldReload == true) {
                            _loadMissions();
                          }
                        });
                      } else if (mission.missionPath == 'draw_triangle') {
                        // Navigate to Draw Triangle mission
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const DrawTrianglePage(),
                          ),
                        ).then((shouldReload) {
                          if (shouldReload == true) {
                            _loadMissions();
                          }
                        });
                      } else {
                        // Default: show message for unhandled missions
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Mission "${mission.missionPath}" coming soon!'),
                            duration: const Duration(seconds: 2),
                          ),
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
                    'missions/$missionPath/background.png',
                    fit: BoxFit.cover,
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
                    'missions/$missionPath/vector1.png',
                    width: 60,
                    height: 60,
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                right: 10,
                child: Opacity(
                  opacity: 0.3,
                  child: Image.asset(
                    'missions/$missionPath/vector2.png',
                    width: 50,
                    height: 50,
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
                          ? 'missions/quiz/quiz.png'
                          : 'missions/$missionPath/card_drawing.png',
                      fit: BoxFit.contain,
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
                    mission.title,
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
}