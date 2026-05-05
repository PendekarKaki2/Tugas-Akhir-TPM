import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/question_provider.dart';
import '../../../providers/score_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/custom_widgets.dart';
import '../../../../sensors/shake_service.dart';
import '../../../../core/constants/app_constants.dart';

/// Quiz Screen
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentQuestionIndex = 0;
  int _score = 0;
  List<String?> _selectedAnswers = [];
  bool _isAnswered = false;
  bool _quizStarted = false;
  String _selectedCategory = AppConstants.categories.first;
  String _selectedDifficulty = AppConstants.difficulties.first;
  final ShakeService _shakeService = ShakeService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _shakeService.startListening(onShake: () async {
        if (!_quizStarted) {
          return;
        }

        if (!mounted) return;
        await context.read<QuestionProvider>().prepareQuiz(
              category: _selectedCategory,
              difficulty: _selectedDifficulty,
              limit: 8,
            );
        if (!mounted) return;
        setState(() {
          _currentQuestionIndex = 0;
          _score = 0;
          _selectedAnswers = [];
          _isAnswered = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Device digoyang: soal diacak ulang')),
        );
      });
    });
  }

  @override
  void dispose() {
    _shakeService.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz'),
        elevation: 0,
      ),
      body: Consumer<QuestionProvider>(
        builder: (context, provider, _) {
          if (!_quizStarted) {
            return _buildSetupPanel(provider);
          }

          if (provider.isLoading) {
            return const LoadingIndicator();
          }

          if (provider.currentQuestions.isEmpty) {
            return AppErrorWidget(
              message: provider.error ?? 'No questions available',
              onRetry: () async {
                await provider.prepareQuiz(
                  category: _selectedCategory,
                  difficulty: _selectedDifficulty,
                  limit: 8,
                );
              },
            );
          }

          if (_selectedAnswers.length != provider.currentQuestions.length) {
            _selectedAnswers =
                List<String?>.filled(provider.currentQuestions.length, null);
          }

          final currentQuestion = provider.currentQuestions[_currentQuestionIndex];
          final isLastQuestion =
              _currentQuestionIndex == provider.currentQuestions.length - 1;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Progress Bar
                  LinearProgressIndicator(
                    value: (_currentQuestionIndex + 1) /
                        provider.currentQuestions.length,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(
                        label: Text(_selectedCategory),
                        avatar: const Icon(Icons.category, size: 16),
                      ),
                      Chip(
                        label: Text(_selectedDifficulty),
                        avatar: const Icon(Icons.bolt, size: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Question ${_currentQuestionIndex + 1}/${provider.currentQuestions.length}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Question Text
                  Text(
                    currentQuestion.question,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Options
                  ...currentQuestion.options.asMap().entries.map((entry) {
                    final index = entry.key;
                    final option = entry.value;
                    final isSelected =
                        _selectedAnswers[_currentQuestionIndex] == option;
                    final isCorrect = option == currentQuestion.correctAnswer;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: _isAnswered
                            ? null
                            : () {
                                setState(() {
                                  _selectedAnswers[_currentQuestionIndex] =
                                      option;
                                  _isAnswered = true;
                                  if (option == currentQuestion.correctAnswer) {
                                    _score++;
                                  }
                                });
                              },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected
                                  ? (isCorrect ? Colors.green : Colors.red)
                                  : Colors.grey,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: isSelected
                              ? (isCorrect
                                ? Colors.green.withValues(alpha: 0.2)
                                : Colors.red.withValues(alpha: 0.2))
                              : Colors.transparent,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isSelected
                                        ? (isCorrect
                                            ? Colors.green
                                            : Colors.red)
                                        : Colors.grey,
                                  ),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Center(
                                  child: Text(
                                    String.fromCharCode(65 + index),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(option),
                              ),
                              if (isSelected && isCorrect)
                                const Icon(Icons.check, color: Colors.green)
                              else if (isSelected)
                                const Icon(Icons.close, color: Colors.red),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 32),

                  // Next/Finish Button
                  if (_isAnswered)
                    CustomButton(
                      text: isLastQuestion ? 'Finish' : 'Next',
                      onPressed: () async {
                        if (isLastQuestion) {
                          // Save score
                          final authProvider = context.read<AuthProvider>();
                          final scoreProvider = context.read<ScoreProvider>();
                          
                          if (authProvider.currentUser != null) {
                            await scoreProvider.saveScore(
                              authProvider.currentUser!.id ?? 0,
                              _score,
                              provider.currentQuestions.length,
                              'General',
                            );
                          }

                          if (context.mounted) {
                            _showResultDialog(
                              context,
                              _score,
                              provider.currentQuestions.length,
                            );
                          }
                        } else {
                          setState(() {
                            _currentQuestionIndex++;
                            _isAnswered = false;
                          });
                        }
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showResultDialog(BuildContext context, int score, int total) {
    final percentage = (score / total) * 100;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quiz Completed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Score: $score/$total',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('${percentage.toStringAsFixed(1)}%'),
            const SizedBox(height: 16),
            Text(
              percentage >= 60 ? '🎉 Great job!' : '📚 Keep practicing!',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _quizStarted = false;
                _currentQuestionIndex = 0;
                _score = 0;
                _selectedAnswers = [];
                _isAnswered = false;
              });
            },
            child: const Text('Ganti Kategori'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Back Home'),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupPanel(QuestionProvider provider) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF0EA5E9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pilih Mode Quiz',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tentukan kategori dan tingkat kesulitan dulu, lalu mulai bermain.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Kategori',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: AppConstants.categories.map((category) {
                final selected = category == _selectedCategory;
                return ChoiceChip(
                  selected: selected,
                  label: Text(category),
                  onSelected: (_) {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const Text(
              'Kesulitan',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: AppConstants.difficulties.map((difficulty) {
                final selected = difficulty == _selectedDifficulty;
                return FilterChip(
                  selected: selected,
                  label: Text(difficulty),
                  onSelected: (_) {
                    setState(() {
                      _selectedDifficulty = difficulty;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            if (provider.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  provider.error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            CustomButton(
              text: 'Mulai Quiz',
              isLoading: provider.isLoading,
              onPressed: () async {
                await provider.prepareQuiz(
                  category: _selectedCategory,
                  difficulty: _selectedDifficulty,
                  limit: 8,
                );

                if (!mounted) {
                  return;
                }

                if (provider.currentQuestions.isNotEmpty) {
                  setState(() {
                    _quizStarted = true;
                    _currentQuestionIndex = 0;
                    _score = 0;
                    _selectedAnswers = [];
                    _isAnswered = false;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
