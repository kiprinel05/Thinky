import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thinky/shared_controls/theme/app_colors.dart';
import 'package:thinky/shared_controls/theme/app_dimens.dart';
import 'package:thinky/core_controls/models/workshop_models.dart';
import 'package:thinky/core_controls/services/workshop_service.dart';

class CreateMissionPage extends StatefulWidget {
  const CreateMissionPage({super.key});

  @override
  State<CreateMissionPage> createState() => _CreateMissionPageState();
}

class _CreateMissionPageState extends State<CreateMissionPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final List<_QuestionData> _questions = [_QuestionData()];
  bool _isPublishing = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _addQuestion() {
    setState(() => _questions.add(_QuestionData()));
  }

  void _removeQuestion(int index) {
    if (_questions.length <= 1) return;
    setState(() => _questions.removeAt(index));
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate all questions
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      if (q.textController.text.trim().isEmpty) {
        _showError('Question ${i + 1} text is empty');
        return;
      }
      final nonEmptyAnswers = q.answers
          .where((a) => a.controller.text.trim().isNotEmpty)
          .toList();
      if (nonEmptyAnswers.length < 2) {
        _showError('Question ${i + 1} needs at least 2 answers');
        return;
      }
      if (q.correctIndex >= nonEmptyAnswers.length) {
        _showError('Question ${i + 1}: select a valid correct answer');
        return;
      }
    }

    setState(() => _isPublishing = true);

    try {
      final tags = _tagsController.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      final questions = _questions.map((q) {
        final validAnswers = q.answers
            .where((a) => a.controller.text.trim().isNotEmpty)
            .toList();
        return WorkshopQuestion(
          text: q.textController.text.trim(),
          answers: validAnswers
              .map((a) => WorkshopAnswer(text: a.controller.text.trim()))
              .toList(),
          correctAnswerIndex: q.correctIndex,
        );
      }).toList();

      await WorkshopService.uploadMission(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        tags: tags,
        questions: questions,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mission published!', style: GoogleFonts.alata()),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            ),
          ),
        );
        context.pop();
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.alata()),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Create Mission',
          style: GoogleFonts.alata(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppDimens.lg, AppDimens.sm, AppDimens.lg, 100,
          ),
          children: [
            // Title
            _buildLabel('Title'),
            _buildTextField(
              controller: _titleController,
              hint: 'e.g. Capital Cities Quiz',
              validator: (v) =>
                  v == null || v.trim().length < 3 ? 'Title must be at least 3 characters' : null,
            ),
            const SizedBox(height: AppDimens.md),

            // Description
            _buildLabel('Description (optional)'),
            _buildTextField(
              controller: _descriptionController,
              hint: 'Describe your mission...',
              maxLines: 3,
            ),
            const SizedBox(height: AppDimens.md),

            // Tags
            _buildLabel('Tags (comma separated)'),
            _buildTextField(
              controller: _tagsController,
              hint: 'e.g. geography, science, fun',
            ),
            const SizedBox(height: AppDimens.xl),

            // Questions header
            Row(
              children: [
                Text(
                  'Questions',
                  style: GoogleFonts.alata(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_questions.length}',
                  style: GoogleFonts.alata(
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.md),

            // Question cards
            ..._questions.asMap().entries.map((entry) {
              return _buildQuestionCard(entry.key, entry.value);
            }),

            // Add question button
            const SizedBox(height: AppDimens.md),
            OutlinedButton.icon(
              onPressed: _addQuestion,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryPurple,
                side: const BorderSide(color: AppColors.primaryPurple),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                ),
                padding: const EdgeInsets.symmetric(vertical: AppDimens.md),
              ),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(
                'Add Question',
                style: GoogleFonts.alata(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: AppDimens.xl),

            // Publish button
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isPublishing ? null : _publish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                  ),
                  elevation: 0,
                ),
                icon: _isPublishing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.publish_rounded, size: 22),
                label: Text(
                  _isPublishing ? 'Publishing...' : 'Publish to Workshop',
                  style: GoogleFonts.alata(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.xs),
      child: Text(
        text,
        style: GoogleFonts.alata(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: GoogleFonts.alata(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.alata(fontSize: 14, color: AppColors.textHint),
        filled: true,
        fillColor: AppColors.backgroundGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimens.md,
          vertical: AppDimens.sm + 2,
        ),
      ),
    );
  }

  Widget _buildQuestionCard(int index, _QuestionData question) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.md),
      padding: const EdgeInsets.all(AppDimens.md),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question header
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.alata(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDimens.sm),
              Text(
                'Question',
                style: GoogleFonts.alata(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (_questions.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  color: AppColors.error,
                  onPressed: () => _removeQuestion(index),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
          const SizedBox(height: AppDimens.sm),

          // Question text
          _buildTextField(
            controller: question.textController,
            hint: 'Enter your question...',
          ),
          const SizedBox(height: AppDimens.md),

          // Answers
          Text(
            'Answers (tap ✓ to mark correct)',
            style: GoogleFonts.alata(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: AppDimens.sm),

          ...question.answers.asMap().entries.map((entry) {
            final aIndex = entry.key;
            final answer = entry.value;
            final isCorrect = question.correctIndex == aIndex;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppDimens.xs),
              child: Row(
                children: [
                  // Correct answer selector
                  GestureDetector(
                    onTap: () => setState(() => question.correctIndex = aIndex),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isCorrect ? AppColors.success : AppColors.backgroundGrey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: isCorrect ? Colors.white : AppColors.textHint,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimens.sm),
                  // Answer text
                  Expanded(
                    child: TextFormField(
                      controller: answer.controller,
                      style: GoogleFonts.alata(fontSize: 13, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Answer ${aIndex + 1}',
                        hintStyle: GoogleFonts.alata(fontSize: 13, color: AppColors.textHint),
                        filled: true,
                        fillColor: AppColors.backgroundGrey,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppDimens.sm,
                          vertical: AppDimens.xs + 2,
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                  // Remove answer
                  if (question.answers.length > 2)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16),
                      color: AppColors.textHint,
                      onPressed: () => setState(() {
                        question.answers.removeAt(aIndex);
                        if (question.correctIndex >= question.answers.length) {
                          question.correctIndex = 0;
                        }
                      }),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.only(left: 4),
                    ),
                ],
              ),
            );
          }),

          // Add answer button
          if (question.answers.length < 6)
            TextButton.icon(
              onPressed: () => setState(() => question.answers.add(_AnswerData())),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text(
                'Add answer',
                style: GoogleFonts.alata(fontSize: 12),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryPurple,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
        ],
      ),
    );
  }
}

/// Internal data holder for a question being built.
class _QuestionData {
  final TextEditingController textController = TextEditingController();
  List<_AnswerData> answers = [_AnswerData(), _AnswerData(), _AnswerData(), _AnswerData()];
  int correctIndex = 0;
}

/// Internal data holder for an answer option.
class _AnswerData {
  final TextEditingController controller = TextEditingController();
}
