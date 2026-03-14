import 'package:flutter/material.dart';

import '../../models/app_models.dart';
import '../theme/sprint_theme_tokens.dart';

class OfflineMirrorSetupCard extends StatefulWidget {
  const OfflineMirrorSetupCard({
    required this.localSessionState,
    required this.isLocalSource,
    required this.onStartLocalDisplay,
    required this.onConnectLocalDisplay,
    required this.onStopLocalDisplay,
    required this.onUseLocalConnection,
    required this.onUseDatabase,
    required this.onConnectHost,
    required this.onDisconnectLocal,
    required this.onAcceptLocalConnection,
    required this.onRejectLocalConnection,
    super.key,
  });

  final LocalSessionState localSessionState;
  final bool isLocalSource;
  final VoidCallback onStartLocalDisplay;
  final VoidCallback onConnectLocalDisplay;
  final VoidCallback onStopLocalDisplay;
  final VoidCallback onUseLocalConnection;
  final VoidCallback onUseDatabase;
  final ValueChanged<String> onConnectHost;
  final VoidCallback onDisconnectLocal;
  final VoidCallback onAcceptLocalConnection;
  final VoidCallback onRejectLocalConnection;

  @override
  State<OfflineMirrorSetupCard> createState() => _OfflineMirrorSetupCardState();
}

class _OfflineMirrorSetupCardState extends State<OfflineMirrorSetupCard> {
  bool _connectFlowRequested = false;

  @override
  void didUpdateWidget(covariant OfflineMirrorSetupCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final phase = widget.localSessionState.phase;
    final shouldResetConnectFlow =
        widget.localSessionState.role == LocalSessionRole.none &&
        phase == LocalSessionPhase.idle &&
        widget.localSessionState.discoveredHosts.isEmpty;
    if (shouldResetConnectFlow && _connectFlowRequested) {
      _connectFlowRequested = false;
    }
  }

