import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thinky/shared_controls/theme/app_colors.dart';
import 'package:thinky/shared_controls/theme/app_dimens.dart';
import 'package:thinky/core_controls/models/workshop_models.dart';
import 'package:thinky/core_controls/storage/workshop_storage.dart';

class WorkshopPlayPage extends StatefulWidget {
  final int missionId;

  const WorkshopPlayPage({super.key, required this.missionId});

  @override
  State<WorkshopPlayPage> createState() => _WorkshopPlayPageState();
}

class _WorkshopPlayPageState extends State<WorkshopPlayPage> {
  WorkshopMissionDetail? _mission;
  int _currentQuestion = 0;
  int? _selectedAnswer;
  bool _answered = false;
  int _correctCount = 0;
  bool _isFinished = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMission();
  }

  Future<void> _loadMission() async {
    final missions = await WorkshopStorage.getDownloadedMissions();
    final mission = missions.where((m) => m.id == widget.missionId).firstOrNull;
    setState(() {
      _mission = mission;
      _isLoading = false;
    });
  }

  void _selectAnswer(int index) {
    if (_answered) return;
    setState(() {
      _selectedAnswer = index;
      _answered = true;
      if (index == _mission!.questions[_currentQuestion].correctAnswerIndex) {
        _correctCount++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentQuestion + 1 >= _mission!.questions.length) {
      setState(() => _isFinished = true);
    } else {
      setState(() {
        _currentQuestion++;
        _selectedAnswer = null;
        _answered = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryPurple)),
      );
    }

    if (_mission == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Text(
            'Mission not found',
            style: GoogleFonts.alata(fontSize: 16, color: AppColors.textSecondary),
          ),
        ),
      );
    }

    if (_isFinished) return _buildResults();
    return _buildQuiz();
  }

  Widget _buildQuiz() {
    final question = _mission!.questions[_currentQuestion];
    final total = _mission!.questions.length;
    final progress = (_currentQuestion + 1) / total;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _mission!.title,
          style: GoogleFonts.alata(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress bar
            const SizedBox(height: AppDimens.sm),
            Row(
              children: [
                Text(
                  '${_currentQuestion + 1}/$total',
                  style: GoogleFonts.alata(fontSize: 13, color: AppColors.textMuted),
                ),
                const SizedBox(width: AppDimens.sm),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: AppColors.backgroundGrey,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primaryPurple),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.xl),

            // Question text
            Text(
              question.text,
              style: GoogleFonts.alata(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: AppDimens.xl),

            // Answer buttons
            ...question.answers.asMap().entries.map((entry) {
              final i = entry.key;
              final answer = entry.value;
              final isCorrect = i == question.correctAnswerIndex;
              final isSelected = _selectedAnswer == i;

              Color bgColor = AppColors.backgroundGrey;
              Color borderColor = const Color(0xFFE8E8ED);
              Color textColor = AppColors.textPrimary;

              if (_answered) {
                if (isCorrect) {
                  bgColor = const Color(0xFFE8F5E9);
                  borderColor = const Color(0xFF4CAF50);
                  textColor = const Color(0xFF2E7D32);
                } else if (isSelected && !isCorrect) {
                  bgColor = const Color(0xFFFFEBEE);
                  borderColor = const Color(0xFFEF5350);
                  textColor = const Color(0xFFC62828);
                }
              } else if (isSelected) {
                bgColor = AppColors.primaryPurple.withValues(alpha: 0.08);
                borderColor = AppColors.primaryPurple;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: AppDimens.sm),
                child: GestureDetector(
                  onTap: () => _selectAnswer(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.md,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                      border: Border.all(color: borderColor, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            answer.text,
                            style: GoogleFonts.alata(
                              fontSize: 15,
                              color: textColor,
                              fontWeight: (isSelected || (_answered && isCorrect))
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (_answered && isCorrect)
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50), size: 22),
                        if (_answered && isSelected && !isCorrect)
                          const Icon(Icons.cancel_rounded, color: Color(0xFFEF5350), size: 22),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const Spacer(),

            // Next button
            if (_answered)
              Padding(
                padding: const EdgeInsets.only(bottom: AppDimens.xxl),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _nextQuestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _currentQuestion + 1 >= _mission!.questions.length
                          ? 'See Results'
                          : 'Next Question',
                      style: GoogleFonts.alata(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    final total = _mission!.questions.length;
    final percentage = ((_correctCount / total) * 100).round();
    final isPerfect = _correctCount == total;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Result icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: isPerfect
                      ? const Color(0xFFE8F5E9)
                      : AppColors.primaryPurple.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPerfect ? Icons.emoji_events_rounded : Icons.quiz_rounded,
                  size: 50,
                  color: isPerfect ? const Color(0xFF4CAF50) : AppColors.primaryPurple,
                ),
              ),
              const SizedBox(height: AppDimens.xl),
              Text(
                isPerfect ? 'Perfect!' : 'Quiz Complete!',
                style: GoogleFonts.alata(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppDimens.sm),
              Text(
                '$_correctCount / $total correct ($percentage%)',
                style: GoogleFonts.alata(
                  fontSize: 18,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppDimens.sm),
              Text(
                _mission!.title,
                style: GoogleFonts.alata(
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              // Buttons
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _currentQuestion = 0;
                      _selectedAnswer = null;
                      _answered = false;
                      _correctCount = 0;
                      _isFinished = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Play Again',
                    style: GoogleFonts.alata(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.sm),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: Color(0xFFE8E8ED)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    ),
                  ),
                  child: Text(
                    'Back to Missions',
                    style: GoogleFonts.alata(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.lg),
            ],
          ),
        ),
      ),
    );
  }
}
