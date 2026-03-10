# AI Agent Configuration

## Serena Tools Setup

Call `serena.activate_project`, `serena.check_onboarding_performed` and `serena.initial_instructions` and use tools exposed by serena.

Update memories when appropriate: `.serena/memories/`

## Context7 MCP

Always use Context7 MCP when I need library/API documentation, code generation, setup or configuration steps without me having to explicitly ask.

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