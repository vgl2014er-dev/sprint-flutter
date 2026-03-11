import 'package:flutter/material.dart';

import '../../models/app_models.dart';
import '../theme/breakpoints.dart';
import '../theme/sprint_theme_tokens.dart';

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

class DeathMatchSelectionScreen extends StatefulWidget {
  const DeathMatchSelectionScreen({
    required this.players,
    required this.deathMatchInProgress,
    required this.deathMatchLives,
    required this.deathMatchChampionId,
    required this.deathMatchParticipantIds,
    required this.deathMatchPairingStrategy,
    required this.deathMatchLossesByPlayerId,
    required this.onStart,
    required this.onReset,
    required this.onResume,
    super.key,
  });

  final List<Player> players;
  final bool deathMatchInProgress;
  final int deathMatchLives;
  final String? deathMatchChampionId;
  final List<String> deathMatchParticipantIds;
  final PairingStrategy? deathMatchPairingStrategy;
  final Map<String, int> deathMatchLossesByPlayerId;
  final void Function(Set<String>, PairingStrategy, int) onStart;
  final VoidCallback onReset;
  final VoidCallback onResume;

  @override
  State<DeathMatchSelectionScreen> createState() =>
      _DeathMatchSelectionScreenState();
}

class _DeathMatchSelectionScreenState extends State<DeathMatchSelectionScreen> {
  static const int _minLives = 1;
  static const int _maxLives = 9;

  late Set<String> _selectedIds;
  late PairingStrategy _pairingStrategy;
  late int _lives;

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.players.map((player) => player.id).toSet();
    _pairingStrategy =
        widget.deathMatchPairingStrategy ?? PairingStrategy.random;
    _lives = widget.deathMatchLives.clamp(_minLives, _maxLives);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tokens = context.sprintTokens;
    final champion = widget.deathMatchChampionId == null
        ? null
        : widget.players
              .where((player) => player.id == widget.deathMatchChampionId)
              .cast<Player?>()
              .firstWhere((_) => true, orElse: () => null);

    if (champion != null) {
      return Center(
        child: Card(
          margin: const EdgeInsets.all(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.emoji_events_rounded,
                  color: tokens.warning,
                  size: 64,
                ),
                const SizedBox(height: 12),
                Text(
                  'Death Match Winner',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  champion.name,
                  style: textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: widget.onReset,
                  child: const Text('Start New Tournament'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (widget.deathMatchInProgress) {
      final survivors = widget.players
          .where((player) {
            if (!widget.deathMatchParticipantIds.contains(player.id)) {
              return false;
            }
            return (widget.deathMatchLossesByPlayerId[player.id] ?? 0) <
                widget.deathMatchLives;
          })
          .toList(growable: false);

      return Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Death Match In Progress',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.deathMatchPairingStrategy == PairingStrategy.elo ? 'Elo' : 'Random'} pairing is locked for this tournament.',
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.deathMatchLives == 1 ? 'One loss' : '${widget.deathMatchLives} losses'} eliminates a player.',
                ),
                const SizedBox(height: 4),
                Text(
                  'Survivors: ${survivors.length} / ${widget.deathMatchParticipantIds.length}',
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    children: survivors
                        .map(
                          (player) => ListTile(
                            dense: true,
                            title: Text(player.name),
                            trailing: Text(
                              'losses ${widget.deathMatchLossesByPlayerId[player.id] ?? 0}/${widget.deathMatchLives}',
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: widget.onResume,
                  child: const Text('Continue Tournament'),
                ),
                OutlinedButton(
                  onPressed: widget.onReset,
                  child: const Text('Reset Tournament'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 460;
              final segmented = SegmentedButton<PairingStrategy>(
                segments: const <ButtonSegment<PairingStrategy>>[
                  ButtonSegment<PairingStrategy>(
                    value: PairingStrategy.random,
                    icon: Icon(Icons.shuffle_rounded),
                    label: Text('Random'),
                  ),
                  ButtonSegment<PairingStrategy>(
                    value: PairingStrategy.elo,
                    icon: Icon(Icons.balance_rounded),
                    label: Text('Elo'),
                  ),
                ],
                selected: <PairingStrategy>{_pairingStrategy},
                onSelectionChanged: (selection) {
                  setState(() {
                    _pairingStrategy = selection.first;
                  });
                },
              );

              if (!compact) {
                return Row(
                  children: <Widget>[
                    Text(
                      'Setup',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    segmented,
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Setup',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(alignment: Alignment.centerRight, child: segmented),
                ],
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 440;
              final controls = Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  IconButton(
                    tooltip: 'Decrease lives',
                    onPressed: _lives <= _minLives
                        ? null
                        : () {
                            setState(() {
                              _lives -= 1;
                            });
                          },
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                  ),
                  Text(
                    '$_lives',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Increase lives',
                    onPressed: _lives >= _maxLives
                        ? null
                        : () {
                            setState(() {
                              _lives += 1;
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
                      'Lives',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('(losses to eliminate)', style: textTheme.labelSmall),
                    const Spacer(),
                    controls,
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Lives',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text('(losses to eliminate)', style: textTheme.labelSmall),
                  Align(alignment: Alignment.centerRight, child: controls),
                ],
              );
            },
          ),
        ),
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
        Expanded(
          child: _PlayerSelectionGrid(
            players: widget.players,
            selectedIds: _selectedIds,
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
                : () => widget.onStart(_selectedIds, _pairingStrategy, _lives),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Start Death Match'),
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
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 400;
          final actions = Wrap(
            spacing: 4,
            children: <Widget>[
              TextButton(
                onPressed: onSelectAll,
                child: const Text('Select All'),
              ),
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
