import 'package:flutter_test/flutter_test.dart';
import 'package:thinky/core_controls/features/missions/mission_quiz/presentation/utils/quiz_feedback_text.dart';

void main() {
  test('keeps explanation when answer is correct', () {
    const s = 'Exactly! AI is cool.';
    expect(quizFeedbackBodyForDisplay(s, isCorrect: true), s);
  });

  test('strips celebratory prefix when answer is wrong (EN)', () {
    expect(
      quizFeedbackBodyForDisplay(
        'Exactly! AI is like a student.',
        isCorrect: false,
      ),
      'AI is like a student.',
    );
  });

  test('strips celebratory prefix when answer is wrong (RO)', () {
    expect(
      quizFeedbackBodyForDisplay(
        'Exact! IA este rapidă.',
        isCorrect: false,
      ),
      'IA este rapidă.',
    );
  });
}
