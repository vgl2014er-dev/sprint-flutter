import 'package:flutter/material.dart';

import '../theme/breakpoints.dart';
import '../theme/sprint_theme_tokens.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    required this.currentKFactor,
    required this.onSelectKFactor,
    super.key,
  });

  final int currentKFactor;
  final ValueChanged<int> onSelectKFactor;

  @override
  Widget build(BuildContext context) {
    const presets = <int>[8, 16, 24, 32, 40, 48, 64];
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = SprintBreakpoints.isCompact(constraints.maxWidth);
        return Padding(
          padding: EdgeInsets.all(compact ? 12 : 16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Elo K-Factor',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Controls how strongly each new result changes Elo. Changes apply to future matches only.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: context.sprintTokens.mutedText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Current K: $currentKFactor',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: presets
                        .map((preset) {
                          final active = preset == currentKFactor;
                          return ChoiceChip(
                            selected: active,
                            label: Text('$preset'),
                            onSelected: (_) => onSelectKFactor(preset),
                          );
                        })
                        .toList(growable: false),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
