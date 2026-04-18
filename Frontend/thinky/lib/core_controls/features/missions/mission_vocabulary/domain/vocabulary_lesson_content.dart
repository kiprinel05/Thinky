import 'package:flutter/material.dart';

import 'package:thinky/core_controls/constants/app_texts.dart';
import 'package:thinky/core_controls/features/missions/mission_quiz/domain/quiz_lesson_content.dart';

/// Five short, kid-friendly lessons shown in the "Learn with Pixy" view
/// of the Word Match mission.
final List<LessonCard> vocabularyLessonCards = [
  LessonCard(
    icon: Icons.label_important_rounded,
    title: () => Vocabulary.lessonCardTitle(1),
    body: () => Vocabulary.lessonCardBody(1),
    funFact: () => Vocabulary.lessonCardFact(1),
  ),
  LessonCard(
    icon: Icons.visibility_rounded,
    title: () => Vocabulary.lessonCardTitle(2),
    body: () => Vocabulary.lessonCardBody(2),
    funFact: () => Vocabulary.lessonCardFact(2),
  ),
  LessonCard(
    icon: Icons.psychology_rounded,
    title: () => Vocabulary.lessonCardTitle(3),
    body: () => Vocabulary.lessonCardBody(3),
    funFact: () => Vocabulary.lessonCardFact(3),
  ),
  LessonCard(
    icon: Icons.translate_rounded,
    title: () => Vocabulary.lessonCardTitle(4),
    body: () => Vocabulary.lessonCardBody(4),
    funFact: () => Vocabulary.lessonCardFact(4),
  ),
  LessonCard(
    icon: Icons.fitness_center_rounded,
    title: () => Vocabulary.lessonCardTitle(5),
    body: () => Vocabulary.lessonCardBody(5),
    funFact: () => Vocabulary.lessonCardFact(5),
  ),
];
