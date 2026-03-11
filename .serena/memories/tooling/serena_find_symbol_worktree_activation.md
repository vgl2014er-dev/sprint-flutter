`find_symbol` can return empty results in this repo family if Serena is attached to the wrong project context.
Reliable lookup path:
1. Invoke the Serena executable directly with global `--project` (worktree path or project name).
2. Then run `find-symbol` with `--relative-path`.
Example:
`serena-windows-x64.exe --project C:\Users\paul\projects\flutter\sprint-theme-full-sweep find-symbol --name-path-pattern AppThemePreference --relative-path lib/models/app_models.dart`
Known issue: If MCP Serena tools return `Transport closed`, use CLI fallback and restart Codex thread/client to restore MCP transport.