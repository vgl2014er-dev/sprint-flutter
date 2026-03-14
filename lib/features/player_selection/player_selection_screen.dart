import 'package:flutter/material.dart';

import '../../core/models/app_models.dart';
import '../../ui/theme/breakpoints.dart';
import '../../ui/theme/sprint_theme_tokens.dart';

class PlayerSelectionScreen extends StatefulWidget {
  const PlayerSelectionScreen({
    required this.title,
    required this.isEloMode,
    required this.players,
    required this.onGenerate,
    super.key,
  });

  final String title;
  final bool isEloMode;
  final List<Player> players;
  final void Function(Set<String>, int) onGenerate;

  @override
  State<PlayerSelectionScreen> createState() => _PlayerSelectionScreenState();
}

class _PlayerSelectionScreenState extends State<PlayerSelectionScreen> {
  static const int _minTargetMatchesPerPlayer = 1;
  static const int _maxTargetMatchesPerPlayer = 20;
  static const int _defaultTargetMatchesPerPlayer = 3;

  late Set<String> _selectedIds;
  late int _targetMatchesPerPlayer;

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.players.map((player) => player.id).toSet();
    _targetMatchesPerPlayer = _defaultTargetMatchesPerPlayer;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final sortedPlayers = widget.isEloMode
        ? (List<Player>.from(widget.players)..sort((left, right) {
            final byElo = right.elo.compareTo(left.elo);
            return byElo == 0 ? left.name.compareTo(right.name) : byElo;
          }))
        : widget.players;

    return Column(
      children: <Widget>[
        _PlayerSelectionGridHeader(
          selectedCount: _selectedIds.length,
          totalCount: widget.players.length,
          onSelectAll: () {
            setState(() {
              _selectedIds = widget.players.map((player) => player.id).toSet();
            });
          },
          onClear: () {
            setState(() {
              _selectedIds = <String>{};
            });
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 420;
              final controls = Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  IconButton(
                    key: const Key('standard-target-decrease'),
                    tooltip: 'Decrease target',
                    onPressed:
                        _targetMatchesPerPlayer <= _minTargetMatchesPerPlayer
                        ? null
                        : () {
                            setState(() {
                              _targetMatchesPerPlayer -= 1;
                            });
                          },
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                  ),
                  Text(
                    '$_targetMatchesPerPlayer',
                    key: const Key('standard-target-value'),
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  IconButton(
                    key: const Key('standard-target-increase'),
                    tooltip: 'Increase target',
                    onPressed:
                        _targetMatchesPerPlayer >= _maxTargetMatchesPerPlayer
                        ? null
                        : () {
                            setState(() {
                              _targetMatchesPerPlayer += 1;
                            });
                          },
                    icon: const Icon(Icons.add_circle_outline_rounded),
                  ),
                ],
              );

              if (!compact) {
                return Row(
                  children: <Widget>[
                    Text(
                      'Target per player',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    controls,
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Target per player',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Align(alignment: Alignment.centerRight, child: controls),
                ],
              );
            },
          ),
        ),
        Expanded(
          child: _PlayerSelectionGrid(
            players: sortedPlayers,
            selectedIds: _selectedIds,
            showElo: widget.isEloMode,
            onToggle: (playerId) {
              setState(() {
                if (_selectedIds.contains(playerId)) {
                  _selectedIds.remove(playerId);
                } else {
                  _selectedIds.add(playerId);
                }
              });
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _selectedIds.length < 2
                ? null
                : () =>
                      widget.onGenerate(_selectedIds, _targetMatchesPerPlayer),
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(
              widget.isEloMode ? 'Generate Elo Matches' : 'Generate Matches',
            ),
          ),
        ),
      ],
    );
  }
}

class _PlayerSelectionGridHeader extends StatelessWidget {
  const _PlayerSelectionGridHeader({
    required this.selectedCount,
    required this.totalCount,
    required this.onSelectAll,
    required this.onClear,
  });

  final int selectedCount;
  final int totalCount;
  final VoidCallback onSelectAll;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(12),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 400;
        final actions = Wrap(
          spacing: 4,
          children: <Widget>[
            TextButton(onPressed: onSelectAll, child: const Text('Select All')),
            TextButton(onPressed: onClear, child: const Text('Clear')),
          ],
        );

        if (!compact) {
          return Row(
            children: <Widget>[
              Text('$selectedCount / $totalCount selected'),
              const Spacer(),
              actions,
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('$selectedCount / $totalCount selected'),
            Align(alignment: Alignment.centerRight, child: actions),
          ],
        );
      },
    ),
  );
}

class _PlayerSelectionGrid extends StatelessWidget {
  const _PlayerSelectionGrid({
    required this.players,
    required this.selectedIds,
    required this.onToggle,
    this.showElo = false,
  });

  final List<Player> players;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;
  final bool showElo;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tokens = context.sprintTokens;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = SprintBreakpoints.isCompact(width)
            ? 2
            : SprintBreakpoints.isRegular(width)
            ? 3
            : 4;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 2.2,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          children: players
              .map((player) {
                final selected = selectedIds.contains(player.id);
                return Card(
                  color: selected
                      ? tokens.selectedCard
                      : Theme.of(context).cardColor,
                  child: InkWell(
                    onTap: () => onToggle(player.id),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            player.name,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (showElo)
                            Text(
                              'Elo ${player.elo}',
                              style: textTheme.labelSmall,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              })
              .toList(growable: false),
        );
      },
    );
  }
}
