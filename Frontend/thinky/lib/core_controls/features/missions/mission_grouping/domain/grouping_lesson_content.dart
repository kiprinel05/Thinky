import 'package:flutter/material.dart';
import 'package:thinky/core_controls/constants/app_texts.dart';
import 'package:thinky/core_controls/features/missions/mission_quiz/domain/quiz_lesson_content.dart';

final List<LessonCard> groupingLessonCards = [
  LessonCard(
    icon: Icons.category_rounded,
    title: () => GroupingSorting.lessonCard1Title,
    body: () => GroupingSorting.lessonCard1Body,
    funFact: () => GroupingSorting.lessonCard1Fact,
  ),
  LessonCard(
    icon: Icons.fingerprint_rounded,
    title: () => GroupingSorting.lessonCard2Title,
    body: () => GroupingSorting.lessonCard2Body,
    funFact: () => GroupingSorting.lessonCard2Fact,
  ),
  LessonCard(
    icon: Icons.model_training_rounded,
    title: () => GroupingSorting.lessonCard3Title,
    body: () => GroupingSorting.lessonCard3Body,
    funFact: () => GroupingSorting.lessonCard3Fact,
  ),
  LessonCard(
    icon: Icons.grid_on_rounded,
    title: () => GroupingSorting.lessonCard4Title,
    body: () => GroupingSorting.lessonCard4Body,
    funFact: () => GroupingSorting.lessonCard4Fact,
  ),
  LessonCard(
    icon: Icons.auto_awesome_rounded,
    title: () => GroupingSorting.lessonCard5Title,
    body: () => GroupingSorting.lessonCard5Body,
    funFact: () => GroupingSorting.lessonCard5Fact,
  ),
];
