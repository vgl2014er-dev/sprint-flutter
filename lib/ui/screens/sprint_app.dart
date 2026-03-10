import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../domain/head_to_head_calculator.dart';
import '../../models/app_models.dart';
import '../../state/sprint_controller.dart';

final AudioPlayer _startBeepPlayer = AudioPlayer()
  ..setReleaseMode(ReleaseMode.stop);

Future<void> _playStartBeep() async {
  try {
    await _startBeepPlayer.stop();
    await _startBeepPlayer.play(AssetSource('audio/start_beep.mp3'));
  } catch (_) {
    // Ignore playback failures so match flow is never blocked by audio.
  }
}

class SprintApp extends ConsumerWidget {
  const SprintApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sprintControllerProvider);
    final controller = ref.read(sprintControllerProvider.notifier);

    final showHeader = <Screen>{
      Screen.leaderboard,
      Screen.randomPlayerSelection,
      Screen.eloPlayerSelection,
      Screen.deathMatchSelection,
      Screen.playerList,
      Screen.playerProfile,
      Screen.settings,
    }.contains(state.screen);

    final showFooter =
        state.screen != Screen.matchRunner &&
        state.screen != Screen.playerProfile;

    final body = switch (state.screen) {
      Screen.landing => LandingScreen(
        localSessionState: state.localSessionState,
        onOpenRandom: () => controller.navigateTo(Screen.randomPlayerSelection),
        onOpenElo: () => controller.navigateTo(Screen.eloPlayerSelection),
        onOpenDeathMatch: () =>
            controller.navigateTo(Screen.deathMatchSelection),
        onStartLocalDisplay: () => controller.startLocalHosting(_deviceLabel()),
        onConnectLocalDisplay: () => controller.scanLocalHosts(_deviceLabel()),
        onStopLocalDisplay: controller.stopLocalHosting,
      ),
      Screen.randomPlayerSelection => PlayerSelectionScreen(
        title: 'Random Matches',
        isEloMode: false,
        players: state.players,
        onGenerate: (selected) {
          final success = controller.generateMatches(
            selected,
            PairingStrategy.random,
          );
          if (!success) {
            _showSnack(context, 'Select at least 2 players.');
          }
        },
      ),
      Screen.eloPlayerSelection => PlayerSelectionScreen(
        title: 'Elo Matches',
        isEloMode: true,
        players: state.players,
        onGenerate: (selected) {
          final success = controller.generateMatches(
            selected,
            PairingStrategy.elo,
          );
          if (!success) {
            _showSnack(context, 'Select at least 2 players.');
          }
        },
      ),
      Screen.deathMatchSelection => DeathMatchSelectionScreen(
        players: state.players,
        deathMatchInProgress: state.deathMatchInProgress,
        deathMatchLives: state.deathMatchLives,
        deathMatchChampionId: state.deathMatchChampionId,
        deathMatchParticipantIds: state.deathMatchParticipantIds,
        deathMatchPairingStrategy: state.deathMatchPairingStrategy,
        deathMatchLossesByPlayerId: state.deathMatchLossesByPlayerId,
        onStart: (selected, strategy, lives) {
          final success = controller.startDeathMatch(selected, strategy, lives);
          if (!success) {
            _showSnack(context, 'Select at least 2 players.');
          }
        },
        onReset: controller.resetDeathMatch,
        onResume: () => controller.navigateTo(Screen.matchRunner),
      ),
      Screen.matchRunner => MatchRunnerScreen(
        state: state,
        onBack: () => controller.finishRound(Screen.leaderboard),
        onClose: controller.closeRoundToLanding,
        onNextRound: controller.startNextRound,
        onStart: controller.startMatch,
        onResult: controller.recordResult,
      ),
      Screen.leaderboard => LeaderboardScreen(
        state: state,
        onViewProfile: (player) {
          if (!state.isReadOnlyClientMode) {
            controller.openProfile(player.id, Screen.leaderboard);
          }
        },
        onUseLocalConnection: () => controller.scanLocalHosts(_deviceLabel()),
        onUseDatabase: controller.useDatabaseLeaderboard,
        onConnectHost: controller.connectToLocalHost,
        onDisconnectLocal: controller.disconnectLocalConnection,
      ),
      Screen.playerList => PlayerListScreen(
        players: state.players,
        onViewProfile: (player) {
          controller.openProfile(player.id, Screen.playerList);
        },
      ),
      Screen.playerProfile => PlayerProfileScreen(
        selectedPlayer: state.selectedPlayerId == null
            ? null
            : state.players
                  .where((player) => player.id == state.selectedPlayerId)
                  .cast<Player?>()
                  .firstWhere((_) => true, orElse: () => null),
        players: state.players,
        history: state.history,
        onDeleteMatch: controller.deleteMatch,
      ),
      Screen.settings => SettingsScreen(
        currentKFactor: state.kFactor,
        onSelectKFactor: controller.setKFactor,
      ),
    };

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sprint Duels',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F172A)),
        useMaterial3: true,
      ),
      home: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        body: SafeArea(
          child: Column(
            children: <Widget>[
              if (showHeader)
                AppHeader(
                  title: _headerTitle(state.screen),
                  onBack:
                      state.isReadOnlyClientMode &&
                          state.screen == Screen.leaderboard
                      ? null
                      : () {
                          if (state.screen == Screen.playerProfile) {
                            controller.backFromProfile();
                            return;
                          }
                          controller.navigateTo(Screen.landing);
                        },
                  actionIcon:
                      state.screen == Screen.leaderboard &&
                          !state.isReadOnlyClientMode
                      ? Icons.refresh_rounded
                      : null,
                  actionTooltip:
                      state.screen == Screen.leaderboard &&
                          !state.isReadOnlyClientMode
                      ? 'Reset leaderboard'
                      : null,
                  onAction:
                      state.screen == Screen.leaderboard &&
                          !state.isReadOnlyClientMode
                      ? () async {
                          final confirm = await _showResetLeaderboardDialog(
                            context,
                          );
                          if (confirm) {
                            controller.resetData();
                          }
                        }
                      : null,
                ),
              if (state.localSessionState.phase ==
                  LocalSessionPhase.awaitingApproval)
                LocalApprovalBanner(
                  sessionState: state.localSessionState,
                  onAccept: controller.acceptLocalConnection,
                  onReject: controller.rejectLocalConnection,
                ),
              Expanded(child: body),
            ],
          ),
        ),
        bottomNavigationBar: showFooter
            ? AppFooter(
                currentScreen: state.screen,
                disabled: state.isReadOnlyClientMode,
                onNavigate: controller.navigateTo,
              )
            : null,
      ),
    );
  }
}

