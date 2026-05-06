import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart';

/// Database Service for SQLite
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  /// Get database instance
  Future<Database> get database async {
    _database ??= await _initializeDatabase();
    return _database!;
  }

  /// Initialize database
  Future<Database> _initializeDatabase() async {
    final Directory appDocumentsDir =
        await getApplicationDocumentsDirectory();
    final String path = join(appDocumentsDir.path, 'edufun.db');

    // Try opening database with a small number of retries to handle transient IO issues
    const int maxAttempts = 3;
    int attempt = 0;
    while (true) {
      attempt++;
      try {
        return await openDatabase(
          path,
          version: 3,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
          onOpen: _onOpen,
        );
      } catch (e) {
        if (attempt >= maxAttempts) rethrow;
        await Future.delayed(Duration(milliseconds: 250 * attempt));
      }
    }
  }

  /// Called when DB is opened. Set PRAGMA and safety settings.
  Future<void> _onOpen(Database db) async {
    try {
      await db.execute('PRAGMA foreign_keys = ON');
      await db.execute("PRAGMA journal_mode = WAL");
      await db.execute('PRAGMA synchronous = NORMAL');
      await db.execute('PRAGMA temp_store = MEMORY');
      // Limit cache size (negative value means KB)
      await db.execute('PRAGMA cache_size = -2000');
      // Busy timeout (ms)
      await db.execute('PRAGMA busy_timeout = 5000');
    } catch (_) {
      // Ignore individual pragma failures but continue.
    }
  }

  /// Create tables
  Future<void> _onCreate(Database db, int version) async {
    // User table (include role)
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        role TEXT DEFAULT 'student',
        photo TEXT,
        createdAt TEXT NOT NULL,
        level INTEGER DEFAULT 1,
        xp INTEGER DEFAULT 0
      )
    ''');

    // Question table
    await db.execute('''
      CREATE TABLE questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question TEXT NOT NULL,
        options TEXT NOT NULL,
        correctAnswer TEXT NOT NULL,
        category TEXT NOT NULL,
        difficulty TEXT NOT NULL,
        imageUrl TEXT
      )
    ''');

    // Score table
    await db.execute('''
      CREATE TABLE scores (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        score INTEGER NOT NULL,
        totalQuestions INTEGER NOT NULL,
        category TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users(id)
      )
    ''');

    // Badge table
    await db.execute('''
      CREATE TABLE badges (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        badgeName TEXT NOT NULL,
        badgeIcon TEXT,
        unlockedAt TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users(id)
      )
    ''');

    // Location-based data
    await db.execute('''
      CREATE TABLE user_locations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users(id)
      )
    ''');

    // Materials table (mentors upload)
    await db.execute('''
      CREATE TABLE materials (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mentorId INTEGER NOT NULL,
        title TEXT NOT NULL,
        content TEXT,
        filePath TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (mentorId) REFERENCES users(id)
      )
    ''');

    // Quizzes and questions
    await db.execute('''
      CREATE TABLE quizzes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mentorId INTEGER NOT NULL,
        title TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (mentorId) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE quiz_questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        quizId INTEGER NOT NULL,
        questionText TEXT NOT NULL,
        type TEXT DEFAULT 'multiple_choice',
        options TEXT NOT NULL,
        correctAnswer TEXT NOT NULL,
        FOREIGN KEY (quizId) REFERENCES quizzes(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE quiz_submissions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        quizId INTEGER NOT NULL,
        studentId INTEGER NOT NULL,
        answers TEXT NOT NULL,
        score INTEGER NOT NULL,
        submittedAt TEXT NOT NULL,
        FOREIGN KEY (quizId) REFERENCES quizzes(id),
        FOREIGN KEY (studentId) REFERENCES users(id)
      )
    ''');
  }

  /// Handle version upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // add role column to users if missing
      try {
        await db.execute("ALTER TABLE users ADD COLUMN role TEXT DEFAULT 'student'");
      } catch (_) {}

      // create new tables for materials/quizzes
      await db.execute('''
        CREATE TABLE IF NOT EXISTS materials (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          mentorId INTEGER NOT NULL,
          title TEXT NOT NULL,
          content TEXT,
          filePath TEXT,
          createdAt TEXT NOT NULL,
          FOREIGN KEY (mentorId) REFERENCES users(id)
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS quizzes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          mentorId INTEGER NOT NULL,
          title TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          FOREIGN KEY (mentorId) REFERENCES users(id)
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS quiz_questions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          quizId INTEGER NOT NULL,
          questionText TEXT NOT NULL,
          options TEXT NOT NULL,
          correctAnswer TEXT NOT NULL,
          FOREIGN KEY (quizId) REFERENCES quizzes(id)
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS quiz_submissions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          quizId INTEGER NOT NULL,
          studentId INTEGER NOT NULL,
          answers TEXT NOT NULL,
          score INTEGER NOT NULL,
          submittedAt TEXT NOT NULL,
          FOREIGN KEY (quizId) REFERENCES quizzes(id),
          FOREIGN KEY (studentId) REFERENCES users(id)
        )
      ''');
    }
    
    if (oldVersion < 3) {
      // Add type column to quiz_questions table
      try {
        await db.execute("ALTER TABLE quiz_questions ADD COLUMN type TEXT DEFAULT 'multiple_choice'");
      } catch (_) {
        // Column might already exist
      }
    }
  }

  // Configuration limits to avoid unbounded growth
  static const int maxMaterials = 5000;
  static const int maxQuizzes = 2000;
  static const int maxQuizQuestions = 20000;
  static const int maxQuizSubmissions = 100000;

  /// Run an integrity check and return true when OK.
  Future<bool> ensureHealthy() async {
    try {
      final db = await database;
      final res = await db.rawQuery('PRAGMA integrity_check');
      if (res.isNotEmpty) {
        final first = res.first.values.first;
        if (first is String && first.toLowerCase() == 'ok') return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Run a transaction safely with an optional timeout to avoid long-running DB locks.
  Future<T> runInTransaction<T>(Future<T> Function(Transaction txn) action, {Duration timeout = const Duration(seconds: 10)}) async {
    final db = await database;
    try {
      final future = db.transaction<T>((txn) => action(txn));
      return await future.timeout(timeout);
    } catch (e) {
      rethrow;
    }
  }

  /// Get approximate row count for a table.
  Future<int> getRowCount(String table) async {
    try {
      final db = await database;
      final result = await db.rawQuery('SELECT COUNT(1) as c FROM $table');
      if (result.isNotEmpty) {
        final v = result.first['c'];
        if (v is int) return v;
        if (v is int?) return v ?? 0;
        if (v is String) return int.tryParse(v) ?? 0;
      }
    } catch (_) {}
    return 0;
  }

  /// Close database
  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
