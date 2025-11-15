import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/widgets/animated_widgets.dart';
import 'quiz_page.dart';

class MissionsMenuPage extends StatelessWidget {
  const MissionsMenuPage({super.key});

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
                  FadeInWidget(
                    delay: const Duration(milliseconds: 200),
                    child: Text(
                      "Let's start teaching Pixy simple things!",
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
                      "choose a topic to teach:",
                      style: GoogleFonts.alata(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF8A8A8F),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildMissionsGrid(context),
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

      final missions = [
        {
          'type': 'mission',
          'title': 'Introduction Quiz',
          'backgroundColor': const Color(0xFF8E97FD),
          'missionPath': 'quiz',
          'height': 220.0,
          'locked': false,
        },
        {
          'type': 'mission',
          'title': 'Geometric Shapes',
          'backgroundColor': const Color(0xFF9B59B6),
          'missionPath': 'geometric_shapes',
          'height': 200.0,
          'locked': true,
        },
        {
          'type': 'placeholder',
          'title': 'Improve Performance',
          'backgroundColor': Colors.red.shade300,
          'height': 180.0,
          'locked': true,
        },
      {
        'type': 'placeholder',
        'title': 'Increase Happiness',
        'backgroundColor': Colors.orange.shade300,
        'height': 200.0,
        'locked': true,
      },
      {
        'type': 'placeholder',
        'title': 'Reduce Anxiety',
        'backgroundColor': Colors.yellow.shade300,
        'height': 190.0,
        'locked': true,
      },
      {
        'type': 'placeholder',
        'title': 'Personal Growth',
        'backgroundColor': Colors.green.shade300,
        'height': 210.0,
        'locked': true,
      },
      {
        'type': 'placeholder',
        'title': 'Better Sleep',
        'backgroundColor': Colors.blueGrey.shade300,
        'height': 195.0,
        'locked': true,
      },
    ];

    final List<Map<String, double>> positions = [];
    final List<double> columnHeights = [0.0, 0.0];

    final double gap = spacing;

    for (int i = 0; i < missions.length; i++) {
      final height = missions[i]['height'] as double;

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
        children: List.generate(missions.length, (index) {
          final mission = missions[index];
          final position = positions[index];

          final isLocked = mission['locked'] as bool? ?? false;

          return Positioned(
            left: position['x'],
            top: position['y'],
            width: position['width'],
            height: position['height'],
            child: mission['type'] == 'mission'
                ? _buildMissionCard(
                    context: context,
                    title: mission['title'] as String,
                    backgroundColor: mission['backgroundColor'] as Color,
                    missionPath: mission['missionPath'] as String,
                    isLocked: isLocked,
                    onTap: isLocked
                        ? null
                        : () {
                            if (mission['missionPath'] == 'quiz') {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const QuizPage(),
                                ),
                              );
                            } else if (mission['missionPath'] == 'geometric_shapes') {
                              // TODO: Navigate to Geometric Shapes mission
                            }
                          },
                  )
                : _buildPlaceholderCard(
                    title: mission['title'] as String,
                    backgroundColor: mission['backgroundColor'] as Color,
                    isLocked: isLocked,
                  ),
          );
        }),
      ),
    );
  }

  Widget _buildMissionCard({
    required BuildContext context,
    required String title,
    required Color backgroundColor,
    required String missionPath,
    required bool isLocked,
    VoidCallback? onTap,
  }) {
    return ScaleInWidget(
      delay: const Duration(milliseconds: 400),
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
                      'missions/$missionPath/card_drawing.png',
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
                            'Locked',
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
                          'Locked',
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
