import 'package:flutter/material.dart';

class AppColors {
  static const canvas = Color(0xFF131F24);
  static const surface = Color(0xFF202F36);
  static const sidebar = Color(0xFF17262D);
  static const surfaceMuted = Color(0xFF2A3A43);
  static const inputSurface = Color(0xFF26363E);
  static const ink = Color(0xFFF7F7F7);
  static const muted = Color(0xFFAFBFC5);
  static const line = Color(0xFF3A4B55);
  static const green = Color(0xFF58CC02);
  static const blue = Color(0xFF1CB0F6);
  static const yellow = Color(0xFFFFC800);
  static const red = Color(0xFFFF4B4B);
}

ThemeData buildAppTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final surface = isDark ? AppColors.surface : const Color(0xFFFFFFFF);
  final canvas = isDark ? AppColors.canvas : const Color(0xFFF7F7F7);
  final ink = isDark ? AppColors.ink : const Color(0xFF263238);
  final muted = isDark ? AppColors.muted : const Color(0xFF66757F);
  final line = isDark ? AppColors.line : const Color(0xFFD9E1E4);
  final input = isDark ? AppColors.inputSurface : const Color(0xFFFFFFFF);

  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: AppColors.green,
      onPrimary: AppColors.canvas,
      secondary: AppColors.blue,
      onSecondary: AppColors.canvas,
      error: AppColors.red,
      onError: AppColors.ink,
      surface: surface,
      onSurface: ink,
      outline: line,
    ),
    scaffoldBackgroundColor: canvas,
    dividerColor: line,
    textTheme: ThemeData(brightness: brightness).textTheme
        .apply(bodyColor: ink, displayColor: ink),
    appBarTheme: AppBarTheme(
      backgroundColor: isDark ? AppColors.sidebar : surface,
      foregroundColor: ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: input,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      hintStyle: TextStyle(color: muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.green, width: 2),
      ),
    ),
  );
}

Color themeMuted(ThemeData theme) {
  return theme.brightness == Brightness.dark
      ? AppColors.muted
      : const Color(0xFF66757F);
}
