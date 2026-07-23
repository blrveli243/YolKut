import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'app_colors.dart';

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
      final savedTheme = await _storage
          .read(key: _themeKey)
          .timeout(const Duration(seconds: 3));
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
      await _storage
          .write(
            key: _themeKey,
            value: state == ThemeMode.light ? 'light' : 'dark',
          )
          .timeout(const Duration(seconds: 3));
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
    scaffoldBackgroundColor: AppColors.lightBackground,
    cardColor: AppColors.lightCard,
    fontFamily: 'Inter',
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      surface: AppColors.lightCard,
      onSurface: AppColors.lightText,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.lightText),
      titleTextStyle: TextStyle(
        color: AppColors.lightText,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
    dividerColor: AppColors.lightDivider,
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.lightCard,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.black38,
    ),
  );

  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBackground,
    cardColor: AppColors.darkCard,
    fontFamily: 'Inter',
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      surface: AppColors.darkCard,
      onSurface: AppColors.darkText,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.darkText),
      titleTextStyle: TextStyle(
        color: AppColors.darkText,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
    dividerColor: AppColors.darkDivider,
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.darkBackground,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.white54,
    ),
  );
}
