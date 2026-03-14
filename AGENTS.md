# AI Agent Configuration

## Serena Tools Setup

Call `serena.activate_project`, `serena.check_onboarding_performed` and `serena.initial_instructions` and use tools exposed by serena.

Update memories when appropriate: `.serena/memories/`
## Exa & Context7 MCP

Always use Exa MCP & Context7 MCP when I need library/API documentation, code generation, setup or configuration steps without me having to explicitly ask.

## DeepWiki CLI Tool

I have a CLI tool installed called `deepwiki`.

**Capabilities:** `deepwiki --help`

It can query GitHub repositories for context-grounded information using the following syntax:

```bash
deepwiki ask-question --repo-name <owner/repo> --question "<your question>" --raw true
```

## Agentic Feature Locality Rule

- Use `lib/features/<feature>/` as the default app structure.
- Default per-feature structure is two primary files:
  - `<feature>_screen.dart`
  - `<feature>_controller.dart`
- Small feature-specific models can live at the top of the feature controller file.
- Keep a centralized `app_shell` for global overview and app-level coordination (routing, back policy, composition), but do not keep unrelated feature behavior there.
- No `domain/usecases` layer for new work.
- Shared models and repositories live under `lib/core/`.
- Feature understandability budget is `<=1200` lines, counting only files inside that feature folder.
- Enforcement mode is manual review only (no CI hard gate).
- `app_shell` is allowed as an architectural exception when needed for global overview; any exception above `1200` lines must include a short justification and a follow-up split note in the PR.

### PR Checklist (Architecture)

- Each touched feature includes a line-budget total (feature-folder files only) and confirms it is `<=1200` lines, or explains any temporary exception.



## Context MCP Performance

- Context savings: `1.7x (39% reduction)`
- Total calls: `45`
- Call breakdown: `ctx_batch_execute=7`, `ctx_execute=1`, `ctx_execute_file=34`, `ctx_search=3`
- Session totals: `794.6KB processed`, `313.6KB sandboxed`, `481.0KB entered context`

### Follow-up Session (2026-03-14, Death Match Hard Delete)

- Context savings: `N/A (no context-mode tool calls in this session)`
- Total calls: `0`
- Call breakdown: `ctx_batch_execute=0`, `ctx_execute=0`, `ctx_execute_file=0`, `ctx_search=0`, `ctx_stats=1`
- Session totals: `0B processed`, `0B sandboxed`, `0B entered context`

### Follow-up Session (2026-03-14, Always-Connected Leaderboard + Hide Settings Icons)

- Context savings: `1.0x (0% reduction)`
- Total calls: `1`
- Call breakdown: `ctx_batch_execute=0`, `ctx_execute=0`, `ctx_execute_file=0`, `ctx_search=0`, `ctx_stats=1`
- Session totals: `0.3KB processed`, `0.0KB sandboxed`, `0.3KB entered context`

