Added new Codex environment action for debug rebuild/install/start workflow.

File:
- .codex/environments/environment.toml

Action added:
- name: Rebuild + Run Debug
- command: powershell -ExecutionPolicy Bypass -File scripts/rebuild-install-all-devices.ps1

This uses the existing script default mode (debug), which runs flutter clean + pub get + flutter build apk --debug + install-all-devices + app launch on connected targets.