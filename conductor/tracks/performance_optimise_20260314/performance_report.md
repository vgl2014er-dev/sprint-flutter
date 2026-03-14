# Performance Analysis Report: Sprint Duels

## 1. Executive Summary
The Sprint Duels application, while functional, exhibits several O(N) scaling bottlenecks in its UI, state management, and data synchronization layers. These issues will lead to noticeable "jank" (frame drops) and high battery/data usage as the number of players and match history increases.

## 2. Identified Bottlenecks

### 2.1 UI Rendering (High Impact)
- **Leaderboard Screen:**
    - Sorting of the entire player list occurs within the `build()` method.
    - Multiple `AnimationController` instances running simultaneously for top-ranked players.
    - Complex layout calculations (`LayoutBuilder`) performed during the build pass.
- **Match Runner Screen:**
    - **O(N) History Filtering:** For every rebuild, the entire match history is filtered to calculate head-to-head (H2H) win rates. This is the single most critical UI bottleneck.

### 2.2 State Management (Medium Impact)
- **Monolithic AppState:** A single `StateNotifier` manages all application data.
- **Excessive Rebuilds:** Any change to any part of the state (e.g., a background sync update) triggers a full rebuild of the active screen, even if the data is unrelated.
- **Frequent Projections:** The controller reconstructs the entire `AppState` object on every backend event (repository or platform channel).

### 2.3 Data Layer & Synchronization (Critical Impact)
- **SQLite Inefficiency:** The repository clears and re-inserts entire tables (`players`, `history`) for every match result instead of performing targeted updates.
- **Firebase Scaling:** The entire state (all players and all history) is pushed to and pulled from Firebase on every update. This will fail to scale beyond a small number of records and will cause high latency/data costs.
- **Redundant Persistence:** Configuration settings are saved twice (SQLite and SharedPreferences).

## 3. Recommended Optimizations (Prioritized)

### Priority 1: Data Efficiency (Data Layer)
- **Targeted Updates:** Replace `clear()` and `upsertAll()` with targeted `update` or `insert` operations in the repository.
- **Firebase Atomic Updates:** Use Firebase's `update()` or `push()` methods to synchronize only the changed records (single match result, individual player ELO update) instead of the entire state.

### Priority 2: UI Responsiveness (UI Layer)
- **Memoized Head-to-Head:** Move H2H calculations out of the `build()` method. Use a `Provider` that memoizes the results or perform the calculation once when entering the match runner.
- **Background Sorting:** Sort the player list in the `SprintController` or a dedicated provider, not in the `LeaderboardScreen.build()`.
- **Selector-based Rebuilds:** Refactor screens to use `ref.watch(sprintControllerProvider.select(...))` to minimize rebuilds to only relevant state changes.

### Priority 3: Architecture Refinement (State Layer)
- **Split State:** Break the monolithic `AppState` into smaller, focused states (e.g., `LeaderboardState`, `MatchSessionState`, `SettingsState`).
- **Isolate Processing:** Move heavy data processing (like standard session match generation) to a background Isolate.

## 4. Conclusion
By transitioning from full-state operations to incremental, targeted updates and optimizing the UI's data dependencies, Sprint Duels can achieve the performance and scalability required for a professional competitive tool.
