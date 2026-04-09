import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:thinky/core_controls/features/missions/mission_quiz/domain/quiz_models.dart';
import 'package:thinky/core_controls/services/text_service.dart';

/// Localized quiz copy. Keys match [Question.id].
/// - `quiz_ro.json` — Romanian (API is English).
/// - `quiz_en.json` — mirrors [Backend/api/routers/quiz_router.py] `QUIZ_QUESTIONS` for 100% bundle-based EN or offline parity.
class QuizContentLocalization {
  QuizContentLocalization._();

  static const _roPath = 'assets/i18n/quiz_ro.json';
  static const _enPath = 'assets/i18n/quiz_en.json';

  static Map<String, dynamic>? _roCache;
  static Map<String, dynamic>? _enCache;

  static Future<Map<String, dynamic>> _loadMap(String assetPath) async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  static Future<void> _ensureLoaded(String languageCode) async {
    if (languageCode == 'ro') {
      _roCache ??= await _loadMap(_roPath);
      return;
    }
    if (languageCode == 'en') {
      _enCache ??= await _loadMap(_enPath);
    }
  }

  /// Applies `quiz_ro.json` or `quiz_en.json` when the locale matches and the bundle has entries.
  static Future<List<Question>> applyLocale(List<Question> questions) async {
    final code = TextService.currentLanguageCode;
    if (code != 'ro' && code != 'en') return questions;
    await _ensureLoaded(code);
    final map = code == 'ro' ? _roCache : _enCache;
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
