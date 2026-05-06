import 'package:flutter/material.dart';

/// Theme Provider for Dark/Light Mode
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  /// Toggle theme
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  /// Set theme
  void setTheme(bool isDark) {
    _isDarkMode = isDark;
    notifyListeners();
  }
}
