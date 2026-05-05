import 'package:flutter/material.dart';
import '../../data/models/question_model.dart';
import '../../data/repositories/question_repository.dart';

/// Question Provider for Quiz
class QuestionProvider extends ChangeNotifier {
  final QuestionRepository _questionRepository;

  List<QuestionModel> _allQuestions = [];
  List<QuestionModel> _currentQuestions = [];
  String _selectedCategory = 'General';
  String _selectedDifficulty = 'Easy';
  bool _isLoading = false;
  String? _error;

  QuestionProvider(this._questionRepository);

  List<QuestionModel> get allQuestions => _allQuestions;
  List<QuestionModel> get currentQuestions => _currentQuestions;
  String get selectedCategory => _selectedCategory;
  String get selectedDifficulty => _selectedDifficulty;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Initialize questions
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _questionRepository.initializeSampleQuestions();
      _allQuestions = await _questionRepository.getAllQuestions();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get questions by category
  Future<void> getQuestionsByCategory(String category) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentQuestions = await _questionRepository.getQuestionsByCategory(category);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get random questions
  Future<void> getRandomQuestions(int limit) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentQuestions = await _questionRepository.getRandomQuestions(limit);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Search questions
  Future<void> searchQuestions(String searchTerm) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentQuestions = await _questionRepository.searchQuestions(searchTerm);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get questions by difficulty
  Future<void> getQuestionsByDifficulty(String difficulty) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentQuestions = await _questionRepository.getQuestionsByDifficulty(difficulty);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Prepare quiz by category and difficulty
  Future<void> prepareQuiz({
    required String category,
    required String difficulty,
    int limit = 10,
  }) async {
    _isLoading = true;
    _error = null;
    _selectedCategory = category;
    _selectedDifficulty = difficulty;
    notifyListeners();

    try {
      if (_allQuestions.isEmpty) {
        await _questionRepository.initializeSampleQuestions();
        _allQuestions = await _questionRepository.getAllQuestions();
      }

      final byCategory = _allQuestions
          .where((q) => q.category.toLowerCase() == category.toLowerCase())
          .toList();

      final filtered = byCategory
          .where((q) => q.difficulty.toLowerCase() == difficulty.toLowerCase())
          .toList();

      final source = filtered.isNotEmpty ? filtered : byCategory;
      source.shuffle();
      _currentQuestions = source.take(limit).toList();

      if (_currentQuestions.isEmpty) {
        _error = 'Belum ada soal untuk kategori ini.';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
