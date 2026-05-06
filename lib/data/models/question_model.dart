/// Question Model
class QuestionModel {
  final int? id;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String category;
  final String difficulty;
  final String? imageUrl;

  QuestionModel({
    this.id,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.category,
    required this.difficulty,
    this.imageUrl,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options.join('|'), // Store as pipe-separated
      'correctAnswer': correctAnswer,
      'category': category,
      'difficulty': difficulty,
      'imageUrl': imageUrl,
    };
  }

  /// Create from JSON
  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'],
      question: json['question'],
      options: (json['options'] as String).split('|'),
      correctAnswer: json['correctAnswer'],
      category: json['category'],
      difficulty: json['difficulty'],
      imageUrl: json['imageUrl'],
    );
  }

  /// Create copy with modifications
  QuestionModel copyWith({
    int? id,
    String? question,
    List<String>? options,
    String? correctAnswer,
    String? category,
    String? difficulty,
    String? imageUrl,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      question: question ?? this.question,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
