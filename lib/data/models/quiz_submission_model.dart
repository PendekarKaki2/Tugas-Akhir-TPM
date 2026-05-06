/// Quiz submission model
class QuizSubmissionModel {
  final int? id;
  final int quizId;
  final int studentId;
  final String answers; // JSON stringified map
  final int score;
  final String? submittedAt;

  QuizSubmissionModel({
    this.id,
    required this.quizId,
    required this.studentId,
    required this.answers,
    required this.score,
    this.submittedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quizId': quizId,
      'studentId': studentId,
      'answers': answers,
      'score': score,
      'submittedAt': submittedAt,
    };
  }

  factory QuizSubmissionModel.fromJson(Map<String, dynamic> json) {
    return QuizSubmissionModel(
      id: json['id'],
      quizId: json['quizId'],
      studentId: json['studentId'],
      answers: json['answers'],
      score: json['score'],
      submittedAt: json['submittedAt'],
    );
  }
}
