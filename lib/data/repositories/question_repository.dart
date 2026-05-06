import '../models/question_model.dart';
import '../sources/local/question_local_data_source.dart';

/// Question Repository
class QuestionRepository {
  final QuestionLocalDataSource _localDataSource;

  QuestionRepository(this._localDataSource);

  /// Initialize with sample questions if needed
  Future<void> initializeSampleQuestions() async {
    final questions = await _localDataSource.getAllQuestions();
    if (questions.isEmpty) {
      await _localDataSource.insertSampleQuestions();
    }
  }

  /// Get all questions
  Future<List<QuestionModel>> getAllQuestions() async {
    return await _localDataSource.getAllQuestions();
  }

  /// Get questions by category
  Future<List<QuestionModel>> getQuestionsByCategory(String category) async {
    return await _localDataSource.getQuestionsByCategory(category);
  }

  /// Get questions by difficulty
  Future<List<QuestionModel>> getQuestionsByDifficulty(String difficulty) async {
    return await _localDataSource.getQuestionsByDifficulty(difficulty);
  }

  /// Search questions
  Future<List<QuestionModel>> searchQuestions(String searchTerm) async {
    return await _localDataSource.searchQuestions(searchTerm);
  }

  /// Get random questions for quiz
  Future<List<QuestionModel>> getRandomQuestions(int limit) async {
    return await _localDataSource.getRandomQuestions(limit);
  }
}
