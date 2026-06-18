import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() {
    return _theme(
      ColorScheme.fromSeed(
        seedColor: const Color(0xff2f7d6d),
        brightness: Brightness.light,
      ),
    );
  }

  static ThemeData dark() {
    return _theme(
      ColorScheme.fromSeed(
        seedColor: const Color(0xff7ac7b8),
        brightness: Brightness.dark,
      ),
    );
  }

  static ThemeData _theme(ColorScheme colorScheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: const AppBarTheme(centerTitle: false),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
