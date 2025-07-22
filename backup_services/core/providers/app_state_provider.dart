import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/service_locator.dart';

class AppStateProvider extends ChangeNotifier {
  static const String _firstTimeKey = 'first_time';
  static const String _themeModeKey = 'theme_mode';

  bool _isFirstTime = true;
  ThemeMode _themeMode = ThemeMode.system;
  bool _isInitialized = false;

  bool get isFirstTime => _isFirstTime;
  ThemeMode get themeMode => _themeMode;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    try {
      final prefs = getIt<SharedPreferences>();

      _isFirstTime = prefs.getBool(_firstTimeKey) ?? true;

      final themeModeIndex =
          prefs.getInt(_themeModeKey) ?? ThemeMode.system.index;
      _themeMode = ThemeMode.values[themeModeIndex];

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing app state: $e');
    }
  }

  Future<void> setFirstTimeComplete() async {
    try {
      final prefs = getIt<SharedPreferences>();
      await prefs.setBool(_firstTimeKey, false);
      _isFirstTime = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting first time complete: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    try {
      final prefs = getIt<SharedPreferences>();
      await prefs.setInt(_themeModeKey, mode.index);
      _themeMode = mode;
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting theme mode: $e');
    }
  }

  void reset() {
    _isFirstTime = true;
    _themeMode = ThemeMode.system;
    _isInitialized = false;
    notifyListeners();
  }
}
