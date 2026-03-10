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
