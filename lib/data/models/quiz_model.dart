/// Quiz model
class QuizModel {
  final int? id;
  final int mentorId;
  final String title;
  final String type; // 'multiple_choice' or 'essay'
  final String? createdAt;

  QuizModel({
    this.id,
    required this.mentorId,
    required this.title,
    this.type = 'multiple_choice',
    this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mentorId': mentorId,
      'title': title,
      'type': type,
      'createdAt': createdAt,
    };
  }

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    return QuizModel(
      id: json['id'],
      mentorId: json['mentorId'],
      title: json['title'],
      type: json['type'] ?? 'multiple_choice',
      createdAt: json['createdAt'],
    );
  }
}
