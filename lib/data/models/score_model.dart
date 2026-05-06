/// Score Model
class ScoreModel {
  final int? id;
  final int userId;
  final int score;
  final int totalQuestions;
  final String category;
  final String? timestamp;

  ScoreModel({
    this.id,
    required this.userId,
    required this.score,
    required this.totalQuestions,
    required this.category,
    this.timestamp,
  });

  /// Calculate percentage
  double getPercentage() {
    if (totalQuestions == 0) return 0;
    return (score / totalQuestions) * 100;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'score': score,
      'totalQuestions': totalQuestions,
      'category': category,
      'timestamp': timestamp,
    };
  }

  /// Create from JSON
  factory ScoreModel.fromJson(Map<String, dynamic> json) {
    return ScoreModel(
      id: json['id'],
      userId: json['userId'],
      score: json['score'],
      totalQuestions: json['totalQuestions'],
      category: json['category'],
      timestamp: json['timestamp'],
    );
  }

  /// Create copy with modifications
  ScoreModel copyWith({
    int? id,
    int? userId,
    int? score,
    int? totalQuestions,
    String? category,
    String? timestamp,
  }) {
    return ScoreModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      score: score ?? this.score,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      category: category ?? this.category,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
