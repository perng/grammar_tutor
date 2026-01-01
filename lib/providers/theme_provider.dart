import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      // access via context usually required, but for simple toggle check we can imply
      // actually we can complicate this or just keep it simple.
      // For UI logic, relying on Theme.of(context).brightness is better.
      // This is mainly for the Radio/Toggle state.
      return false;
    }
    return _themeMode == ThemeMode.dark;
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
}
