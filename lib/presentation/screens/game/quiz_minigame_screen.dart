import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:provider/provider.dart';
import '../../../presentation/providers/question_provider.dart';
import '../../../presentation/providers/score_provider.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/location_provider.dart';

class QuizMinigameScreen extends StatefulWidget {
  const QuizMinigameScreen({super.key});

  @override
  State<QuizMinigameScreen> createState() => _QuizMinigameScreenState();
}

class _QuizMinigameScreenState extends State<QuizMinigameScreen> {
  double _pos = 0.5; // 0.0 (left) .. 1.0 (right)
  StreamSubscription<AccelerometerEvent>? _sub;
  int _currentIndex = 0;
  bool _isAnswered = false;
  int _score = 0;
  List<String?> _selectedAnswers = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<QuestionProvider>();
      await provider.prepareQuiz(category: 'General', difficulty: 'Easy', limit: 6);
      if (!mounted) return;
      setState(() {
        _selectedAnswers = List<String?>.filled(provider.currentQuestions.length, null);
      });
    });

    _sub = accelerometerEvents.listen((event) {
      // event.x: tilt left/right, adjust sensitivity
      final delta = -event.x * 0.02;
      setState(() {
        _pos = (_pos + delta).clamp(0.0, 1.0);
      });
      _checkOverlap();
    });
  }

  void _checkOverlap() {
    final provider = context.read<QuestionProvider>();
    if (provider.currentQuestions.isEmpty) return;
    final options = provider.currentQuestions[_currentIndex].options;
    final zone = (_pos * options.length).floor().clamp(0, options.length - 1);
    if (!_isAnswered) {
      // automatically select when center of player in zone for short time
      _selectOption(zone);
    }
  }

  void _selectOption(int optionIndex) {
    final provider = context.read<QuestionProvider>();
    if (provider.currentQuestions.isEmpty) return;
    final option = provider.currentQuestions[_currentIndex].options[optionIndex];
    setState(() {
      _selectedAnswers[_currentIndex] = option;
      _isAnswered = true;
      if (option == provider.currentQuestions[_currentIndex].correctAnswer) {
        _score++;
      }
    });
    // move to next after delay
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      final isLast = _currentIndex == provider.currentQuestions.length - 1;
      if (isLast) {
        _finish(provider.currentQuestions.length);
      } else {
        setState(() {
          _currentIndex++;
          _isAnswered = false;
        });
      }
    });
  }

  Future<void> _finish(int total) async {
    final auth = context.read<AuthProvider>();
    final scoreProvider = context.read<ScoreProvider>();
    final locationProvider = context.read<LocationProvider>();
    if (auth.currentUser != null) {
      await scoreProvider.saveScore(auth.currentUser!.id ?? 0, _score, total, 'Minigame');
      await locationProvider.fetchLocation(
        userId: auth.currentUser!.id,
        userName: auth.currentUser!.username,
        points: _score,
      );
    }
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Selesai'),
        content: Text('Skor: $_score / $total'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuestionProvider>();
    if (provider.currentQuestions.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final q = provider.currentQuestions[_currentIndex];
    final options = q.options;

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz Minigame')),
      body: Stack(
        children: [
          // Question
          Positioned(top: 24, left: 16, right: 16, child: Text(q.question, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),

          // Answer zones
          Positioned.fill(
            bottom: 120,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Row(
                children: List.generate(options.length, (i) {
                  return Expanded(
                    child: Container(
                      height: 120,
                      margin: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _isAnswered && _selectedAnswers[_currentIndex] == options[i]
                            ? (options[i] == q.correctAnswer ? Colors.green : Colors.red)
                            : Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white30),
                      ),
                      child: Center(child: Text(options[i], textAlign: TextAlign.center)),
                    ),
                  );
                }),
              ),
            ),
          ),

          // Player character
          Positioned(
            left: MediaQuery.of(context).size.width * _pos - 24,
            bottom: 160,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.blueAccent),
              child: const Icon(Icons.person, color: Colors.white),
            ),
          ),

          // Hint
          const Positioned(bottom: 24, left: 16, right: 16, child: Center(child: Text('Gerakkan perangkat untuk menggerakkan karakter ke area jawaban'))),
        ],
      ),
    );
  }
}
