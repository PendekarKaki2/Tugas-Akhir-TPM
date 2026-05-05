import 'package:flutter/foundation.dart';
import '../../../core/services/database_service.dart';
import '../../models/question_model.dart';

/// Local Data Source for Questions
class QuestionLocalDataSource {
  final DatabaseService _databaseService;
  static final Map<int, QuestionModel> _memoryQuestions = {};
  static int _memoryIdCounter = 1;

  QuestionLocalDataSource(this._databaseService);

  /// Create question
  Future<QuestionModel> createQuestion(QuestionModel question) async {
    if (kIsWeb) {
      final id = _memoryIdCounter++;
      final stored = question.copyWith(id: id);
      _memoryQuestions[id] = stored;
      return stored;
    }

    try {
      final db = await _databaseService.database;
      final id = await db.insert('questions', question.toJson());
      return question.copyWith(id: id);
    } catch (_) {
      final id = _memoryIdCounter++;
      final stored = question.copyWith(id: id);
      _memoryQuestions[id] = stored;
      return stored;
    }
  }

  /// Get all questions
  Future<List<QuestionModel>> getAllQuestions() async {
    if (kIsWeb) {
      return _memoryQuestions.values.toList();
    }

    try {
      final db = await _databaseService.database;
      final result = await db.query('questions');
      return result.map((json) => QuestionModel.fromJson(json)).toList();
    } catch (_) {
      return _memoryQuestions.values.toList();
    }
  }

  /// Get questions by category
  Future<List<QuestionModel>> getQuestionsByCategory(String category) async {
    final all = await getAllQuestions();
    return all.where((q) => q.category == category).toList();
  }

  /// Get questions by difficulty
  Future<List<QuestionModel>> getQuestionsByDifficulty(String difficulty) async {
    final all = await getAllQuestions();
    return all.where((q) => q.difficulty == difficulty).toList();
  }

  /// Search questions
  Future<List<QuestionModel>> searchQuestions(String searchTerm) async {
    final all = await getAllQuestions();
    final lower = searchTerm.toLowerCase();
    return all.where((q) => q.question.toLowerCase().contains(lower)).toList();
  }

  /// Get random questions
  Future<List<QuestionModel>> getRandomQuestions(int limit) async {
    final all = await getAllQuestions();
    if (all.isEmpty) return [];
    final shuffled = List<QuestionModel>.from(all)..shuffle();
    return shuffled.take(limit).toList();
  }

