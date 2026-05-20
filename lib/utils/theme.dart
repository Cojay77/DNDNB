import 'package:flutter/material.dart';

// ─── Colour Palette ───────────────────────────────────────────────────────────

class DndColors {
  DndColors._();

  static const fire = Color(0xFFFF4500);
  static const blood = Color(0xFF8B0000);
  static const ember = Color(0xFFFF7043);
  static const gold = Color(0xFFFFC107);
  static const amber = Color(0xFFFFB300);

  static const surface = Color(0xFF1A1A1A);
  static const surfaceVariant = Color(0xFF242424);
  static const card = Color(0xFF1E1E1E);
  static const cardElevated = Color(0xFF2A2A2A);

  static const onPrimary = Colors.white;
  static const onSurface = Color(0xFFE0E0E0);
  static const onSurfaceMuted = Color(0xFF9E9E9E);

  static const beerGreen = Color(0xFF4CAF50);
  static const beerOrange = Color(0xFFF57C00);
  static const beerRed = Color(0xFFD32F2F);
}

// ─── Theme Data ───────────────────────────────────────────────────────────────

class DndTheme {
  DndTheme._();

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'UncialAntiqua',
      colorScheme: const ColorScheme.dark(
        primary: DndColors.fire,
        secondary: DndColors.blood,
        surface: DndColors.surface,
        surfaceContainerHighest: DndColors.surfaceVariant,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: DndColors.onSurface,
      ),
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'UncialAntiqua',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: DndColors.card,
        elevation: 3,
        shadowColor: DndColors.fire.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DndColors.fire,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: DndColors.ember,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DndColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DndColors.fire, width: 1.5),
        ),
        labelStyle: const TextStyle(color: DndColors.onSurfaceMuted),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF333333),
        space: 1,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: DndColors.fire,
        foregroundColor: Colors.white,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: DndColors.cardElevated,
        contentTextStyle: const TextStyle(color: DndColors.onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: DndColors.onSurfaceMuted,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        unselectedLabelStyle: TextStyle(fontSize: 14),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontFamily: 'UncialAntiqua',
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: DndColors.onSurface,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'UncialAntiqua',
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: DndColors.onSurface,
        ),
        titleLarge: TextStyle(
          fontFamily: 'UncialAntiqua',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: DndColors.onSurface,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: DndColors.onSurface,
        ),
        bodyLarge: TextStyle(fontSize: 15, color: DndColors.onSurface),
        bodyMedium: TextStyle(fontSize: 13, color: DndColors.onSurfaceMuted),
        labelLarge: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: DndColors.onSurface,
        ),
      ),
    );
  }
}

// ─── Spacing Tokens ───────────────────────────────────────────────────────────

class DndSpacing {
  DndSpacing._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

// ─── Border Radius Tokens ─────────────────────────────────────────────────────

class DndRadius {
  DndRadius._();

  static const sm = Radius.circular(8);
  static const md = Radius.circular(12);
  static const lg = Radius.circular(16);
  static const xl = Radius.circular(24);

  static const BorderRadius cardRadius =
      BorderRadius.all(Radius.circular(16));
  static const BorderRadius buttonRadius =
      BorderRadius.all(Radius.circular(12));
}
