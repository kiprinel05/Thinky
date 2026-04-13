import 'package:flutter/material.dart';
import 'package:thinky/core_controls/constants/app_texts.dart';
import 'package:thinky/core_controls/features/missions/mission_quiz/domain/quiz_lesson_content.dart';

final List<LessonCard> pixyLearnsLessonCards = [
  LessonCard(
    icon: Icons.image_search_rounded,
    title: () => PixyLearnsTexts.lessonCard1Title,
    body: () => PixyLearnsTexts.lessonCard1Body,
    funFact: () => PixyLearnsTexts.lessonCard1Fact,
  ),
  LessonCard(
    icon: Icons.dataset_rounded,
    title: () => PixyLearnsTexts.lessonCard2Title,
    body: () => PixyLearnsTexts.lessonCard2Body,
    funFact: () => PixyLearnsTexts.lessonCard2Fact,
  ),
  LessonCard(
    icon: Icons.school_rounded,
    title: () => PixyLearnsTexts.lessonCard3Title,
    body: () => PixyLearnsTexts.lessonCard3Body,
    funFact: () => PixyLearnsTexts.lessonCard3Fact,
  ),
  LessonCard(
    icon: Icons.grid_view_rounded,
    title: () => PixyLearnsTexts.lessonCard4Title,
    body: () => PixyLearnsTexts.lessonCard4Body,
    funFact: () => PixyLearnsTexts.lessonCard4Fact,
  ),
  LessonCard(
    icon: Icons.rocket_launch_rounded,
    title: () => PixyLearnsTexts.lessonCard5Title,
    body: () => PixyLearnsTexts.lessonCard5Body,
    funFact: () => PixyLearnsTexts.lessonCard5Fact,
  ),
];
