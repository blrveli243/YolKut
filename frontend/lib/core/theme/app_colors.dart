import 'package:flutter/material.dart';

class AppColors {
  // Primary (Ateş Turuncusu / Deep Orange for Discipline & Action)
  static const Color primary = Color(0xFFFF4D00); // Sharp Action Orange
  
  // Semantic Colors (Slightly muted to maintain seriousness)
  static const Color error = Color(0xFFE63946); // Crimson Red
  static const Color warning = Color(0xFFFF9F0A);
  static const Color info = Color(0xFF007AFF);
  
  // Macros & Specific (High contrast on black)
  static const Color protein = Color(0xFFE63946);
  static const Color carbs = Color(0xFFFF9F0A);
  static const Color fat = Color(0xFF8B5CF6);
  static const Color sugar = Color(0xFF00C896);
  static const Color water = Color(0xFF0EA5E9);

  // Light Theme Neutrals (Very minimal usage)
  static const Color lightBackground = Color(0xFFF9FAFB);
  static const Color lightCard = Colors.white;
  static const Color lightText = Color(0xFF111827);
  static const Color lightDivider = Color(0xFFE5E7EB);

  // Dark Theme Neutrals (The core of the discipline aesthetic)
  static const Color darkBackground = Color(0xFF000000); // Pure Black for focus
  static const Color darkCard = Color(0xFF09090B); // Extremely dark gray for slight elevation
  static const Color darkText = Color(0xFFF9FAFB); // Off-white for readability
  static const Color darkDivider = Color(0xFF27272A); // Sharp, subtle borders
}
