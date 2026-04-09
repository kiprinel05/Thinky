import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:thinky/core_controls/features/missions/mission_quiz/domain/quiz_models.dart';
import 'package:thinky/core_controls/services/text_service.dart';

/// Romanian copy for quiz items (API returns English). Keys match [Question.id].
class QuizContentLocalization {
  QuizContentLocalization._();

  static const _assetPath = 'assets/i18n/quiz_ro.json';

  static Map<String, dynamic>? _cache;

  static Future<void> _ensureLoaded() async {
    if (_cache != null) return;
    try {
      final raw = await rootBundle.loadString(_assetPath);
      _cache = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      _cache = {};
    }
  }

  /// Returns a new list with RO text applied when locale is `ro` and overrides exist.
  static Future<List<Question>> applyLocale(List<Question> questions) async {
    if (TextService.currentLanguageCode != 'ro') return questions;
    await _ensureLoaded();
    final map = _cache;
    if (map == null || map.isEmpty) return questions;

    return questions.map((q) {
      final entry = map['${q.id}'];
      if (entry is! Map<String, dynamic>) return q;

      final qText = entry['question'] as String?;
      final expl = entry['explanation'] as String?;
      final optionsMap = entry['options'];
      List<AnswerOption> opts = q.options;
      if (optionsMap is Map<String, dynamic>) {
        opts = q.options
            .map((o) {
              final t = optionsMap['${o.id}'] as String?;
              return t != null ? AnswerOption(id: o.id, text: t) : o;
            })
            .toList();
      }

      return Question(
        id: q.id,
        question: qText ?? q.question,
        options: opts,
        correctAnswerId: q.correctAnswerId,
        explanation: expl ?? q.explanation,
      );
    }).toList();
  }
}
