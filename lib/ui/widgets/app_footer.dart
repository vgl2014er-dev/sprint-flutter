import 'package:flutter/material.dart';

import '../../models/app_models.dart';
import '../theme/sprint_theme_tokens.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({
    required this.currentScreen,
    required this.disabled,
    required this.onNavigate,
    super.key,
  });

  final Screen currentScreen;
  final bool disabled;
  final ValueChanged<Screen> onNavigate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.sprintTokens;
    final textTheme = Theme.of(context).textTheme;
    final items = <({Screen screen, IconData icon, String label})>[
      (screen: Screen.landing, icon: Icons.home_rounded, label: 'Home'),
      (
        screen: Screen.leaderboard,
        icon: Icons.emoji_events_rounded,
        label: 'Leaderboard',
      ),
      (screen: Screen.playerList, icon: Icons.people_rounded, label: 'Players'),
    ];

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: tokens.footerBorder)),
      ),
      child: Row(
        children: items
            .map((item) {
              final active = currentScreen == item.screen;
              return Expanded(
                child: InkWell(
                  onTap: disabled ? null : () => onNavigate(item.screen),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        item.icon,
                        color: active ? scheme.primary : tokens.inactive,
                      ),
                      Text(
                        item.label,
                        style: textTheme.labelSmall?.copyWith(
                          fontSize: 11,
                          color: active ? scheme.primary : tokens.inactive,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}
