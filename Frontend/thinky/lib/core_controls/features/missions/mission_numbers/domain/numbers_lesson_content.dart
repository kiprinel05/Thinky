import 'package:flutter/material.dart';

import 'package:thinky/core_controls/constants/app_texts.dart';
import 'package:thinky/core_controls/features/missions/mission_quiz/domain/quiz_lesson_content.dart';

/// Five short, kid-friendly lessons shown in the "Learn with Pixy" view
/// of the Numbers mission. The content is sourced from the `NumbersMission`
/// i18n keys so it stays bilingual.
final List<LessonCard> numbersLessonCards = [
  LessonCard(
    icon: Icons.format_list_numbered_rounded,
    title: () => NumbersMission.lessonCardTitle(1),
    body: () => NumbersMission.lessonCardBody(1),
    funFact: () => NumbersMission.lessonCardFact(1),
  ),
  LessonCard(
    icon: Icons.visibility_rounded,
    title: () => NumbersMission.lessonCardTitle(2),
    body: () => NumbersMission.lessonCardBody(2),
    funFact: () => NumbersMission.lessonCardFact(2),
  ),
  LessonCard(
    icon: Icons.draw_rounded,
    title: () => NumbersMission.lessonCardTitle(3),
    body: () => NumbersMission.lessonCardBody(3),
    funFact: () => NumbersMission.lessonCardFact(3),
  ),
  LessonCard(
    icon: Icons.school_rounded,
    title: () => NumbersMission.lessonCardTitle(4),
    body: () => NumbersMission.lessonCardBody(4),
    funFact: () => NumbersMission.lessonCardFact(4),
  ),
  LessonCard(
    icon: Icons.favorite_rounded,
    title: () => NumbersMission.lessonCardTitle(5),
    body: () => NumbersMission.lessonCardBody(5),
    funFact: () => NumbersMission.lessonCardFact(5),
  ),
];
