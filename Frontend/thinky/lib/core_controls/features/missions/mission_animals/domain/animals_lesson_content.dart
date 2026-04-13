import 'package:flutter/material.dart';
import 'package:thinky/core_controls/constants/app_texts.dart';
import 'package:thinky/core_controls/features/missions/mission_quiz/domain/quiz_lesson_content.dart';

final List<LessonCard> animalsLessonCards = [
  LessonCard(
    icon: Icons.hub_rounded,
    title: () => Animals.lessonCard1Title,
    body: () => Animals.lessonCard1Body,
    funFact: () => Animals.lessonCard1Fact,
  ),
  LessonCard(
    icon: Icons.swap_horiz_rounded,
    title: () => Animals.lessonCard2Title,
    body: () => Animals.lessonCard2Body,
    funFact: () => Animals.lessonCard2Fact,
  ),
  LessonCard(
    icon: Icons.speed_rounded,
    title: () => Animals.lessonCard3Title,
    body: () => Animals.lessonCard3Body,
    funFact: () => Animals.lessonCard3Fact,
  ),
  LessonCard(
    icon: Icons.trending_up_rounded,
    title: () => Animals.lessonCard4Title,
    body: () => Animals.lessonCard4Body,
    funFact: () => Animals.lessonCard4Fact,
  ),
  LessonCard(
    icon: Icons.pets_rounded,
    title: () => Animals.lessonCard5Title,
    body: () => Animals.lessonCard5Body,
    funFact: () => Animals.lessonCard5Fact,
  ),
];