  /// Insert sample questions
  Future<void> insertSampleQuestions() async {
    final samples = [
      {
        'question': 'What is 2 + 2?',
        'options': '3|4|5|6',
        'correctAnswer': '4',
        'category': 'Math',
        'difficulty': 'Easy',
      },
      {
        'question': 'What is the capital of France?',
        'options': 'Berlin|Paris|Madrid|Rome',
        'correctAnswer': 'Paris',
        'category': 'General',
        'difficulty': 'Easy',
      },
      {
        'question': 'What is H2O?',
        'options': 'Hydrogen|Water|Oxygen|Nitrogen',
        'correctAnswer': 'Water',
        'category': 'Science',
        'difficulty': 'Easy',
      },
      {
        'question': 'What is 15 × 12?',
        'options': '160|170|180|190',
        'correctAnswer': '180',
        'category': 'Math',
        'difficulty': 'Medium',
      },
      {
        'question': 'What is the largest planet in our solar system?',
        'options': 'Saturn|Neptune|Jupiter|Uranus',
        'correctAnswer': 'Jupiter',
        'category': 'Science',
        'difficulty': 'Medium',
      },
      {
        'question': 'What is 9 x 7?',
        'options': '56|63|72|67',
        'correctAnswer': '63',
        'category': 'Math',
        'difficulty': 'Easy',
      },
      {
        'question': 'What is 144 / 12?',
        'options': '10|11|12|13',
        'correctAnswer': '12',
        'category': 'Math',
        'difficulty': 'Easy',
      },
      {
        'question': 'What is 18 + 27?',
        'options': '45|46|47|44',
        'correctAnswer': '45',
        'category': 'Math',
        'difficulty': 'Easy',
      },
      {
        'question': 'What is 5 squared?',
        'options': '10|20|25|15',
        'correctAnswer': '25',
        'category': 'Math',
        'difficulty': 'Medium',
      },
      {
        'question': 'Solve: 3x = 21, x = ?',
        'options': '6|7|8|9',
        'correctAnswer': '7',
        'category': 'Math',
        'difficulty': 'Medium',
      },
      {
        'question': 'Area of rectangle with 8 and 6?',
        'options': '14|28|48|42',
        'correctAnswer': '48',
        'category': 'Math',
        'difficulty': 'Medium',
      },
      {
        'question': 'What is the derivative of x^2?',
        'options': 'x|2x|x^2|2',
        'correctAnswer': '2x',
        'category': 'Math',
        'difficulty': 'Hard',
      },
      {
        'question': 'What is 2^5?',
        'options': '16|24|32|64',
        'correctAnswer': '32',
        'category': 'Math',
        'difficulty': 'Hard',
      },
      {
        'question': 'What is the value of pi (approx)?',
        'options': '2.14|3.14|4.13|3.41',
        'correctAnswer': '3.14',
        'category': 'Math',
        'difficulty': 'Hard',
      },
      {
        'question': 'Earth revolves around?',
        'options': 'Moon|Mars|Sun|Jupiter',
        'correctAnswer': 'Sun',
        'category': 'Science',
        'difficulty': 'Easy',
      },
      {
        'question': 'What gas do humans breathe in?',
        'options': 'Hydrogen|Carbon Dioxide|Oxygen|Nitrogen',
        'correctAnswer': 'Oxygen',
        'category': 'Science',
        'difficulty': 'Easy',
      },
      {
        'question': 'How many planets in our solar system?',
        'options': '7|8|9|10',
        'correctAnswer': '8',
        'category': 'Science',
        'difficulty': 'Easy',
      },
      {
        'question': 'What force pulls objects to Earth?',
        'options': 'Magnetism|Gravity|Friction|Pressure',
        'correctAnswer': 'Gravity',
        'category': 'Science',
        'difficulty': 'Medium',
      },
      {
        'question': 'Boiling point of water in Celsius?',
        'options': '90|95|100|110',
        'correctAnswer': '100',
        'category': 'Science',
        'difficulty': 'Medium',
      },
      {
        'question': 'Which organ pumps blood?',
        'options': 'Lungs|Liver|Heart|Kidney',
        'correctAnswer': 'Heart',
        'category': 'Science',
        'difficulty': 'Medium',
      },
      {
        'question': 'Chemical symbol for Sodium?',
        'options': 'S|So|Na|N',
        'correctAnswer': 'Na',
        'category': 'Science',
        'difficulty': 'Hard',
      },
      {
        'question': 'Center of an atom is called?',
        'options': 'Shell|Core|Nucleus|Cell',
        'correctAnswer': 'Nucleus',
        'category': 'Science',
        'difficulty': 'Hard',
      },
      {
        'question': 'Speed of light is about?',
        'options': '300 km/s|3000 km/s|300000 km/s|3000000 km/s',
        'correctAnswer': '300000 km/s',
        'category': 'Science',
        'difficulty': 'Hard',
      },
      {
        'question': 'Which day comes after Monday?',
        'options': 'Sunday|Tuesday|Friday|Saturday',
        'correctAnswer': 'Tuesday',
        'category': 'General',
        'difficulty': 'Easy',
      },
      {
        'question': 'How many hours in a day?',
        'options': '12|18|24|36',
        'correctAnswer': '24',
        'category': 'General',
        'difficulty': 'Easy',
      },
      {
        'question': 'What color is a stop sign?',
        'options': 'Blue|Green|Red|Yellow',
        'correctAnswer': 'Red',
        'category': 'General',
        'difficulty': 'Easy',
      },
      {
        'question': 'Capital of Japan?',
        'options': 'Seoul|Beijing|Tokyo|Bangkok',
        'correctAnswer': 'Tokyo',
        'category': 'General',
        'difficulty': 'Medium',
      },
      {
        'question': 'Which ocean is the largest?',
        'options': 'Atlantic|Indian|Arctic|Pacific',
        'correctAnswer': 'Pacific',
        'category': 'General',
        'difficulty': 'Medium',
      },
      {
        'question': 'Who wrote Romeo and Juliet?',
        'options': 'Tolstoy|Shakespeare|Hemingway|Twain',
        'correctAnswer': 'Shakespeare',
        'category': 'General',
        'difficulty': 'Medium',
      },
      {
        'question': 'Which country has the most population?',
        'options': 'USA|India|China|Indonesia',
        'correctAnswer': 'India',
        'category': 'General',
        'difficulty': 'Hard',
      },
      {
        'question': 'UN stands for?',
        'options': 'United Nations|Universal Network|Union Node|United North',
        'correctAnswer': 'United Nations',
        'category': 'General',
        'difficulty': 'Hard',
      },
      {
        'question': 'Which continent has the most countries?',
        'options': 'Asia|Europe|Africa|South America',
        'correctAnswer': 'Africa',
        'category': 'General',
        'difficulty': 'Hard',
      },
    ];

    for (var sample in samples) {
      final question = QuestionModel(
        question: sample['question'] as String,
        options: (sample['options'] as String).split('|'),
        correctAnswer: sample['correctAnswer'] as String,
        category: sample['category'] as String,
        difficulty: sample['difficulty'] as String,
      );
      await createQuestion(question);
    }
  }
}
