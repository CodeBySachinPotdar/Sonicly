import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsViewModel extends ChangeNotifier {
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyAmoled = 'is_amoled';
  static const String _keyResume = 'resume_playback';

  ThemeMode _themeMode = ThemeMode.system;
  bool _isAmoled = false;
  bool _resumeOnLaunch = true;

  ThemeMode get themeMode => _themeMode;
  bool get isAmoled => _isAmoled;
  bool get resumeOnLaunch => _resumeOnLaunch;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_keyThemeMode) ?? 0;
    _themeMode = ThemeMode.values[themeIndex.clamp(0, ThemeMode.values.length - 1)];
    _isAmoled = prefs.getBool(_keyAmoled) ?? false;
    _resumeOnLaunch = prefs.getBool(_keyResume) ?? true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyThemeMode, mode.index);
  }

  Future<void> setAmoled(bool value) async {
    _isAmoled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAmoled, value);
  }

  Future<void> setResumeOnLaunch(bool value) async {
    _resumeOnLaunch = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyResume, value);
  }
}
