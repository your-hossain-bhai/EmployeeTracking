import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Service to manage theme preferences
class ThemePreferencesService {
  static const String _boxName = 'theme_prefs';
  static const String _themeModeKey = 'theme_mode';

  Box? _box;

  /// Initialize theme preferences
  Future<void> initialize() async {
    _box = await Hive.openBox(_boxName);
  }

  /// Get saved theme mode (null = system default)
  ThemeMode getThemeMode() {
    final modeStr = _box?.get(_themeModeKey, defaultValue: 'system') as String;
    switch (modeStr) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  /// Save theme mode preference
  Future<void> setThemeMode(ThemeMode mode) async {
    String modeStr;
    switch (mode) {
      case ThemeMode.light:
        modeStr = 'light';
        break;
      case ThemeMode.dark:
        modeStr = 'dark';
        break;
      case ThemeMode.system:
        modeStr = 'system';
        break;
    }
    await _box?.put(_themeModeKey, modeStr);
  }

  /// Clear all theme preferences
  Future<void> clear() async {
    await _box?.clear();
  }
}
