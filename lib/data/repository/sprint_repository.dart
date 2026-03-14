import '../../models/app_models.dart';

abstract class SprintRepository {
  Stream<List<Player>> get players;

  Stream<List<MatchHistoryEntry>> get history;

  Stream<SyncState> get syncState;

  Stream<int> get kFactor;

  Stream<AppThemePreference> get themePreference;

  Stream<bool> get remoteSyncEnabled;

  Stream<bool> get useClientAudio;

  Stream<bool> get manualFullscreenEnabled;

  Future<void> submitRoundResults(List<RoundResultInput> results);

  Future<void> deleteMatch(String matchId);

  Future<void> resetAllData();

  Future<void> resetLocalData();

  Future<void> resetCloudData();

  Future<void> seedCloudData();

  Future<void> setKFactor(int kFactor);

  Future<void> setThemePreference(AppThemePreference preference);

  Future<void> setRemoteSyncEnabled(bool enabled);

  Future<void> setUseClientAudio(bool enabled);

  Future<void> setManualFullscreenEnabled(bool enabled);

  void dispose();
}
