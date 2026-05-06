import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/database_service.dart';
import '../../models/user_model.dart';

/// Local Data Source for User
class UserLocalDataSource {
  final DatabaseService _databaseService;
  static final Map<int, UserModel> _memoryUsers = {};
  static int _memoryIdCounter = 1;
  static bool _isMemoryLoaded = false;
  static const String _usersCacheKey = 'cached_users_v1';
  static const String _usersIdCounterKey = 'cached_users_id_counter_v1';

  UserLocalDataSource(this._databaseService);

  Future<void> _ensureMemoryLoaded() async {
    if (_isMemoryLoaded) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_usersCacheKey);
    final idCounter = prefs.getInt(_usersIdCounterKey);
    if (idCounter != null && idCounter > 0) {
      _memoryIdCounter = idCounter;
    }

    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        for (final item in decoded) {
          final map = (item as Map).cast<String, dynamic>();
          final user = UserModel.fromJson(map);
          if (user.id != null) {
            _memoryUsers[user.id!] = user;
          }
        }
      } catch (_) {
        // Ignore corrupt cache and continue with fresh memory map.
      }
    }

    _isMemoryLoaded = true;
  }

  Future<void> _saveMemoryToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final users = _memoryUsers.values.map((e) => e.toJson()).toList();
    await prefs.setString(_usersCacheKey, jsonEncode(users));
    await prefs.setInt(_usersIdCounterKey, _memoryIdCounter);
  }

  /// Migrate any users cached in SharedPreferences memory into SQLite DB.
  /// This will insert users that do not exist in DB and update the in-memory
  /// cache keys to the DB-assigned ids. Also migrates saved session `user_id`.
  Future<void> migratePrefsToDb() async {
    await _ensureMemoryLoaded();

    if (kIsWeb) return; // DB persistence not available on web in this app

    try {
      final db = await _databaseService.database;

      // Work on a snapshot to avoid concurrent modification while iterating
      final entries = _memoryUsers.entries.toList();
      for (final e in entries) {
        final memUser = e.value;

        // Check if user already exists in DB by username
        try {
          final existing = await getUserByUsername(memUser.username);
          if (existing != null && existing.id != null) {
            // Map memory entry to existing DB id
            _memoryUsers.remove(e.key);
            _memoryUsers[existing.id!] = existing;
            continue;
          }

          // Insert into DB
          final id = await db.insert('users', {
            'username': memUser.username,
            'password': memUser.password,
            'role': memUser.role,
            'photo': memUser.photo,
            'createdAt': memUser.createdAt ?? DateTime.now().toIso8601String(),
            'level': memUser.level,
            'xp': memUser.xp,
          });

          final migrated = memUser.copyWith(id: id);
          _memoryUsers.remove(e.key);
          _memoryUsers[id] = migrated;
        } catch (_) {
          // Ignore per-user migration errors and continue
          continue;
        }
      }

      // Persist updated memory cache
      await _saveMemoryToPrefs();

      // Migrate session user_id if it references an old memory id
      final prefs = await SharedPreferences.getInstance();
      final sessionId = prefs.getInt('user_id');
      if (sessionId != null) {
        if (!_memoryUsers.containsKey(sessionId)) {
          // Try to find by username in cache
          final raw = prefs.getString('username');
          if (raw != null) {
            UserModel? byName;
            try {
              byName = _memoryUsers.values.firstWhere((u) => u.username == raw);
            } catch (_) {
              byName = null;
            }
            if (byName != null && byName.id != null) {
              await prefs.setInt('user_id', byName.id!);
            }
          }
        }
      }
    } catch (_) {
      // migration failed, but don't crash app
    }
  }

  /// Create user
  Future<UserModel> createUser(UserModel user) async {
    await _ensureMemoryLoaded();

    if (kIsWeb) {
      final id = _memoryIdCounter++;
      final storedUser = user.copyWith(
        id: id,
        createdAt: DateTime.now().toIso8601String(),
      );
      _memoryUsers[id] = storedUser;
      await _saveMemoryToPrefs();
      return storedUser;
    }

    try {
      final db = await _databaseService.database;
      final id = await db.insert(
        'users',
        {
          'username': user.username,
          'password': user.password,
          'role': user.role,
          'photo': user.photo,
          'createdAt': DateTime.now().toIso8601String(),
          'level': user.level,
          'xp': user.xp,
        },
      );
      return user.copyWith(id: id);
    } catch (_) {
      final id = _memoryIdCounter++;
      final storedUser = user.copyWith(
        id: id,
        createdAt: DateTime.now().toIso8601String(),
      );
      _memoryUsers[id] = storedUser;
      await _saveMemoryToPrefs();
      return storedUser;
    }
  }

  /// Get user by ID
  Future<UserModel?> getUserById(int id) async {
    await _ensureMemoryLoaded();

    if (kIsWeb) {
      return _memoryUsers[id];
    }

    try {
      final db = await _databaseService.database;
      final result = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (result.isEmpty) return null;
      return UserModel.fromJson(result.first);
    } catch (_) {
      return _memoryUsers[id];
    }
  }

  /// Get user by username
  Future<UserModel?> getUserByUsername(String username) async {
    await _ensureMemoryLoaded();

    UserModel? findInMemory() {
      for (final user in _memoryUsers.values) {
        if (user.username == username) {
          return user;
        }
      }
      return null;
    }

    if (kIsWeb) {
      return findInMemory();
    }

    try {
      final db = await _databaseService.database;
      final result = await db.query(
        'users',
        where: 'username = ?',
        whereArgs: [username],
      );
      if (result.isEmpty) return null;
      return UserModel.fromJson(result.first);
    } catch (_) {
      return findInMemory();
    }
  }

  /// Update user
  Future<void> updateUser(UserModel user) async {
    await _ensureMemoryLoaded();

    if (kIsWeb) {
      if (user.id != null) {
        _memoryUsers[user.id!] = user;
        await _saveMemoryToPrefs();
      }
      return;
    }

    try {
      final db = await _databaseService.database;
      await db.update(
        'users',
        user.toJson(),
        where: 'id = ?',
        whereArgs: [user.id],
      );
    } catch (_) {
      if (user.id != null) {
        _memoryUsers[user.id!] = user;
        await _saveMemoryToPrefs();
      }
    }
  }

  /// Delete user
  Future<void> deleteUser(int id) async {
    await _ensureMemoryLoaded();

    if (kIsWeb) {
      _memoryUsers.remove(id);
      await _saveMemoryToPrefs();
      return;
    }

    try {
      final db = await _databaseService.database;
      await db.delete(
        'users',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (_) {
      _memoryUsers.remove(id);
      await _saveMemoryToPrefs();
    }
  }

  /// Get all users
  Future<List<UserModel>> getAllUsers() async {
    await _ensureMemoryLoaded();

    if (kIsWeb) {
      return _memoryUsers.values.toList();
    }

    try {
      final db = await _databaseService.database;
      final result = await db.query('users');
      return result.map((json) => UserModel.fromJson(json)).toList();
    } catch (_) {
      return _memoryUsers.values.toList();
    }
  }

  /// Update user XP and Level
  Future<void> updateUserXP(int userId, int xpGained) async {
    await _ensureMemoryLoaded();

    final user = await getUserById(userId);
    if (user != null) {
      final newXP = user.xp + xpGained;
      final newLevel = (newXP ~/ 100) + 1;
      final updated = user.copyWith(xp: newXP, level: newLevel);
      if (kIsWeb) {
        _memoryUsers[userId] = updated;
        await _saveMemoryToPrefs();
        return;
      }

      try {
        final db = await _databaseService.database;
        await db.update(
          'users',
          {'xp': newXP, 'level': newLevel},
          where: 'id = ?',
          whereArgs: [userId],
        );
      } catch (_) {
        _memoryUsers[userId] = updated;
        await _saveMemoryToPrefs();
      }
    }
  }
}
