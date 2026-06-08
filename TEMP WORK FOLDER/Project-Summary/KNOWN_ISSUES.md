# LibraPlates Known Issues

## Existing Bugs / Risks
- Addon startup and data load can fail if Lua table syntax is broken in data files.
- Invalid/malformed row formatting in generated data (especially `data/npc_icons.lua`) can break `require(...)` and unload the addon.
- Native/Libra UI interop edge behavior still exists (targeting visuals and overlays may vary by setting/state).

## Workarounds
- Keep suspicious data edits tightly scoped and validate syntax before runtime load.
- Use known-good settings/profile backups before enabling new rendering/features.
- When native conflicts occur, use config toggles to adjust Libra-vs-native target/arrow behavior.

## Technical Debt
- Debug trace/logging is still embedded in runtime-native-adapter modules and may complicate maintenance.
- `TEMP WORK FOLDER` suggests iterative/manual workflows that are not always committed into runtime polish.
- Feature flags and fallback paths are necessary but can reduce clarity of the active intended behavior.
- Large generated data sets are difficult to audit manually and can drift from source sources.

## Disabled / Unfinished Functionality
- Some optional systems exist but are not enabled by default or are partially wired.
- Event/handler scaffolding exists without full lifecycle usage (`handlers/events.lua`).
- Some preview/assist paths are not clearly separated into explicit isolated architecture, implying mixed concerns.

## Potential Problem Areas
- Data integrity: wrong icons/type/note/zone formatting can silently affect runtime behavior.
- Performance/accumulation: historical notes indicate repeated-area performance concern tied to repeated state/render usage.
- Profile migration edge cases under heavy config change cycles.
- Zone/name typos in data can create user-visible mislabeling.

## Debug Code Still Present
- Trace-oriented helpers and temporary diagnostics exist in native/UI bridging files.
- Some debug strings and optional logging paths can become noisy if enabled and may impact troubleshooting clarity.

## Uncertainty Notes
- This file lists observed risks from codebase inspection and repository notes, but not gameplay outcomes.
- Full validation of every external dataset row was not performed in this analysis; unresolved data inconsistencies may remain.
