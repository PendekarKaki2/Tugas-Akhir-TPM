import 'package:flutter/material.dart';
import '../../widgets/custom_widgets.dart';

/// Feedback Screen
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _feedbackController = TextEditingController();
  int _rating = 5;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Help us improve EduFun!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Rating
              const Text(
                'How would you rate your experience?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ...List.generate(5, (index) {
                    return IconButton(
                      onPressed: () {
                        setState(() => _rating = index + 1);
                      },
                      icon: Icon(
                        Icons.star,
                        size: 40,
                        color: index < _rating
                            ? Colors.amber
                            : Colors.grey[300],
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 24),

              // Feedback Text
              const Text(
                'Your feedback:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Tell us what you think...',
                controller: _feedbackController,
                maxLines: 6,
              ),
              const SizedBox(height: 24),

              // Categories
              const Text(
                'Category (optional):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  _CategoryChip(label: 'Bug Report'),
                  _CategoryChip(label: 'Feature Request'),
                  _CategoryChip(label: 'Improvement'),
                  _CategoryChip(label: 'General'),
                ],
              ),
              const SizedBox(height: 32),

              // Submit Button
              CustomButton(
                text: 'Send Feedback',
                onPressed: () {
                  if (_feedbackController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter your feedback'),
                      ),
                    );
                    return;
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Thank you for your feedback! 🙏'),
                    ),
                  );

                  _feedbackController.clear();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatefulWidget {
  final String label;

  const _CategoryChip({required this.label});

  @override
  State<_CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<_CategoryChip> {
  bool _selected = false;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(widget.label),
      selected: _selected,
      onSelected: (selected) {
        setState(() => _selected = selected);
      },
    );
  }
}
