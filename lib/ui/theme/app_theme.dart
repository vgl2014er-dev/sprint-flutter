import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/app_models.dart';
import 'sprint_theme_tokens.dart';

ThemeData buildSprintTheme(Brightness brightness) {
  final isLight = brightness == Brightness.light;
  final seededScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF3B82F6), // tailwind blue-500
    brightness: brightness,
  );
  final scheme = seededScheme.copyWith(
    primary: const Color(0xFF3B82F6), // blue-500
    onPrimary: Colors.white,
    secondary: const Color(0xFFDC2626), // red-600
    onSecondary: Colors.white,
    secondaryContainer: isLight
        ? const Color(0xFFFEE2E2) // red-100
        : const Color(0xFF7F1D1D), // red-900
    onSecondaryContainer: isLight
        ? const Color(0xFF991B1B) // red-800
        : const Color(0xFFFECACA), // red-200
  );
  final tokens = isLight ? SprintThemeTokens.light : SprintThemeTokens.dark;

  final base = ThemeData(useMaterial3: true, colorScheme: scheme);

  final textTheme = GoogleFonts.rajdhaniTextTheme(base.textTheme).copyWith(
    displayLarge: GoogleFonts.rajdhani(
      textStyle: base.textTheme.displayLarge,
      fontWeight: FontWeight.w700,
    ),
    titleLarge: GoogleFonts.rajdhani(
      textStyle: base.textTheme.titleLarge,
      fontWeight: FontWeight.w700,
    ),
    titleMedium: GoogleFonts.rajdhani(
      textStyle: base.textTheme.titleMedium,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: GoogleFonts.rajdhani(
      textStyle: base.textTheme.bodyLarge,
      height: 1.5,
    ),
    bodyMedium: GoogleFonts.rajdhani(
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ), // xl
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
            return const Color(0xFF2563EB); // blue-600
          }
          return scheme.primary;
        }),
        foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.disabled)) {
            return scheme.onSurface.withValues(alpha: 0.38);
          }
          return scheme.onPrimary;
        }),
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        ),
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
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        ),
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
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        ),
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
