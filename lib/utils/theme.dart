import 'package:flutter/material.dart';

// ─── Colour Palette ───────────────────────────────────────────────────────────

class DndColors {
  DndColors._();

  // D&D Crimson Red
  static const darkRed = Color(0xFF7A2021);
  static const fire = darkRed;
  static const blood = Color(0xFF58180D);
  static const ember = Color(0xFF9E2C2D);
  
  // D&D Gold accents
  static const gold = Color(0xFFC5A059);
  static const amber = Color(0xFFB48A3C);

  // Parchment tones
  static const parchment = Color(0xFFF4ECE1);
  static const parchmentDark = Color(0xFFE8DDCB);
  static const parchmentLight = Color(0xFFFAF6EE);

  static const surface = parchment;
  static const surfaceVariant = parchmentDark;
  static const card = parchmentLight;
  static const cardElevated = Color(0xFFFFFDF9);

  // Text colors
  static const textPrimary = Color(0xFF2C1A1B); // Dark red-brown-black for top legibility
  static const textSecondary = Color(0xFF5C4C42); // Warm gray-brown
  static const textMuted = Color(0xFF8C7C72); // Disabled gray-brown
  
  static const onPrimary = Colors.white;
  static const onSurface = textPrimary;
  static const onSurfaceMuted = textSecondary;

  // Status/utility colors (adjusted for visibility on light parchment)
  static const beerGreen = Color(0xFF2E7D32);
  static const beerOrange = Color(0xFFE65100);
  static const beerRed = Color(0xFFC62828);
}

// ─── Theme Data ───────────────────────────────────────────────────────────────

class DndTheme {
  DndTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'EBGaramond',
      colorScheme: const ColorScheme.light(
        primary: DndColors.darkRed,
        secondary: DndColors.gold,
        surface: DndColors.parchment,
        surfaceContainerHighest: DndColors.parchmentDark,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: DndColors.textPrimary,
        onSurfaceVariant: DndColors.textSecondary,
      ),
      scaffoldBackgroundColor: DndColors.parchment,
      appBarTheme: const AppBarTheme(
        backgroundColor: DndColors.darkRed,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Cinzel',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 1.1,
        ),
      ),
      cardTheme: CardThemeData(
        color: DndColors.parchmentLight,
        elevation: 2,
        shadowColor: DndColors.darkRed.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: DndColors.parchmentDark, width: 1.2),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DndColors.darkRed,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(
            fontFamily: 'Cinzel',
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 0.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: DndColors.darkRed,
          textStyle: const TextStyle(
            fontFamily: 'Cinzel',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DndColors.darkRed,
          side: const BorderSide(color: DndColors.darkRed, width: 1.2),
          textStyle: const TextStyle(
            fontFamily: 'Cinzel',
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DndColors.parchmentLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: DndColors.parchmentDark, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: DndColors.parchmentDark, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: DndColors.darkRed, width: 1.8),
        ),
        labelStyle: const TextStyle(color: DndColors.textSecondary, fontFamily: 'EBGaramond'),
        hintStyle: const TextStyle(color: DndColors.textMuted, fontFamily: 'EBGaramond'),
      ),
      dividerTheme: const DividerThemeData(
        color: DndColors.parchmentDark,
        space: 1,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: DndColors.darkRed,
        foregroundColor: Colors.white,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: DndColors.textPrimary,
        contentTextStyle: const TextStyle(color: DndColors.parchmentLight, fontFamily: 'EBGaramond'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: DndColors.darkRed,
        unselectedLabelColor: DndColors.textSecondary,
        indicatorColor: DndColors.darkRed,
        dividerColor: DndColors.parchmentDark,
        labelStyle: TextStyle(fontFamily: 'Cinzel', fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle: TextStyle(fontFamily: 'Cinzel', fontSize: 13),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontFamily: 'Cinzel',
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: DndColors.darkRed,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Cinzel',
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: DndColors.darkRed,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Cinzel',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: DndColors.darkRed,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Cinzel',
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: DndColors.darkRed,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'EBGaramond',
          fontSize: 16,
          color: DndColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'EBGaramond',
          fontSize: 14,
          color: DndColors.textSecondary,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Cinzel',
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: DndColors.darkRed,
        ),
      ),
    );
  }

  static ThemeData get dark => light;
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
