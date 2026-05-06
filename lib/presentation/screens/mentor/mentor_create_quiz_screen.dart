import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/mentor_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../data/models/quiz_question_model.dart';
import 'dart:convert';

class MentorCreateQuizScreen extends StatefulWidget {
  const MentorCreateQuizScreen({super.key});

  @override
  State<MentorCreateQuizScreen> createState() => _MentorCreateQuizScreenState();
}

class _MentorCreateQuizScreenState extends State<MentorCreateQuizScreen> {
  final _titleController = TextEditingController();
  final _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  final _essayAnswerController = TextEditingController();
  
  final List<QuizQuestionModel> _questions = [];
  String _quizType = 'multiple_choice';
  String _selectedQuestionType = 'multiple_choice';
  int? _selectedCorrectIndex;

  @override
  void dispose() {
    _titleController.dispose();
    _questionController.dispose();
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    _essayAnswerController.dispose();
    super.dispose();
  }

  void _resetQuestionForm() {
    _questionController.clear();
    for (final controller in _optionControllers) {
      controller.clear();
    }
    _essayAnswerController.clear();
    _selectedCorrectIndex = null;
    // _selectedQuestionType tetap _quizType
  }

  void _addQuestion() {
    final question = _questionController.text.trim();
    if (question.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pertanyaan tidak boleh kosong')),
      );
      return;
    }

    if (_quizType == 'multiple_choice') {
      // Validasi untuk pilihan ganda
      final options = _optionControllers.map((c) => c.text.trim()).toList();
      if (options.any((o) => o.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Semua opsi harus diisi')),
        );
        return;
      }

      if (_selectedCorrectIndex == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih jawaban yang benar')),
        );
        return;
      }

      setState(() {
        _questions.add(QuizQuestionModel(
          quizId: 0,
          questionText: question,
          type: 'multiple_choice',
          options: jsonEncode(options),
          correctAnswer: options[_selectedCorrectIndex!],
        ));
      });
    } else {
      // Validasi untuk essay
      final rubric = _essayAnswerController.text.trim();
      if (rubric.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rubrik/Model jawaban tidak boleh kosong')),
        );
        return;
      }

      setState(() {
        _questions.add(QuizQuestionModel(
          quizId: 0,
          questionText: question,
          type: 'essay',
          options: '[]',
          correctAnswer: rubric,
        ));
      });
    }

    _resetQuestionForm();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pertanyaan ditambahkan')),
    );
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final mentor = Provider.of<MentorProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    if (auth.currentUser?.role != 'mentor') {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Buat Quiz'),
          backgroundColor: const Color(0xFF6366F1),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Akses Ditolak',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Hanya mentor dapat membuat quiz'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Kembali'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Quiz', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF6366F1),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Step 1: Quiz Title
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📝 Judul Quiz',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: 'Contoh: Kuis Matematika Bab 1',
                          prefixIcon: const Icon(Icons.title),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Step 1.5: Quiz Type
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🎯 Tipe Quiz',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              selected: _quizType == 'multiple_choice',
                              label: const Text('Pilihan Ganda'),
                              onSelected: (_) {
                                setState(() {
                                  _quizType = 'multiple_choice';
                                  _questions.clear(); // Clear questions if type changes
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ChoiceChip(
                              selected: _quizType == 'essay',
                              label: const Text('Essay'),
                              onSelected: (_) {
                                setState(() {
                                  _quizType = 'essay';
                                  _questions.clear(); // Clear questions if type changes
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Step 2: Add Questions
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '❓ Tambah Pertanyaan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Question text
                      const Text(
                        'Pertanyaan',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _questionController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Tulis pertanyaan di sini...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Multiple choice form
                      if (_quizType == 'multiple_choice') ...[
                        const Text(
                          'Opsi Jawaban',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...List.generate(4, (index) {
                          final labels = ['A', 'B', 'C', 'D'];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TextField(
                              controller: _optionControllers[index],
                              decoration: InputDecoration(
                                prefixText: '${labels[index]}. ',
                                hintText: 'Opsi ${labels[index]}',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 12),
                        const Text(
                          'Jawaban yang Benar',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[400]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<int>(
                            value: _selectedCorrectIndex,
                            isExpanded: true,
                            hint: const Text('Pilih jawaban yang benar'),
                            items: List.generate(4, (index) {
                              final labels = ['A', 'B', 'C', 'D'];
                              final text = _optionControllers[index].text.trim();
                              return DropdownMenuItem(
                                value: index,
                                child: Text(text.isNotEmpty
                                    ? '${labels[index]}. $text'
                                    : '${labels[index]}. (belum diisi)'),
                              );
                            }),
                            onChanged: (value) {
                              setState(() {
                                _selectedCorrectIndex = value;
                              });
                            },
                          ),
                        ),
                      ] else ...[
                        // Essay form
                        const Text(
                          'Rubrik / Model Jawaban',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _essayAnswerController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Tulis rubrik penilaian atau model jawaban yang diharapkan...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Add button
                      ElevatedButton.icon(
                        onPressed: _addQuestion,
                        icon: const Icon(Icons.add),
                        label: const Text('Tambah Pertanyaan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Step 3: Question List
              if (_questions.isNotEmpty) ...[
                Text(
                  '📋 Daftar Pertanyaan (${_questions.length})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _questions.length,
                  itemBuilder: (context, index) {
                    final q = _questions[index];
                    final isMultipleChoice = q.type == 'multiple_choice';

                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isMultipleChoice
                                        ? Colors.blue.withValues(alpha: 0.1)
                                        : Colors.orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    isMultipleChoice ? 'Pilihan Ganda' : 'Essay',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isMultipleChoice
                                          ? Colors.blue
                                          : Colors.orange,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  'Soal ${index + 1}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              q.questionText,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (isMultipleChoice) ...[
                              const Text(
                                'Opsi:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              ...jsonDecode(q.options).asMap().entries.map((e) {
                                final labels = ['A', 'B', 'C', 'D'];
                                return Text(
                                  '${labels[e.key]}. ${e.value}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: e.value == q.correctAnswer
                                        ? Colors.green
                                        : Colors.black54,
                                    fontWeight: e.value == q.correctAnswer
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                );
                              }),
                            ] else ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Rubrik: ${q.correctAnswer}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeQuestion(index),
                                tooltip: 'Hapus',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],

              // Submit button
              ElevatedButton.icon(
                onPressed: mentor.isLoading || _questions.isEmpty
                    ? null
                    : () async {
                        final title = _titleController.text.trim();
                        if (title.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Judul quiz harus diisi')),
                          );
                          return;
                        }

                        if (_questions.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Tambahkan minimal 1 pertanyaan')),
                          );
                          return;
                        }

                        final quizId = await mentor.createQuiz(
                          auth.currentUser?.id ?? 1,
                          title,
                          _quizType,
                          _questions,
                        );

                        if (!mounted) return;
                        if (quizId != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('✓ Quiz berhasil dibuat!')),
                          );
                          _titleController.clear();
                          _resetQuestionForm();
                          setState(() {
                            _questions.clear();
                            _quizType = 'multiple_choice';
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(mentor.error ?? 'Gagal membuat quiz')),
                          );
                        }
                      },
                icon: const Icon(Icons.save),
                label: const Text('Buat Quiz'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: mentor.isLoading || _questions.isEmpty
                      ? Colors.grey[400]
                      : const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
