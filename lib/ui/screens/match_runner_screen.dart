import 'package:flutter/material.dart';

import '../../models/app_models.dart';
import '../theme/sprint_theme_tokens.dart';

class MatchRunnerScreen extends StatelessWidget {
  const MatchRunnerScreen({
    required this.state,
    required this.onBack,
    required this.onClose,
    required this.onNextRound,
    required this.onStart,
    required this.onResult,
    super.key,
  });

  final AppState state;
  final VoidCallback onBack;
  final VoidCallback onClose;
  final VoidCallback onNextRound;
  final ValueChanged<String> onStart;
  final void Function(String, MatchResult) onResult;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final matches = state.roundMatches;
    final currentMatch = matches.isEmpty
        ? null
        : matches[state.currentMatchIndex.clamp(0, matches.length - 1)];
    final allPlayed =
        matches.isNotEmpty && matches.every((match) => match.played);
    final isStandardSession =
        state.isStandardSession && !state.deathMatchInProgress;

    if (allPlayed && state.deathMatchInProgress) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onNextRound();
      });
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              Expanded(
                child: Text(
                  state.deathMatchInProgress
                      ? 'Death Match · ${_survivorsCount(state)} survivors'
                      : 'Match ${matches.isEmpty ? 0 : state.currentMatchIndex + 1} of ${matches.length}',
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          if (state.deathMatchInProgress)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                border: Border.all(color: Theme.of(context).colorScheme.error),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${state.deathMatchLives == 1 ? 'One loss' : '${state.deathMatchLives} losses'} eliminates a player. Draws do not add losses.',
              ),
            ),
          Expanded(
            child: allPlayed
                ? isStandardSession
                      ? const _StandardSessionCompleteState()
                      : const Center(child: Text('Round complete'))
                : currentMatch == null
                ? const Center(child: Text('Round complete'))
                : _MatchCard(
                    match: currentMatch,
                    history: state.history,
                    isDeathMatch: state.deathMatchInProgress,
                    isStandardSession: isStandardSession,
                    standardSessionTargetMatchesPerPlayer:
                        state.standardSessionTargetMatchesPerPlayer,
                    standardSessionCompletedMatchesByPlayerId:
                        state.standardSessionCompletedMatchesByPlayerId,
                    deathMatchLives: state.deathMatchLives,
                    deathMatchLossesByPlayerId:
                        state.deathMatchLossesByPlayerId,
                    deathMatchMatchesPlayedByPlayerId:
                        state.deathMatchMatchesPlayedByPlayerId,
                    onStart: () {
                      onStart(currentMatch.id);
                    },
                    onP1: () => onResult(currentMatch.id, MatchResult.p1),
                    onP2: () => onResult(currentMatch.id, MatchResult.p2),
                    onDraw: () => onResult(currentMatch.id, MatchResult.draw),
                  ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: onBack,
            child: Text(allPlayed ? 'View Home' : 'Go Home'),
          ),
        ],
      ),
    );
  }
}

class _StandardSessionCompleteState extends StatelessWidget {
  const _StandardSessionCompleteState();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tokens = context.sprintTokens;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.check_circle_rounded, size: 48, color: tokens.success),
          const SizedBox(height: 10),
          Text(
            'Session complete',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'All scheduled matches are finished. View Home to continue.',
          ),
        ],
      ),
    );
  }
}

int _survivorsCount(AppState state) => state.deathMatchParticipantIds.where((id) {
    return (state.deathMatchLossesByPlayerId[id] ?? 0) < state.deathMatchLives;
  }).length;

class _MatchCard extends StatelessWidget {
  const _MatchCard({
    required this.match,
    required this.history,
    required this.isDeathMatch,
    required this.isStandardSession,
    required this.standardSessionTargetMatchesPerPlayer,
    required this.standardSessionCompletedMatchesByPlayerId,
    required this.deathMatchLives,
    required this.deathMatchLossesByPlayerId,
    required this.deathMatchMatchesPlayedByPlayerId,
    required this.onStart,
    required this.onP1,
    required this.onP2,
    required this.onDraw,
  });

  final UiRoundMatch match;
  final List<MatchHistoryEntry> history;
  final bool isDeathMatch;
  final bool isStandardSession;
  final int standardSessionTargetMatchesPerPlayer;
  final Map<String, int> standardSessionCompletedMatchesByPlayerId;
  final int deathMatchLives;
  final Map<String, int> deathMatchLossesByPlayerId;
  final Map<String, int> deathMatchMatchesPlayedByPlayerId;
  final VoidCallback onStart;
  final VoidCallback onP1;
  final VoidCallback onP2;
  final VoidCallback onDraw;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final h2h = history
        .where((entry) {
          final p1Id = match.player1.id;
          final p2Id = match.player2.id;
          return (entry.p1Id == p1Id && entry.p2Id == p2Id) ||
              (entry.p1Id == p2Id && entry.p2Id == p1Id);
        })
        .toList(growable: false);

