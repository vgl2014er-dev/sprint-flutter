import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_models.dart';
import '../../state/sprint_controller.dart';
import '../theme/app_theme.dart';
import '../theme/breakpoints.dart';
import '../widgets/app_footer.dart';
import '../widgets/app_header.dart';
import 'landing_screen.dart';
import 'leaderboard_screen.dart';
import 'match_runner_screen.dart';
import 'player_list_screen.dart';
import 'player_profile_screen.dart';
import 'player_selection_screen.dart';

final AudioPlayer _startBeepPlayer = AudioPlayer()
  ..setReleaseMode(ReleaseMode.stop);
final Future<void> _startBeepPreload = _preloadStartBeep();

Future<void> _preloadStartBeep() async {
  try {
    await _startBeepPlayer.setSource(
      AssetSource('assets/sounds/beeps/start.wav'),
    );
  } catch (_) {
    // Ignore preload failures and fall back to direct play.
  }
}

Future<void> _playStartBeep() async {
  try {
    await _startBeepPreload;
    await _startBeepPlayer.seek(Duration.zero);
    await _startBeepPlayer.resume();
  } catch (_) {
    try {
      await _startBeepPlayer.play(
        AssetSource('assets/sounds/beeps/start.wav'),
        mode: PlayerMode.lowLatency,
      );
    } catch (_) {
      // Ignore playback failures so match flow is never blocked by audio.
    }
  }
}

class SprintApp extends ConsumerStatefulWidget {
  const SprintApp({super.key});

  @override
  ConsumerState<SprintApp> createState() => _SprintAppState();
}

class _SprintAppState extends ConsumerState<SprintApp> {
  StreamSubscription<LocalControlEvent>? _controlSubscription;

  @override
  void initState() {
    super.initState();
    _controlSubscription = ref
        .read(platformChannelsProvider)
        .localControlEvents
        .listen((event) {
          if (event == LocalControlEvent.startMatchBeep) {
            unawaited(_playStartBeep());
          }
        });
  }

  @override
  void dispose() {
    _controlSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sprintControllerProvider);
    final controller = ref.read(sprintControllerProvider.notifier);
    final connectedClientFullscreen =
        state.screen == Screen.leaderboard &&
        state.isReadOnlyClientMode &&
        state.localSessionState.phase == LocalSessionPhase.connected;
    final useFullscreenShell =
        connectedClientFullscreen || state.manualFullscreenEnabled;

    final showHeader =
        <Screen>{
          Screen.leaderboard,
          Screen.randomPlayerSelection,
          Screen.eloPlayerSelection,
          Screen.deathMatchSelection,
          Screen.playerList,
          Screen.playerProfile,
        }.contains(state.screen) &&
        !useFullscreenShell;

    final showFooter =
        state.screen != Screen.matchRunner &&
        state.screen != Screen.playerProfile &&
        !useFullscreenShell;

