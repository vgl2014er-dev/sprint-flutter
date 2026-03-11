import '../models/app_models.dart';

class HistoryPolicy {
  static List<MatchHistoryEntry> cap(
    List<MatchHistoryEntry> history, {
    int maxEntries = 500,
  }) {
    final sorted = List<MatchHistoryEntry>.from(history)
      ..sort((left, right) => right.timestamp.compareTo(left.timestamp));
    return sorted.take(maxEntries).toList(growable: false);
  }
}
