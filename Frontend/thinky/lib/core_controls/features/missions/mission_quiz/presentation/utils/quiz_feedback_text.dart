/// Quiz API explanations are written for the *correct* case (e.g. "Exactly! ...").
/// When the learner is wrong, strip leading celebratory prefixes so the copy stays honest.
String quizFeedbackBodyForDisplay(String rawExplanation, {required bool isCorrect}) {
  var s = rawExplanation.trim();
  if (isCorrect) return s;

  const patterns = [
    r'^Exactly!\s*',
    r'^Correct!\s*',
    r'^Bingo!\s*',
    r'^Very good!\s*',
    r'^Great attitude!\s*',
    r'^Well done!\s*',
    r'^Nice!\s*',
    r'^Super!\s*',
    // Romanian overlays (`quiz_ro.json`)
    r'^Exact!\s*',
    r'^Corect!\s*',
    r'^Bravo!\s*',
    r'^Foarte bine!\s*',
    r'^Super atitudine!\s*',
  ];
  for (final p in patterns) {
    s = s.replaceFirst(RegExp(p, caseSensitive: false), '');
  }
  return s.trimLeft();
}
