/// Models for the Describe-It mission.
///
/// The backend returns preloaded, bilingual, emoji-based scenes. The UI
/// picks the active language from LanguageService.
library;

import 'package:flutter/material.dart';

class DescribeItem {
  final int id;
  final String emoji;
  final String secondaryEmoji;
  final String accentHex;
  final String themeEn;
  final String themeRo;
  final String hintEn;
  final String hintRo;
  final List<String> keywordsEn;
  final List<String> keywordsRo;

  const DescribeItem({
    required this.id,
    required this.emoji,
    required this.secondaryEmoji,
    required this.accentHex,
    required this.themeEn,
    required this.themeRo,
    required this.hintEn,
    required this.hintRo,
    required this.keywordsEn,
    required this.keywordsRo,
  });

  factory DescribeItem.fromJson(Map<String, dynamic> json) {
    return DescribeItem(
      id: json['id'] ?? 0,
      emoji: (json['emoji'] ?? '') as String,
      secondaryEmoji: (json['secondaryEmoji'] ?? '') as String,
      accentHex: (json['accentHex'] ?? '#FF7043') as String,
      themeEn: (json['themeEn'] ?? '') as String,
      themeRo: (json['themeRo'] ?? '') as String,
      hintEn: (json['hintEn'] ?? '') as String,
      hintRo: (json['hintRo'] ?? '') as String,
      keywordsEn: (json['keywordsEn'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      keywordsRo: (json['keywordsRo'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  String themeFor(String lang) =>
      lang.toLowerCase().startsWith('ro') ? themeRo : themeEn;

  String hintFor(String lang) =>
      lang.toLowerCase().startsWith('ro') ? hintRo : hintEn;

  List<String> keywordsFor(String lang) =>
      lang.toLowerCase().startsWith('ro') ? keywordsRo : keywordsEn;

  /// Parses [accentHex] into a [Color]. Falls back to orange on failure.
  Color get accentColor {
    var hex = accentHex.replaceAll('#', '').trim();
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.tryParse(hex, radix: 16) ?? 0xFFFF7043);
  }
}

class DescribeStartResponse {
  final int missionId;
  final List<DescribeItem> questions;
  final int totalRounds;

  const DescribeStartResponse({
    required this.missionId,
    required this.questions,
    required this.totalRounds,
  });

  factory DescribeStartResponse.fromJson(Map<String, dynamic> json) {
    return DescribeStartResponse(
      missionId: json['missionId'] ?? 0,
      questions: (json['questions'] as List<dynamic>?)
              ?.map((e) => DescribeItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      totalRounds: json['totalRounds'] ?? 0,
    );
  }
}

class TranscriptionRoundResult {
  final bool success;
  final String transcription;
  final String detectedLang; // 'en' | 'ro' | 'mixed'
  final double matchScore;
  final List<String> matchedKeywords;
  final List<String> missingKeywords;
  final String message;
  final String encouragement;

  const TranscriptionRoundResult({
    required this.success,
    required this.transcription,
    required this.detectedLang,
    required this.matchScore,
    required this.matchedKeywords,
    required this.missingKeywords,
    required this.message,
    required this.encouragement,
  });

  factory TranscriptionRoundResult.fromJson(Map<String, dynamic> json) {
    return TranscriptionRoundResult(
      success: json['success'] ?? false,
      transcription: (json['transcription'] ?? '') as String,
      detectedLang: (json['detectedLang'] ?? 'en') as String,
      matchScore: (json['matchScore'] ?? 0.0).toDouble(),
      matchedKeywords: (json['matchedKeywords'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      missingKeywords: (json['missingKeywords'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      message: (json['message'] ?? '') as String,
      encouragement: (json['encouragement'] ?? '') as String,
    );
  }
}

class DescribeAnswerResponse {
  final bool success;
  final bool correct;
  final TranscriptionRoundResult result;
  final int completed;
  final int total;

  const DescribeAnswerResponse({
    required this.success,
    required this.correct,
    required this.result,
    required this.completed,
    required this.total,
  });

  factory DescribeAnswerResponse.fromJson(Map<String, dynamic> json) {
    return DescribeAnswerResponse(
      success: json['success'] ?? false,
      correct: json['correct'] ?? false,
      result: TranscriptionRoundResult.fromJson(
        (json['result'] as Map<String, dynamic>?) ?? const {},
      ),
      completed: json['completed'] ?? 0,
      total: json['total'] ?? 0,
    );
  }
}
