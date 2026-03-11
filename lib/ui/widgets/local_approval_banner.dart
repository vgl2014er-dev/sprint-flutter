import 'package:flutter/material.dart';

import '../../models/app_models.dart';
import '../theme/sprint_theme_tokens.dart';

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
    final textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.sprintTokens.bannerBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.sprintTokens.bannerBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Approve Nearby Connection',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            'Compare code ${sessionState.authToken ?? '...'} with ${sessionState.pendingConnectionName ?? 'the nearby device'} before accepting.',
            style: textTheme.bodySmall,
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
