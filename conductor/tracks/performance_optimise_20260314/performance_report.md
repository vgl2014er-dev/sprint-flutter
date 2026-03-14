# Performance Analysis Report: Sprint Duels

## 1. Executive Summary
This report is scoped to the real deployment model:
- Personal project
- Static player roster
- Hard cap: 20 players
- Primary runtime: nearby connected devices (host + client)

Within that scope, the app is structurally acceptable, but there are still a few high-impact inefficiencies that can cause avoidable UI stalls and extra battery/network work:
- Match-runner head-to-head calculations are recalculated from full history during rebuilds.
- Repository write/read sync paths still perform clear-and-reinsert cycles.
- Full-state Firebase writes include the full history blob on each push.

These are manageable at 20 players, but they are still the top candidates for perceptible jank reduction on lower-end devices.

## 2. Scope, Method, and Evidence

### 2.1 Scope
- In-scope: connected-device flow, max 20 static players, history capped by app policy.
- Out-of-scope: web/desktop profiling, large-scale growth architecture, multi-hundred-player scenarios.

### 2.2 Evidence Sources
1. Source-path audit (UI, controller, repository, nearby transport).
2. Synthetic payload sizing run using the current wire shapes and a realistic capped dataset:
   - 20 players
   - 500 history entries (current cap)

### 2.3 Measured Payload Sizing (Synthetic, Reproducible)
Command output from local sizing run:
- `players_count`: `20`
- `history_count`: `500`
- `local_snapshot_json_bytes`: `1905`
- `cloud_players_json_bytes`: `1769`
- `cloud_history_json_bytes`: `104523`
- `cloud_total_json_bytes`: `106315`

Interpretation:
- Nearby connected snapshot payload is small (~1.9 KB) and suitable for frequent updates.
- Full cloud sync payload is materially larger (~106 KB per full push at cap), mostly from history.

## 3. Findings (Ordered by Impact in This Project Context)

### P1 — Full-table rewrite pattern in local persistence paths
Evidence:
- Result submit path clears and reinserts both players and history tables.
- Similar clear-and-reinsert behavior exists in Firebase listener ingest.

References:
- `lib/data/repository/sprint_repository_impl.dart:224`
- `lib/data/repository/sprint_repository_impl.dart:229`
- `lib/data/repository/sprint_repository_impl.dart:452`
- `lib/data/repository/sprint_repository_impl.dart:483`

Impact under max-20/static:
- Bounded, but still unnecessary write amplification and potential short UI stalls on weaker storage.

### P1 — Full-state Firebase push/pull remains expensive relative to nearby mode
Evidence:
- Cloud push writes full players + full history arrays.
- Synthetic payload at cap is ~106 KB, dominated by history.

References:
- `lib/data/repository/sprint_repository_impl.dart:552`
- `lib/data/repository/sprint_repository_impl.dart:555`
- `lib/data/repository/sprint_repository_impl.dart:475`

Impact under max-20/static:
- Acceptable for occasional sync, but expensive for frequent updates and unnecessary for nearby-connected primary mode.

### P2 — Match-runner rebuild cost includes full-history H2H filtering
Evidence:
- Match card rebuild filters entire history list to compute H2H win rates.

References:
- `lib/ui/screens/match_runner_screen.dart:193`
- `lib/ui/screens/match_runner_screen.dart:299`

Impact under max-20/static:
- History cap (`500`) keeps this bounded, but repeated filtering still contributes to avoidable frame work during active match flow.

### P2 — Broad state projection and full-state watch increase rebuild fan-out
Evidence:
- Controller recomputes projected `AppState` on each repository/platform event.
- App shell watches full provider state.

References:
- `lib/state/sprint_controller.dart:1023`
- `lib/state/sprint_controller.dart:1045`
- `lib/ui/screens/sprint_app_shell.dart:83`

Impact under max-20/static:
- Mostly fine in practice, but still broader rebuild surface than necessary for connected real-time updates.

### P3 — Leaderboard build still performs sort + latest-match scan each build
Evidence:
- Sorting and history scan happen in `build()`.

References:
- `lib/ui/screens/leaderboard_screen.dart:20`
- `lib/ui/screens/leaderboard_screen.dart:23`

Impact under max-20/static:
- Low absolute cost at 20 players, but easy cleanup target.

## 4. Connected-Only Context Assessment

### What is already good for your usage
- Nearby snapshot/control transport is lightweight and direct.
  - Snapshot send path: `android/app/src/main/kotlin/elo/flutter/nearby/LocalLeaderboardConnectionManager.kt:214`
  - Control send path: `android/app/src/main/kotlin/elo/flutter/nearby/LocalLeaderboardConnectionManager.kt:229`
  - Typed payload decode path: `android/app/src/main/kotlin/elo/flutter/nearby/LocalLeaderboardConnectionManager.kt:439`
- Default roster size is already below your cap (`16` seeded names).
  - `lib/domain/defaults.dart:15`

### Risk profile (for 20-player static roster)
- Primary runtime risk is not transport size; it is repeated local rewrite/recompute work during active play.
- Cloud sync overhead is optional and should remain secondary for your connected-first setup.

## 5. Prioritized Optimization Plan (Right-Sized)

### Do Now (high value, low complexity)
1. Replace clear-and-reinsert in `submitRoundResults` and listener ingest with targeted updates/upserts where possible.
2. Cache/memoize match-runner H2H computation per active pairing and invalidate only when history changes.
3. Keep remote sync disabled during connected sessions unless explicitly needed.

### Do Next (moderate value, still simple)
1. Move leaderboard sorting/latest-match derivation to a cached projection keyed on player/history updates.
2. Narrow high-frequency widget rebuilds using selectors/derived providers at screen subtrees instead of full app-shell dependency.

### Explicitly Not Needed Now
- No immediate need to split `AppState` into multiple domain states solely for scale.
- No isolate/off-thread architectural work justified by current 20-player constraint.

## 6. Baseline and Acceptance Targets (Connected Devices)
For future repeat runs on your actual devices, use these practical targets:
- Connected leaderboard: no sustained jank during normal interaction.
- Match result commit (host): no user-visible stall on submit.
- Nearby update latency: perceived near-real-time update on client after host result.
- Memory: no monotonic leak trend over a 10-minute connected session.

If these targets are met after the Do Now set, further architecture refactors are optional.
