import 'package:flutter/material.dart';

@immutable
class SprintThemeTokens extends ThemeExtension<SprintThemeTokens> {
  const SprintThemeTokens({
    required this.shellBackground,
    required this.headerBackground,
    required this.footerBorder,
    required this.bannerBackground,
    required this.bannerBorder,
    required this.mutedText,
    required this.playerName,
    required this.neutralChip,
    required this.selectedCard,
    required this.localPanelBackground,
    required this.localPanelBorder,
    required this.success,
    required this.warning,
    required this.danger,
    required this.inactive,
  });

  final Color shellBackground;
  final Color headerBackground;
  final Color footerBorder;
  final Color bannerBackground;
  final Color bannerBorder;
  final Color mutedText;
  final Color playerName;
  final Color neutralChip;
  final Color selectedCard;
  final Color localPanelBackground;
  final Color localPanelBorder;
  final Color success;
  final Color warning;
  final Color danger;
  final Color inactive;

  static const SprintThemeTokens light = SprintThemeTokens(
    shellBackground: Color(0xFFF1F5F9), // tailwind slate-100
    headerBackground: Color(0xFFF1F5F9), // tailwind slate-100
    footerBorder: Color(0xFFE2E8F0), // tailwind slate-200
    bannerBackground: Color(0xFFEFF6FF), // tailwind blue-50
    bannerBorder: Color(0xFF93C5FD), // tailwind blue-300
    mutedText: Color(0xFF64748B), // tailwind slate-500
    playerName: Color(0xFF111827), // tailwind gray-900
    neutralChip: Color(0xFFE5E7EB), // tailwind gray-200
    selectedCard: Color(0xFFE2E8F0), // tailwind slate-200
    localPanelBackground: Color(0xFFEFF6FF), // tailwind blue-50
    localPanelBorder: Color(0xFF93C5FD), // tailwind blue-300
    success: Color(0xFF10B981), // tailwind emerald-500
    warning: Color(0xFFF59E0B), // tailwind amber-500
    danger: Color(0xFFDC2626), // tailwind red-600
    inactive: Color(0xFF94A3B8), // tailwind slate-400
  );

  static const SprintThemeTokens dark = SprintThemeTokens(
    shellBackground: Color(0xFF000000), // true black
    headerBackground: Color(0xFF000000), // true black
    footerBorder: Color(0xFF334155), // tailwind slate-700
    bannerBackground: Color(0xFF1E293B), // tailwind slate-800
    bannerBorder: Color(0xFF334155), // tailwind slate-700
    mutedText: Color(0xFF94A3B8), // tailwind slate-400
    playerName: Color(0xFFF1F5F9), // tailwind slate-100
    neutralChip: Color(0xFF334155), // tailwind slate-700
    selectedCard: Color(0xFF1E293B), // tailwind slate-800
    localPanelBackground: Color(0xFF1E293B), // tailwind slate-800
    localPanelBorder: Color(0xFF334155), // tailwind slate-700
    success: Color(0xFF22C55E), // tailwind green-500
    warning: Color(0xFFFBBF24), // tailwind amber-400
    danger: Color(0xFFF87171), // tailwind red-400
    inactive: Color(0xFF64748B), // tailwind slate-500
  );

  @override
  ThemeExtension<SprintThemeTokens> copyWith({
    Color? shellBackground,
    Color? headerBackground,
    Color? footerBorder,
    Color? bannerBackground,
    Color? bannerBorder,
    Color? mutedText,
    Color? playerName,
    Color? neutralChip,
    Color? selectedCard,
    Color? localPanelBackground,
    Color? localPanelBorder,
    Color? success,
    Color? warning,
    Color? danger,
    Color? inactive,
  }) => SprintThemeTokens(
    shellBackground: shellBackground ?? this.shellBackground,
    headerBackground: headerBackground ?? this.headerBackground,
    footerBorder: footerBorder ?? this.footerBorder,
    bannerBackground: bannerBackground ?? this.bannerBackground,
    bannerBorder: bannerBorder ?? this.bannerBorder,
    mutedText: mutedText ?? this.mutedText,
    playerName: playerName ?? this.playerName,
    neutralChip: neutralChip ?? this.neutralChip,
    selectedCard: selectedCard ?? this.selectedCard,
    localPanelBackground: localPanelBackground ?? this.localPanelBackground,
    localPanelBorder: localPanelBorder ?? this.localPanelBorder,
    success: success ?? this.success,
    warning: warning ?? this.warning,
    danger: danger ?? this.danger,
    inactive: inactive ?? this.inactive,
  );

  @override
  ThemeExtension<SprintThemeTokens> lerp(
    ThemeExtension<SprintThemeTokens>? other,
    double t,
  ) {
    if (other is! SprintThemeTokens) {
      return this;
    }
    return SprintThemeTokens(
      shellBackground: Color.lerp(shellBackground, other.shellBackground, t)!,
      headerBackground: Color.lerp(
        headerBackground,
        other.headerBackground,
        t,
      )!,
      footerBorder: Color.lerp(footerBorder, other.footerBorder, t)!,
      bannerBackground: Color.lerp(
        bannerBackground,
        other.bannerBackground,
        t,
      )!,
      bannerBorder: Color.lerp(bannerBorder, other.bannerBorder, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
      playerName: Color.lerp(playerName, other.playerName, t)!,
      neutralChip: Color.lerp(neutralChip, other.neutralChip, t)!,
      selectedCard: Color.lerp(selectedCard, other.selectedCard, t)!,
      localPanelBackground: Color.lerp(
        localPanelBackground,
        other.localPanelBackground,
        t,
      )!,
      localPanelBorder: Color.lerp(
        localPanelBorder,
        other.localPanelBorder,
        t,
      )!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      inactive: Color.lerp(inactive, other.inactive, t)!,
    );
  }
}

extension SprintThemeTokensX on BuildContext {
  SprintThemeTokens get sprintTokens =>
      Theme.of(this).extension<SprintThemeTokens>() ?? SprintThemeTokens.light;
}
