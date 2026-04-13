import 'package:flutter/material.dart';
import 'package:thinky/core_controls/constants/app_texts.dart';
import 'package:thinky/core_controls/features/missions/mission_quiz/domain/quiz_lesson_content.dart';

final List<LessonCard> drawShapesLessonCards = [
  LessonCard(
    icon: Icons.visibility_rounded,
    title: () => Drawing.shapesLessonCard1Title,
    body: () => Drawing.shapesLessonCard1Body,
    funFact: () => Drawing.shapesLessonCard1Fact,
  ),
  LessonCard(
    icon: Icons.border_style_rounded,
    title: () => Drawing.shapesLessonCard2Title,
    body: () => Drawing.shapesLessonCard2Body,
    funFact: () => Drawing.shapesLessonCard2Fact,
  ),
  LessonCard(
    icon: Icons.fingerprint_rounded,
    title: () => Drawing.shapesLessonCard3Title,
    body: () => Drawing.shapesLessonCard3Body,
    funFact: () => Drawing.shapesLessonCard3Fact,
  ),
  LessonCard(
    icon: Icons.how_to_vote_rounded,
    title: () => Drawing.shapesLessonCard4Title,
    body: () => Drawing.shapesLessonCard4Body,
    funFact: () => Drawing.shapesLessonCard4Fact,
  ),
  LessonCard(
    icon: Icons.auto_awesome_rounded,
    title: () => Drawing.shapesLessonCard5Title,
    body: () => Drawing.shapesLessonCard5Body,
    funFact: () => Drawing.shapesLessonCard5Fact,
  ),
];
