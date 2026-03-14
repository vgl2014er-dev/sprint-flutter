Replaced conductor performance report with a connected-devices-focused, max-20-player analysis for personal project usage.

Updated file:
- conductor/tracks/performance_optimise_20260314/performance_report.md

What changed:
- Reframed scope to nearby connected host+client runtime with static roster and 20-player cap.
- Removed large-scale assumptions and architecture-overreach.
- Added evidence-backed findings tied to current code paths:
  - full-table clear/reinsert local persistence paths,
  - full-state Firebase push/pull paths,
  - match-runner full-history H2H filtering in build,
  - broad app-state projection/rebuild fan-out,
  - leaderboard build-time sort/history scan.
- Added synthetic payload sizing metrics at cap:
  - local snapshot ~1.9KB,
  - cloud players ~1.8KB,
  - cloud history ~104.5KB,
  - cloud total ~106.3KB.
- Added right-sized optimization priorities (Do Now / Do Next / Not Needed Now).
- Added connected-device acceptance targets for repeat runs.

No code behavior changes made; report-only update.