  void _startConnectFlow() {
    if (!_connectFlowRequested) {
      setState(() => _connectFlowRequested = true);
    }
    widget.onConnectLocalDisplay();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tokens = context.sprintTokens;
    final state = widget.localSessionState;
    final phase = state.phase;
    final localActive = state.role == LocalSessionRole.host;
    final hasDiscoveredHosts = state.discoveredHosts.isNotEmpty;
    final awaitingApproval = phase == LocalSessionPhase.awaitingApproval;
    final showScanning = phase == LocalSessionPhase.discovering;
    final showConnecting = phase == LocalSessionPhase.connecting;
    final showConnectFlow =
        _connectFlowRequested ||
        awaitingApproval ||
        showScanning ||
        showConnecting ||
        hasDiscoveredHosts;
    final showExpandedBody = showConnectFlow || widget.isLocalSource;

    final bool isDisconnectedState =
        phase == LocalSessionPhase.idle ||
        phase == LocalSessionPhase.error ||
        phase == LocalSessionPhase.disconnected;

    // Use a clean slate/white design block
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: Container(
        margin: const EdgeInsets.only(top: 8), // mt-2 from React
        padding: const EdgeInsets.all(20), // p-5
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: const Color(0xFFE2E8F0),
          ), // border-slate-200
          borderRadius: BorderRadius.circular(12), // rounded-xl
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Offline Mirror',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111827), // text-gray-900
                fontSize: 18,
              ),
            ),

            if (state.errorMessage != null &&
                state.errorMessage!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2), // bg-red-50
                  border: Border.all(
                    color: const Color(0xFFFECACA),
                  ), // border-red-200
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  state.errorMessage!,
                  style: textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFDC2626), // text-red-600
                  ),
                ),
              ),
            ],

            if (isDisconnectedState) ...[
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 16),
                child: Text(
                  'A nearby second device can mirror the leaderboard without internet.',
                  style: textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF64748B), // slate-500
                    fontSize: 14,
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: widget.onStartLocalDisplay,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.play_arrow_rounded,
                              size: 16,
                              color: Color(0xFF111827),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Host',
                              style: textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF111827),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _startConnectFlow,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.wifi_rounded,
                              size: 16,
                              color: Color(0xFF111827),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Connect',
                              style: textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF111827),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            if (phase == LocalSessionPhase.advertising) ...[
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 16),
                child: Text(
                  'Hosting nearby mirror as ${state.localEndpointName ?? 'Sprint Device'}. Waiting for connections...',
                  style: textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF64748B), // slate-500
                    fontSize: 14,
                  ),
                ),
              ),
              InkWell(
                onTap: widget.onStopLocalDisplay,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.stop_rounded,
                        size: 16,
                        color: Color(0xFF111827),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Stop Host',
                        style: textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            if (showExpandedBody &&
                !isDisconnectedState &&
                phase != LocalSessionPhase.advertising) ...<Widget>[
              const SizedBox(height: 10),
              ClipRect(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: awaitingApproval
                      ? _ApprovalActions(
                          deviceName:
                              state.pendingConnectionName ?? 'Nearby device',
                          onAccept: widget.onAcceptLocalConnection,
                          onReject: widget.onRejectLocalConnection,
                        )
                      : _ConnectionActions(
                          state: state,
                          showScanning: showScanning,
                          showConnecting: showConnecting,
                          showConnectFlow: showConnectFlow,
                          isLocalSource: widget.isLocalSource,
                          onRetryScan: widget.onUseLocalConnection,
                          onConnectHost: widget.onConnectHost,
                          onDisconnectLocal: widget.onDisconnectLocal,
                          onUseDatabase: widget.onUseDatabase,
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ApprovalActions extends StatelessWidget {
  const _ApprovalActions({
    required this.deviceName,
    required this.onAccept,
    required this.onReject,
  });

  final String deviceName;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tokens = context.sprintTokens;
    return Column(
      key: const ValueKey<String>('approval'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '$deviceName wants to connect.',
          style: textTheme.bodySmall?.copyWith(color: tokens.mutedText),
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
    );
  }
}

class _ConnectionActions extends StatelessWidget {
  const _ConnectionActions({
    required this.state,
    required this.showScanning,
    required this.showConnecting,
    required this.showConnectFlow,
    required this.isLocalSource,
    required this.onRetryScan,
    required this.onConnectHost,
    required this.onDisconnectLocal,
    required this.onUseDatabase,
  });

  final LocalSessionState state;
  final bool showScanning;
  final bool showConnecting;
  final bool showConnectFlow;
  final bool isLocalSource;
  final VoidCallback onRetryScan;
  final ValueChanged<String> onConnectHost;
  final VoidCallback onDisconnectLocal;
  final VoidCallback onUseDatabase;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tokens = context.sprintTokens;
    final showHostList = state.discoveredHosts.isNotEmpty;
    final showRetry = showConnectFlow && state.role != LocalSessionRole.host;
    final showDisconnect =
        state.phase == LocalSessionPhase.connected && isLocalSource;

    return Column(
      key: const ValueKey<String>('connect-actions'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (showScanning) ...<Widget>[
          Row(
            children: <Widget>[
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Scanning for nearby devices...',
                style: textTheme.bodySmall?.copyWith(color: tokens.mutedText),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        if (showConnecting) ...<Widget>[
          Text(
            'Connecting to ${state.pendingConnectionName ?? 'host'}...',
            style: textTheme.bodySmall?.copyWith(color: tokens.mutedText),
          ),
          const SizedBox(height: 8),
        ],
        if (showHostList) ...<Widget>[
          Text(
            'Available devices',
            style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: state.discoveredHosts.length,
              itemBuilder: (context, index) {
                final host = state.discoveredHosts[index];
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(host.displayName),
                  subtitle: Text(host.endpointId),
                  trailing: TextButton(
                    onPressed: () => onConnectHost(host.endpointId),
                    child: const Text('Connect'),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            if (showRetry)
              TextButton.icon(
                onPressed: onRetryScan,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            if (showDisconnect)
              OutlinedButton(
                onPressed: onDisconnectLocal,
                child: const Text('Disconnect'),
              ),
            if (isLocalSource)
              OutlinedButton(
                onPressed: onUseDatabase,
                child: const Text('Use DB'),
              ),
          ],
        ),
        if (state.phase == LocalSessionPhase.error &&
            state.errorMessage != null) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            state.errorMessage!,
            style: textTheme.bodySmall?.copyWith(color: tokens.danger),
          ),
        ],
      ],
    );
  }
}

String _statusText(LocalSessionState state) {
  final phase = state.phase;
  if (phase == LocalSessionPhase.connected) {
    if (state.role == LocalSessionRole.host) {
      return '${state.connectedHostName ?? 'Display device'} is receiving live updates.';
    }
    return 'Connected to ${state.connectedHostName ?? 'host'}.';
  }
  if (phase == LocalSessionPhase.awaitingApproval) {
    return 'Waiting for connection approval.';
  }
  if (state.role == LocalSessionRole.host) {
    return 'Hosting nearby mirror as ${state.localEndpointName ?? 'Sprint Device'}.';
  }
  return 'A nearby second device can mirror the leaderboard without internet.';
}
