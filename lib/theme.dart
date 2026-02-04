import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFFEA4C89); // pink
  static const Color accent = Color(0xFF6C5CE7); // purple
  static const Color bg = Color(0xFFF7F6FA);

  static ThemeData lightTheme() {
    final base = ThemeData.light();
    return base.copyWith(
      primaryColor: primary,
      scaffoldBackgroundColor: bg,
      colorScheme: base.colorScheme.copyWith(
        primary: primary,
        secondary: accent,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFF7A1F48),
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
        iconTheme: IconThemeData(color: Color(0xFFEA4C89)),
      ),
      textTheme: base.textTheme.copyWith(
        headlineSmall: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        titleLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        bodyMedium: const TextStyle(fontSize: 14),
        labelLarge: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Color(0x26EA4C89))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primary, width: 2)),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      ),
    );
  }
}
