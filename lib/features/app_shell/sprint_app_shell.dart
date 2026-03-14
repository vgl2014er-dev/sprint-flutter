import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/app_models.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/theme/breakpoints.dart';
import '../../ui/widgets/app_footer.dart';
import '../../ui/widgets/app_header.dart';
import '../landing/landing_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../match_runner/match_runner_screen.dart';
import '../player_list/player_list_screen.dart';
import '../player_profile/player_profile_screen.dart';
import '../player_selection/player_selection_screen.dart';
import 'app_shell_controller.dart';

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

class _ShellState {
  const _ShellState({
    required this.screen,
    required this.themePreference,
    required this.isSettingsOpen,
    required this.manualFullscreenEnabled,
    required this.isReadOnlyClientMode,
  });

  factory _ShellState.fromAppState(AppState state) => _ShellState(
    screen: state.screen,
    themePreference: state.themePreference,
    isSettingsOpen: state.isSettingsOpen,
    manualFullscreenEnabled: state.manualFullscreenEnabled,
    isReadOnlyClientMode: state.isReadOnlyClientMode,
  );

  final Screen screen;
  final AppThemePreference themePreference;
  final bool isSettingsOpen;
  final bool manualFullscreenEnabled;
  final bool isReadOnlyClientMode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _ShellState &&
          screen == other.screen &&
          themePreference == other.themePreference &&
          isSettingsOpen == other.isSettingsOpen &&
          manualFullscreenEnabled == other.manualFullscreenEnabled &&
          isReadOnlyClientMode == other.isReadOnlyClientMode;

  @override
  int get hashCode => Object.hash(
    screen,
    themePreference,
    isSettingsOpen,
    manualFullscreenEnabled,
    isReadOnlyClientMode,
  );
}

class _SettingsModalState {
  const _SettingsModalState({
    required this.themePreference,
    required this.manualFullscreenEnabled,
    required this.kFactor,
    required this.remoteSyncEnabled,
    required this.useClientAudio,
  });

  factory _SettingsModalState.fromAppState(AppState state) =>
      _SettingsModalState(
        themePreference: state.themePreference,
        manualFullscreenEnabled: state.manualFullscreenEnabled,
        kFactor: state.kFactor,
        remoteSyncEnabled: state.remoteSyncEnabled,
        useClientAudio: state.useClientAudio,
      );

  final AppThemePreference themePreference;
  final bool manualFullscreenEnabled;
  final int kFactor;
  final bool remoteSyncEnabled;
  final bool useClientAudio;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _SettingsModalState &&
          themePreference == other.themePreference &&
          manualFullscreenEnabled == other.manualFullscreenEnabled &&
          kFactor == other.kFactor &&
          remoteSyncEnabled == other.remoteSyncEnabled &&
          useClientAudio == other.useClientAudio;

  @override
  int get hashCode => Object.hash(
    themePreference,
    manualFullscreenEnabled,
    kFactor,
    remoteSyncEnabled,
    useClientAudio,
  );
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
    final shellState = ref.watch(
      sprintControllerProvider.select(_ShellState.fromAppState),
    );
    final controller = ref.read(sprintControllerProvider.notifier);
    final connectedClientFullscreen = shellState.screen == Screen.leaderboard;
    final useFullscreenShell =
        connectedClientFullscreen || shellState.manualFullscreenEnabled;

    final showHeader =
        <Screen>{
          Screen.leaderboard,
          Screen.randomPlayerSelection,
          Screen.eloPlayerSelection,
          Screen.playerList,
          Screen.playerProfile,
        }.contains(shellState.screen) &&
        !useFullscreenShell;

