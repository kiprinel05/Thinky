import 'dart:convert';

abstract class MissionFixtures {
  static String singleMissionJson() => jsonEncode({
        'missions': [
          {
            'id': 1,
            'title': 'Test Mission',
            'description': 'A test mission',
            'mission_path': 'quiz',
            'icon': '📝',
            'color': '#8E97FD',
            'order': 1,
            'is_locked': false,
            'is_completed': false,
          }
        ],
      });

  static String multipleMissionsJson() => jsonEncode({
        'missions': [
          {
            'id': 1,
            'title': 'Quiz Time',
            'description': 'Test your knowledge',
            'mission_path': 'quiz',
            'icon': '📝',
            'color': '#8E97FD',
            'order': 1,
            'is_locked': false,
            'is_completed': false,
          },
          {
            'id': 2,
            'title': 'Draw Shapes',
            'description': 'Creative drawing',
            'mission_path': 'draw_shapes',
            'icon': '🎨',
            'color': '#FFB59E',
            'order': 2,
            'is_locked': true,
            'is_completed': false,
          },
        ],
      });

  static Map<String, dynamic> textsMap() => {
        'Missions': {
          'title': 'Test Missions Title',
          'subtitle': 'Test subtitle',
          'errorLoading': 'Error loading: ',
          'locked': 'Locked',
        },
      };
}
