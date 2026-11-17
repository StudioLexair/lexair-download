import 'package:flutter/material.dart';

abstract final class LexairTheme {
  static ThemeData create(Brightness brightness) {
    final colors = ColorScheme.fromSeed(
      seedColor: const Color(0xff4085ff),
      brightness: brightness,
      surface: brightness == Brightness.dark
          ? const Color(0xff11141b)
          : const Color(0xfff6f8fc),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: colors.surface,
      fontFamily: 'Segoe UI',
      cardTheme: CardThemeData(
        color: colors.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
