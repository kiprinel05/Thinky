import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:thinky/base_controls/base_page.dart';
import 'package:thinky/base_controls/base_state.dart';
import 'package:thinky/shared_controls/widgets/animations/animated_widgets.dart';
import '../controllers/quiz_controller.dart';
import '../controllers/quiz_state.dart';
import 'package:thinky/core_controls/features/missions/mission_quiz/domain/quiz_models.dart';
import 'package:thinky/core_controls/constants/app_texts.dart';

// We might need to import these if we extract them or just define here
// import 'quiz_result_page.dart'; // We will inline or use existing

class QuizPageNew extends BasePage {
  const QuizPageNew({super.key});

  @override
  Color get backgroundColor => const Color(0xFFF5F6FA);

  @override
  String? get title => Quiz.title;

  // Specific implementation for Quiz - we want custom background handling perhaps?
  // BasePage provides Scaffold. The original page had a specific gradient background for header.
  
  @override
  Widget buildBody(BuildContext context, WidgetRef ref) {
    // Watch state
    final state = ref.watch(quizStateProvider);
    final controller = ref.read(quizStateProvider.notifier);

    // Initial load
    if (state.status == StateStatus.initial) {
      // Trigger load safely
      Future.microtask(() => controller.loadQuestions());
      return buildLoading(context);
    }

    if (state.isLoading) {
      return buildLoading(context);
    }

    if (state.isError) {
      return buildError(context, state.errorMessage ?? 'Unknown error', controller.loadQuestions);
    }

    // Success state - Show Content
    return _QuizContent(state: state, controller: controller);
  }
}

class _QuizContent extends StatefulWidget {
  final QuizState state;
  final QuizController controller;

  const _QuizContent({required this.state, required this.controller});

  @override
  State<_QuizContent> createState() => _QuizContentState();
}

