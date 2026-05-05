import 'package:flutter/material.dart';
import '../../../widgets/custom_widgets.dart';

/// Tebak Gambar (Guess Image) Screen
class TebakGambarScreen extends StatefulWidget {
  const TebakGambarScreen({super.key});

  @override
  State<TebakGambarScreen> createState() => _TebakGambarScreenState();
}

class _TebakGambarScreenState extends State<TebakGambarScreen> {
  final _answerController = TextEditingController();
  int _score = 0;
  int _currentLevel = 1;

  final List<Map<String, String>> _games = [
    {'image': '🐶', 'answer': 'dog'},
    {'image': '🐱', 'answer': 'cat'},
    {'image': '🌳', 'answer': 'tree'},
    {'image': '🏠', 'answer': 'house'},
    {'image': '⚽', 'answer': 'ball'},
  ];

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentGame = _games[_currentLevel - 1];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guess The Image'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Score
            Text(
              'Level: $_currentLevel | Score: $_score',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),

            // Image
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  currentGame['image']!,
                  style: const TextStyle(fontSize: 100),
                ),
              ),
            ),
            const SizedBox(height: 48),

            // Input
            CustomTextField(
              label: 'Your Answer',
              controller: _answerController,
              prefixIcon: const Icon(Icons.keyboard),
            ),
            const SizedBox(height: 24),

            // Submit Button
            CustomButton(
              text: 'Submit Answer',
              onPressed: () {
                final answer = _answerController.text.toLowerCase().trim();
                if (answer == currentGame['answer']) {
                  setState(() {
                    _score++;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ Correct!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          '❌ Wrong! Answer: ${currentGame['answer']}'),
                    ),
                  );
                }

                _answerController.clear();

                if (_currentLevel < _games.length) {
                  setState(() {
                    _currentLevel++;
                  });
                } else {
                  _showGameOverDialog();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Game Over!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉'),
            const SizedBox(height: 16),
            Text(
              'Final Score: $_score/${_games.length}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Back'),
          ),
        ],
      ),
    );
  }
}
