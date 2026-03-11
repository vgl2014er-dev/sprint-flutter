import 'package:flutter/material.dart';

import '../../models/app_models.dart';
import '../theme/sprint_theme_tokens.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({
    required this.state,
    required this.onViewProfile,
    super.key,
  });

  final AppState state;
  final ValueChanged<Player> onViewProfile;

  @override
  Widget build(BuildContext context) {
    final sortedPlayers = List<Player>.from(state.players)
      ..sort((left, right) => right.elo.compareTo(left.elo));
    MatchHistoryEntry? latestMatch;
    for (final entry in state.history) {
      final currentLatest = latestMatch;
      if (currentLatest == null || entry.timestamp > currentLatest.timestamp) {
        latestMatch = entry;
      }
    }

    final highlightedPlayerIds = <String>{};
    final latestEloDeltaByPlayerId = <String, int>{};
    final resolvedLatestMatch = latestMatch;
    if (resolvedLatestMatch != null) {
      highlightedPlayerIds.add(resolvedLatestMatch.p1Id);
      highlightedPlayerIds.add(resolvedLatestMatch.p2Id);
      latestEloDeltaByPlayerId[resolvedLatestMatch.p1Id] =
          resolvedLatestMatch.p1EloAfter - resolvedLatestMatch.p1EloBefore;
      latestEloDeltaByPlayerId[resolvedLatestMatch.p2Id] =
          resolvedLatestMatch.p2EloAfter - resolvedLatestMatch.p2EloBefore;
    }

    final useConnectedDisplayForceFit =
        state.isReadOnlyClientMode &&
        state.localSessionState.phase == LocalSessionPhase.connected;
    final connectionBadgeLabel = _connectedTransportLabel(
      state.localSessionState,
    );

    _LeaderboardPlayerRow buildPlayerRow(Player player, int index) {
      final matches = player.wins + player.losses + player.draws;
      final winRate = matches == 0 ? 0 : (player.wins / matches * 100).round();
      return _LeaderboardPlayerRow(
        rank: index + 1,
        player: player,
        winRate: winRate,
        onTap: state.isReadOnlyClientMode ? null : () => onViewProfile(player),
        isHighlighted: highlightedPlayerIds.contains(player.id),
        eloDelta: latestEloDeltaByPlayerId[player.id],
      );
    }

    return Column(
      children: <Widget>[
        Expanded(
          child: Column(
            children: <Widget>[
              _LeaderboardHeaderRow(connectionBadgeLabel: connectionBadgeLabel),
              const Divider(height: 1),
              Expanded(
                child: useConnectedDisplayForceFit
                    ? LayoutBuilder(
                        builder: (context, constraints) {
                          final rows = <Widget>[];
                          for (
                            var index = 0;
                            index < sortedPlayers.length;
                            index++
                          ) {
                            if (index > 0) {
                              rows.add(const Divider(height: 1));
                            }
                            rows.add(
                              buildPlayerRow(sortedPlayers[index], index),
                            );
                          }

                          return ClipRect(
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.topCenter,
                                child: SizedBox(
                                  width: constraints.maxWidth,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: rows,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : MediaQuery.removePadding(
                        context: context,
                        removeTop: true,
                        removeBottom: true,
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: sortedPlayers.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) =>
                              buildPlayerRow(sortedPlayers[index], index),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LeaderboardHeaderRow extends StatelessWidget {
  const _LeaderboardHeaderRow({this.connectionBadgeLabel});

  final String? connectionBadgeLabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tokens = context.sprintTokens;
    return ColoredBox(
      color: tokens.shellBackground,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: <Widget>[
            Expanded(
              flex: 16,
              child: Text(
                'RANK',
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            Expanded(
              flex: 44,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'PLAYER',
                      style: textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (connectionBadgeLabel case final label?)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: _ConnectionMediumBadge(label: label),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 20,
              child: Text(
                'ELO',
                textAlign: TextAlign.right,
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            Expanded(
              flex: 20,
              child: Text(
                'WIN %',
                textAlign: TextAlign.right,
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectionMediumBadge extends StatelessWidget {
  const _ConnectionMediumBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tokens = context.sprintTokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: tokens.localPanelBackground.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tokens.localPanelBorder),
      ),
      child: Text(
        label,
        style: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 10,
          color: tokens.mutedText,
        ),
      ),
    );
  }
}

class _LeaderboardPlayerRow extends StatelessWidget {
  const _LeaderboardPlayerRow({
    required this.rank,
    required this.player,
    required this.winRate,
    required this.onTap,
    required this.isHighlighted,
    required this.eloDelta,
  });

  final int rank;
  final Player player;
  final int winRate;
  final VoidCallback? onTap;
  final bool isHighlighted;
  final int? eloDelta;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tokens = context.sprintTokens;
    final rowContent = Material(
      color: Theme.of(context).cardColor,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Row(
            children: <Widget>[
              Expanded(flex: 16, child: _LeaderboardRankBadge(rank: rank)),
              Expanded(
                flex: 44,
                child: Text(
                  player.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: tokens.playerName,
                  ),
                ),
              ),
              Expanded(
                flex: 20,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      '${player.elo}',
                      textAlign: TextAlign.right,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: tokens.mutedText,
                      ),
                    ),
                    if (eloDelta != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: _LeaderboardEloDeltaIndicator(
                          playerId: player.id,
                          delta: eloDelta!,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: 20,
                child: Text(
                  '$winRate%',
                  textAlign: TextAlign.right,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: tokens.mutedText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!isHighlighted) {
      return rowContent;
    }

    final rowKey = Key('leaderboard-highlight-row-${player.id}');
    final semanticsLabel = 'leaderboard_highlight_row_${player.id}';
    return Semantics(
      label: semanticsLabel,
      container: true,
      explicitChildNodes: true,
      child: Container(
        key: rowKey,
        decoration: BoxDecoration(
          border: Border.all(color: tokens.warning, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: rowContent,
      ),
    );
  }
}

class _LeaderboardEloDeltaIndicator extends StatelessWidget {
  const _LeaderboardEloDeltaIndicator({
    required this.playerId,
    required this.delta,
  });

  final String playerId;
  final int delta;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tokens = context.sprintTokens;

    final deltaState = switch (delta) {
      > 0 => _LeaderboardDeltaState.positive,
      < 0 => _LeaderboardDeltaState.negative,
      _ => _LeaderboardDeltaState.neutral,
    };
    final color = switch (deltaState) {
      _LeaderboardDeltaState.positive => tokens.success,
      _LeaderboardDeltaState.negative => tokens.danger,
      _LeaderboardDeltaState.neutral => tokens.mutedText,
    };
    final icon = switch (deltaState) {
      _LeaderboardDeltaState.positive => Icons.arrow_upward_rounded,
      _LeaderboardDeltaState.negative => Icons.arrow_downward_rounded,
      _LeaderboardDeltaState.neutral => null,
    };
    final valueText = switch (deltaState) {
      _LeaderboardDeltaState.positive => '+$delta',
      _LeaderboardDeltaState.negative => '$delta',
      _LeaderboardDeltaState.neutral => '0',
    };
    final semanticsLabel =
        'leaderboard_elo_delta_${playerId}_${deltaState.name}_${delta.abs()}';

    return Semantics(
      label: semanticsLabel,
      container: true,
      explicitChildNodes: true,
      child: Row(
        key: Key('leaderboard-elo-delta-$playerId'),
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 2),
          ],
          Text(
            valueText,
            style: textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

enum _LeaderboardDeltaState { positive, negative, neutral }

class _LeaderboardRankBadge extends StatelessWidget {
  const _LeaderboardRankBadge({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tokens = context.sprintTokens;
    final value = switch (rank) {
      1 => Icon(
        Icons.workspace_premium_rounded,
        color: tokens.warning,
        size: 22,
      ),
      2 => Icon(
        Icons.workspace_premium_rounded,
        color: tokens.inactive,
        size: 22,
      ),
      3 => Icon(
        Icons.workspace_premium_rounded,
        color: Theme.of(context).colorScheme.tertiary,
        size: 22,
      ),
      _ => Text(
        '$rank',
        style: textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: tokens.mutedText,
        ),
      ),
    };

    return SizedBox(
      width: 28,
      child: Align(alignment: Alignment.centerLeft, child: value),
    );
  }
}

String? _connectedTransportLabel(LocalSessionState state) {
  if (state.phase != LocalSessionPhase.connected) {
    return null;
  }
  switch (state.connectionMedium) {
    case LocalConnectionMedium.ble:
      return 'BLE';
    case LocalConnectionMedium.bt:
      return 'BT';
    case LocalConnectionMedium.wifi:
      return 'WiFi';
    case LocalConnectionMedium.unknown:
      return null;
  }
}
