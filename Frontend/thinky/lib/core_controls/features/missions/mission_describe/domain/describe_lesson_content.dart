import 'package:flutter/material.dart';

import 'package:thinky/core_controls/constants/app_texts.dart';
import 'package:thinky/core_controls/features/missions/mission_quiz/domain/quiz_lesson_content.dart';

/// Five short, kid-friendly lessons shown in the "Learn with Pixy" view
/// of the Describe-It mission.
final List<LessonCard> describeLessonCards = [
  LessonCard(
    icon: Icons.record_voice_over_rounded,
    title: () => DescribeMission.lessonCardTitle(1),
    body: () => DescribeMission.lessonCardBody(1),
    funFact: () => DescribeMission.lessonCardFact(1),
  ),
  LessonCard(
    icon: Icons.palette_rounded,
    title: () => DescribeMission.lessonCardTitle(2),
    body: () => DescribeMission.lessonCardBody(2),
    funFact: () => DescribeMission.lessonCardFact(2),
  ),
  LessonCard(
    icon: Icons.hearing_rounded,
    title: () => DescribeMission.lessonCardTitle(3),
    body: () => DescribeMission.lessonCardBody(3),
    funFact: () => DescribeMission.lessonCardFact(3),
  ),
  LessonCard(
    icon: Icons.translate_rounded,
    title: () => DescribeMission.lessonCardTitle(4),
    body: () => DescribeMission.lessonCardBody(4),
    funFact: () => DescribeMission.lessonCardFact(4),
  ),
  LessonCard(
    icon: Icons.fitness_center_rounded,
    title: () => DescribeMission.lessonCardTitle(5),
    body: () => DescribeMission.lessonCardBody(5),
    funFact: () => DescribeMission.lessonCardFact(5),
  ),
];
