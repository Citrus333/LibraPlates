# LibraPlates Current Tasks

## Features Currently Under Development (Inferred)
- Ongoing stabilization of data integrity for NPC/object lookups.
- Gradual hardening of targeting/overlay behavior against native UI conflicts.
- Cleanup of legacy or partially enabled systems before broader feature expansion.

## Partially Completed Systems
- Action-range/target action queue system appears present but not broadly enabled by default.
- Native UI policy integration is operational but still has compatibility edge behavior.
- Quick-menu/module overlay settings exist and are used, but placement/behavior still shows historical caveats in notes.
- Settings system is broad and active, but UI/interaction consistency varies by workflow.

## TODO Items Discovered in Code
No `TODO`/`FIXME`/`XXX` markers were found in tracked runtime source via direct scan.
Important: this does not mean there are no unfinished tasks; several are recorded in notes/docs and behavior-level comments.

## Comments/Future Work Signals from Codebase and Notes
- `handlers/events.lua` is present but effectively unused/skeleton-like.
- Native debug/logging and trace calls are present in key target-arrow and marker systems.
- Temporary working folder contains iterative artifacts that suggest unresolved refactors.
- Some fallback/feature gating indicates planned-but-paused workflows.

## Areas That Appear Unfinished
- Action-range/queued targeting integration is incomplete from user-facing perspective.
- Data synchronization and validation pipeline for icon/note/type rows remains high maintenance.
- Deep cleanup of legacy/feature-flagged modules and debug-only hooks is pending.
- Complete replacement of temporary workaround behavior in native interoperability has not yet been finalized.

## Suggested Next Priorities
1. Add safe validation checks for core data tables (`npc_icons`, generated data) to prevent load-time syntax/bad-row breakage.
2. Reconcile all entity rendering edge cases while preserving existing order/behavior.
3. Document and formalize remaining feature-flaged modules (enable/disable policy).
4. Remove or harden debug-only code paths from normal runtime with low-risk toggles.
5. Add a focused maintenance task list for data hygiene (missing icons, malformed rows, duplicate/conflicting entries).
