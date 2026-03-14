import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import '../theme/sprint_theme_tokens.dart';
import '../widgets/conic_gradient_progress.dart';

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
                                  width: constraints.maxWidth < 650
                                      ? 650
                                      : constraints.maxWidth,
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
                        child: CustomScrollView(
                          slivers: [
                            SliverPadding(
                              padding: EdgeInsets.zero,
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    if (index.isOdd) {
                                      return const Divider(height: 1);
                                    }
                                    final playerIndex = index ~/ 2;
                                    return buildPlayerRow(
                                      sortedPlayers[playerIndex],
                                      playerIndex,
                                    );
                                  },
                                  childCount: math.max(
                                    0,
                                    math.min(3, sortedPlayers.length) * 2 - 1,
                                  ),
                                ),
                              ),
                            ),
                            if (sortedPlayers.length > 3) ...[
                              const SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.only(bottom: 8.0),
                                  child: Divider(height: 1),
                                ),
                              ),
                              SliverPadding(
                                padding: EdgeInsets.zero,
                                sliver: SliverGrid(
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        mainAxisExtent:
                                            84, // matches height of row
                                        crossAxisSpacing: 8,
                                        mainAxisSpacing: 8,
                                      ),
                                  delegate: SliverChildBuilderDelegate((
                                    context,
                                    index,
                                  ) {
                                    final playerIndex = index + 3;
                                    return buildPlayerRow(
                                      sortedPlayers[playerIndex],
                                      playerIndex,
                                    );
                                  }, childCount: sortedPlayers.length - 3),
                                ),
                              ),
                            ],
                          ],
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
    return ColoredBox(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: <Widget>[
            Expanded(
              flex: 16,
              child: Text(
                '',
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
                      '',
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
                '',
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
                '',
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

class _LeaderboardPlayerRow extends StatefulWidget {
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
  State<_LeaderboardPlayerRow> createState() => _LeaderboardPlayerRowState();
}

class _LeaderboardPlayerRowState extends State<_LeaderboardPlayerRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    if (widget.rank <= 3) {
      _scanController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _LeaderboardPlayerRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rank <= 3 && !_scanController.isAnimating) {
      _scanController.repeat();
    } else if (widget.rank > 3 && _scanController.isAnimating) {
      _scanController.stop();
    }
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rank = widget.rank;
    final player = widget.player;
    final winRate = widget.winRate;
    final onTap = widget.onTap;
    final isHighlighted = widget.isHighlighted;
    final eloDelta = widget.eloDelta;

    final textTheme = Theme.of(context).textTheme;
    final tokens = context.sprintTokens;

    Color themeColor = const Color(0xFF38BDF8); // sky-400
    Color borderGradientStart = const Color(0xFF273549);
    final Color borderGradientEnd = const Color(0xFF273549);
    Color borderColor = const Color(0x4D38BDF8); // sky-400/30
    Color badgeColor = const Color(0xFF38BDF8);
    Color innerCircleBg = const Color(0xFF273549);

    if (rank == 1) {
      themeColor = const Color(0xFFD4AF37);
      borderGradientStart = const Color(0xFF3A3F34);
      borderColor = const Color(0xFFD4AF37);
      badgeColor = const Color(0xFFD4AF37);
      innerCircleBg = const Color(0xFF3A3F34);
    } else if (rank == 2) {
      themeColor = const Color(0xFFA0AEC0);
      borderGradientStart = const Color(0xFF323B46);
      borderColor = const Color(0xFFA0AEC0);
      badgeColor = const Color(0xFFA0AEC0);
      innerCircleBg = const Color(0xFF323B46);
    } else if (rank == 3) {
      themeColor = const Color(0xFFCD7F32);
      borderGradientStart = const Color(0xFF3D3027);
      borderColor = const Color(0xFFCD7F32);
      badgeColor = const Color(0xFFCD7F32);
      innerCircleBg = const Color(0xFF3D3027);
    }

    final rowContent = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: LayoutBuilder(
          builder: (context, cardConstraints) {
            final cardWidth = cardConstraints.maxWidth;
            final showElo = cardWidth >= 200;
            final showWinRate = cardWidth >= 280;
            // Scale down for narrow cards (2-col grid)
            final isNarrow = cardWidth < 280;
            final nameFontSize = isNarrow ? 18.0 : 26.0;
            final rankFontSize = isNarrow ? 16.0 : 20.0;
            final rankLabelSize = isNarrow ? 8.0 : 9.6;
            final badgeSize = isNarrow ? 40.0 : 52.0;
            final badgeMargin = isNarrow ? 10.0 : 20.0;
            final nameLabelSize = isNarrow ? 10.0 : 14.0;

            return Container(
              height: 84,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: <Widget>[
                  // Rank Badge
                  Container(
                    width: badgeSize,
                    height: badgeSize,
                    margin: EdgeInsets.only(right: badgeMargin),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: badgeColor.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'RANK',
                          style: textTheme.labelSmall?.copyWith(
                            fontSize: rankLabelSize,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF94A3B8),
                            height: 1.0,
                          ),
                        ),
                        Text(
                          rank.toString().padLeft(2, '0'),
                          style: textTheme.titleMedium?.copyWith(
                            fontSize: rankFontSize,
                            fontWeight: FontWeight.w700,
                            color: badgeColor,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Info (always visible)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'NAME',
                          style: textTheme.labelSmall?.copyWith(
                            fontSize: nameLabelSize,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF94A3B8),
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          player.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium?.copyWith(
                            fontSize: nameFontSize,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFE2E8F0),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Score Card — shown if width >= 200
                  if (showElo)
                    Container(
                      margin: EdgeInsets.only(right: isNarrow ? 8 : 20),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            constraints: const BoxConstraints(minWidth: 38),
                            child: Text(
                              '${player.elo}',
                              textAlign: TextAlign.right,
                              style: textTheme.titleLarge?.copyWith(
                                fontSize: isNarrow ? 18 : 24,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                          ),
                          if (!isNarrow) ...[
                            const SizedBox(width: 8),
                            Container(
                              constraints: const BoxConstraints(minWidth: 40),
                              child: _LeaderboardEloDeltaIndicator(
                                playerId: player.id,
                                delta: eloDelta ?? 0,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                  // Win % — shown if width >= 280
                  if (showWinRate)
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 60,
                            height: 60,
                            child: CustomPaint(
                              painter: ConicGradientProgress(
                                percentage: winRate.toDouble(),
                                color: themeColor,
                              ),
                            ),
                          ),
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: innerCircleBg,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$winRate%',
                              style: textTheme.titleSmall?.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFE2E8F0),
                                height: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );

    final highlightKey = Key('leaderboard-highlight-row-${player.id}');
    final semanticsLabel = 'leaderboard_highlight_row_${player.id}';

    return Semantics(
      label: semanticsLabel,
      container: true,
      explicitChildNodes: true,
      child: Container(
        key: highlightKey,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isHighlighted ? tokens.warning : borderColor,
            width: isHighlighted ? 1.5 : 2.0,
          ),
          gradient: LinearGradient(
            colors: [borderGradientStart, borderGradientEnd],
          ),
          boxShadow: [
            if (rank == 1)
              const BoxShadow(
                color: Color(0x4DD4AF37), // rgba(212,175,55,0.3)
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
          ],
        ),
        child: Stack(
          children: [
            if (rank <= 3)
              Positioned.fill(
                child: IgnorePointer(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedBuilder(
                      animation: _scanController,
                      builder: (context, _) => FractionalTranslation(
                        translation: Offset(_scanController.value * 2 - 1, 0),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              stops: const [0.0, 0.5, 1.0],
                              colors: [
                                Colors.white.withValues(alpha: 0),
                                Colors.white.withValues(alpha: 0.15),
                                Colors.white.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            rowContent,
          ],
        ),
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

    final deltaState = switch (delta) {
      > 0 => _LeaderboardDeltaState.positive,
      < 0 => _LeaderboardDeltaState.negative,
      _ => _LeaderboardDeltaState.neutral,
    };
    final color = switch (deltaState) {
      _LeaderboardDeltaState.positive => const Color(0xFF4ADE80), // green-400
      _LeaderboardDeltaState.negative => const Color(0xFFEF4444), // red-500
      _LeaderboardDeltaState.neutral => const Color(
        0xFF94A3B8,
      ).withValues(alpha: 0.3), // slate-400
    };
    final icon = switch (deltaState) {
      _LeaderboardDeltaState.positive => Icons.trending_up,
      _LeaderboardDeltaState.negative => Icons.trending_down,
      _LeaderboardDeltaState.neutral => Icons.remove,
    };
    final valueText = switch (deltaState) {
      _LeaderboardDeltaState.positive => '$delta',
      _LeaderboardDeltaState.negative => '${delta.abs()}',
      _LeaderboardDeltaState.neutral => '',
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
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          if (deltaState != _LeaderboardDeltaState.neutral)
            Text(
              valueText,
              style: textTheme.labelSmall?.copyWith(
                fontSize: 15.2, // 0.95rem
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
