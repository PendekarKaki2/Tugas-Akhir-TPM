import 'package:flutter/material.dart';
import '../../data/models/score_model.dart';
import '../../data/repositories/score_repository.dart';

/// Score Provider for Game Scores
class ScoreProvider extends ChangeNotifier {
  final ScoreRepository _scoreRepository;

  List<ScoreModel> _userScores = [];
  List<ScoreModel> _topScores = [];
  double _averageScore = 0;
  bool _isLoading = false;
  String? _error;

  ScoreProvider(this._scoreRepository);

  List<ScoreModel> get userScores => _userScores;
  List<ScoreModel> get topScores => _topScores;
  double get averageScore => _averageScore;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Save score
  Future<bool> saveScore(int userId, int score, int totalQuestions, String category) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final scoreModel = ScoreModel(
        userId: userId,
        score: score,
        totalQuestions: totalQuestions,
        category: category,
      );
      await _scoreRepository.createScore(scoreModel);
      await getScoresByUser(userId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get user scores
  Future<void> getScoresByUser(int userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _userScores = await _scoreRepository.getScoresByUser(userId);
      _averageScore = await _scoreRepository.getAverageScore(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get top scores (leaderboard)
  Future<void> getTopScores(int limit) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _topScores = await _scoreRepository.getTopScores(limit);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get scores by category
  Future<void> getScoresByCategory(int userId, String category) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _userScores = await _scoreRepository.getScoresByCategory(userId, category);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
