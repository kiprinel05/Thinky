import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:thinky/base_controls/base_page.dart';
import 'package:thinky/base_controls/base_state.dart';
import 'package:thinky/shared_controls/widgets/states/app_content_skeletons.dart';
import 'package:thinky/core_controls/constants/app_texts.dart';
import 'package:thinky/core_controls/services/language_service.dart';

import '../controllers/quiz_controller.dart';
import 'quiz_question_view.dart';
import 'quiz_result_view.dart';

class QuizPage extends BasePage {
  const QuizPage({super.key});

  @override
  String? get title => Quiz.title;

  @override
  Widget buildLoading(BuildContext context) {
    return AppContentSkeletons.quizPageBody(context);
  }

  @override
  Widget buildBody(BuildContext context, WidgetRef ref) {
    ref.watch(textRefreshProvider);
    final state = ref.watch(quizStateProvider);
    final controller = ref.read(quizStateProvider.notifier);

    if (state.status == StateStatus.initial) {
      Future.microtask(() => controller.loadQuestions());
      return buildLoading(context);
    }

    if (state.isLoading) return buildLoading(context);

    if (state.isError) {
      return buildError(
        context,
        state.errorMessage ?? 'Unknown error',
        controller.loadQuestions,
      );
    }

    if (state.quizResult != null) {
      return QuizResultView(state: state);
    }

    return QuizQuestionView(state: state, controller: controller);
  }
}
