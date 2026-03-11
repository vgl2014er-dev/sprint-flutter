Updated .codex/environments/environment.toml actions to include common deployment/test workflows.

Added actions:
- Run Release: powershell -ExecutionPolicy Bypass -File scripts/install-all-devices.ps1 -Release
- Rebuild + Run Release: powershell -ExecutionPolicy Bypass -File scripts/rebuild-install-all-devices.ps1 -Release
- Mode Tests: powershell -ExecutionPolicy Bypass -File scripts/mobile-mcp/run-mode-tests.ps1
- Mode Tests + Local: powershell -ExecutionPolicy Bypass -File scripts/mobile-mcp/run-mode-tests.ps1 -IncludeLocalMode

Kept existing action:
- Run (debug install): powershell -ExecutionPolicy Bypass -File scripts/install-all-devices.ps1