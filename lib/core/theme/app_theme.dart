import 'package:flutter/material.dart';

class AppTheme {
  static const darkBackground = Color(0xFF0D0D0D);
  static const primaryNeon = Color(0xFF39FF14); // Verde Neon p/ Academia/Futebol
  static const glassColor = Color(0xFF1A1A1A);

  static final theme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBackground,
    primaryColor: primaryNeon,
    cardColor: glassColor,
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
      bodyMedium: TextStyle(color: Colors.white70, fontSize: 16),
    ),
  );
}
