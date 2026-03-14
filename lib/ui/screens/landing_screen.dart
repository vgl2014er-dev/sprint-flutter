import 'package:flutter/material.dart';

import '../../models/app_models.dart';
import '../theme/breakpoints.dart';
import '../theme/sprint_theme_tokens.dart';
import '../widgets/offline_mirror_setup_card.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({
    required this.localSessionState,
    required this.isLocalSource,
    required this.onOpenRandom,
    required this.onOpenElo,
    required this.onOpenDeathMatch,
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
  final VoidCallback onOpenRandom;
  final VoidCallback onOpenElo;
  final VoidCallback onOpenDeathMatch;
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
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.sprintTokens;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = SprintBreakpoints.isCompact(constraints.maxWidth);
        final padding = compact ? 12.0 : 20.0;

        return ListView(
          padding: EdgeInsets.all(padding),
          children: <Widget>[
            Text(
              'Sprint Duels',
              style: textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Matchmaking and Elo tracking',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: tokens.mutedText),
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
              accent: scheme.error,
            ),
            OfflineMirrorSetupCard(
              localSessionState: localSessionState,
              isLocalSource: isLocalSource,
              onStartLocalDisplay: onStartLocalDisplay,
              onConnectLocalDisplay: onConnectLocalDisplay,
              onStopLocalDisplay: onStopLocalDisplay,
              onUseLocalConnection: onUseLocalConnection,
              onUseDatabase: onUseDatabase,
              onConnectHost: onConnectHost,
              onDisconnectLocal: onDisconnectLocal,
              onAcceptLocalConnection: onAcceptLocalConnection,
              onRejectLocalConnection: onRejectLocalConnection,
            ),
          ],
        );
      },
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
    final textTheme = Theme.of(context).textTheme;
    final tokens = context.sprintTokens;
    final resolvedAccent = accent ?? Theme.of(context).colorScheme.primary;
    final isDeathMatch = title.toLowerCase().contains('death match');
    final avatarBackgroundColor = isDeathMatch
        ? const Color(0xFFFEE2E2) // bg-red-100
        : const Color(0xFFDBEAFE); // bg-blue-100

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE2E8F0)), // border-slate-200
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: avatarBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: resolvedAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827), // text-gray-900
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF64748B), // text-slate-500
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF94A3B8), // text-slate-400
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
