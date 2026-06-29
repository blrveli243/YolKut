import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppThemeNotifier extends Notifier<ThemeMode> {
  static const _storage = FlutterSecureStorage();
  static const _themeKey = 'theme_mode';

  @override
  ThemeMode build() {
    _loadTheme();
    return ThemeMode.dark; // Default to dark until loaded
  }

  Future<void> _loadTheme() async {
    try {
      final savedTheme = await _storage.read(key: _themeKey).timeout(const Duration(seconds: 3));
      if (savedTheme != null) {
        state = savedTheme == 'light' ? ThemeMode.light : ThemeMode.dark;
      }
    } catch (e) {
      // Ignored: Default is dark.
    }
  }

  Future<void> toggleTheme() async {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    try {
      await _storage.write(key: _themeKey, value: state == ThemeMode.light ? 'light' : 'dark').timeout(const Duration(seconds: 3));
    } catch (e) {
      // Ignore
    }
  }
}

final themeProvider = NotifierProvider<AppThemeNotifier, ThemeMode>(() {
  return AppThemeNotifier();
});

class AppThemes {
  static final lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF2F2F7), // iOS Light Gray
    cardColor: Colors.white,
    fontFamily: 'Inter',
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF0A84FF),
      surface: Colors.white,
      onSurface: Colors.black87,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.black87),
      titleTextStyle: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
    ),
    dividerColor: const Color(0xFFE5E5EA), // Light divider
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Color(0xFF0A84FF),
      unselectedItemColor: Colors.black38,
    ),
  );

  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0F0F13), // Premium Dark
    cardColor: const Color(0xFF161618), // Dark card
    fontFamily: 'Inter',
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF0A84FF),
      surface: Color(0xFF1C1C1E),
      onSurface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
    ),
    dividerColor: const Color(0xFF2C2C2E), // Dark divider
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF161618),
      selectedItemColor: Color(0xFF32D74B),
      unselectedItemColor: Colors.white54,
    ),
  );
}
