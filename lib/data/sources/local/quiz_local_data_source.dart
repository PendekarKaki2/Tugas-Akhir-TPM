import '../../../core/services/database_service.dart';
import '../../models/quiz_model.dart';
import '../../models/quiz_question_model.dart';
import '../../models/quiz_submission_model.dart';

class QuizLocalDataSource {
  final DatabaseService _databaseService;

  QuizLocalDataSource(this._databaseService);

  Future<int> createQuiz(QuizModel quiz) async {
    try {
      final count = await _databaseService.getRowCount('quizzes');
      if (count >= DatabaseService.maxQuizzes) throw Exception('Quiz limit reached');
      final db = await _databaseService.database;
      final id = await db.insert('quizzes', {
        'mentorId': quiz.mentorId,
        'title': quiz.title,
        'createdAt': quiz.createdAt ?? DateTime.now().toIso8601String(),
      });
      return id;
    } catch (e) {
      throw Exception('Failed to create quiz: $e');
    }
  }

  Future<int> createQuestion(QuizQuestionModel question) async {
    try {
      final count = await _databaseService.getRowCount('quiz_questions');
      if (count >= DatabaseService.maxQuizQuestions) throw Exception('Quiz questions limit reached');
      final db = await _databaseService.database;
      final id = await db.insert('quiz_questions', {
        'quizId': question.quizId,
        'questionText': question.questionText,
        'type': question.type,
        'options': question.options,
        'correctAnswer': question.correctAnswer,
      });
      return id;
    } catch (e) {
      throw Exception('Failed to insert question: $e');
    }
  }

  Future<List<QuizModel>> getQuizzes() async {
    final db = await _databaseService.database;
    final rows = await db.query('quizzes', orderBy: 'createdAt DESC');
    return rows.map((r) => QuizModel.fromJson(r)).toList();
  }

  Future<List<QuizQuestionModel>> getQuestionsForQuiz(int quizId) async {
    final db = await _databaseService.database;
    final rows = await db.query('quiz_questions', where: 'quizId = ?', whereArgs: [quizId]);
    return rows.map((r) => QuizQuestionModel.fromJson(r)).toList();
  }

  Future<int> submitQuiz(QuizSubmissionModel submission) async {
    try {
      final count = await _databaseService.getRowCount('quiz_submissions');
      if (count >= DatabaseService.maxQuizSubmissions) throw Exception('Submissions limit reached');
      final db = await _databaseService.database;
      final id = await db.insert('quiz_submissions', {
        'quizId': submission.quizId,
        'studentId': submission.studentId,
        'answers': submission.answers,
        'score': submission.score,
        'submittedAt': submission.submittedAt ?? DateTime.now().toIso8601String(),
      });
      return id;
    } catch (e) {
      throw Exception('Failed to submit quiz: $e');
    }
  }
}