String _headerTitle(Screen screen) {
  switch (screen) {
    case Screen.leaderboard:
      return 'Leaderboard';
    case Screen.randomPlayerSelection:
    case Screen.eloPlayerSelection:
      return 'Select Players';
    case Screen.deathMatchSelection:
      return 'Death Match';
    case Screen.playerList:
      return 'Players';
    case Screen.playerProfile:
      return 'Player Profile';
    case Screen.settings:
      return 'Settings';
    case Screen.landing:
    case Screen.matchRunner:
      return '';
  }
}

void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Future<bool> _showResetLeaderboardDialog(BuildContext context) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Reset Leaderboard?'),
        content: const Text(
          'Delete all match history and reset all players to 1200 Elo.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Reset Data'),
          ),
        ],
      );
    },
  );
  return confirm == true;
}

String _deviceLabel() => 'Sprint Device';

class AppHeader extends StatelessWidget {
  const AppHeader({
    required this.title,
    required this.onBack,
    this.actionIcon,
    this.actionTooltip,
    this.onAction,
    super.key,
  });

  final String title;
  final VoidCallback? onBack;
  final IconData? actionIcon;
  final String? actionTooltip;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
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
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (actionIcon != null)
              IconButton(
                onPressed: onAction,
                tooltip: actionTooltip,
                icon: Icon(actionIcon),
              )
            else
              const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
}

class LocalApprovalBanner extends StatelessWidget {
  const LocalApprovalBanner({
    required this.sessionState,
    required this.onAccept,
    required this.onReject,
    super.key,
  });

