import 'package:crypto/crypto.dart';

/// Password Hashing Utility using SHA-256
class PasswordHashing {
  /// Hash password using SHA-256
  static String hashPassword(String password) {
    return sha256.convert(password.codeUnits).toString();
  }

  /// Verify password against hash
  static bool verifyPassword(String password, String hash) {
    final hashedPassword = hashPassword(password);
    return hashedPassword == hash;
  }

  /// Validate password strength
  static bool isPasswordStrong(String password) {
    // At least 8 characters, 1 uppercase, 1 lowercase, 1 number
    final regex =
        RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$');
    return regex.hasMatch(password);
  }
}
