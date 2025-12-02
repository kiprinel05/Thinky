import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import '../../../core/widgets/animated_widgets.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/mission_service.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> with TickerProviderStateMixin {
  List<Question> _questions = [];
  int _currentQuestionIndex = 0;
  Map<int, int> _selectedAnswers = {};
  bool _isLoading = true;
  bool _showIntroduction = true;
  bool _showResult = false;
  QuizResult? _quizResult;
  bool _isSubmitting = false;
  bool _showFeedback = false;
  bool _isCurrentAnswerCorrect = false;
  String _currentFeedbackText = '';
  late AnimationController _pixyAnimationController;
  late Animation<double> _pixyScaleAnimation;

  @override
  void initState() {
    super.initState();
    _pixyAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pixyScaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _pixyAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _loadQuestions();
  }

  @override
  void dispose() {
    _pixyAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    try {
      final response = await ApiClient.get('/quiz/questions');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _questions = (data['questions'] as List)
              .map((q) => Question.fromJson(q))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading questions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _selectAnswer(int answerId) {
    setState(() {
      _selectedAnswers[_currentQuestionIndex] = answerId;
    });
    _pixyAnimationController.forward(from: 0.0);
  }

  void _startQuiz() {
    setState(() {
      _showIntroduction = false;
    });
  }

  void _handleNextPressed() {
    if (!_selectedAnswers.containsKey(_currentQuestionIndex) || _showFeedback) {
      return;
    }

    final question = _questions[_currentQuestionIndex];
    final selectedAnswerId = _selectedAnswers[_currentQuestionIndex]!;
    final isCorrect = selectedAnswerId == question.correctAnswerId;

    setState(() {
      _isCurrentAnswerCorrect = isCorrect;
      _currentFeedbackText = question.explanation;
      _showFeedback = true;
    });
  }

  void _goToNextAfterFeedback() {
    setState(() {
      _showFeedback = false;
    });

    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      _submitQuiz();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  Future<void> _submitQuiz() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final answers = _questions.asMap().entries.map((entry) {
        final questionIndex = entry.key;
        final question = entry.value;
        final selectedAnswerId = _selectedAnswers[questionIndex] ?? 0;
        return {'question_id': question.id, 'answer_id': selectedAnswerId};
      }).toList();

      final response = await ApiClient.post('/quiz/submit', {
        'answers': answers,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _quizResult = QuizResult.fromJson(data);
          _showResult = true;
          _isSubmitting = false;
        });

        // Mark quiz mission as completed (assuming quiz is the first mission with order_index 0)
        try {
          await MissionService.completeMission(
            1,
            score: _quizResult!.percentage,
          );
        } catch (e) {
          // Log error but don't block UI
        }
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting quiz: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF9AA2FD),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 24),
              Text(
                'Loading questions...',
                style: GoogleFonts.alata(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (_showIntroduction) {
      return _buildIntroductionScreen();
    }

    if (_showResult && _quizResult != null) {
      return _buildResultScreen();
    }

    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF9AA2FD),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Text(
            'No questions available',
            style: GoogleFonts.alata(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF8E97FD)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'AI Quiz',
          style: GoogleFonts.alata(
            color: const Color(0xFF222222),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Top gradient background
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 220,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF8E97FD), Color(0xFF9AA2FD)],
                  ),
                ),
              ),
            ),
            // Main content
            Column(
              children: [
                // Progress bar
                _buildProgressBar(),
                const SizedBox(height: 8),
                // Pixy mascot fixed under header
                _buildPixyMascot(),
                const SizedBox(height: 16),
                // Scrollable question content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        // Question card
                        _buildQuestionCard(),
                        const SizedBox(height: 24),
                        // Navigation buttons
                        _buildNavigationButtons(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_showFeedback) _buildFeedbackOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroductionScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF9AA2FD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Background decoration
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Image.asset(
                'welcome/page1/background_welcome.png',
                fit: BoxFit.fitWidth,
                alignment: Alignment.bottomCenter,
                width: double.infinity,
              ),
            ),
            // Main content
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // Pixy mascot with enhanced styling
                  ScaleInWidget(
                    delay: const Duration(milliseconds: 300),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withOpacity(0.2),
                            Colors.white.withOpacity(0.05),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.3),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: ScaleTransition(
                        scale: _pixyScaleAnimation,
                        child: Image.asset(
                          'welcome/page2/thinking.png',
                          height: 220,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  // Introduction text with enhanced styling
                  FadeInWidget(
                    delay: const Duration(milliseconds: 400),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        "Let's see what you know about AI!",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.alata(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.3,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeInWidget(
                    delay: const Duration(milliseconds: 500),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "This is just a quick introduction to understand your knowledge. Don't worry, there are no wrong answers!",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.alata(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withOpacity(0.95),
                          height: 1.6,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),
                  // Start button with enhanced styling
                  FadeInWidget(
                    delay: const Duration(milliseconds: 600),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _startQuiz,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 22),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'START QUIZ',
                                style: GoogleFonts.alata(
                                  color: const Color(0xFF8E97FD),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 17,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: const Color(0xFF8E97FD),
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = (_currentQuestionIndex + 1) / _questions.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                style: GoogleFonts.alata(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: GoogleFonts.alata(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.white, Color(0xFFE3E7FF)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.6),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPixyMascot() {
    return FadeInWidget(
      delay: const Duration(milliseconds: 400),
      child: ScaleTransition(
        scale: _pixyScaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.15),
          ),
          child: Image.asset(
            'welcome/page2/thinking.png',
            height: 120,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard() {
    final question = _questions[_currentQuestionIndex];
    final selectedAnswerId = _selectedAnswers[_currentQuestionIndex];

    return FadeInWidget(
      delay: const Duration(milliseconds: 200),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question number badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF8E97FD).withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Question ${_currentQuestionIndex + 1}',
                style: GoogleFonts.alata(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF8E97FD),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Question text
            Text(
              question.question,
              style: GoogleFonts.alata(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF222222),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            // Answer options
            ...question.options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              final isSelected = selectedAnswerId == option.id;

              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 300 + (index * 100)),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Opacity(opacity: value, child: child),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () => _selectAnswer(option.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [Color(0xFF8E97FD), Color(0xFF9AA2FD)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isSelected ? null : const Color(0xFFF2F3F7),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : const Color(0xFFE0E2EA),
                          width: 2,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFF8E97FD,
                                  ).withOpacity(0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 6),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          // Radio button indicator
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFFB7BAC3),
                                width: 2.5,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Color(0xFF8E97FD),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          // Answer text
                          Expanded(
                            child: Text(
                              option.text,
                              style: GoogleFonts.alata(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF222222),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final hasSelection = _selectedAnswers.containsKey(_currentQuestionIndex);
    final isLastQuestion = _currentQuestionIndex == _questions.length - 1;
    final showPrevious = _currentQuestionIndex > 0;

    return Row(
      children: [
        if (showPrevious) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: _previousQuestion,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Color(0xFF8E97FD), width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                'PREVIOUS',
                style: GoogleFonts.alata(
                  color: const Color(0xFF8E97FD),
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
        Expanded(
          child: ElevatedButton(
            onPressed: hasSelection && !_isSubmitting
                ? _handleNextPressed
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: hasSelection
                  ? const Color(0xFF8E97FD)
                  : const Color(0xFF8E97FD).withOpacity(0.4),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: hasSelection ? 4 : 0,
              shadowColor: const Color(0xFF8E97FD).withOpacity(0.4),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    isLastQuestion ? 'SEE RESULT' : 'NEXT',
                    style: GoogleFonts.alata(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackOverlay() {
    final Color accentColor = _isCurrentAnswerCorrect
        ? const Color(0xFF4CAF50)
        : const Color(0xFFFF7043);
    final String titleText = _isCurrentAnswerCorrect
        ? 'Professor Pixy says:'
        : 'Professor Pixy explains:';
    final String badgeText = _isCurrentAnswerCorrect
        ? 'Correct answer!'
        : 'Let\'s learn from this';
    String feedbackText = _currentFeedbackText;
    if (!_isCurrentAnswerCorrect) {
      const positivePrefixes = [
        'Exactly! ',
        'Correct! ',
        'Great! ',
        'Very good! ',
        'Super! ',
        'Awesome! ',
      ];
      for (final prefix in positivePrefixes) {
        if (feedbackText.startsWith(prefix)) {
          feedbackText = feedbackText.substring(prefix.length);
          break;
        }
      }
    }

    return Stack(
      children: [
        // Blurred background
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(color: Colors.black.withOpacity(0.25)),
          ),
        ),
        // Professor + feedback card
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: FadeInWidget(
              delay: const Duration(milliseconds: 100),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: -170,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: 400,
                        height: 400,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.transparent,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Image.asset(
                            'missions/quiz/professor.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Feedback card
                  Container(
                    margin: const EdgeInsets.only(top: 60),
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title row with icon
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isCurrentAnswerCorrect
                                  ? Icons.check_circle_rounded
                                  : Icons.error_rounded,
                              size: 18,
                              color: accentColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              titleText,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.alata(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: accentColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            badgeText,
                            style: GoogleFonts.alata(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: accentColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          feedbackText,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.alata(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF222222),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _goToNextAfterFeedback,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'CONTINUE',
                              style: GoogleFonts.alata(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultScreen() {
    final result = _quizResult!;
    final percentage = result.percentage;
    final isExcellent = percentage >= 80;
    final isGood = percentage >= 60;

    return Scaffold(
      backgroundColor: const Color(0xFF9AA2FD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Background decoration
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Image.asset(
                'welcome/page1/background_welcome.png',
                fit: BoxFit.fitWidth,
                alignment: Alignment.bottomCenter,
                width: double.infinity,
              ),
            ),
            // Main content
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  ScaleInWidget(
                    delay: const Duration(milliseconds: 300),
                    child: Image.asset(
                      isExcellent
                          ? 'welcome/page1/hello.png'
                          : 'welcome/page2/thinking.png',
                      height: 180,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 40),
                  FadeInWidget(
                    delay: const Duration(milliseconds: 400),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isExcellent
                              ? '🎉'
                              : isGood
                              ? '👍'
                              : '💪',
                          style: const TextStyle(fontSize: 32),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isExcellent
                              ? 'Excellent!'
                              : isGood
                              ? 'Good Job!'
                              : 'Keep Learning!',
                          style: GoogleFonts.alata(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  FadeInWidget(
                    delay: const Duration(milliseconds: 500),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 32,
                        horizontal: 24,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${percentage.toInt()}%',
                            style: GoogleFonts.alata(
                              fontSize: 56,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF8E97FD),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F3F7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${result.correctAnswers} out of ${result.totalQuestions} correct',
                              style: GoogleFonts.alata(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF60646D),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Message text
                  FadeInWidget(
                    delay: const Duration(milliseconds: 600),
                    child: Text(
                      'Great! Now we know what you already know about AI. Let\'s start learning together!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.alata(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                  FadeInWidget(
                    delay: const Duration(milliseconds: 700),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'CONTINUE TO MISSIONS',
                              style: GoogleFonts.alata(
                                color: const Color(0xFF8E97FD),
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: const Color(0xFF8E97FD),
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Question {
  final int id;
  final String question;
  final List<AnswerOption> options;
  final int correctAnswerId;
  final String explanation;

  Question({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswerId,
    required this.explanation,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      question: json['question'],
      options: (json['options'] as List)
          .map((o) => AnswerOption.fromJson(o))
          .toList(),
      correctAnswerId: json['correct_answer_id'],
      explanation: json['explanation'],
    );
  }
}

class AnswerOption {
  final int id;
  final String text;

  AnswerOption({required this.id, required this.text});

  factory AnswerOption.fromJson(Map<String, dynamic> json) {
    return AnswerOption(id: json['id'], text: json['text']);
  }
}

class QuizResult {
  final int score;
  final int totalQuestions;
  final double percentage;
  final int correctAnswers;
  final int incorrectAnswers;

  QuizResult({
    required this.score,
    required this.totalQuestions,
    required this.percentage,
    required this.correctAnswers,
    required this.incorrectAnswers,
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      score: json['score'],
      totalQuestions: json['total_questions'],
      percentage: json['percentage'].toDouble(),
      correctAnswers: json['correct_answers'],
      incorrectAnswers: json['incorrect_answers'],
    );
  }
}

// FA PAGINA DE RASPUNSURI SI TRY AGAIN + EXPLICATIE
