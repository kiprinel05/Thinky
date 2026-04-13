import 'package:flutter/material.dart';
import 'package:thinky/core_controls/constants/app_texts.dart';
import 'package:thinky/core_controls/features/missions/mission_quiz/domain/quiz_lesson_content.dart';

final List<LessonCard> colorCircleLessonCards = [
  LessonCard(
    icon: Icons.palette_rounded,
    title: () => Drawing.colorLessonCard1Title,
    body: () => Drawing.colorLessonCard1Body,
    funFact: () => Drawing.colorLessonCard1Fact,
  ),
  LessonCard(
    icon: Icons.hub_rounded,
    title: () => Drawing.colorLessonCard2Title,
    body: () => Drawing.colorLessonCard2Body,
    funFact: () => Drawing.colorLessonCard2Fact,
  ),
  LessonCard(
    icon: Icons.color_lens_rounded,
    title: () => Drawing.colorLessonCard3Title,
    body: () => Drawing.colorLessonCard3Body,
    funFact: () => Drawing.colorLessonCard3Fact,
  ),
  LessonCard(
    icon: Icons.crop_free_rounded,
    title: () => Drawing.colorLessonCard4Title,
    body: () => Drawing.colorLessonCard4Body,
    funFact: () => Drawing.colorLessonCard4Fact,
  ),
  LessonCard(
    icon: Icons.colorize_rounded,
    title: () => Drawing.colorLessonCard5Title,
    body: () => Drawing.colorLessonCard5Body,
    funFact: () => Drawing.colorLessonCard5Fact,
  ),
];