class _QuizContentState extends State<_QuizContent> with SingleTickerProviderStateMixin {
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
  }

  @override
  void dispose() {
    _pixyAnimationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_QuizContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If selected answer changed to a new selection on current question, animate Pixy?
    // Original: _selectAnswer -> controller.forward(from: 0).
    final currentQ = widget.state.currentQuestionIndex;
    final oldQ = oldWidget.state.currentQuestionIndex;
    
    // Logic: if answer selected for THIS question just now.
    if (currentQ == oldQ) {
       final newSel = widget.state.selectedAnswers[currentQ];
       final oldSel = oldWidget.state.selectedAnswers[currentQ];
       if (newSel != null && oldSel != newSel) {
          _pixyAnimationController.forward(from: 0.0);
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    // If result exists, show Result View
    if (widget.state.quizResult != null) {
      return _QuizResultView(result: widget.state.quizResult!);
    }
    
    // Check if questions empty
    if (widget.state.questions.isEmpty) {
        return Center(child: Text(Quiz.noQuestions, style: GoogleFonts.alata()));
    }

    return Stack(
      children: [
        // Header Gradient
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 160, // Adjusted height since AppBar is handled by BasePage or we are inside body
          // BasePage wraps body in Scaffold. AppBar is separate.
          // Original had Stack with gradient behind everything?
          // Original: Scaffold body: SafeArea(Stack(gradient container, content)).
          // BasePage: Scaffold body: buildBody.
          // We can put gradient here.
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
        
        Column(
          children: [
             _buildProgressBar(),
             const SizedBox(height: 8),
             _buildPixyMascot(),
             const SizedBox(height: 16),
             Expanded(
               child: SingleChildScrollView(
                 padding: const EdgeInsets.symmetric(horizontal: 24),
                 child: Column(
                   children: [
                     _buildQuestionCard(),
                     const SizedBox(height: 24),
                     _buildNavigationButtons(),
                     const SizedBox(height: 32),
                   ],
                 ),
               ),
             ),
          ],
        ),
        
        if (widget.state.showFeedback) _buildFeedbackOverlay(),
        
        // Loading overlay if submitting
        if (widget.state.isSubmitting)
           Container(
             color: Colors.black12,
             child: const Center(child: CircularProgressIndicator()),
           )
      ],
    );
  }

  Widget _buildProgressBar() {
    final state = widget.state;
    final total = state.questions.length;
    final current = state.currentQuestionIndex + 1;
    final progress = current / total;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${Quiz.questionLabel} $current ${Quiz.ofLabel} $total',
                style: GoogleFonts.alata(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
            'welcome/page2/thinking.png', // Corrected path assumption? Original was 'welcome/page2/thinking.png'
            // Keep original path structure if that's how assets are declared
            height: 120,
            fit: BoxFit.contain,
            errorBuilder: (c, e, s) => const Icon(Icons.person, size: 80, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard() {
    final state = widget.state;
    final question = state.currentQuestion;
    if (question == null) return const SizedBox();
    
    final selectedAnswerId = state.currentSelectedAnswerId;

    return FadeInWidget(
      key: ValueKey(question.id), // Animate when question changes
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
            Container(
               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
               decoration: BoxDecoration(
                 color: const Color(0xFF8E97FD).withOpacity(0.08),
                 borderRadius: BorderRadius.circular(16),
               ),
               child: Text(
                 '${Quiz.questionLabel} ${state.currentQuestionIndex + 1}',
                 style: GoogleFonts.alata(
                   fontSize: 11,
                   fontWeight: FontWeight.w500,
                   color: const Color(0xFF8E97FD),
                 ),
               ),
             ),
             const SizedBox(height: 12),
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
             ...question.options.map((option) {
               final isSelected = selectedAnswerId == option.id;
               return Padding(
                 padding: const EdgeInsets.only(bottom: 12),
                 child: GestureDetector(
                   onTap: () => widget.controller.selectAnswer(option.id),
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
                         color: isSelected ? Colors.transparent : const Color(0xFFE0E2EA),
                         width: 2,
                       ),
                       boxShadow: isSelected
                           ? [
                               BoxShadow(
                                 color: const Color(0xFF8E97FD).withOpacity(0.25),
                                 blurRadius: 10,
                                 offset: const Offset(0, 6),
                               ),
                             ]
                           : null,
                     ),
                     child: Row(
                       children: [
                         Container(
                           width: 24,
                           height: 24,
                           decoration: BoxDecoration(
                             shape: BoxShape.circle,
                             color: isSelected ? Colors.white : Colors.transparent,
                             border: Border.all(
                               color: isSelected ? Colors.white : const Color(0xFFB7BAC3),
                               width: 2.5,
                             ),
                           ),
                           child: isSelected
                               ? const Icon(Icons.check, size: 16, color: Color(0xFF8E97FD))
                               : null,
                         ),
                         const SizedBox(width: 16),
                         Expanded(
                           child: Text(
                             option.text,
                             style: GoogleFonts.alata(
                               fontSize: 14,
                               fontWeight: FontWeight.w500,
                               color: isSelected ? Colors.white : const Color(0xFF222222),
                               height: 1.4,
                             ),
                           ),
                         ),
                       ],
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
    final state = widget.state;
    final hasSelection = state.hasSelectedAnswer;
    final isLast = state.isLastQuestion;
    final showPrev = state.currentQuestionIndex > 0;

    return Row(
       children: [
         if (showPrev) ...[
           Expanded(
             child: OutlinedButton(
               onPressed: widget.controller.previousQuestion,
               style: OutlinedButton.styleFrom(
                 padding: const EdgeInsets.symmetric(vertical: 16),
                 side: const BorderSide(color: Color(0xFF8E97FD), width: 2),
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
               ),
               child: Text(
                 Quiz.previous,
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
             onPressed: hasSelection && !state.isSubmitting
                 ? widget.controller.showFeedback // Show detailed explanation first
                 : null,
             style: ElevatedButton.styleFrom(
               backgroundColor: hasSelection
                   ? const Color(0xFF8E97FD)
                   : const Color(0xFF8E97FD).withOpacity(0.4),
               padding: const EdgeInsets.symmetric(vertical: 16),
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
               elevation: hasSelection ? 4 : 0,
             ),
             child: state.isSubmitting
                 ? const SizedBox(
                     height: 22,
                     width: 22,
                     child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                   )
                 : Text(
                     isLast ? Quiz.seeResult : Quiz.next,
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
    final state = widget.state;
    final isCorrect = state.isLastAnswerCorrect;
    final Color accentColor = isCorrect ? const Color(0xFF4CAF50) : const Color(0xFFFF7043);
    final String titleText = isCorrect ? Quiz.feedbackCorrectTitle : Quiz.feedbackIncorrectTitle;
    
    return Stack(
      children: [
         Positioned.fill(
           child: BackdropFilter(
             filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
             child: Container(color: Colors.black.withOpacity(0.25)),
           ),
         ),
         Center(
           child: Padding(
             padding: const EdgeInsets.symmetric(horizontal: 24),
             child: FadeInWidget(
               child: Column(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   // Image etc omitted for brevity, using simplified card
                   Container(
                     padding: const EdgeInsets.all(24),
                     decoration: BoxDecoration(
                       color: Colors.white,
                       borderRadius: BorderRadius.circular(24),
                     ),
                     child: Column(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         Icon(
                            isCorrect ? Icons.check_circle_rounded : Icons.error_rounded,
                            size: 48, 
                            color: accentColor,
                         ),
                         const SizedBox(height: 16),
                         Text(
                           titleText,
                           style: GoogleFonts.alata(fontSize: 18, color: accentColor, fontWeight: FontWeight.bold),
                         ),
                         const SizedBox(height: 12),
                         Text(
                           state.feedbackText,
                           textAlign: TextAlign.center,
                           style: GoogleFonts.alata(fontSize: 15),
                         ),
                         const SizedBox(height: 24),
                         SizedBox(
                           width: double.infinity,
                           child: ElevatedButton(
                             onPressed: widget.controller.goToNextAfterFeedback,
                             style: ElevatedButton.styleFrom(backgroundColor: accentColor, shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(vertical: 14)),
                             child: Text(Quiz.continueAction, style: GoogleFonts.alata(color: Colors.white, fontWeight: FontWeight.bold)),
                           ),
                         )
                       ],
                     ),
                   ),
                 ],
               ),
             ),
           ),
         )
      ],
    );
  }
}

class _QuizResultView extends StatelessWidget {
  final QuizResult result;

  const _QuizResultView({required this.result});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events, size: 80, color: Color(0xFFFFCA28)),
          const SizedBox(height: 24),
          Text(
            Quiz.completedTitle,
            style: GoogleFonts.alata(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            '${Quiz.scoreLabel} ${(result.percentage).toInt()}%',
            style: GoogleFonts.alata(fontSize: 48, fontWeight: FontWeight.bold, color: const Color(0xFF8E97FD)),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(), // Go back to missions
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: const StadiumBorder(),
              backgroundColor: const Color(0xFF8E97FD),
            ),
            child: Text(Quiz.completeMission, style: GoogleFonts.alata(color: Colors.white)),
          )
        ],
      ),
    );
  }
}