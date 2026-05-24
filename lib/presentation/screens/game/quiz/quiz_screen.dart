import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/question_provider.dart';
import '../../../providers/score_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/location_provider.dart';
import '../../../widgets/custom_widgets.dart';
import '../../../../sensors/shake_service.dart';
import '../../../../core/constants/app_constants.dart';

/// Quiz Screen (Quiziz-style)
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  int _currentQuestionIndex = 0;
  int _score = 0;
  List<String?> _selectedAnswers = [];
  bool _isAnswered = false;
  bool _quizStarted = false;
  String _selectedCategory = AppConstants.categories.first;
  String _selectedDifficulty = AppConstants.difficulties.first;
  final ShakeService _shakeService = ShakeService();
  late AnimationController _progressAnimController;
  late AnimationController _fadeAnimController;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _progressAnimController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
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
    _progressAnimController.dispose();
    _fadeAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Challenge', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: const Color(0xFF6366F1),
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

          // Animate on question change
          _fadeAnimController.forward(from: 0.0);
          _progressAnimController.forward(from: 0.0);

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Header dengan progress dan score
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Progress bar dengan animasi
                        ScaleTransition(
                          scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                            CurvedAnimation(parent: _progressAnimController, curve: Curves.easeOut),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: LinearProgressIndicator(
                              value: (_currentQuestionIndex + 1) / provider.currentQuestions.length,
                              minHeight: 8,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Soal ${_currentQuestionIndex + 1}/${provider.currentQuestions.length}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Skor: $_score',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Question card
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            // Question text
                            FadeTransition(
                              opacity: _fadeAnimController,
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pertanyaan ${_currentQuestionIndex + 1}',
                                      style: const TextStyle(
                                        color: Color(0xFF6366F1),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      currentQuestion.question,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Options dengan animasi
                            for (final entry in currentQuestion.options.asMap().entries)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildQuizOptionButton(
                                  label: String.fromCharCode(65 + entry.key),
                                  option: entry.value,
                                  isSelected: _selectedAnswers[_currentQuestionIndex] == entry.value,
                                  isCorrect: entry.value == currentQuestion.correctAnswer,
                                  isAnswered: _isAnswered,
                                  onTap: _isAnswered
                                      ? null
                                      : () {
                                          setState(() {
                                            _selectedAnswers[_currentQuestionIndex] = entry.value;
                                            _isAnswered = true;
                                            if (entry.value == currentQuestion.correctAnswer) {
                                              _score++;
                                            }
                                          });
                                        },
                                ),
                              ),

                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Next/Finish Button
                  if (_isAnswered)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                          CurvedAnimation(parent: _fadeAnimController, curve: Curves.elasticOut),
                        ),
                        child: CustomButton(
                          text: isLastQuestion ? 'Selesai' : 'Lanjut',
                          onPressed: () async {
                            if (isLastQuestion) {
                              final authProvider = context.read<AuthProvider>();
                              final scoreProvider = context.read<ScoreProvider>();
                              final locationProvider = context.read<LocationProvider>();
                              
                              if (authProvider.currentUser != null) {
                                await scoreProvider.saveScore(
                                  authProvider.currentUser!.id ?? 0,
                                  _score,
                                  provider.currentQuestions.length,
                                  'General',
                                );
                                await locationProvider.fetchLocation(
                                  userId: authProvider.currentUser!.id,
                                  userName: authProvider.currentUser!.username,
                                  points: _score,
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
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuizOptionButton({
    required String label,
    required String option,
    required bool isSelected,
    required bool isCorrect,
    required bool isAnswered,
    required VoidCallback? onTap,
  }) {
    Color getBgColor() {
      if (!isAnswered) return Colors.white;
      if (isSelected && isCorrect) return const Color(0xFF10B981);
      if (isSelected && !isCorrect) return const Color(0xFFEF4444);
      if (!isSelected && isCorrect && isAnswered) return const Color(0xFF10B981);
      return Colors.white;
    }

    Color getTextColor() {
      if (!isAnswered || (isSelected && isCorrect) || (isSelected && !isCorrect) || (!isSelected && isCorrect && isAnswered)) {
        return Colors.white;
      }
      return Colors.black87;
    }

    return GestureDetector(
      onTap: onTap,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.95, end: 1.0).animate(
          CurvedAnimation(parent: _fadeAnimController, curve: Curves.easeOut),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: getBgColor(),
            border: Border.all(
              color: isSelected ? getBgColor() : Colors.white30,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: getBgColor().withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.1),
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.white30,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: getTextColor(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: 16,
                    color: getTextColor(),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
              if (isSelected && isCorrect)
                const Icon(Icons.check_circle, color: Colors.white, size: 24)
              else if (isSelected && !isCorrect)
                const Icon(Icons.cancel, color: Colors.white, size: 24)
              else if (!isSelected && isCorrect && isAnswered)
                const Icon(Icons.check_circle, color: Colors.white, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showResultDialog(BuildContext context, int score, int total) {
    final percentage = (score / total) * 100;
    final isPassed = percentage >= 60;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: isPassed
                  ? [const Color(0xFF10B981), const Color(0xFF059669)]
                  : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Emoji/Icon
              Text(
                isPassed ? '🎉' : '📚',
                style: const TextStyle(fontSize: 64),
              ),
              const SizedBox(height: 16),
              
              // Title
              Text(
                isPassed ? 'Luar Biasa!' : 'Bagus! Coba Lagi',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              
              // Score
              Text(
                '$score/$total Benar',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              
              // Percentage
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 24),
              
              // Message
              Text(
                isPassed
                    ? 'Kamu sangat memahami materi ini!'
                    : 'Tingkatkan belajarmu untuk hasil lebih baik',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
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
                      child: const Text(
                        'Ganti',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Home',
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSetupPanel(QuestionProvider provider) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white30, width: 2),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🚀 Quiz Challenge',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Uji kemampuanmu dengan menjawab soal-soal menarik',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              
              // Category
              const Text(
                'Pilih Kategori',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
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
                    backgroundColor: Colors.white12,
                    selectedColor: Colors.white,
                    labelStyle: TextStyle(
                      color: selected ? const Color(0xFF6366F1) : Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    side: BorderSide(
                      color: selected ? Colors.white : Colors.white30,
                      width: 2,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),
              
              // Difficulty
              const Text(
                'Tingkat Kesulitan',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
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
                    backgroundColor: Colors.white12,
                    selectedColor: Colors.white,
                    labelStyle: TextStyle(
                      color: selected ? const Color(0xFF6366F1) : Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    side: BorderSide(
                      color: selected ? Colors.white : Colors.white30,
                      width: 2,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              
              // Error message
              if (provider.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      provider.error!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              
              // Start button
              CustomButton(
                text: 'Mulai Quiz 🎮',
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
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
