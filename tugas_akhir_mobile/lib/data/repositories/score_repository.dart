import '../models/score_model.dart';
import '../sources/local/score_local_data_source.dart';

/// Score Repository
class ScoreRepository {
  final ScoreLocalDataSource _localDataSource;

  ScoreRepository(this._localDataSource);

  /// Create score
  Future<ScoreModel> createScore(ScoreModel score) async {
    return await _localDataSource.createScore(score);
  }

  /// Get scores by user
  Future<List<ScoreModel>> getScoresByUser(int userId) async {
    return await _localDataSource.getScoresByUser(userId);
  }

  /// Get scores by category
  Future<List<ScoreModel>> getScoresByCategory(int userId, String category) async {
    return await _localDataSource.getScoresByCategory(userId, category);
  }

  /// Get top scores (leaderboard)
  Future<List<ScoreModel>> getTopScores(int limit) async {
    return await _localDataSource.getTopScores(limit);
  }

  /// Get average score
  Future<double> getAverageScore(int userId) async {
    return await _localDataSource.getAverageScore(userId);
  }
}
