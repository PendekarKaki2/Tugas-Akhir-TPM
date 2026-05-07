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
      debugPrint('[UserLocalDataSource] Memory already loaded (${_memoryUsers.length} users in memory)');
      return;
    }

    debugPrint('[UserLocalDataSource] Starting memory load from SharedPreferences...');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Show all keys in SharedPreferences for debugging
      final allKeys = prefs.getKeys();
      debugPrint('[UserLocalDataSource] All SharedPreferences keys: $allKeys');
      
      final raw = prefs.getString(_usersCacheKey);
      final idCounter = prefs.getInt(_usersIdCounterKey);
      
      debugPrint('[UserLocalDataSource] SharedPreferences raw data: ${raw != null ? "found (${raw.length} chars)" : "NOT FOUND"}');
      debugPrint('[UserLocalDataSource] SharedPreferences key $_usersCacheKey exists: ${prefs.containsKey(_usersCacheKey)}');
      debugPrint('[UserLocalDataSource] ID Counter from prefs: $idCounter');
      
      if (idCounter != null && idCounter > 0) {
        _memoryIdCounter = idCounter;
        debugPrint('[UserLocalDataSource] Set memory ID counter to: $_memoryIdCounter');
      }

      if (raw != null && raw.isNotEmpty) {
        try {
          debugPrint('[UserLocalDataSource] Decoding JSON from SharedPreferences...');
          final decoded = jsonDecode(raw) as List<dynamic>;
          debugPrint('[UserLocalDataSource] Decoded ${decoded.length} users from JSON');
          
          for (final item in decoded) {
            final map = (item as Map).cast<String, dynamic>();
            final user = UserModel.fromJson(map);
            if (user.id != null) {
              _memoryUsers[user.id!] = user;
              debugPrint('[UserLocalDataSource]   - Loaded user: id=${user.id}, username=${user.username}');
            }
          }
          debugPrint('[UserLocalDataSource] ✓ Loaded ${_memoryUsers.length} users from SharedPreferences cache');
        } catch (e) {
          debugPrint('[UserLocalDataSource] ✗ ERROR decoding SharedPreferences cache: $e');
          debugPrint('[UserLocalDataSource] Raw data: $raw');
        }
      } else {
        debugPrint('[UserLocalDataSource] No cached users found in SharedPreferences');
        debugPrint('[UserLocalDataSource] ⚠ This may be normal on first run, OR indicate persistence issue (e.g., private browsing)');
        if (kIsWeb) {
          debugPrint('[UserLocalDataSource] Web storage is tied to the browser origin.');
          debugPrint('[UserLocalDataSource] Use the same web hostname and port on every run, for example:');
          debugPrint('[UserLocalDataSource] flutter run -d chrome --web-hostname 127.0.0.1 --web-port 5000');
        }
      }

      _isMemoryLoaded = true;
      debugPrint('[UserLocalDataSource] Memory load complete. Total users in memory: ${_memoryUsers.length}');
    } catch (e) {
      debugPrint('[UserLocalDataSource] ✗ ERROR in _ensureMemoryLoaded: $e');
      _isMemoryLoaded = true;
    }
  }

  Future<void> _saveMemoryToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final users = _memoryUsers.values.map((e) => e.toJson()).toList();
      final encoded = jsonEncode(users);
      
      debugPrint('[UserLocalDataSource] Saving ${users.length} users to SharedPreferences (${encoded.length} chars)');
      debugPrint('[UserLocalDataSource] Saving ID counter: $_memoryIdCounter');
      
      try {
        final success1 = await prefs.setString(_usersCacheKey, encoded);
        debugPrint('[UserLocalDataSource] setString result: $success1');
        
        final success2 = await prefs.setInt(_usersIdCounterKey, _memoryIdCounter);
        debugPrint('[UserLocalDataSource] setInt result: $success2');
        
        if (!success1 || !success2) {
          debugPrint('[UserLocalDataSource] ⚠ WARNING: setString or setInt returned false!');
        }
        
        // Verify write was successful
        final verification = prefs.getString(_usersCacheKey);
        if (verification != null && verification.isNotEmpty) {
          debugPrint('[UserLocalDataSource] ✓ Verified: Data successfully written to SharedPreferences');
          debugPrint('[UserLocalDataSource] Verification length: ${verification.length} chars');
        } else {
          debugPrint('[UserLocalDataSource] ✗ CRITICAL: Could not verify SharedPreferences write!');
          debugPrint('[UserLocalDataSource] Data was NOT persisted to SharedPreferences!');
          debugPrint('[UserLocalDataSource] This is likely a browser/platform issue:');
          debugPrint('[UserLocalDataSource]   - Private browsing mode?');
          debugPrint('[UserLocalDataSource]   - localStorage disabled?');
          debugPrint('[UserLocalDataSource]   - Browser quota exceeded?');
        }
        
      } catch (writeError) {
        debugPrint('[UserLocalDataSource] ✗ CRITICAL ERROR during write: $writeError');
        debugPrint('[UserLocalDataSource] Stack trace: ${writeError.toString()}');
      }
      
    } catch (e) {
      debugPrint('[UserLocalDataSource] ✗ ERROR getting SharedPreferences instance: $e');
      debugPrint('[UserLocalDataSource] ⚠ This indicates SharedPreferences is not available on this platform');
    }
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
      debugPrint('[UserLocalDataSource] Added user to memory: id=$id, username=${user.username}');
      debugPrint('[UserLocalDataSource] Total users in memory now: ${_memoryUsers.length}');
      
      await _saveMemoryToPrefs();
      debugPrint('[UserLocalDataSource] ✓ User created (web memory): id=$id, username=${user.username}');
      return storedUser;
    }

    try {
      final db = await _databaseService.database;
      final createdAt = DateTime.now().toIso8601String();
      final insertData = {
        'username': user.username,
        'password': user.password,
        'role': user.role,
        'photo': user.photo,
        'createdAt': createdAt,
        'level': user.level ?? 1,
        'xp': user.xp ?? 0,
      };
      
      debugPrint('[UserLocalDataSource] Inserting user to SQLite: $insertData');
      final id = await db.insert(
        'users',
        insertData,
      );
      debugPrint('[UserLocalDataSource] ✓ User successfully created in SQLite: id=$id, username=${user.username}');
      
      final savedUser = user.copyWith(id: id, createdAt: createdAt);
      
      // Also cache in memory for quick access
      _memoryUsers[id] = savedUser;
      
      return savedUser;
    } catch (e) {
      debugPrint('[UserLocalDataSource] ✗ ERROR creating user in SQLite: $e');
      debugPrint('[UserLocalDataSource] Falling back to in-memory storage (NOT PERSISTENT!)');
      
      // Re-throw to let caller know about the failure
      rethrow;
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
      debugPrint('[UserLocalDataSource] Querying SQLite for user ID: $id');
      
      final result = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (result.isEmpty) {
        debugPrint('[UserLocalDataSource] ✗ User NOT found in SQLite: id=$id');
        return _memoryUsers[id];
      }
      
      debugPrint('[UserLocalDataSource] ✓ User found in SQLite: id=$id');
      return UserModel.fromJson(result.first);
    } catch (e) {
      debugPrint('[UserLocalDataSource] ✗ ERROR querying SQLite by ID: $e');
      return _memoryUsers[id];
    }
  }

  /// Get user by username
  Future<UserModel?> getUserByUsername(String username) async {
    await _ensureMemoryLoaded();

    UserModel? findInMemory() {
      debugPrint('[UserLocalDataSource] Searching in memory for username: $username (${_memoryUsers.length} users in memory)');
      
      for (final user in _memoryUsers.values) {
        debugPrint('[UserLocalDataSource]   - Checking user: ${user.username}');
        if (user.username == username) {
          debugPrint('[UserLocalDataSource] ✓ User found in memory: $username');
          return user;
        }
      }
      
      debugPrint('[UserLocalDataSource] ✗ User NOT found in memory: $username');
      debugPrint('[UserLocalDataSource] Available usernames in memory: ${_memoryUsers.values.map((u) => u.username).toList()}');
      return null;
    }

    if (kIsWeb) {
      return findInMemory();
    }

    try {
      final db = await _databaseService.database;
      debugPrint('[UserLocalDataSource] Querying SQLite for user: $username');
      
      final result = await db.query(
        'users',
        where: 'username = ?',
        whereArgs: [username],
      );
      
      if (result.isEmpty) {
        debugPrint('[UserLocalDataSource] ✗ User NOT found in SQLite: $username');
        debugPrint('[UserLocalDataSource] Memory users count: ${_memoryUsers.length}');
        return findInMemory();
      }
      
      debugPrint('[UserLocalDataSource] ✓ User found in SQLite: $username (id=${result.first['id']})');
      return UserModel.fromJson(result.first);
    } catch (e) {
      debugPrint('[UserLocalDataSource] ✗ ERROR querying SQLite: $e');
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
