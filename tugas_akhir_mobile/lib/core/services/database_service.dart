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

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create tables
  Future<void> _onCreate(Database db, int version) async {
    // User table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
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
  }

  /// Handle version upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle migrations here if needed
  }

  /// Close database
  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
