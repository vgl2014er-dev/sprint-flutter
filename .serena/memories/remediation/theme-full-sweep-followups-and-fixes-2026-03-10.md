Follow-up fixes applied during theme full sweep execution on branch codex/theme-full-sweep (worktree C:/Users/paul/projects/flutter/sprint-theme-full-sweep):

1) Fixed reset dialog context bug in SprintApp shell:
- Problem: showDialog() was called with a BuildContext above MaterialApp, causing missing MaterialLocalizations in tests and risk at runtime.
- Fix: moved screen/action callback construction under MaterialApp via a Builder and used that app context for snackbars/dialogs.

2) Fixed compact-width layout overflows in player selection/death-match setup:
- Problem: several horizontal Row layouts overflowed at narrow widths.
- Fix: converted key control strips to LayoutBuilder-responsive row/column variants; added Wrap-based action controls in selection header.

3) Removed duplicate dispose wiring for SprintController provider:
- Problem: StateNotifierProvider already disposes notifiers; extra ref.onDispose(controller.dispose) caused double-dispose state errors in tests.
- Fix: removed manual onDispose call from sprintControllerProvider.