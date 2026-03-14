Implemented RANDOM pairing heuristics in PairingEngine and controller wiring.

What changed:
- PairingEngine.generate now accepts optional recentOpponentByPlayerId and eloBlockByPlayerId inputs.
- RANDOM strategy now uses sampled candidates (12) and scores candidates lexicographically:
  1) minimize immediate rematches against recentOpponentByPlayerId
  2) minimize cross-block pairings using eloBlockByPlayerId
  3) random tie-break among equal-best candidates
- Preserved legacy RANDOM behavior when both maps are empty.
- AppShellController now builds and passes pairing context for all random generation entry points:
  - _generateMatchesForStandardSession (including in-flight recent opponent updates across batch queue generation)
  - _generateMatchesForRound
  - _generateDeathMatchRound
- Added helpers in controller:
  - _buildRecentOpponentByPlayerId(selectedIds)
  - _buildEloBlockByPlayerId(selectedPlayers) with 3 near-equal Elo tiers (top/mid/bottom)

Tests added in test/domain/domain_logic_test.dart:
- avoids immediate rematches when alternatives exist
- novelty priority above elo blocks
- same-block preference when novelty ties

Verification:
- flutter test test/domain/domain_logic_test.dart passed
- flutter test test/state/sprint_controller_test.dart passed

Also updated AGENTS.md Context MCP Performance with this session stats section:
- Follow-up Session (2026-03-14, Random Pairing Novelty + Elo Blocks)
