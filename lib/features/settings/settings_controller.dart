import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends ChangeNotifier {
  SettingsController(this._prefs) {
    _themeMode = _loadThemeMode();
  }

  final SharedPreferences _prefs;
  static const String _themeKey = 'themeMode';
  static const String _aiProviderKey = 'aiProvider';
  static const String _geminiApiKey = 'geminiApiKey';
  static const String _openaiApiKey = 'openaiApiKey';
  static const String _syncToCloudKey = 'syncToCloud';

  late ThemeMode _themeMode;
  ThemeMode get themeMode => _themeMode;

  String get aiProvider => _prefs.getString(_aiProviderKey) ?? 'gemini';
  String get geminiApiKey => _prefs.getString(_geminiApiKey) ?? '';
  String get openaiApiKey => _prefs.getString(_openaiApiKey) ?? '';
  bool get syncToCloud => _prefs.getBool(_syncToCloudKey) ?? false;

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

  Future<void> setAiProvider(String provider) async {
    await _prefs.setString(_aiProviderKey, provider);
    notifyListeners();
  }

  Future<void> setGeminiApiKey(String key) async {
    await _prefs.setString(_geminiApiKey, key);
    notifyListeners();
  }

  Future<void> setOpenaiApiKey(String key) async {
    await _prefs.setString(_openaiApiKey, key);
    notifyListeners();
  }

  Future<void> setSyncToCloud(bool value) async {
    await _prefs.setBool(_syncToCloudKey, value);
    notifyListeners();
  }
}


