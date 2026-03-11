import '../models/app_models.dart';

class Defaults {
  static const int initialElo = 1200;
  static const int historyLimit = 500;
  static const int eloK = 32;

  static const Set<int> supportedEloKPresets = <int>{8, 16, 24, 32, 40, 48, 64};

  static const String dbPlayersPath = 'sprint_elo/players';
  static const String dbHistoryPath = 'sprint_elo/history';
  static const String dbTournamentPath = 'sprint_elo/tournament';
  static const String dbSettingsPath = 'sprint_elo/settings';

  static const List<String> initialNames = <String>[
    'Silas',
    'Finley',
    'Kayden',
    'Eray',
    'Erik',
    'Arvid',
    'Lion',
    'Jakob',
    'Paul',
    'Lennox',
    'Levi',
    'Lasse',
    'Berat',
    'Moritz',
    'Milan',
    'Moussa',
  ];

  static List<Player> initialPlayers() {
    return initialNames
        .map(
          (name) => Player(
            id: name.toLowerCase(),
            name: name,
            elo: initialElo,
            wins: 0,
            losses: 0,
            draws: 0,
            matchesPlayed: 0,
          ),
        )
        .toList(growable: false);
  }
}
