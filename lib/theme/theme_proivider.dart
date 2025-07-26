import 'package:flutter/material.dart';
import 'package:zypto/theme/theme.dart';

enum AppThemeMode { system, light, dark }

class ThemeProvider with ChangeNotifier, WidgetsBindingObserver {
  AppThemeMode _appThemeMode = AppThemeMode.system;
  ThemeData _themeData;

  ThemeProvider() : _themeData = lightMode {
    WidgetsBinding.instance.addObserver(this);
    _updateThemeFromSystem();
  }

  ThemeData get themeData => _themeData;
  AppThemeMode get appThemeMode => _appThemeMode;

  void setThemeMode(AppThemeMode mode) {
    _appThemeMode = mode;
    if (mode == AppThemeMode.system) {
      _updateThemeFromSystem();
    } else if (mode == AppThemeMode.light) {
      _themeData = lightMode;
    } else if (mode == AppThemeMode.dark) {
      _themeData = darkMode;
    }
    notifyListeners();
  }

  void toggleTheme() {
    if (_appThemeMode == AppThemeMode.system) {
      setThemeMode(AppThemeMode.light);
    } else if (_appThemeMode == AppThemeMode.light) {
      setThemeMode(AppThemeMode.dark);
    } else {
      setThemeMode(AppThemeMode.system);
    }
  }

  void _updateThemeFromSystem() {
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    _themeData = brightness == Brightness.dark ? darkMode : lightMode;
  }

  @override
  void didChangePlatformBrightness() {
    if (_appThemeMode == AppThemeMode.system) {
      _updateThemeFromSystem();
      notifyListeners();
    }
  }
  void disposeObserver() {
    WidgetsBinding.instance.removeObserver(this);
  }
}
