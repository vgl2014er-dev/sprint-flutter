import 'package:flutter/material.dart';

import '../../core/models/app_models.dart';
import '../../ui/theme/sprint_theme_tokens.dart';

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
    final isStandardSession = state.isStandardSession;

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
                  'Match ${matches.isEmpty ? 0 : state.currentMatchIndex + 1} of ${matches.length}',
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
                    isStandardSession: isStandardSession,
                    standardSessionTargetMatchesPerPlayer:
                        state.standardSessionTargetMatchesPerPlayer,
                    standardSessionCompletedMatchesByPlayerId:
                        state.standardSessionCompletedMatchesByPlayerId,
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

class _MatchCard extends StatelessWidget {
  const _MatchCard({
    required this.match,
    required this.history,
    required this.isStandardSession,
    required this.standardSessionTargetMatchesPerPlayer,
    required this.standardSessionCompletedMatchesByPlayerId,
    required this.onStart,
    required this.onP1,
    required this.onP2,
    required this.onDraw,
  });

  final UiRoundMatch match;
  final List<MatchHistoryEntry> history;
  final bool isStandardSession;
  final int standardSessionTargetMatchesPerPlayer;
  final Map<String, int> standardSessionCompletedMatchesByPlayerId;
  final VoidCallback onStart;
  final VoidCallback onP1;
  final VoidCallback onP2;
  final VoidCallback onDraw;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final h2hWinRates = _HeadToHeadWinRateCache.resolve(
      history,
      match.player1.id,
      match.player2.id,
    );
    final p1WinRate = h2hWinRates.p1WinRate;
    final p2WinRate = h2hWinRates.p2WinRate;

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
                    active: match.played && match.winnerId == match.player1.id,
                    enabled: !match.played,
                    buttonType: _ResultButtonType.p1,
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
                    active: match.played && match.winnerId == match.player2.id,
                    enabled: !match.played,
                    buttonType: _ResultButtonType.p2,
                    onPressed: onP2,
                  ),
                  const SizedBox(height: 8),
                  _ResultButton(
                    label: 'DRAW',
                    subtitle: 'No Elo winner',
                    active: match.played && match.isDraw,
                    enabled: !match.played,
                    buttonType: _ResultButtonType.draw,
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
}

class _HeadToHeadWinRates {
  const _HeadToHeadWinRates({required this.p1WinRate, required this.p2WinRate});

  final double p1WinRate;
  final double p2WinRate;

  _HeadToHeadWinRates flipped() =>
      _HeadToHeadWinRates(p1WinRate: p2WinRate, p2WinRate: p1WinRate);
}

class _HeadToHeadWinRateCache {
  static List<MatchHistoryEntry>? _historyRef;
  static final Map<String, _HeadToHeadWinRates> _cacheByPair =
      <String, _HeadToHeadWinRates>{};

