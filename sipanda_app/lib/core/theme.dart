import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SipandaTheme {
  // Brand Colors
  static const Color background = Color(0xFF131313);
  static const Color surface = Color(0xFF1C1B1B);
  static const Color surfaceHigh = Color(0xFF2A2A2A);
  static const Color primary = Color(0xFFA5C8FF);
  static const Color textPrimary = Color(0xFFE5E2E1);
  static const Color textSecondary = Color(0xFFC1C6D4);
  
  // Status Colors
  static const Color statusAman = Color(0xFF88D982); // Green
  static const Color statusWaspada = Color(0xFFFFEA00); // Yellow
  static const Color statusSiaga = Color(0xFF800000); // Maroon
  
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        surface: surface,
      ),
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
    );
  }
}
