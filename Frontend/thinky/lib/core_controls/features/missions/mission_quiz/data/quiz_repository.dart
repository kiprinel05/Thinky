import 'package:thinky/base_controls/base_repository.dart';
import 'package:thinky/core_controls/network/api_endpoints.dart';
import 'package:thinky/core_controls/network/api_exceptions.dart';
import 'package:thinky/shared/models/result.dart';
import 'package:thinky/core_controls/features/missions/mission_quiz/domain/quiz_models.dart';

/// Repository for Quiz feature
class QuizRepository extends BaseRepository {
  QuizRepository(super.storage);

  /// Fetch quiz questions
  Future<Result<List<Question>, ApiException>> getQuestions() async {
    return get<List<Question>>(
      endpoint: ApiEndpoints.quizQuestions,
      parser: (data) {
        final questionsList = data['questions'] as List;
        return questionsList.map((q) => Question.fromJson(q)).toList();
      },
    );
  }

  /// Submit quiz answers
  Future<Result<QuizResult, ApiException>> submitQuiz(List<Map<String, int>> answers) async {
    return post<QuizResult>(
      endpoint: ApiEndpoints.quizSubmit,
      body: {'answers': answers},
      parser: (data) => QuizResult.fromJson(data),
    );
  }
}