  final LocalSessionState sessionState;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF93C5FD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Approve Nearby Connection',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          Text(
            'Compare code ${sessionState.authToken ?? '...'} with ${sessionState.pendingConnectionName ?? 'the nearby device'} before accepting.',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              ElevatedButton(onPressed: onAccept, child: const Text('Accept')),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: onReject, child: const Text('Reject')),
            ],
          ),
        ],
      ),
    );
  }
}

class AppFooter extends StatelessWidget {
  const AppFooter({
    required this.currentScreen,
    required this.disabled,
    required this.onNavigate,
    super.key,
  });

  final Screen currentScreen;
  final bool disabled;
  final ValueChanged<Screen> onNavigate;

  @override
  Widget build(BuildContext context) {
    final items = <({Screen screen, IconData icon, String label})>[
      (screen: Screen.landing, icon: Icons.home_rounded, label: 'Home'),
      (
        screen: Screen.leaderboard,
        icon: Icons.emoji_events_rounded,
        label: 'Leaderboard',
      ),
      (screen: Screen.playerList, icon: Icons.people_rounded, label: 'Players'),
      (
        screen: Screen.settings,
        icon: Icons.settings_rounded,
        label: 'Settings',
      ),
    ];

    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: items
            .map((item) {
              final active = currentScreen == item.screen;
              return Expanded(
                child: InkWell(
                  onTap: disabled ? null : () => onNavigate(item.screen),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        item.icon,
                        color: active
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF94A3B8),
                      ),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 11,
                          color: active
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

class LandingScreen extends StatelessWidget {
  const LandingScreen({
    required this.localSessionState,
    required this.onOpenRandom,
    required this.onOpenElo,
    required this.onOpenDeathMatch,
    required this.onStartLocalDisplay,
    required this.onConnectLocalDisplay,
    required this.onStopLocalDisplay,
    super.key,
  });

  final LocalSessionState localSessionState;
  final VoidCallback onOpenRandom;
  final VoidCallback onOpenElo;
  final VoidCallback onOpenDeathMatch;
  final VoidCallback onStartLocalDisplay;
  final VoidCallback onConnectLocalDisplay;
  final VoidCallback onStopLocalDisplay;

  @override
  Widget build(BuildContext context) {
    final localActive = localSessionState.role == LocalSessionRole.host;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        const Text(
          'Sprint Duels',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Matchmaking and Elo tracking',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 24),
        _ActionCard(
          title: 'Random Matches',
          subtitle: 'Generate random 1v1 matchups.',
          icon: Icons.casino_rounded,
          onTap: onOpenRandom,
        ),
        _ActionCard(
          title: 'Elo Matches',
          subtitle: 'Pair nearby Elo ratings together.',
          icon: Icons.balance_rounded,
          onTap: onOpenElo,
        ),
        _ActionCard(
          title: 'Death Match',
          subtitle: 'Set lives and fight until one remains.',
          icon: Icons.favorite_rounded,
          onTap: onOpenDeathMatch,
          accent: const Color(0xFFBE123C),
        ),
        Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Offline Mirror',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                localActive
                    ? (localSessionState.phase == LocalSessionPhase.connected
                          ? '${localSessionState.connectedHostName ?? 'Display device'} is receiving live updates.'
                          : 'Hosting nearby mirror as ${localSessionState.localEndpointName ?? 'Sprint Device'}.')
                    : 'A nearby second device can mirror the leaderboard without internet.',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
              if (localSessionState.authToken != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Code ${localSessionState.authToken}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  ElevatedButton.icon(
                    onPressed: localActive
                        ? onStopLocalDisplay
                        : onStartLocalDisplay,
                    icon: Icon(
                      localActive
                          ? Icons.stop_rounded
                          : Icons.play_arrow_rounded,
                    ),
                    label: Text(localActive ? 'Stop' : 'Host'),
                  ),
                  if (!localActive) ...<Widget>[
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: onConnectLocalDisplay,
                      icon: const Icon(Icons.wifi_tethering_rounded),
                      label: const Text('Connect'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.accent,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: (accent ?? const Color(0xFF334155)).withAlpha(26),
          child: Icon(icon, color: accent ?? const Color(0xFF334155)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

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
  final ValueChanged<Set<String>> onGenerate;

  @override
  State<PlayerSelectionScreen> createState() => _PlayerSelectionScreenState();
}

class _PlayerSelectionScreenState extends State<PlayerSelectionScreen> {
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.players.map((player) => player.id).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final sortedPlayers = widget.isEloMode
        ? (List<Player>.from(widget.players)..sort((left, right) {
            final byElo = right.elo.compareTo(left.elo);
            return byElo == 0 ? left.name.compareTo(right.name) : byElo;
          }))
        : widget.players;

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              Text(
                '${_selectedIds.length} / ${widget.players.length} selected',
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedIds = widget.players
                        .map((player) => player.id)
                        .toSet();
                  });
                },
                child: const Text('Select All'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedIds = <String>{};
                  });
                },
                child: const Text('Clear'),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.count(
            crossAxisCount: 3,
            childAspectRatio: 2.2,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: sortedPlayers
                .map((player) {
                  final selected = _selectedIds.contains(player.id);
                  return Card(
                    color: selected ? const Color(0xFFE2E8F0) : Colors.white,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          if (selected) {
                            _selectedIds.remove(player.id);
                          } else {
                            _selectedIds.add(player.id);
                          }
                        });
                      },
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              player.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (widget.isEloMode)
                              Text(
                                'Elo ${player.elo}',
                                style: const TextStyle(fontSize: 11),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                })
                .toList(growable: false),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _selectedIds.length < 2
                ? null
                : () => widget.onGenerate(_selectedIds),
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
                const Icon(
                  Icons.emoji_events_rounded,
                  color: Color(0xFFF59E0B),
                  size: 64,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Death Match Winner',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  champion.name,
                  style: const TextStyle(
                    fontSize: 24,
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
                const Text(
                  'Death Match In Progress',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
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
          child: Row(
            children: <Widget>[
              const Text(
                'Setup',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              SegmentedButton<PairingStrategy>(
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
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: <Widget>[
              const Text(
                'Lives',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              const Text(
                '(losses to eliminate)',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
              const Spacer(),
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
                style: const TextStyle(
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
          ),
        ),
        Expanded(
          child: GridView.count(
            crossAxisCount: 3,
            childAspectRatio: 2.2,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: widget.players
                .map((player) {
                  final selected = _selectedIds.contains(player.id);
                  return Card(
                    color: selected ? const Color(0xFFFEE2E2) : Colors.white,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          if (selected) {
                            _selectedIds.remove(player.id);
                          } else {
                            _selectedIds.add(player.id);
                          }
                        });
                      },
                      child: Center(
                        child: Text(
                          player.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  );
                })
                .toList(growable: false),
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
    final matches = state.roundMatches;
    final currentMatch = matches.isEmpty
        ? null
        : matches[state.currentMatchIndex.clamp(0, matches.length - 1)];
    final allPlayed =
        matches.isNotEmpty && matches.every((match) => match.played);

    if (allPlayed) {
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
                  style: const TextStyle(fontWeight: FontWeight.w700),
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
                color: const Color(0xFFFFE4E6),
                border: Border.all(color: const Color(0xFFFDA4AF)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${state.deathMatchLives == 1 ? 'One loss' : '${state.deathMatchLives} losses'} eliminates a player. Draws do not add losses.',
              ),
            ),
          Expanded(
            child: currentMatch == null
                ? const Center(child: Text('Round complete'))
                : _MatchCard(
                    match: currentMatch,
                    history: state.history,
                    isDeathMatch: state.deathMatchInProgress,
                    deathMatchLives: state.deathMatchLives,
                    deathMatchLossesByPlayerId:
                        state.deathMatchLossesByPlayerId,
                    deathMatchMatchesPlayedByPlayerId:
                        state.deathMatchMatchesPlayedByPlayerId,
                    onStart: () {
                      unawaited(_playStartBeep());
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
            child: Text(allPlayed ? 'View Leaderboard' : 'Go Back'),
          ),
        ],
      ),
    );
  }
}

int _survivorsCount(AppState state) {
  return state.deathMatchParticipantIds.where((id) {
    return (state.deathMatchLossesByPlayerId[id] ?? 0) < state.deathMatchLives;
  }).length;
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({
    required this.match,
    required this.history,
    required this.isDeathMatch,
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
  final int deathMatchLives;
  final Map<String, int> deathMatchLossesByPlayerId;
  final Map<String, int> deathMatchMatchesPlayedByPlayerId;
  final VoidCallback onStart;
  final VoidCallback onP1;
  final VoidCallback onP2;
  final VoidCallback onDraw;

  @override
  Widget build(BuildContext context) {
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: <Widget>[
            ElevatedButton(
              onPressed: match.started || match.played ? null : onStart,
              child: Text(match.started ? 'STARTED' : 'START'),
            ),
            const SizedBox(height: 12),
            _ResultButton(
              label: '${match.player1.name.toUpperCase()} WINS',
              subtitle:
                  'Elo: ${match.player1.elo} · ${p1WinRate.toStringAsFixed(0)}%',
              detail: isDeathMatch ? _buildLivesRow(match.player1.id) : null,
              active: match.played && match.winnerId == match.player1.id,
              enabled: match.started && !match.played,
              onPressed: onP1,
            ),
            const SizedBox(height: 8),
            _ResultButton(
              label: '${match.player2.name.toUpperCase()} WINS',
              subtitle:
                  'Elo: ${match.player2.elo} · ${p2WinRate.toStringAsFixed(0)}%',
              detail: isDeathMatch ? _buildLivesRow(match.player2.id) : null,
              active: match.played && match.winnerId == match.player2.id,
              enabled: match.started && !match.played,
              onPressed: onP2,
            ),
            const SizedBox(height: 8),
            _ResultButton(
              label: 'DRAW',
              subtitle: 'No Elo winner',
              active: match.played && match.isDraw,
              enabled: match.started && !match.played,
              onPressed: onDraw,
            ),
          ],
        ),
      ),
    );
  }

  double _winRateFor(String playerId, List<MatchHistoryEntry> history) {
    if (history.isEmpty) {
      return 0;
    }
    final wins = history.where((entry) {
      return (entry.p1Id == playerId && entry.result == MatchResult.p1) ||
          (entry.p2Id == playerId && entry.result == MatchResult.p2);
    }).length;
    return wins / history.length * 100;
  }

  Widget _buildLivesRow(String playerId) {
    final losses = deathMatchLossesByPlayerId[playerId] ?? 0;
    final remainingLives = (deathMatchLives - losses).clamp(0, deathMatchLives);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ...List<Widget>.generate(deathMatchLives, (index) {
          final filled = index < remainingLives;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Icon(
              filled ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 14,
              color: filled ? const Color(0xFFDC2626) : const Color(0xFF94A3B8),
            ),
          );
        }),
        const SizedBox(width: 6),
        Text(
          '$remainingLives/$deathMatchLives',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
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
    return FilledButton.tonal(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(72),
        backgroundColor: active ? const Color(0xFF10B981) : null,
      ),
      onPressed: enabled ? onPressed : null,
      child: Column(
        children: <Widget>[
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          Text(subtitle, style: const TextStyle(fontSize: 12)),
          if (detail != null) const SizedBox(height: 4),
          if (detail case final Widget extraDetail) extraDetail,
        ],
      ),
    );
  }
}

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({
    required this.state,
    required this.onViewProfile,
    required this.onUseLocalConnection,
    required this.onUseDatabase,
    required this.onConnectHost,
    required this.onDisconnectLocal,
    super.key,
  });

  final AppState state;
  final ValueChanged<Player> onViewProfile;
  final VoidCallback onUseLocalConnection;
  final VoidCallback onUseDatabase;
  final VoidCallback onDisconnectLocal;
  final ValueChanged<String> onConnectHost;

  @override
  Widget build(BuildContext context) {
    final sortedPlayers = List<Player>.from(state.players)
      ..sort((left, right) => right.elo.compareTo(left.elo));

    final isLocalSource = state.leaderboardSource == LeaderboardSource.local;

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(8),
          child: Wrap(
            spacing: 8,
            children: <Widget>[
              if (isLocalSource)
                OutlinedButton(
                  onPressed: onUseDatabase,
                  child: const Text('Use DB'),
                ),
            ],
          ),
        ),
        if (state.localSessionState.role == LocalSessionRole.client ||
            state.localSessionState.discoveredHosts.isNotEmpty ||
            state.leaderboardSource == LeaderboardSource.local)
          _LocalPanel(
            state: state.localSessionState,
            isLocalSource: isLocalSource,
            onUseLocalConnection: onUseLocalConnection,
            onConnectHost: onConnectHost,
            onDisconnectLocal: onDisconnectLocal,
          ),
        Expanded(
          child: ListView.builder(
            itemCount: sortedPlayers.length,
            itemBuilder: (context, index) {
              final player = sortedPlayers[index];
              final matches = player.wins + player.losses + player.draws;
              final winRate = matches == 0
                  ? 0
                  : (player.wins / matches * 100).round();
              return ListTile(
                onTap: state.isReadOnlyClientMode
                    ? null
                    : () => onViewProfile(player),
                leading: Text(
                  index == 0
                      ? '🥇'
                      : index == 1
                      ? '🥈'
                      : index == 2
                      ? '🥉'
                      : '${index + 1}',
                ),
                title: Text(
                  player.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text('Win rate: $winRate%'),
                trailing: Text(
                  '${player.elo}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LocalPanel extends StatelessWidget {
  const _LocalPanel({
    required this.state,
    required this.isLocalSource,
    required this.onUseLocalConnection,
    required this.onConnectHost,
    required this.onDisconnectLocal,
  });

  final LocalSessionState state;
  final bool isLocalSource;
  final VoidCallback onUseLocalConnection;
  final ValueChanged<String> onConnectHost;
  final VoidCallback onDisconnectLocal;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        border: Border.all(color: const Color(0xFF93C5FD)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Nearby', style: TextStyle(fontWeight: FontWeight.w700)),
          Text(_localPhaseText(state), style: const TextStyle(fontSize: 12)),
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

class PlayerListScreen extends StatelessWidget {
  const PlayerListScreen({
    required this.players,
    required this.onViewProfile,
    super.key,
  });

  final List<Player> players;
  final ValueChanged<Player> onViewProfile;

  @override
  Widget build(BuildContext context) {
    final sorted = List<Player>.from(players)
      ..sort((left, right) => left.name.compareTo(right.name));

    return ListView.builder(
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final player = sorted[index];
        return ListTile(
          onTap: () => onViewProfile(player),
          leading: const CircleAvatar(child: Icon(Icons.person_rounded)),
          title: Text(
            player.name,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text('Elo: ${player.elo}'),
        );
      },
    );
  }
}

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
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Card(
                      margin: const EdgeInsets.all(8),
                      child: Column(
                        children: <Widget>[
                          const Padding(
                            padding: EdgeInsets.all(8),
                            child: Text(
                              'Head to Head',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Expanded(
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
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Card(
                      margin: const EdgeInsets.all(8),
                      child: Column(
                        children: <Widget>[
                          const Padding(
                            padding: EdgeInsets.all(8),
                            child: Text(
                              'Recent Matches',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Expanded(
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
                                        (isP1 &&
                                            entry.result == MatchResult.p1) ||
                                        (!isP1 &&
                                            entry.result == MatchResult.p2);
                                    final isLoss =
                                        (isP1 &&
                                            entry.result == MatchResult.p2) ||
                                        (!isP1 &&
                                            entry.result == MatchResult.p1);
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
                                            style: TextStyle(
                                              color: eloChange >= 0
                                                  ? const Color(0xFF10B981)
                                                  : const Color(0xFFEF4444),
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
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_matchToDelete != null)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black54,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Text(
                          'Delete Match?',
                          style: TextStyle(fontWeight: FontWeight.w700),
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
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
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
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
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

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Elo K-Factor',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
              ),
              const SizedBox(height: 6),
              const Text(
                'Controls how strongly each new result changes Elo. Changes apply to future matches only.',
              ),
              const SizedBox(height: 12),
              Text(
                'Current K: $currentKFactor',
                style: const TextStyle(fontWeight: FontWeight.w700),
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
  }
}