    final showFloatingSettings =
        !useFullscreenShell && !state.isReadOnlyClientMode;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sprint Duels',
      theme: buildSprintTheme(Brightness.light),
      darkTheme: buildSprintTheme(Brightness.dark),
      themeMode: toThemeMode(state.themePreference),
      home: Builder(
        builder: (appContext) {
          final body = switch (state.screen) {
            Screen.landing => LandingScreen(
              localSessionState: state.localSessionState,
              isLocalSource: state.leaderboardSource == LeaderboardSource.local,
              onOpenRandom: () =>
                  controller.navigateTo(Screen.randomPlayerSelection),
              onOpenElo: () => controller.navigateTo(Screen.eloPlayerSelection),
              onOpenDeathMatch: () =>
                  controller.navigateTo(Screen.deathMatchSelection),
              onStartLocalDisplay: () =>
                  controller.startLocalHosting(_deviceLabel()),
              onConnectLocalDisplay: () =>
                  controller.scanLocalHosts(_deviceLabel()),
              onStopLocalDisplay: controller.stopLocalHosting,
              onUseLocalConnection: () =>
                  controller.scanLocalHosts(_deviceLabel()),
              onUseDatabase: controller.useDatabaseLeaderboard,
              onConnectHost: controller.connectToLocalHost,
              onDisconnectLocal: controller.disconnectLocalConnection,
              onAcceptLocalConnection: controller.acceptLocalConnection,
              onRejectLocalConnection: controller.rejectLocalConnection,
            ),
            Screen.randomPlayerSelection => PlayerSelectionScreen(
              title: 'Random Matches',
              isEloMode: false,
              players: state.players,
              onGenerate: (selected, targetMatchesPerPlayer) {
                final success = controller.generateMatches(
                  selected,
                  PairingStrategy.random,
                  targetMatchesPerPlayer: targetMatchesPerPlayer,
                );
                if (!success) {
                  _showSnack(appContext, 'Select at least 2 players.');
                }
              },
            ),
            Screen.eloPlayerSelection => PlayerSelectionScreen(
              title: 'Elo Matches',
              isEloMode: true,
              players: state.players,
              onGenerate: (selected, targetMatchesPerPlayer) {
                final success = controller.generateMatches(
                  selected,
                  PairingStrategy.elo,
                  targetMatchesPerPlayer: targetMatchesPerPlayer,
                );
                if (!success) {
                  _showSnack(appContext, 'Select at least 2 players.');
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
                final success = controller.startDeathMatch(
                  selected,
                  strategy,
                  lives,
                );
                if (!success) {
                  _showSnack(appContext, 'Select at least 2 players.');
                }
              },
              onReset: controller.resetDeathMatch,
              onResume: () => controller.navigateTo(Screen.matchRunner),
            ),
            Screen.matchRunner => MatchRunnerScreen(
              state: state,
              onBack: () {
                controller.handleBackAction();
              },
              onClose: () {
                controller.handleBackAction();
              },
              onNextRound: controller.startNextRound,
              onStart: (matchId) {
                controller.startMatch(matchId);
                unawaited(_playStartBeep());
              },
              onResult: controller.recordResult,
            ),
            Screen.leaderboard => LeaderboardScreen(
              state: state,
              onViewProfile: (player) {
                if (!state.isReadOnlyClientMode) {
                  controller.openProfile(player.id, Screen.leaderboard);
                }
              },
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
            Screen.settings => const SizedBox.shrink(),
          };

          final headerActions = <AppHeaderAction>[
            AppHeaderAction(
              icon: state.themePreference == AppThemePreference.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              tooltip: state.themePreference == AppThemePreference.dark
                  ? 'Use light theme'
                  : 'Use dark theme',
              onPressed: controller.toggleThemePreference,
            ),
            if (state.screen == Screen.leaderboard &&
                !state.isReadOnlyClientMode)
              AppHeaderAction(
                icon: Icons.refresh_rounded,
                tooltip: 'Reset leaderboard',
                onPressed: () async {
                  final confirm = await _showResetLeaderboardDialog(appContext);
                  if (confirm) {
                    controller.resetLocalData();
                  }
                },
              ),
          ];

          final shellBody = useFullscreenShell
              ? body
              : SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = SprintBreakpoints.isWide(
                        constraints.maxWidth,
                      );
                      final horizontalPadding = isWide ? 24.0 : 8.0;
                      final maxWidth = isWide ? 1100.0 : 900.0;

                      return Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                            ),
                            child: Column(
                              children: <Widget>[
                                if (showHeader)
                                  AppHeader(
                                    title: _headerTitle(state.screen),
                                    onBack:
                                        state.isReadOnlyClientMode &&
                                            state.screen == Screen.leaderboard
                                        ? null
                                        : () => _handleBack(controller),
                                    actions: headerActions,
                                  ),
                                Expanded(child: body),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );

          return PopScope<void>(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) {
                _handleBack(controller);
              }
            },
            child: Scaffold(
              body: Stack(
                children: <Widget>[
                  shellBody,
                  if (state.isSettingsOpen)
                    _SettingsModal(
                      state: state,
                      onClose: controller.closeSettingsModal,
                      onToggleTheme: controller.toggleThemePreference,
                      onToggleFullscreen: controller.toggleFullscreen,
                      onSelectKFactor: controller.setKFactor,
                      onToggleRemoteSync: controller.toggleRemoteSync,
                      onToggleClientAudio: controller.toggleClientAudio,
                      onResetLocal: controller.resetLocalData,
                      onResetCloud: controller.resetCloudData,
                      onSeedCloud: controller.seedCloudData,
                    ),
                ],
              ),
              floatingActionButton: showFloatingSettings
                  ? FloatingActionButton(
                      key: const Key('settings-fab'),
                      onPressed: controller.openSettingsModal,
                      child: const Icon(Icons.settings_rounded),
                    )
                  : null,
              bottomNavigationBar: showFooter
                  ? AppFooter(
                      currentScreen: state.isSettingsOpen
                          ? Screen.settings
                          : state.screen,
                      disabled: state.isReadOnlyClientMode,
                      onNavigate: (screen) {
                        if (screen == Screen.settings) {
                          controller.openSettingsModal();
                          return;
                        }
                        controller.navigateTo(screen);
                      },
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  void _handleBack(SprintController controller) {
    final shouldExit = controller.handleBackAction();
    if (shouldExit) {
      unawaited(SystemNavigator.pop());
    }
  }
}

class _SettingsModal extends StatelessWidget {
  const _SettingsModal({
    required this.state,
    required this.onClose,
    required this.onToggleTheme,
    required this.onToggleFullscreen,
    required this.onSelectKFactor,
    required this.onToggleRemoteSync,
    required this.onToggleClientAudio,
    required this.onResetLocal,
    required this.onResetCloud,
    required this.onSeedCloud,
  });

  final AppState state;
  final VoidCallback onClose;
  final VoidCallback onToggleTheme;
  final ValueChanged<bool> onToggleFullscreen;
  final ValueChanged<int> onSelectKFactor;
  final ValueChanged<bool> onToggleRemoteSync;
  final ValueChanged<bool> onToggleClientAudio;
  final VoidCallback onResetLocal;
  final VoidCallback onResetCloud;
  final VoidCallback onSeedCloud;

  @override
  Widget build(BuildContext context) {
    const presets = <int>[8, 16, 24, 32, 40, 48, 64];
    final isDark = state.themePreference == AppThemePreference.dark;

    return Positioned.fill(
      child: Stack(
        children: <Widget>[
          GestureDetector(
            key: const Key('settings-modal-backdrop'),
            onTap: onClose,
            child: Container(color: Colors.black45),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520, maxHeight: 740),
              child: Material(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Text(
                              'Settings',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const Spacer(),
                            IconButton(
                              key: const Key('settings-modal-close'),
                              onPressed: onClose,
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Appearance',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile.adaptive(
                          value: isDark,
                          onChanged: (_) => onToggleTheme(),
                          title: const Text('Dark mode'),
                        ),
                        SwitchListTile.adaptive(
                          value: state.manualFullscreenEnabled,
                          onChanged: onToggleFullscreen,
                          title: const Text('Fullscreen'),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Match settings',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text('Elo K-factor (${state.kFactor})'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: presets
                              .map(
                                (preset) => ChoiceChip(
                                  selected: preset == state.kFactor,
                                  label: Text('$preset'),
                                  onSelected: (_) => onSelectKFactor(preset),
                                ),
                              )
                              .toList(growable: false),
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile.adaptive(
                          value: state.remoteSyncEnabled,
                          onChanged: onToggleRemoteSync,
                          title: const Text('Remote sync'),
                        ),
                        SwitchListTile.adaptive(
                          value: state.useClientAudio,
                          onChanged: onToggleClientAudio,
                          title: const Text('Client audio'),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Data',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: <Widget>[
                            OutlinedButton(
                              onPressed: onResetLocal,
                              child: const Text('Reset local'),
                            ),
                            OutlinedButton(
                              onPressed: state.remoteSyncEnabled
                                  ? onResetCloud
                                  : null,
                              child: const Text('Reset cloud'),
                            ),
                            FilledButton(
                              onPressed: state.remoteSyncEnabled
                                  ? onSeedCloud
                                  : null,
                              child: const Text('Seed cloud'),
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
    builder: (dialogContext) => AlertDialog(
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
    ),
  );
  return confirm == true;
}

String _deviceLabel() => 'Sprint Device';
