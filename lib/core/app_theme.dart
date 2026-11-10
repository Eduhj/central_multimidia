import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF0B0F14);
  static const surface = Color(0xFF151B23);
  static const surfaceHigh = Color(0xFF202A36);
  static const accent = Color(0xFF29B6F6);
  static const text = Color(0xFFEAF1F8);
  static const textDim = Color(0xFF8FA3B5);
  static const ok = Color(0xFF4CAF50);
  static const warn = Color(0xFFFFB300);
}

class AppTheme {
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accent,
          surface: AppColors.surface,
        ),
      );
}
