import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thinky/shared_controls/widgets/animated_widgets.dart';
import 'quiz_models.dart';
import 'quiz_answers_page.dart';

class QuizResultPage extends StatelessWidget {
  final QuizResult result;
  final List<Question> questions;
  final Map<int, int> selectedAnswers;
  final VoidCallback onContinue;

  const QuizResultPage({
    super.key,
    required this.result,
    required this.questions,
    required this.selectedAnswers,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = result.percentage;
    final isExcellent = percentage >= 80;
    final isGood = percentage >= 60;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF8E97FD)),
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top gradient header
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF8E97FD), Color(0xFF9AA2FD)],
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                children: [
                  ScaleInWidget(
                    delay: const Duration(milliseconds: 200),
                    child: Image.asset(
                      'missions/quiz/happy.png',
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isExcellent
                            ? '🎉'
                            : isGood
                                ? '👍'
                                : '💪',
                        style: const TextStyle(fontSize: 26),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isExcellent
                            ? 'Excellent!'
                            : isGood
                                ? 'Good job!'
                                : 'Keep learning!',
                        style: GoogleFonts.alata(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Score card
                    FadeInWidget(
                      delay: const Duration(milliseconds: 300),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 24,
                          horizontal: 20,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${percentage.toInt()}%',
                              style: GoogleFonts.alata(
                                fontSize: 48,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF8E97FD),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${result.correctAnswers} out of ${result.totalQuestions} correct',
                              style: GoogleFonts.alata(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF60646D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Helper text
                    FadeInWidget(
                      delay: const Duration(milliseconds: 350),
                      child: Text(
                        'Nice work! You can review each question and see the correct answers.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.alata(
                          fontSize: 14,
                          color: const Color(0xFF666666),
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Show results button
                    FadeInWidget(
                      delay: const Duration(milliseconds: 400),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => QuizAnswersPage(
                                  questions: questions,
                                  selectedAnswers:
                                      Map<int, int>.from(selectedAnswers),
                                ),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(
                              color: Color(0xFF8E97FD),
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: Text(
                            'SHOW DETAILED RESULTS',
                            style: GoogleFonts.alata(
                              color: const Color(0xFF8E97FD),
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Continue button
                    FadeInWidget(
                      delay: const Duration(milliseconds: 450),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: onContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8E97FD),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'CONTINUE TO MISSIONS',
                            style: GoogleFonts.alata(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