    final showFooter =
        shellState.screen != Screen.matchRunner &&
        shellState.screen != Screen.playerProfile &&
        !useFullscreenShell;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sprint Duels',
      theme: buildSprintTheme(Brightness.light),
      darkTheme: buildSprintTheme(Brightness.dark),
      themeMode: toThemeMode(shellState.themePreference),
      home: Builder(
        builder: (appContext) {
          final body = switch (shellState.screen) {
            Screen.landing => Consumer(
              builder: (context, ref, _) {
                final landingState = ref.watch(
                  sprintControllerProvider.select(
                    (value) =>
                        (value.localSessionState, value.leaderboardSource),
                  ),
                );
                return LandingScreen(
                  localSessionState: landingState.$1,
                  isLocalSource: landingState.$2 == LeaderboardSource.local,
                  onOpenRandom: () =>
                      controller.navigateTo(Screen.randomPlayerSelection),
                  onOpenElo: () =>
                      controller.navigateTo(Screen.eloPlayerSelection),
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
                );
              },
            ),
            Screen.randomPlayerSelection => Consumer(
              builder: (context, ref, _) {
                final players = ref.watch(
                  sprintControllerProvider.select((value) => value.players),
                );
                return PlayerSelectionScreen(
                  title: 'Random Matches',
                  isEloMode: false,
                  players: players,
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
                );
              },
            ),
            Screen.eloPlayerSelection => Consumer(
              builder: (context, ref, _) {
                final players = ref.watch(
                  sprintControllerProvider.select((value) => value.players),
                );
                return PlayerSelectionScreen(
                  title: 'Elo Matches',
                  isEloMode: true,
                  players: players,
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
                );
              },
            ),
            Screen.matchRunner => Consumer(
              builder: (context, ref, _) {
                final matchRunnerState = ref.watch(sprintControllerProvider);
                return MatchRunnerScreen(
                  state: matchRunnerState,
                  onBack: controller.handleBackAction,
                  onClose: controller.handleBackAction,
                  onNextRound: controller.startNextRound,
                  onStart: (matchId) {
                    controller.startMatch(matchId);
                    unawaited(_playStartBeep());
                  },
                  onResult: controller.recordResult,
                );
              },
            ),
            Screen.leaderboard => Consumer(
              builder: (context, ref, _) {
                final leaderboardState = ref.watch(sprintControllerProvider);
                return LeaderboardScreen(
                  state: leaderboardState,
                  onViewProfile: (player) {
                    if (!leaderboardState.isReadOnlyClientMode) {
                      controller.openProfile(player.id, Screen.leaderboard);
                    }
                  },
                );
              },
            ),
            Screen.playerList => Consumer(
              builder: (context, ref, _) {
                final players = ref.watch(
                  sprintControllerProvider.select((value) => value.players),
                );
                return PlayerListScreen(
                  players: players,
                  onViewProfile: (player) {
                    controller.openProfile(player.id, Screen.playerList);
                  },
                );
              },
            ),
            Screen.playerProfile => Consumer(
              builder: (context, ref, _) {
                final profileState = ref.watch(sprintControllerProvider);
                final selectedPlayerId = profileState.selectedPlayerId;
                return PlayerProfileScreen(
                  selectedPlayer: selectedPlayerId == null
                      ? null
                      : profileState.players
                            .where((player) => player.id == selectedPlayerId)
                            .cast<Player?>()
                            .firstWhere((_) => true, orElse: () => null),
                  players: profileState.players,
                  history: profileState.history,
                  onDeleteMatch: controller.deleteMatch,
                );
              },
            ),
            Screen.settings => const SizedBox.shrink(),
          };

          final headerActions = <AppHeaderAction>[
            AppHeaderAction(
              icon: shellState.themePreference == AppThemePreference.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              tooltip: shellState.themePreference == AppThemePreference.dark
                  ? 'Use light theme'
                  : 'Use dark theme',
              onPressed: controller.toggleThemePreference,
            ),
            if (shellState.screen == Screen.leaderboard &&
                !shellState.isReadOnlyClientMode)
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
                                    title: _headerTitle(shellState.screen),
                                    onBack:
                                        shellState.isReadOnlyClientMode &&
                                            shellState.screen ==
                                                Screen.leaderboard
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
                  if (shellState.isSettingsOpen)
                    Consumer(
                      builder: (context, ref, _) {
                        final settingsState = ref.watch(
                          sprintControllerProvider.select(
                            _SettingsModalState.fromAppState,
                          ),
                        );
                        return _SettingsModal(
                          state: settingsState,
                          onClose: controller.closeSettingsModal,
                          onToggleTheme: controller.toggleThemePreference,
                          onToggleFullscreen: controller.toggleFullscreen,
                          onSelectKFactor: controller.setKFactor,
                          onToggleRemoteSync: controller.toggleRemoteSync,
                          onToggleClientAudio: controller.toggleClientAudio,
                          onResetLocal: controller.resetLocalData,
                          onResetCloud: controller.resetCloudData,
                          onSeedCloud: controller.seedCloudData,
                        );
                      },
                    ),
                ],
              ),
              floatingActionButton: null,
              bottomNavigationBar: showFooter
                  ? AppFooter(
                      currentScreen: shellState.screen,
                      disabled: shellState.isReadOnlyClientMode,
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

  final _SettingsModalState state;
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
