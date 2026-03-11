import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/app_models.dart';
import 'sprint_theme_tokens.dart';

ThemeData buildSprintTheme(Brightness brightness) {
  final isLight = brightness == Brightness.light;
  final seededScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF0D47A1),
    brightness: brightness,
  );
  final scheme = seededScheme.copyWith(
    secondary: const Color(0xFFFFC107),
    onSecondary: const Color(0xFF212121),
    secondaryContainer: isLight
        ? const Color(0xFFFFECB3)
        : const Color(0xFF5A4300),
    onSecondaryContainer: isLight
        ? const Color(0xFF2A1800)
        : const Color(0xFFFFE08A),
  );
  final tokens = isLight ? SprintThemeTokens.light : SprintThemeTokens.dark;

  final base = ThemeData(useMaterial3: true, colorScheme: scheme);

  final textTheme = GoogleFonts.merriweatherTextTheme(base.textTheme).copyWith(
    displayLarge: GoogleFonts.oswald(
      textStyle: base.textTheme.displayLarge,
      fontWeight: FontWeight.w700,
    ),
    titleLarge: GoogleFonts.oswald(
      textStyle: base.textTheme.titleLarge,
      fontWeight: FontWeight.w700,
    ),
    titleMedium: GoogleFonts.oswald(
      textStyle: base.textTheme.titleMedium,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: GoogleFonts.merriweather(
      textStyle: base.textTheme.bodyLarge,
      height: 1.5,
    ),
    bodyMedium: GoogleFonts.merriweather(
      textStyle: base.textTheme.bodyMedium,
      height: 1.4,
    ),
  );

  return base.copyWith(
    scaffoldBackgroundColor: tokens.shellBackground,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: tokens.headerBackground,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: textTheme.titleLarge,
    ),
    cardTheme: CardThemeData(
      color: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: isLight ? 1.5 : 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        elevation: WidgetStateProperty.all<double>(0),
        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.disabled)) {
            return scheme.surfaceContainerHighest;
          }
          if (states.contains(WidgetState.pressed)) {
            return scheme.primaryContainer;
          }
          return scheme.primary;
        }),
        foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.disabled)) {
            return scheme.onSurface.withValues(alpha: 0.38);
          }
          return scheme.onPrimary;
        }),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.disabled)) {
            return scheme.surfaceContainerHighest;
          }
          if (states.contains(WidgetState.pressed)) {
            return scheme.secondaryContainer;
          }
          return scheme.secondary;
        }),
        foregroundColor: WidgetStateProperty.all<Color>(scheme.onSecondary),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        side: WidgetStateProperty.resolveWith<BorderSide>((states) {
          if (states.contains(WidgetState.disabled)) {
            return BorderSide(color: scheme.outline.withValues(alpha: 0.35));
          }
          return BorderSide(color: scheme.outlineVariant);
        }),
        foregroundColor: WidgetStateProperty.all<Color>(scheme.onSurface),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      side: BorderSide(color: scheme.outlineVariant),
      shape: const StadiumBorder(),
      labelStyle: textTheme.labelLarge,
      selectedColor: scheme.secondaryContainer,
      checkmarkColor: scheme.onSecondaryContainer,
      color: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.surfaceContainerHighest;
        }
        if (states.contains(WidgetState.selected)) {
          return scheme.secondaryContainer;
        }
        return scheme.surface;
      }),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHighest,
      hintStyle: textTheme.bodyMedium?.copyWith(color: tokens.mutedText),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
    ),
    extensions: <ThemeExtension<dynamic>>[tokens],
  );
}

ThemeMode toThemeMode(AppThemePreference preference) => switch (preference) {
    AppThemePreference.light => ThemeMode.light,
    AppThemePreference.dark => ThemeMode.dark,
  };