  static _HeadToHeadWinRates resolve(
    List<MatchHistoryEntry> history,
    String firstPlayerId,
    String secondPlayerId,
  ) {
    if (!identical(_historyRef, history)) {
      _historyRef = history;
      _cacheByPair.clear();
    }

    final canonicalFirst = firstPlayerId.compareTo(secondPlayerId) <= 0
        ? firstPlayerId
        : secondPlayerId;
    final canonicalSecond = canonicalFirst == firstPlayerId
        ? secondPlayerId
        : firstPlayerId;

    final cacheKey = '$canonicalFirst|$canonicalSecond';
    final cached = _cacheByPair[cacheKey];
    if (cached != null) {
      return firstPlayerId == canonicalFirst ? cached : cached.flipped();
    }

    var matchCount = 0;
    var canonicalFirstWins = 0;
    var canonicalSecondWins = 0;

    for (final entry in history) {
      final isForward =
          entry.p1Id == canonicalFirst && entry.p2Id == canonicalSecond;
      final isReverse =
          entry.p1Id == canonicalSecond && entry.p2Id == canonicalFirst;
      if (!isForward && !isReverse) {
        continue;
      }

      matchCount += 1;
      if (entry.result == MatchResult.draw) {
        continue;
      }
      final winnerId = entry.result == MatchResult.p1 ? entry.p1Id : entry.p2Id;
      if (winnerId == canonicalFirst) {
        canonicalFirstWins += 1;
      } else if (winnerId == canonicalSecond) {
        canonicalSecondWins += 1;
      }
    }

    final computed = _HeadToHeadWinRates(
      p1WinRate: matchCount == 0 ? 0 : canonicalFirstWins / matchCount * 100,
      p2WinRate: matchCount == 0 ? 0 : canonicalSecondWins / matchCount * 100,
    );
    _cacheByPair[cacheKey] = computed;

    return firstPlayerId == canonicalFirst ? computed : computed.flipped();
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
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            player1Name.toUpperCase(),
            textAlign: TextAlign.right,
            style: textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 32, // ≈ text-4xl
              color: const Color(0xFF3B82F6), // text-sky-500
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'VS',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 20, // max text-xl
              color: const Color(0xFF94A3B8), // text-slate-400
            ),
          ),
        ),
        Expanded(
          child: Text(
            player2Name.toUpperCase(),
            textAlign: TextAlign.left,
            style: textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 32, // ≈ text-4xl
              color: const Color(0xFFDC2626), // text-red-600
            ),
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
    required this.buttonType,
  });

  final String label;
  final String subtitle;
  final Widget? detail;
  final bool active;
  final bool enabled;
  final VoidCallback onPressed;
  final _ResultButtonType buttonType;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    Color activeBg, inactiveBorder, inactiveText, inactiveHoverBg;

    switch (buttonType) {
      case _ResultButtonType.p1:
        activeBg = const Color(0xFF3B82F6); // bg-sky-500
        inactiveBorder = const Color(0x803B82F6); // border-sky-500/50
        inactiveText = const Color(0xFF3B82F6); // text-sky-500
        inactiveHoverBg = const Color(0xFFDBEAFE); // hover:bg-sky-100
        break;
      case _ResultButtonType.p2:
        activeBg = const Color(0xFFDC2626); // bg-red-600
        inactiveBorder = const Color(0x80DC2626); // border-red-600/50
        inactiveText = const Color(0xFFDC2626); // text-red-600
        inactiveHoverBg = const Color(0xFFFEE2E2); // hover:bg-red-100
        break;
      case _ResultButtonType.draw:
        activeBg = const Color(0xFF94A3B8); // bg-slate-400
        inactiveBorder = const Color(0xFF94A3B8); // border-slate-400
        inactiveText = const Color(0xFF64748B); // text-slate-500
        inactiveHoverBg = const Color(0xFFF1F5F9); // hover:bg-slate-100
        break;
    }

    final Color currentBg = active ? activeBg : Colors.transparent;
    final Color currentText = active ? Colors.white : inactiveText;
    final BorderSide border = active
        ? BorderSide.none
        : BorderSide(color: inactiveBorder, width: 2);

    return Opacity(
      opacity: !enabled && !active ? 0.5 : 1.0,
      child: Material(
        color: currentBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // rounded-xl
          side: border,
        ),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          hoverColor: active ? Colors.transparent : inactiveHoverBg,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 128, // h-32
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  label,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 24, // text-2xl
                    color: currentText,
                  ),
                ),
                const SizedBox(height: 8), // mt-2
                Text(
                  subtitle,
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: 14, // text-sm
                    fontWeight: FontWeight.w400,
                    color: currentText.withValues(alpha: active ? 0.8 : 0.6),
                  ),
                ),
                if (detail != null) const SizedBox(height: 8),
                if (detail case final Widget extraDetail) extraDetail,
                if (active) ...[
                  const SizedBox(height: 16), // mt-4
                  Text(
                    'RECORDED',
                    style: textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0, // tracking-widest
                      color: currentText,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _ResultButtonType { p1, p2, draw }
