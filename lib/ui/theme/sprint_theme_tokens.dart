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
    shellBackground: Color(0xFFF1F5F9),
    headerBackground: Colors.white,
    footerBorder: Color(0xFFE2E8F0),
    bannerBackground: Color(0xFFEFF6FF),
    bannerBorder: Color(0xFF93C5FD),
    mutedText: Color(0xFF64748B),
    playerName: Color(0xFF111827),
    neutralChip: Color(0xFFE5E7EB),
    selectedCard: Color(0xFFE2E8F0),
    localPanelBackground: Color(0xFFEFF6FF),
    localPanelBorder: Color(0xFF93C5FD),
    success: Color(0xFF16A34A),
    warning: Color(0xFFF59E0B),
    danger: Color(0xFFDC2626),
    inactive: Color(0xFF94A3B8),
  );

  static const SprintThemeTokens dark = SprintThemeTokens(
    shellBackground: Color(0xFF0B1220),
    headerBackground: Color(0xFF111827),
    footerBorder: Color(0xFF27344D),
    bannerBackground: Color(0xFF1E293B),
    bannerBorder: Color(0xFF334155),
    mutedText: Color(0xFF94A3B8),
    playerName: Color(0xFFE2E8F0),
    neutralChip: Color(0xFF334155),
    selectedCard: Color(0xFF1E293B),
    localPanelBackground: Color(0xFF1E293B),
    localPanelBorder: Color(0xFF334155),
    success: Color(0xFF22C55E),
    warning: Color(0xFFFBBF24),
    danger: Color(0xFFF87171),
    inactive: Color(0xFF64748B),
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
  }) {
    return SprintThemeTokens(
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
  }

  @override
  ThemeExtension<SprintThemeTokens> lerp(
    covariant ThemeExtension<SprintThemeTokens>? other,
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
