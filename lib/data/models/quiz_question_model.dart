/// Quiz question model
class QuizQuestionModel {
  final int? id;
  final int quizId;
  final String questionText;
  final String type; // 'multiple_choice' atau 'essay'
  final String options; // JSON stringified list (kosong untuk essay)
  final String correctAnswer; // jawaban benar atau rubrik

  QuizQuestionModel({
    this.id,
    required this.quizId,
    required this.questionText,
    this.type = 'multiple_choice',
    required this.options,
    required this.correctAnswer,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quizId': quizId,
      'questionText': questionText,
      'type': type,
      'options': options,
      'correctAnswer': correctAnswer,
    };
  }

  factory QuizQuestionModel.fromJson(Map<String, dynamic> json) {
    return QuizQuestionModel(
      id: json['id'],
      quizId: json['quizId'],
      questionText: json['questionText'],
      type: json['type'] ?? 'multiple_choice',
      options: json['options'],
      correctAnswer: json['correctAnswer'],
    );
  }
}
