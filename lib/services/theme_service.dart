import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  double _fontSize = 14.0;
  String _fontFamily = 'Roboto';

  ThemeMode get themeMode => _themeMode;
  double get fontSize => _fontSize;
  String get fontFamily => _fontFamily;

  ThemeService() {
    _loadPrefs();
  }

  void _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('theme_mode') ?? 'system';
    _themeMode = mode == 'light'
        ? ThemeMode.light
        : mode == 'dark'
            ? ThemeMode.dark
            : ThemeMode.system;
    _fontSize = prefs.getDouble('font_size') ?? 14.0;
    _fontFamily = prefs.getString('font_family') ?? 'Roboto';
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'theme_mode',
        mode == ThemeMode.light
            ? 'light'
            : mode == ThemeMode.dark
                ? 'dark'
                : 'system');
    notifyListeners();
  }

  void setFontSize(double size) async {
    _fontSize = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('font_size', size);
    notifyListeners();
  }

  void setFontFamily(String family) async {
    _fontFamily = family;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('font_family', family);
    notifyListeners();
  }

  ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.light,
        ),
        fontFamily: _fontFamily,
        textTheme: TextTheme(
          bodyMedium: TextStyle(fontSize: _fontSize),
          bodyLarge: TextStyle(fontSize: _fontSize + 2),
          bodySmall: TextStyle(fontSize: _fontSize - 2),
        ),
      );

  ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
        fontFamily: _fontFamily,
        textTheme: TextTheme(
          bodyMedium: TextStyle(fontSize: _fontSize),
          bodyLarge: TextStyle(fontSize: _fontSize + 2),
          bodySmall: TextStyle(fontSize: _fontSize - 2),
        ),
      );
}
