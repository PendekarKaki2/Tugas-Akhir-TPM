import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';
import '../../data/models/user_model.dart';

/// Service untuk manage dan verify data persistence
/// Memastikan data user tersimpan dengan sempurna di SQLite dan SharedPreferences
class DataPersistenceService {
  static final DataPersistenceService _instance =
      DataPersistenceService._internal();
  final DatabaseService _databaseService;
  bool _loggingEnabled = true;

  factory DataPersistenceService(DatabaseService databaseService) {
    return _instance;
  }

  DataPersistenceService._internal() : _databaseService = DatabaseService();

  /// Enable/disable logging
  void setLoggingEnabled(bool enabled) {
    _loggingEnabled = enabled;
  }

  /// Log data persistence activities
  void _log(String message) {
    if (_loggingEnabled) {
      if (kDebugMode) {
        print('[DataPersistence] $message');
      }
    }
  }

  /// Verify data consistency antara SQLite dan SharedPreferences
  Future<Map<String, dynamic>> verifyDataConsistency() async {
    _log('Starting data consistency check...');

    try {
      final db = await _databaseService.database;

      // Check SQLite
      final sqliteUsers =
          await db.query('users', limit: 100); // Limit untuk safety
      _log('SQLite users count: ${sqliteUsers.length}');

      // Check SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final cachedUsersJson = prefs.getString('cached_users_v1');
      final cachedUsersCount = cachedUsersJson != null ? 1 : 0;
      _log('SharedPreferences cached users: $cachedUsersCount');

      // Verify current user session
      final userId = prefs.getInt('user_id');
      final username = prefs.getString('username');
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

        _log('Current session - User ID: $userId, Username: ${username ?? "none"}, '
          'Logged in: $isLoggedIn');

      return {
        'status': 'success',
        'sqliteUserCount': sqliteUsers.length,
        'cachedUsersExist': cachedUsersJson != null,
        'currentSessionUserId': userId,
        'currentSessionUsername': username,
        'isLoggedIn': isLoggedIn,
        'sqliteUsers': sqliteUsers,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      _log('Error verifying data consistency: $e');
      return {
        'status': 'error',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Save user to both SQLite and SharedPreferences with verification
  Future<bool> persistUserData(UserModel user) async {
    _log('Persisting user data: ${user.username}');

    try {
      // 1. Save to SQLite
      final db = await _databaseService.database;
      final userExists =
          await db.query('users', where: 'id = ?', whereArgs: [user.id]);

      if (userExists.isNotEmpty) {
        // Update existing user
        await db.update(
          'users',
          {
            'username': user.username,
            'password': user.password,
            'photo': user.photo,
            'level': user.level,
            'xp': user.xp,
          },
          where: 'id = ?',
          whereArgs: [user.id],
        );
        _log('Updated user in SQLite: ID=${user.id}');
      } else {
        // Insert new user
        final id = await db.insert('users', {
          'username': user.username,
          'password': user.password,
          'photo': user.photo,
          'createdAt': DateTime.now().toIso8601String(),
          'level': user.level,
          'xp': user.xp,
        });
        _log('Inserted user in SQLite: ID=$id');
      }

      // 2. Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_id', user.id ?? 0);
      await prefs.setString('username', user.username);
      await prefs.setBool('is_logged_in', true);
      _log('Saved user session to SharedPreferences: ${user.username}');

      // 3. Verify data was saved
      final savedUser = await getUserFromDatabase(user.id!);
      if (savedUser != null) {
        _log('✓ Data persistence verified for user: ${savedUser.username}');
        return true;
      } else {
        _log('✗ Data verification failed for user: ${user.username}');
        return false;
      }
    } catch (e) {
      _log('Error persisting user data: $e');
      return false;
    }
  }

  /// Get user from database dengan verification
  Future<UserModel?> getUserFromDatabase(int userId) async {
    try {
      final db = await _databaseService.database;
      final result = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );

      if (result.isNotEmpty) {
        final user = UserModel.fromJson(result.first);
        _log('Retrieved user from SQLite: ${user.username}');
        return user;
      }
      return null;
    } catch (e) {
      _log('Error getting user from database: $e');
      return null;
    }
  }

  /// Get all users (for debugging/admin purposes)
  Future<List<UserModel>> getAllUsers() async {
    try {
      final db = await _databaseService.database;
      final results = await db.query('users');
      final users = results
          .map((json) => UserModel.fromJson(json))
          .toList();
      _log('Retrieved ${users.length} users from SQLite');
      return users;
    } catch (e) {
      _log('Error getting all users: $e');
      return [];
    }
  }

  /// Clear all data (useful untuk testing atau logout dengan data wipe)
  Future<bool> clearAllData() async {
    try {
      // Clear SQLite
      final db = await _databaseService.database;
      await db.delete('users');
      _log('Cleared all users from SQLite');

      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_id');
      await prefs.remove('username');
      await prefs.remove('is_logged_in');
      await prefs.remove('cached_users_v1');
      await prefs.remove('cached_users_id_counter_v1');
      _log('Cleared all data from SharedPreferences');

      return true;
    } catch (e) {
      _log('Error clearing data: $e');
      return false;
    }
  }

  /// Backup user data to file (future enhancement)
  Future<bool> backupUserData() async {
    try {
      final users = await getAllUsers();
      _log('Backed up ${users.length} users');
      // TODO: Implement file backup
      return true;
    } catch (e) {
      _log('Error backing up data: $e');
      return false;
    }
  }

  /// Restore user session dari SharedPreferences
  Future<UserModel?> restoreUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      if (userId != null) {
        final user = await getUserFromDatabase(userId);
        if (user != null) {
          _log('Restored user session: ${user.username}');
          return user;
        }
      }

      _log('No active user session found');
      return null;
    } catch (e) {
      _log('Error restoring user session: $e');
      return null;
    }
  }

  /// Clear user session (logout)
  Future<bool> clearUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_id');
      await prefs.remove('username');
      await prefs.remove('is_logged_in');
      _log('User session cleared');
      return true;
    } catch (e) {
      _log('Error clearing user session: $e');
      return false;
    }
  }

  /// Get database statistics
  Future<Map<String, int>> getDatabaseStats() async {
    try {
      final db = await _databaseService.database;

      final usersCount = _countQueryResult(
        await db.rawQuery('SELECT COUNT(*) AS count FROM users'),
      );
      final scoresCount = _countQueryResult(
        await db.rawQuery('SELECT COUNT(*) AS count FROM scores'),
      );
      final questionsCount = _countQueryResult(
        await db.rawQuery('SELECT COUNT(*) AS count FROM questions'),
      );
      final badgesCount = _countQueryResult(
        await db.rawQuery('SELECT COUNT(*) AS count FROM badges'),
      );

      _log(
          'Database stats - Users: $usersCount, Scores: $scoresCount, Questions: $questionsCount, Badges: $badgesCount');

      return {
        'users': usersCount,
        'scores': scoresCount,
        'questions': questionsCount,
        'badges': badgesCount,
      };
    } catch (e) {
      _log('Error getting database stats: $e');
      return {};
    }
  }

  int _countQueryResult(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) {
      return 0;
    }

    final row = rows.first;
    final value = row.values.first;
    if (value is int) {
      return value;
    }
    return int.tryParse(value.toString()) ?? 0;
  }
}
