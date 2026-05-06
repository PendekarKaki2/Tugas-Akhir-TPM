import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/student_provider.dart';
import '../../../data/models/quiz_question_model.dart';

class StudentTakeQuizScreen extends StatefulWidget {
  final int quizId;
  const StudentTakeQuizScreen({super.key, required this.quizId});

  @override
  State<StudentTakeQuizScreen> createState() => _StudentTakeQuizScreenState();
}

class _StudentTakeQuizScreenState extends State<StudentTakeQuizScreen> {
  late Future<List<QuizQuestionModel>> _questionsFuture;
  

  @override
  void initState() {
    super.initState();
    final student = Provider.of<StudentProvider>(context, listen: false);
    _questionsFuture = student.getQuizQuestions(widget.quizId);
  }

  @override
  Widget build(BuildContext context) {
    final student = Provider.of<StudentProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Kerjakan Quiz')),
      body: FutureBuilder<List<QuizQuestionModel>>(
        future: _questionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          final qs = snapshot.data ?? [];
          if (qs.isEmpty) return const Center(child: Text('Tidak ada pertanyaan'));
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: qs.length,
                  itemBuilder: (context, index) {
                    final q = qs[index];
                    final options = (q.options);
                    return ListTile(
                      title: Text(q.questionText),
                      subtitle: Text('Opsi: $options'),
                    );
                  },
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  // naive scoring: zero
                  final score = 0;
                  // For now assume studentId 2
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);
                  await student.submitQuiz(2, widget.quizId, {}, score);
                  messenger.showSnackBar(const SnackBar(content: Text('Quiz dikirim')));
                  navigator.pop();
                },
                child: const Text('Kirim Jawaban'),
              )
            ],
          );
        },
      ),
    );
  }
}