    final p1WinRate = _winRateFor(match.player1.id, h2h);
    final p2WinRate = _winRateFor(match.player2.id, h2h);

    final showStartOnly = !match.started && !match.played;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (showStartOnly)
                  Column(
                    children: <Widget>[
                      _PreStartMatchup(
                        player1Name: match.player1.name,
                        player2Name: match.player2.name,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(112),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 24,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            textStyle: textTheme.displaySmall?.copyWith(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                            ),
                          ),
                          onPressed: onStart,
                          child: const Text('START'),
                        ),
                      ),
                    ],
                  )
                else ...<Widget>[
                  _ResultButton(
                    label: '${match.player1.name.toUpperCase()} WINS',
                    subtitle: _buildPlayerSubtitle(
                      playerId: match.player1.id,
                      elo: match.player1.elo,
                      winRate: p1WinRate,
                    ),
                    detail: isDeathMatch
                        ? _buildLivesRow(match.player1.id)
                        : null,
                    active: match.played && match.winnerId == match.player1.id,
                    enabled: !match.played,
                    onPressed: onP1,
                  ),
                  const SizedBox(height: 8),
                  _ResultButton(
                    label: '${match.player2.name.toUpperCase()} WINS',
                    subtitle: _buildPlayerSubtitle(
                      playerId: match.player2.id,
                      elo: match.player2.elo,
                      winRate: p2WinRate,
                    ),
                    detail: isDeathMatch
                        ? _buildLivesRow(match.player2.id)
                        : null,
                    active: match.played && match.winnerId == match.player2.id,
                    enabled: !match.played,
                    onPressed: onP2,
                  ),
                  const SizedBox(height: 8),
                  _ResultButton(
                    label: 'DRAW',
                    subtitle: 'No Elo winner',
                    active: match.played && match.isDraw,
                    enabled: !match.played,
                    onPressed: onDraw,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _winRateFor(String playerId, List<MatchHistoryEntry> history) {
    if (history.isEmpty) {
      return 0;
    }
    final wins = history.where((entry) => (entry.p1Id == playerId && entry.result == MatchResult.p1) ||
          (entry.p2Id == playerId && entry.result == MatchResult.p2)).length;
    return wins / history.length * 100;
  }

  String _buildPlayerSubtitle({
    required String playerId,
    required int elo,
    required double winRate,
  }) {
    final parts = <String>['Elo: $elo', '${winRate.toStringAsFixed(0)}%'];
    if (isStandardSession) {
      final completed =
          standardSessionCompletedMatchesByPlayerId[playerId] ?? 0;
      parts.add('$completed/$standardSessionTargetMatchesPerPlayer');
    }
    return parts.join(' · ');
  }

  Widget _buildLivesRow(String playerId) {
    final remainingLives =
        (deathMatchLives - (deathMatchLossesByPlayerId[playerId] ?? 0)).clamp(
          0,
          deathMatchLives,
        );
    return Builder(
      builder: (context) {
        final tokens = context.sprintTokens;
        final textTheme = Theme.of(context).textTheme;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ...List<Widget>.generate(deathMatchLives, (index) {
              final filled = index < remainingLives;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Icon(
                  filled
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 16,
                  color: filled ? tokens.danger : tokens.inactive,
                ),
              );
            }),
            const SizedBox(width: 6),
            Text(
              '$remainingLives/$deathMatchLives',
              style: textTheme.labelLarge?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PreStartMatchup extends StatelessWidget {
  const _PreStartMatchup({
    required this.player1Name,
    required this.player2Name,
  });

  final String player1Name;
  final String player2Name;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: <Widget>[
        Text(
          player1Name.toUpperCase(),
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: scheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'VS',
          textAlign: TextAlign.center,
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.outline,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          player2Name.toUpperCase(),
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: scheme.error,
          ),
        ),
      ],
    );
  }
}

class _ResultButton extends StatelessWidget {
  const _ResultButton({
    required this.label,
    required this.subtitle,
    this.detail,
    required this.active,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final String subtitle;
  final Widget? detail;
  final bool active;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tokens = context.sprintTokens;
    return FilledButton.tonal(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(124),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        backgroundColor: active ? tokens.success : null,
      ),
      onPressed: enabled ? onPressed : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: textTheme.titleMedium?.copyWith(
              fontSize: 19,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (detail != null) const SizedBox(height: 8),
          if (detail case final Widget extraDetail) extraDetail,
        ],
      ),
    );
  }
}
