import 'package:flutter/material.dart';
import '../../data/models/material_model.dart';
import '../../data/models/quiz_model.dart';
import '../../data/models/quiz_question_model.dart';
import '../../data/repositories/material_repository.dart';
import '../../data/repositories/quiz_repository.dart';

class MentorProvider extends ChangeNotifier {
  final MaterialRepository _materialRepo;
  final QuizRepository _quizRepo;

  bool _isLoading = false;
  String? _error;

  MentorProvider(this._materialRepo, this._quizRepo);

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<int?> uploadMaterial(int mentorId, String title, String? content, String? filePath) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final model = MaterialModel(mentorId: mentorId, title: title, content: content, filePath: filePath);
      final id = await _materialRepo.createMaterial(model);
      return id;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<int?> createQuiz(int mentorId, String title, String type, List<QuizQuestionModel> questions) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final quiz = QuizModel(mentorId: mentorId, title: title, type: type);
      final quizId = await _quizRepo.createQuiz(quiz);
      for (final q in questions) {
        final qToInsert = QuizQuestionModel(
          quizId: quizId,
          questionText: q.questionText,
          options: q.options,
          correctAnswer: q.correctAnswer,
        );
        await _quizRepo.createQuestion(qToInsert);
      }
      return quizId;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
