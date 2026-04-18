import 'package:flutter/material.dart';

import 'package:thinky/core_controls/constants/app_texts.dart';
import 'package:thinky/core_controls/features/missions/mission_quiz/domain/quiz_lesson_content.dart';

/// Five short, kid-friendly lessons shown in the "Learn with Pixy" view
/// of the Complete-the-Pattern mission.
final List<LessonCard> patternLessonCards = [
  LessonCard(
    icon: Icons.extension_rounded,
    title: () => PatternMission.lessonCardTitle(1),
    body: () => PatternMission.lessonCardBody(1),
    funFact: () => PatternMission.lessonCardFact(1),
  ),
  LessonCard(
    icon: Icons.psychology_rounded,
    title: () => PatternMission.lessonCardTitle(2),
    body: () => PatternMission.lessonCardBody(2),
    funFact: () => PatternMission.lessonCardFact(2),
  ),
  LessonCard(
    icon: Icons.smart_toy_rounded,
    title: () => PatternMission.lessonCardTitle(3),
    body: () => PatternMission.lessonCardBody(3),
    funFact: () => PatternMission.lessonCardFact(3),
  ),
  LessonCard(
    icon: Icons.language_rounded,
    title: () => PatternMission.lessonCardTitle(4),
    body: () => PatternMission.lessonCardBody(4),
    funFact: () => PatternMission.lessonCardFact(4),
  ),
  LessonCard(
    icon: Icons.fitness_center_rounded,
    title: () => PatternMission.lessonCardTitle(5),
    body: () => PatternMission.lessonCardBody(5),
    funFact: () => PatternMission.lessonCardFact(5),
  ),
];
