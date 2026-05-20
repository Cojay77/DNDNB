import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors
  static const Color primary = Color(0xFFFF4500); // Feu (Deep Orange)
  static const Color secondary = Color(0xFF8B0000); // Dark Red
  static const Color surface = Color(0xFF1E1E1E);
  static const Color background = Colors.black;

  // Status Colors
  static const Color statusConfirmed = Colors.green;
  static const Color statusCancelled = Colors.red;
  static const Color statusModified = Colors.orange;
  static const Color statusDefault = Color.fromARGB(0, 158, 158, 158);

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmée':
        return statusConfirmed;
      case 'annulée':
        return statusCancelled;
      case 'modifiée':
        return statusModified;
      default:
        return statusDefault;
    }
  }

  // Stock Colors
  static Color getStockColor(double stock) {
    if (stock >= 15) return Colors.green;
    if (stock >= 8) return Colors.orange;
    return Colors.red;
  }

  // ThemeData
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white70,
      ),
      textTheme: ThemeData.dark().textTheme.copyWith(
            headlineMedium: const TextStyle(fontFamily: 'UncialAntiqua'),
            titleLarge: const TextStyle(fontFamily: 'UncialAntiqua'),
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
