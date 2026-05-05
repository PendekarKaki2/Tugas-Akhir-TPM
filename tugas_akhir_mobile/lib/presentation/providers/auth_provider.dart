import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';
import '../../core/security/password_hashing.dart';

/// Auth Provider for Login/Register
class AuthProvider extends ChangeNotifier {
  final UserRepository _userRepository;
  
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  AuthProvider(this._userRepository);

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;

  /// Register new user
  Future<bool> register(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final hashedPassword = PasswordHashing.hashPassword(password);
      await _userRepository.registerUser(username, hashedPassword);
      
      // Auto login after registration
      await login(username, password);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Login user
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final hashedPassword = PasswordHashing.hashPassword(password);
      final user = await _userRepository.loginUser(username, hashedPassword);
      _currentUser = user;

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_id', user.id ?? 0);
      await prefs.setString('username', user.username);
      await prefs.setBool('is_logged_in', true);

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check if user is already logged in
  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    
    if (userId != null) {
      _currentUser = await _userRepository.getUserById(userId);
      notifyListeners();
    }
  }

  Future<bool> biometricQuickLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null) {
      _error = 'Belum ada sesi login sebelumnya';
      notifyListeners();
      return false;
    }

    final user = await _userRepository.getUserById(userId);
    if (user == null) {
      _error = 'Data pengguna tidak ditemukan';
      notifyListeners();
      return false;
    }

    _currentUser = user;
    await prefs.setBool('is_logged_in', true);
    notifyListeners();
    return true;
  }

  /// Logout user
  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
    await prefs.remove('user_id');
    await prefs.remove('username');
    notifyListeners();
  }

  /// Update user profile
  Future<bool> updateProfile(String? photo) async {
    if (_currentUser == null) return false;
    
    try {
      final updatedUser = _currentUser!.copyWith(photo: photo);
      await _userRepository.updateUser(updatedUser);
      _currentUser = updatedUser;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
