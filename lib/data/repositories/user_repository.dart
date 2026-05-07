import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../sources/local/user_local_data_source.dart';

/// User Repository
class UserRepository {
  final UserLocalDataSource _localDataSource;

  UserRepository(this._localDataSource);

  /// Register user
  Future<bool> registerUser(String username, String password, {String role = 'student'}) async {
    try {
      // Check if username already exists
      final existingUser = await _localDataSource.getUserByUsername(username);
      if (existingUser != null) {
        throw Exception('Username sudah terdaftar');
      }

      // Create new user model
      final user = UserModel(
        username: username,
        password: password,
        role: role,
      );

      // Try to save to database
      try {
        await _localDataSource.createUser(user);
        debugPrint('[UserRepository] ✓ User registered and saved to database: $username');
        return true;
      } catch (dbError) {
        // Database operation failed
        debugPrint('[UserRepository] ✗ Database save failed: $dbError');
        throw Exception('Gagal menyimpan data user ke database: $dbError. Pastikan database terinialisasi dengan baik.');
      }
    } catch (e) {
      debugPrint('[UserRepository] ✗ Registration error: $e');
      throw Exception('Registrasi gagal: $e');
    }
  }

  /// Login user
  Future<UserModel> loginUser(String username, String password) async {
    try {
      debugPrint('[UserRepository] Attempting login for user: $username');
      debugPrint('[UserRepository] Password hash length: ${password.length}');
      
      final user = await _localDataSource.getUserByUsername(username);
      
      if (user == null) {
        debugPrint('[UserRepository] ✗ User not found in database/memory: $username');
        throw Exception('User not found');
      }
      
      debugPrint('[UserRepository] ✓ User found: $username (id=${user.id})');
      debugPrint('[UserRepository] Comparing passwords - provided length: ${password.length}, stored length: ${user.password.length}');
      
      if (user.password != password) {
        debugPrint('[UserRepository] ✗ Password mismatch for user: $username');
        throw Exception('Invalid password');
      }
      
      debugPrint('[UserRepository] ✓ Password verified for user: $username');
      return user;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  /// Get user by ID
  Future<UserModel?> getUserById(int id) async {
    return await _localDataSource.getUserById(id);
  }

  /// Update user
  Future<void> updateUser(UserModel user) async {
    await _localDataSource.updateUser(user);
  }

  /// Update user XP
  Future<void> updateUserXP(int userId, int xpGained) async {
    await _localDataSource.updateUserXP(userId, xpGained);
  }

  /// Get all users for leaderboard
  Future<List<UserModel>> getAllUsers() async {
    return await _localDataSource.getAllUsers();
  }
}
