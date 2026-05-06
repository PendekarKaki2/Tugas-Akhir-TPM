import 'package:flutter/material.dart';
import '../../data/models/material_model.dart';
import '../../data/models/quiz_model.dart';
import '../../data/models/quiz_question_model.dart';
import '../../data/models/quiz_submission_model.dart';
import '../../data/repositories/material_repository.dart';
import '../../data/repositories/quiz_repository.dart';

class StudentProvider extends ChangeNotifier {
  final MaterialRepository _materialRepo;
  final QuizRepository _quizRepo;

  StudentProvider(this._materialRepo, this._quizRepo);

  Future<List<MaterialModel>> getMaterials() async {
    return await _materialRepo.getAllMaterials();
  }

  Future<List<QuizModel>> getQuizzes() async {
    return await _quizRepo.getQuizzes();
  }

  Future<List<QuizQuestionModel>> getQuizQuestions(int quizId) async {
    return await _quizRepo.getQuestions(quizId);
  }

  Future<int> submitQuiz(int studentId, int quizId, Map<String, dynamic> answers, int score) async {
    final submission = QuizSubmissionModel(
      quizId: quizId,
      studentId: studentId,
      answers: answers.toString(),
      score: score,
    );
    return await _quizRepo.submitQuiz(submission);
  }
}
