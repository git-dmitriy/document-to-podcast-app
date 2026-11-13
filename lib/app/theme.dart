import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTheme {
  static const Color _seed = Color(0xFF1F4B43);

  static ThemeData light() => _theme(Brightness.light);

  static ThemeData dark() => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: brightness,
      visualDensity: VisualDensity.standard,
    );
    final textTheme = _textTheme(base.textTheme);
    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: _textTheme(base.primaryTextTheme),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelMedium),
      ),
      listTileTheme: ListTileThemeData(
        titleTextStyle: textTheme.titleMedium,
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    final ui = GoogleFonts.sourceSans3TextTheme(base);
    final reading = GoogleFonts.literataTextTheme(base);
    return ui.copyWith(
      displayLarge: reading.displayLarge,
      displayMedium: reading.displayMedium,
      displaySmall: reading.displaySmall,
      headlineLarge: reading.headlineLarge,
      headlineMedium: reading.headlineMedium,
      headlineSmall: reading.headlineSmall,
      titleLarge: reading.titleLarge,
      titleMedium: ui.titleMedium,
      titleSmall: ui.titleSmall,
      bodyLarge: reading.bodyLarge?.copyWith(height: 1.55),
      bodyMedium: reading.bodyMedium?.copyWith(height: 1.5),
      bodySmall: ui.bodySmall,
      labelLarge: ui.labelLarge,
      labelMedium: ui.labelMedium,
      labelSmall: ui.labelSmall,
    );
  }
}
