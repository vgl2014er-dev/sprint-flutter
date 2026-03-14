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

---

# Flutter AI Rules
**Role:** Expert Dev. Premium, beautiful code.
**Tools:** `dart_format`, `dart_fix`, `analyze_files`.
**Stack:**
* **Nav:** `go_router` (Type-safe).
* **State:** `ValueNotifier`. NO Riverpod/GetX.
* **Data:** `json_serializable` (snake_case).
* **UI:** Material 3, `ColorScheme.fromSeed`, Dark Mode.
**Code:**
* **SOLID**.
* **Layers:** Pres/Domain/Data.
* **Naming:** PascalTypes, camelMembers, snake_files.
* **Async:** `async/await`, try-catch.
* **Log:** `dart:developer` ONLY.
* **Null:** Sound safety. No `!`.
**Perf:**
* `const` everywhere.
* `ListView.builder`.
* `compute()` for heavy tasks.
**Testing:** `flutter test`, `integration_test`.
**A11y:** 4.5:1 contrast, Semantics.
**Design:** "Wow" factor. Glassmorphism, shadows.
**Docs:** Public API `///`. Explain "Why".

## Context MCP Performance

- Context savings: `1.7x (39% reduction)`
- Total calls: `45`
- Call breakdown: `ctx_batch_execute=7`, `ctx_execute=1`, `ctx_execute_file=34`, `ctx_search=3`
- Session totals: `794.6KB processed`, `313.6KB sandboxed`, `481.0KB entered context`

### Follow-up Session (2026-03-14)

- Context savings: `1.6x (39% reduction)`
- Total calls: `113`
- Call breakdown: `ctx_batch_execute=8`, `ctx_execute=23`, `ctx_execute_file=67`, `ctx_search=11`, `ctx_stats=4`
- Session totals: `1.4MB processed`, `549.5KB sandboxed`, `865.1KB entered context`

### Follow-up Session (2026-03-14, Auto-Connect Accept Fix)

- Context savings: `N/A (no context-mode tool calls in this session)`
- Total calls: `0`
- Call breakdown: `ctx_batch_execute=0`, `ctx_execute=0`, `ctx_execute_file=0`, `ctx_search=0`, `ctx_stats=1`
- Session totals: `0B processed`, `0B sandboxed`, `0B entered context`

### Follow-up Session (2026-03-14, Connected Header + Side Padding Fix)

- Context savings: `1.0x (0% reduction)`
- Total calls: `1`
- Call breakdown: `ctx_batch_execute=0`, `ctx_execute=0`, `ctx_execute_file=0`, `ctx_search=0`, `ctx_stats=1`
- Session totals: `0.3KB processed`, `0.0KB sandboxed`, `0.3KB entered context`

### Follow-up Session (2026-03-14, Connected WiFi Label + Square Card Corners)

- Context savings: `1.0x (0% reduction)`
- Total calls: `2`
- Call breakdown: `ctx_batch_execute=0`, `ctx_execute=0`, `ctx_execute_file=0`, `ctx_search=0`, `ctx_stats=2`
- Session totals: `0.9KB processed`, `0.0KB sandboxed`, `0.9KB entered context`
