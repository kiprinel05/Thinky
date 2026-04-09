import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thinky/shared_controls/theme/app_colors.dart';
import 'package:thinky/shared_controls/theme/app_colors_extension.dart';
import 'package:thinky/shared_controls/theme/app_dimens.dart';
import 'package:thinky/core_controls/models/workshop_models.dart';
import 'package:thinky/core_controls/storage/workshop_storage.dart';
import 'package:thinky/core_controls/constants/app_texts.dart';

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
    final colors = context.appColors;
    if (_isLoading) {
      return Scaffold(
        backgroundColor: colors.background,
        body: const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple)),
      );
    }

    if (_mission == null) {
      return Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_rounded, color: colors.textPrimary),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Text(
            WorkshopTexts.missionNotFound,
            style: GoogleFonts.alata(fontSize: 16, color: colors.textSecondary),
          ),
        ),
      );
    }

    if (_isFinished) return _buildResults();
    return _buildQuiz();
  }

  Widget _buildQuiz() {
    final colors = context.appColors;
    final question = _mission!.questions[_currentQuestion];
    final total = _mission!.questions.length;
    final progress = (_currentQuestion + 1) / total;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                _mission!.title,
                style: GoogleFonts.alata(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_mission!.isVerified) ...[
              const SizedBox(width: 6),
              Tooltip(
                message: WorkshopTexts.verifiedHint,
                child: const Icon(
                  Icons.verified_rounded,
                  color: AppColors.success,
                  size: 22,
                ),
              ),
            ],
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
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
                    colors: [
                      Color(0xFF8E97FD),
                      Color(0xFF9AA2FD),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppDimens.sm),
                  _buildStyledProgress(progress, total),
                  const SizedBox(height: AppDimens.lg),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppDimens.lg),
                            decoration: BoxDecoration(
                              color: colors.cardColor,
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF8E97FD).withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    '${WorkshopTexts.questionLabel} ${_currentQuestion + 1}',
                                    style: GoogleFonts.alata(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF8E97FD),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  question.text,
                                  style: GoogleFonts.alata(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: colors.textPrimary,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: AppDimens.lg),
                                ...question.answers.asMap().entries.map((entry) {
                                  final i = entry.key;
                                  final answer = entry.value;
                                  final isCorrect = i == question.correctAnswerIndex;
                                  final isSelected = _selectedAnswer == i;

                                  Color bgColor = colors.inputFill;
                                  Color borderColor = colors.border;
                                  Color textColor = colors.textPrimary;
                                  Gradient? gradient;
                                  List<BoxShadow>? shadows;

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
                                    gradient = const LinearGradient(
                                      colors: [
                                        Color(0xFF8E97FD),
                                        Color(0xFF9AA2FD),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    );
                                    bgColor = Colors.transparent;
                                    borderColor = Colors.transparent;
                                    textColor = Colors.white;
                                    shadows = [
                                      BoxShadow(
                                        color: const Color(0xFF8E97FD).withOpacity(0.25),
                                        blurRadius: 10,
                                        offset: const Offset(0, 6),
                                      ),
                                    ];
                                  }

                                  return Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: AppDimens.sm),
                                    child: GestureDetector(
                                      onTap: () => _selectAnswer(i),
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 250),
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppDimens.md,
                                          vertical: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: gradient,
                                          color: gradient == null ? bgColor : null,
                                          borderRadius: BorderRadius.circular(18),
                                          border: Border.all(
                                            color: borderColor,
                                            width: 1.5,
                                          ),
                                          boxShadow: shadows,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                answer.text,
                                                style: GoogleFonts.alata(
                                                  fontSize: 15,
                                                  color: textColor,
                                                  fontWeight: (isSelected ||
                                                          (_answered && isCorrect))
                                                      ? FontWeight.w600
                                                      : FontWeight.w400,
                                                ),
                                              ),
                                            ),
                                            if (_answered && isCorrect)
                                              const Icon(
                                                Icons.check_circle_rounded,
                                                color: Color(0xFF4CAF50),
                                                size: 22,
                                              ),
                                            if (_answered &&
                                                isSelected &&
                                                !isCorrect)
                                              const Icon(
                                                Icons.cancel_rounded,
                                                color: Color(0xFFEF5350),
                                                size: 22,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppDimens.xl),
                          if (_answered)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppDimens.xxl,
                              ),
                              child: SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _nextQuestion,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF8E97FD),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(30),
                                    ),
                                    elevation: 4,
                                    shadowColor: const Color(0xFF8E97FD)
                                        .withOpacity(0.4),
                                  ),
                                  child: Text(
                                    _currentQuestion + 1 >=
                                            _mission!.questions.length
                                        ? WorkshopTexts.seeResults
                                        : WorkshopTexts.nextQuestion,
                                    style: GoogleFonts.alata(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
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
      ),
    );
  }

  Widget _buildStyledProgress(double progress, int total) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${WorkshopTexts.questionLabel} ${_currentQuestion + 1} ${Quiz.ofLabel} $total',
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
    );
  }

  Widget _buildResults() {
    final colors = context.appColors;
    final total = _mission!.questions.length;
    final percentage = ((_correctCount / total) * 100).round();
    final isPerfect = _correctCount == total;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
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
                isPerfect ? WorkshopTexts.perfect : WorkshopTexts.quizComplete,
                style: GoogleFonts.alata(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: AppDimens.sm),
              Text(
                '$_correctCount / $total ${WorkshopTexts.correct} ($percentage%)',
                style: GoogleFonts.alata(
                  fontSize: 18,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: AppDimens.sm),
              Text(
                _mission!.title,
                style: GoogleFonts.alata(
                  fontSize: 14,
                  color: colors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
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
                    WorkshopTexts.playAgain,
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
                    foregroundColor: colors.textSecondary,
                    side: BorderSide(color: colors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    ),
                  ),
                  child: Text(
                    Common.backToMissions,
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
