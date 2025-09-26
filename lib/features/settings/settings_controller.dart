import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends ChangeNotifier {
  SettingsController(this._prefs) {
    _themeMode = _loadThemeMode();
  }

  final SharedPreferences _prefs;
  static const String _themeKey = 'themeMode';

  late ThemeMode _themeMode;
  ThemeMode get themeMode => _themeMode;

  ThemeMode _loadThemeMode() {
    final value = _prefs.getString(_themeKey);
    switch (value) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setString(
      _themeKey,
      switch (mode) {
        ThemeMode.dark => 'dark',
        ThemeMode.light => 'light',
        _ => 'system',
      },
    );
    notifyListeners();
  }
}


