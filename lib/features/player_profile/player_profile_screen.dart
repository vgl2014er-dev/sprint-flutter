import 'package:flutter/material.dart';

import '../../core/logic/head_to_head_calculator.dart';
import '../../core/models/app_models.dart';
import '../../ui/theme/breakpoints.dart';
import '../../ui/theme/sprint_theme_tokens.dart';

class PlayerProfileScreen extends StatefulWidget {
  const PlayerProfileScreen({
    required this.selectedPlayer,
    required this.players,
    required this.history,
    required this.onDeleteMatch,
    super.key,
  });

  final Player? selectedPlayer;
  final List<Player> players;
  final List<MatchHistoryEntry> history;
  final ValueChanged<String> onDeleteMatch;

  @override
  State<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen> {
  String? _matchToDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tokens = context.sprintTokens;
    final player = widget.selectedPlayer;
    if (player == null) {
      return const Center(child: Text('Player not found'));
    }

    final playerHistory = widget.history
        .where((entry) => entry.p1Id == player.id || entry.p2Id == player.id)
        .toList(growable: false);

    final winRate = player.matchesPlayed == 0
        ? 0
        : ((player.wins / player.matchesPlayed) * 100).toStringAsFixed(1);

    final summaries =
        widget.players
            .where((candidate) => candidate.id != player.id)
            .map(
              (candidate) => (
                opponent: candidate,
                summary: HeadToHeadCalculator.calculateForPlayer(
                  player.id,
                  candidate.id,
                  widget.history,
                ),
              ),
            )
            .where((entry) => entry.summary.matches > 0)
            .toList(growable: false)
          ..sort(
            (left, right) =>
                right.summary.matches.compareTo(left.summary.matches),
          );

    return Stack(
      children: <Widget>[
        Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  _StatCard(label: 'Elo', value: '${player.elo}'),
                  _StatCard(label: 'Win Rate', value: '$winRate%'),
                  _StatCard(label: 'Matches', value: '${player.matchesPlayed}'),
                  _StatCard(
                    label: 'W-L-D',
                    value: '${player.wins}-${player.losses}-${player.draws}',
                  ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = SprintBreakpoints.isCompact(
                    constraints.maxWidth,
                  );
                  final sectionCards = <Widget>[
                    _buildCardSection(
                      context,
                      title: 'Head to Head',
                      child: ListView(
                        children: summaries
                            .map(
                              (entry) => ListTile(
                                dense: true,
                                title: Text(entry.opponent.name),
                                subtitle: Text(
                                  'M ${entry.summary.matches} · ${entry.summary.wins}-${entry.summary.losses}-${entry.summary.draws}',
                                ),
                                trailing: Text(
                                  '${entry.summary.winRatePercent}%',
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ),
                    _buildCardSection(
                      context,
                      title: 'Recent Matches',
                      child: ListView(
                        children: playerHistory
                            .take(20)
                            .map((entry) {
                              final isP1 = entry.p1Id == player.id;
                              final opponentName = isP1
                                  ? entry.p2Name
                                  : entry.p1Name;
                              final eloChange = isP1
                                  ? entry.p1EloAfter - entry.p1EloBefore
                                  : entry.p2EloAfter - entry.p2EloBefore;
                              final isWin =
                                  (isP1 && entry.result == MatchResult.p1) ||
                                  (!isP1 && entry.result == MatchResult.p2);
                              final isLoss =
                                  (isP1 && entry.result == MatchResult.p2) ||
                                  (!isP1 && entry.result == MatchResult.p1);
                              final result = isWin
                                  ? 'WIN'
                                  : isLoss
                                  ? 'LOSS'
                                  : 'DRAW';

                              return ListTile(
                                dense: true,
                                title: Text('vs $opponentName'),
                                subtitle: Text(
                                  DateTime.fromMillisecondsSinceEpoch(
                                    entry.timestamp,
                                  ).toLocal().toString().split('.').first,
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Text(result),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${eloChange >= 0 ? '+' : ''}$eloChange',
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: eloChange >= 0
                                            ? tokens.success
                                            : Theme.of(
                                                context,
                                              ).colorScheme.error,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _matchToDelete = entry.id;
                                        });
                                      },
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            })
                            .toList(growable: false),
                      ),
                    ),
                  ];

                  if (isCompact) {
                    return ListView(
                      children: sectionCards
                          .map((card) => SizedBox(height: 320, child: card))
                          .toList(growable: false),
                    );
                  }

                  return Row(
                    children: sectionCards
                        .map((card) => Expanded(child: card))
                        .toList(growable: false),
                  );
                },
              ),
            ),
          ],
        ),
        if (_matchToDelete != null)
          Positioned.fill(
            child: ColoredBox(
              color: Theme.of(
                context,
              ).colorScheme.scrim.withValues(alpha: 0.54),
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          'Delete Match?',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'This reverts Elo and stats for both players.',
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _matchToDelete = null;
                                });
                              },
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: () {
                                widget.onDeleteMatch(_matchToDelete!);
                                setState(() {
                                  _matchToDelete = null;
                                });
                              },
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCardSection(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              title,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  fontSize: 12,
                  color: context.sprintTokens.mutedText,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
