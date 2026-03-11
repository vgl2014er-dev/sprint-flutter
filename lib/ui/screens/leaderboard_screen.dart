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

    return Column(
      children: <Widget>[
        Expanded(
          child: Column(
            children: <Widget>[
              const _LeaderboardHeaderRow(),
              const Divider(height: 1),
              Expanded(
                child: MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  removeBottom: true,
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: sortedPlayers.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final player = sortedPlayers[index];
                      final matches =
                          player.wins + player.losses + player.draws;
                      final winRate = matches == 0
                          ? 0
                          : (player.wins / matches * 100).round();
                      return _LeaderboardPlayerRow(
                        rank: index + 1,
                        player: player,
                        winRate: winRate,
                        onTap: state.isReadOnlyClientMode
                            ? null
                            : () => onViewProfile(player),
                      );
                    },
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
  const _LeaderboardHeaderRow();

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
              child: Text(
                'PLAYER',
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
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

class _LeaderboardPlayerRow extends StatelessWidget {
  const _LeaderboardPlayerRow({
    required this.rank,
    required this.player,
    required this.winRate,
    required this.onTap,
  });

  final int rank;
  final Player player;
  final int winRate;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tokens = context.sprintTokens;
    return Material(
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
                child: Text(
                  '${player.elo}',
                  textAlign: TextAlign.right,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: tokens.mutedText,
                  ),
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
  }
}

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

class LocalPanel extends StatelessWidget {
  const LocalPanel({
    required this.state,
    required this.isLocalSource,
    required this.onUseLocalConnection,
    required this.onConnectHost,
    required this.onDisconnectLocal,
    super.key,
  });

  final LocalSessionState state;
  final bool isLocalSource;
  final VoidCallback onUseLocalConnection;
  final ValueChanged<String> onConnectHost;
  final VoidCallback onDisconnectLocal;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tokens = context.sprintTokens;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: tokens.localPanelBackground,
        border: Border.all(color: tokens.localPanelBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Nearby',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            _localPhaseText(state),
            style: textTheme.bodySmall?.copyWith(color: tokens.mutedText),
          ),
          Wrap(
            spacing: 8,
            children: <Widget>[
              if (state.phase == LocalSessionPhase.discovering ||
                  state.phase == LocalSessionPhase.disconnected ||
                  state.phase == LocalSessionPhase.error)
                TextButton(
                  onPressed: onUseLocalConnection,
                  child: const Text('Reconnect'),
                ),
              if (isLocalSource && state.phase == LocalSessionPhase.connected)
                TextButton(
                  onPressed: onDisconnectLocal,
                  child: const Text('Disconnect'),
                ),
            ],
          ),
          ...state.discoveredHosts.map(
            (host) => ListTile(
              dense: true,
              title: Text(host.displayName),
              subtitle: Text(host.endpointId),
              trailing: TextButton(
                onPressed: () => onConnectHost(host.endpointId),
                child: const Text('Connect'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _localPhaseText(LocalSessionState state) {
  switch (state.phase) {
    case LocalSessionPhase.discovering:
      return 'Scanning for nearby hosts.';
    case LocalSessionPhase.connecting:
      return 'Connecting to ${state.pendingConnectionName ?? 'host'}...';
    case LocalSessionPhase.awaitingApproval:
      return 'Awaiting approval code ${state.authToken ?? '...'}.';
    case LocalSessionPhase.connected:
      return 'Connected to ${state.connectedHostName ?? 'host'}.';
    case LocalSessionPhase.disconnected:
      return 'Connection lost. Showing latest snapshot.';
    case LocalSessionPhase.error:
      return state.errorMessage ?? 'Nearby connection failed.';
    case LocalSessionPhase.idle:
    case LocalSessionPhase.advertising:
      return 'Use a nearby host instead of database sync.';
  }
}
