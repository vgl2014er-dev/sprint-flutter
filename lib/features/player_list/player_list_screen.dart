import 'package:flutter/material.dart';

import '../../core/models/app_models.dart';

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
    final textTheme = Theme.of(context).textTheme;
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
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          subtitle: Text('Elo: ${player.elo}'),
        );
      },
    );
  }
}
