import '../models/user_model.dart';
import '../sources/local/user_local_data_source.dart';

/// User Repository
class UserRepository {
  final UserLocalDataSource _localDataSource;

  UserRepository(this._localDataSource);

  /// Register user
  Future<bool> registerUser(String username, String password) async {
    try {
      final existingUser = await _localDataSource.getUserByUsername(username);
      if (existingUser != null) {
        throw Exception('Username already exists');
      }

      final user = UserModel(
        username: username,
        password: password,
      );
      await _localDataSource.createUser(user);
      return true;
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  /// Login user
  Future<UserModel> loginUser(String username, String password) async {
    try {
      final user = await _localDataSource.getUserByUsername(username);
      if (user == null) {
        throw Exception('User not found');
      }
      if (user.password != password) {
        throw Exception('Invalid password');
      }
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
