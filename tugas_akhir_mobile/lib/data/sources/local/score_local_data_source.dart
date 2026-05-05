import 'package:flutter/foundation.dart';
import '../../../core/services/database_service.dart';
import '../../models/score_model.dart';

/// Local Data Source for Scores
class ScoreLocalDataSource {
  final DatabaseService _databaseService;
  static final Map<int, ScoreModel> _memoryScores = {};
  static int _memoryIdCounter = 1;

  ScoreLocalDataSource(this._databaseService);

  /// Create score
  Future<ScoreModel> createScore(ScoreModel score) async {
    if (kIsWeb) {
      final id = _memoryIdCounter++;
      final stored = score.copyWith(id: id, timestamp: DateTime.now().toIso8601String());
      _memoryScores[id] = stored;
      return stored;
    }

    try {
      final db = await _databaseService.database;
      final id = await db.insert(
        'scores',
        {
          'userId': score.userId,
          'score': score.score,
          'totalQuestions': score.totalQuestions,
          'category': score.category,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      return score.copyWith(id: id);
    } catch (_) {
      final id = _memoryIdCounter++;
      final stored = score.copyWith(id: id, timestamp: DateTime.now().toIso8601String());
      _memoryScores[id] = stored;
      return stored;
    }
  }

  /// Get scores by user
  Future<List<ScoreModel>> getScoresByUser(int userId) async {
    if (kIsWeb) {
      return _memoryScores.values.where((s) => s.userId == userId).toList();
    }

    try {
      final db = await _databaseService.database;
      final result = await db.query(
        'scores',
        where: 'userId = ?',
        whereArgs: [userId],
        orderBy: 'timestamp DESC',
      );
      return result.map((json) => ScoreModel.fromJson(json)).toList();
    } catch (_) {
      return _memoryScores.values.where((s) => s.userId == userId).toList();
    }
  }

  /// Get scores by category
  Future<List<ScoreModel>> getScoresByCategory(int userId, String category) async {
    final scores = await getScoresByUser(userId);
    return scores.where((score) => score.category == category).toList();
  }

  /// Get top scores (leaderboard)
  Future<List<ScoreModel>> getTopScores(int limit) async {
    final scores = _memoryScores.values.toList();
    final sorted = List<ScoreModel>.from(scores)..sort((a, b) => b.score.compareTo(a.score));
    return sorted.take(limit).toList();
  }

  /// Get average score for user
  Future<double> getAverageScore(int userId) async {
    final scores = await getScoresByUser(userId);
    if (scores.isEmpty) return 0;
    final total = scores.fold<double>(0, (sum, score) => sum + (score.score * 100.0 / score.totalQuestions));
    return total / scores.length;
  }
}
