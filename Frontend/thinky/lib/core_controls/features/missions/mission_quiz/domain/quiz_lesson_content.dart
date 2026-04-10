import 'package:flutter/material.dart';
import 'package:thinky/core_controls/constants/app_texts.dart';

class LessonCard {
  final IconData icon;
  final String Function() title;
  final String Function() body;
  final String Function() funFact;

  const LessonCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.funFact,
  });
}

final List<LessonCard> quizLessonCards = [
  LessonCard(
    icon: Icons.psychology_rounded,
    title: () => Quiz.lessonCard1Title,
    body: () => Quiz.lessonCard1Body,
    funFact: () => Quiz.lessonCard1Fact,
  ),
  LessonCard(
    icon: Icons.model_training_rounded,
    title: () => Quiz.lessonCard2Title,
    body: () => Quiz.lessonCard2Body,
    funFact: () => Quiz.lessonCard2Fact,
  ),
  LessonCard(
    icon: Icons.devices_rounded,
    title: () => Quiz.lessonCard3Title,
    body: () => Quiz.lessonCard3Body,
    funFact: () => Quiz.lessonCard3Fact,
  ),
  LessonCard(
    icon: Icons.block_rounded,
    title: () => Quiz.lessonCard4Title,
    body: () => Quiz.lessonCard4Body,
    funFact: () => Quiz.lessonCard4Fact,
  ),
  LessonCard(
    icon: Icons.handshake_rounded,
    title: () => Quiz.lessonCard5Title,
    body: () => Quiz.lessonCard5Body,
    funFact: () => Quiz.lessonCard5Fact,
  ),
];
