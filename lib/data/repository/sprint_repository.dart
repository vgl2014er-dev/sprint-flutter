import '../../models/app_models.dart';

abstract class SprintRepository {
  Stream<List<Player>> get players;

  Stream<List<MatchHistoryEntry>> get history;

  Stream<SyncState> get syncState;

  Stream<int> get kFactor;

  Stream<AppThemePreference> get themePreference;

  Future<void> submitRoundResults(List<RoundResultInput> results);

  Future<void> deleteMatch(String matchId);

  Future<void> resetAllData();

  Future<void> setKFactor(int kFactor);

  Future<void> setThemePreference(AppThemePreference preference);

  void dispose();
}
