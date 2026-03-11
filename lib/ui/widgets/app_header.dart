import 'package:flutter/material.dart';

import '../theme/sprint_theme_tokens.dart';

class AppHeaderAction {
  const AppHeaderAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
}

class AppHeader extends StatelessWidget {
  const AppHeader({
    required this.title,
    required this.onBack,
    this.actions = const <AppHeaderAction>[],
    super.key,
  });

  final String title;
  final VoidCallback? onBack;
  final List<AppHeaderAction> actions;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: context.sprintTokens.headerBackground,
      child: SizedBox(
        height: 56,
        child: Row(
          children: <Widget>[
            if (onBack != null)
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
              )
            else
              const SizedBox(width: 48),
            Expanded(
              child: Text(
                title,
                style: textTheme.titleLarge?.copyWith(fontSize: 20),
              ),
            ),
            ...actions.map(
              (action) => IconButton(
                onPressed: action.onPressed,
                tooltip: action.tooltip,
                icon: Icon(action.icon),
              ),
            ),
            if (actions.isEmpty) const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
}
