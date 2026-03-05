import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static const String _keyTheme = 'theme';
  static const String _keyLanguage = 'language';
  static const String _keyAutoPlay = 'auto_play';
  static const String _keyVolume = 'volume';
  static const String _keyShowBubbles = 'show_bubbles';

  ThemeMode _themeMode = ThemeMode.dark;
  String _language = 'en';
  bool _autoPlay = false;
  double _volume = 0.7;
  bool _showBubbles = true;

  ThemeMode get themeMode => _themeMode;
  String get language => _language;
  bool get autoPlay => _autoPlay;
  double get volume => _volume;
  bool get showBubbles => _showBubbles;

  SettingsService() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final theme = prefs.getString(_keyTheme);
    if (theme != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (e) => e.name == theme,
        orElse: () => ThemeMode.dark,
      );
    }

    _language = prefs.getString(_keyLanguage) ?? 'en';
    _autoPlay = prefs.getBool(_keyAutoPlay) ?? false;
    _volume = prefs.getDouble(_keyVolume) ?? 0.7;
    _showBubbles = prefs.getBool(_keyShowBubbles) ?? true;

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTheme, mode.name);
    notifyListeners();
  }

  Future<void> setLanguage(String language) async {
    _language = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, language);
    notifyListeners();
  }

  Future<void> setAutoPlay(bool value) async {
    _autoPlay = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoPlay, value);
    notifyListeners();
  }

  Future<void> setVolume(double value) async {
    _volume = value.clamp(0.0, 1.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyVolume, _volume);
    notifyListeners();
  }

  Future<void> setShowBubbles(bool value) async {
    _showBubbles = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowBubbles, value);
    notifyListeners();
  }
}
