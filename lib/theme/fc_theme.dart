import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';

final ThemeData blackGoldTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF0B0B0B),
  fontFamily: null,
  colorScheme: const ColorScheme.dark(
    primary: AppConstants.primaryColor,
    onPrimary: Color(0xFF111111),
    secondary: Color(0xFFFFD700),
    onSecondary: Color(0xFF111111),
    surface: Color(0xFF121212),
    onSurface: Color(0xFFF5E7B2),
    surfaceContainerHighest: Color(0xFF1C1C1C),
    primaryContainer: Color(0xFF3A2F0B),
    onPrimaryContainer: Color(0xFFF5E7B2),
    error: Color(0xFFCF6679),
    onError: Colors.white,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF0B0B0B),
    foregroundColor: AppConstants.primaryColor,
    elevation: 0,
    centerTitle: true,
  ),
  cardTheme: CardThemeData(
    color: const Color(0xFF141414),
    elevation: 3,
    shadowColor: Colors.black54,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(22),
      side: const BorderSide(color: Color(0xFF3A2F0B), width: 1),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF161616),
    hintStyle: const TextStyle(color: Color(0xFFBFA75A)),
    prefixIconColor: AppConstants.primaryColor,
    suffixIconColor: AppConstants.primaryColor,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFF6E5A1E)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFF4A3B12)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppConstants.primaryColor, width: 1.4),
    ),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: const Color(0xFF181818),
    selectedColor: AppConstants.primaryColor,
    disabledColor: const Color(0xFF1F1F1F),
    secondarySelectedColor: AppConstants.primaryColor,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    labelStyle: const TextStyle(
      color: Color(0xFFF5E7B2),
      fontWeight: FontWeight.w600,
    ),
    secondaryLabelStyle: const TextStyle(
      color: Color(0xFF111111),
      fontWeight: FontWeight.w700,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(999),
      side: const BorderSide(color: Color(0xFF4A3B12)),
    ),
  ),
  textTheme: const TextTheme(
    headlineSmall: TextStyle(
      color: AppConstants.primaryColor,
      fontWeight: FontWeight.w800,
    ),
    titleLarge: TextStyle(
      color: Color(0xFFF5E7B2),
      fontWeight: FontWeight.w800,
    ),
    titleMedium: TextStyle(
      color: Color(0xFFF5E7B2),
      fontWeight: FontWeight.w700,
    ),
    bodyLarge: TextStyle(color: Color(0xFFF5E7B2)),
    bodyMedium: TextStyle(color: Color(0xFFE8D89A)),
    labelMedium: TextStyle(color: Color(0xFFF5E7B2)),
  ),
  iconTheme: const IconThemeData(
    color: AppConstants.primaryColor,
  ),
  dividerTheme: const DividerThemeData(
    color: Color(0xFF3A2F0B),
    thickness: 1,
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: AppConstants.primaryColor,
      foregroundColor: const Color(0xFF111111),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppConstants.primaryColor,
    ),
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: AppConstants.primaryColor,
  ),
);