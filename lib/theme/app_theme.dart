// lib/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppColors {
  // Dark theme - غيمر في الليل
  static const background   = Color(0xFF0A0A0F);
  static const surface      = Color(0xFF13131A);
  static const card         = Color(0xFF1C1C26);
  static const primary      = Color(0xFF6C63FF); // بنفسجي
  static const primaryGlow  = Color(0x336C63FF);
  static const success      = Color(0xFF00E676);
  static const danger       = Color(0xFFFF3D71);
  static const warning      = Color(0xFFFFAA00);
  static const textPrimary  = Color(0xFFEEEEF5);
  static const textSecondary= Color(0xFF8888AA);
  static const border       = Color(0xFF2A2A38);
}

class AppTheme {
  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      surface: AppColors.surface,
    ),
    fontFamily: 'Cairo', // عربي واضح
    useMaterial3: true,
  );
}
