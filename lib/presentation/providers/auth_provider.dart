import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
  bool get isPremium => _currentUser?.isPremium ?? false;

  DateTime? _readMembershipExpiry(SharedPreferences prefs) {
    final raw = prefs.getString('membership_valid_until');
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> _syncMembershipState(UserModel? user, SharedPreferences prefs) async {
    if (user == null) return;

    final expiry = _readMembershipExpiry(prefs);
    final now = DateTime.now();
    final hasExpiry = expiry != null;
    final isExpired = hasExpiry && now.isAfter(expiry!);
    final activeFromStorage = prefs.getBool('is_premium') ?? user.isPremium;
    final shouldBePremium = isExpired ? false : activeFromStorage;

    if (isExpired) {
      await prefs.setBool('is_premium', false);
      await prefs.remove('membership_plan_code');
      await prefs.remove('membership_payment_method');
      await prefs.remove('membership_receipt_id');
      await prefs.remove('membership_purchased_at');
      await prefs.remove('membership_valid_until');
    } else {
      await prefs.setBool('is_premium', shouldBePremium);
    }

    if (user.isPremium != shouldBePremium) {
      final updatedUser = user.copyWith(isPremium: shouldBePremium);
      await _userRepository.updateUser(updatedUser);
      _currentUser = updatedUser;
    } else {
      _currentUser = user.copyWith(isPremium: shouldBePremium);
    }
  }

  /// Register new user
  Future<bool> register(String username, String password, {String role = 'student'}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('[AuthProvider] Starting registration for user: $username');
      
      final hashedPassword = PasswordHashing.hashPassword(password);
      await _userRepository.registerUser(username, hashedPassword, role: role);
      
      debugPrint('[AuthProvider] ✓ User registered successfully: $username');
      
      // Auto login after registration
      final loginSuccess = await login(username, password);
      
      if (loginSuccess) {
        debugPrint('[AuthProvider] ✓ Auto-login successful after registration');
      } else {
        debugPrint('[AuthProvider] ✗ Auto-login failed after registration');
      }
      
      return loginSuccess;
    } catch (e) {
      debugPrint('[AuthProvider] ✗ Registration error: $e');
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
      debugPrint('[AuthProvider] Starting login for user: $username');
      
      final hashedPassword = PasswordHashing.hashPassword(password);
      final user = await _userRepository.loginUser(username, hashedPassword);
      
      _currentUser = user;
      debugPrint('[AuthProvider] ✓ Login successful: $username (id=${user.id})');

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_id', user.id ?? 0);
      await prefs.setString('username', user.username);
      await prefs.setString('role', user.role);
      await prefs.setBool('is_logged_in', true);
      await prefs.setBool('is_premium', user.isPremium);
      await _syncMembershipState(_currentUser, prefs);
      
      debugPrint('[AuthProvider] ✓ Session saved to SharedPreferences');

      return true;
    } catch (e) {
      debugPrint('[AuthProvider] ✗ Login error: $e');
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
      await _syncMembershipState(_currentUser, prefs);
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
    await prefs.setBool('is_premium', user.isPremium);
    await _syncMembershipState(_currentUser, prefs);
    notifyListeners();
    return true;
  }

  /// Logout user
  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
    await prefs.remove('user_id');
    await prefs.remove('is_premium');
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

  /// Mark current user as premium and persist the status.
  Future<bool> setPremiumStatus(bool value) async {
    if (_currentUser == null) return false;

    try {
      final updatedUser = _currentUser!.copyWith(isPremium: value);
      await _userRepository.updateUser(updatedUser);
      _currentUser = updatedUser;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_premium', value);
      if (!value) {
        await prefs.remove('membership_plan_code');
        await prefs.remove('membership_payment_method');
        await prefs.remove('membership_receipt_id');
        await prefs.remove('membership_purchased_at');
        await prefs.remove('membership_valid_until');
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Store membership purchase metadata for the active user.
  Future<bool> recordMembershipPurchase({
    required String planCode,
    required String paymentMethod,
    required String receiptId,
    required DateTime purchasedAt,
    required DateTime? validUntil,
  }) async {
    if (_currentUser == null) return false;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('membership_plan_code', planCode);
      await prefs.setString('membership_payment_method', paymentMethod);
      await prefs.setString('membership_receipt_id', receiptId);
      await prefs.setString('membership_purchased_at', purchasedAt.toIso8601String());
      if (validUntil != null) {
        await prefs.setString('membership_valid_until', validUntil.toIso8601String());
      } else {
        await prefs.remove('membership_valid_until');
      }

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
