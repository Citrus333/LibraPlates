# LibraPlates Project Summary

## Project Purpose
LibraPlates is an Ashita Lua addon for FFXI that renders in-game informational plates/overlays for multiple entity types (self, players, enemies, trusts, pets, NPCs, and objects) and provides configurable targeting/UI behavior in place of or alongside native UI elements.

## High-level Overview
The addon is organized as a Lua modular system with a small coordinator (`LibraPlates.lua`) that wires Ashita events to:

- core systems (`core/*`) for state, targeting, rendering helpers, native UI handling, and mouse/interaction
- plate modules (`modules/plates/*`) that produce plate content per entity type
- widget modules (`modules/widgets/*`) that render text bars/icons/status visuals
- settings UI (`modules/settings/*`) for runtime customization
- generated or curated data tables (`data/*`) for icons and metadata

## Major Features
- Multi-entity plate rendering (self, player, enemy, trust, pet, NPC, object)
- World marker plate rendering and click handling
- Per-entity and per-state widget configuration
- Target/subtarget overlays and targeting behavior controls
- Optional interaction with native Ashita target/arrow behavior
- Profile-based persisted settings with fallback to defaults
- Optional quick menu and world depth plate paths
- Extensive data-driven NPC handling via `data/npc_icons.lua`

## Supported Entity Types
- `self` (current player)
- `pc` (other player characters)
- `enemy` (hostile NPCs/monsters)
- `trust` (party AI entities)
- `pet` (summons/charm pets and job-specific pet handling)
- `npc` (NPCs and object-like interactive entities)
- `object` (present in settings/state matrices and behavior paths)

## Configuration Systems
- `config/global.lua`: core feature flags, targeting/range behavior, render/perf knobs
- `config/defaults.lua`: default bar/widget setups
- `config/canvas.lua`: visual sizing, alignment, and scaling parameters
- `core/state.lua`: profile loading/saving and migration/fallback behavior
- `modules/settings/*`: interactive settings UI + presets + tabbed workflow

## Current State of the Project
- Functionally complete enough to run a production overlay flow for plates and settings.
- Some features appear intentionally disabled or incomplete (for example, action-range features are not default-enabled in current flow).
- The codebase is broad and mostly operational but includes technical debt (debug hooks, legacy paths, mixed data quality risks).
- No major architectural rewrite is currently indicated in source; changes trend toward incremental fixes.

## File Structure Overview
- `LibraPlates.lua`: addon entry and event binding
- `core/`: runtime systems (state, rendering helpers, targeting, mouse handling, native integration)
- `modules/`: high-level module orchestration and plate/widget rendering logic
- `modules/plates/*`: one file per entity plate family
- `modules/widgets/*`: reusable UI primitives on plates
- `config/*`: defaults and static config
- `data/*`: icon maps, generated helper data, NPC metadata
- `assets/`: image resources (e.g., `assets/images/*`)
- `ui/*`, `handlers/*`, `libs/*`, `submodules/*`, `native/*`: supporting systems and adapters
- `TEMP WORK FOLDER/*`: work-in-progress area used by contributors (not primary runtime path)

## Development Priorities (Inferred)
- Preserve stable rendering and targeting behavior while resolving known data integrity issues.
- Improve reliability of data parsing and validation (especially NPC data tables).
- Remove or gate debug-heavy code paths and finalize incomplete modules.
- Keep behavior stable across updates unless explicitly requested.

## Important Project Conventions
- Event-driven flow via Ashita event callbacks.
- Central coordination in `modules/init.lua` and `LibraPlates.lua`.
- Entity behavior separated by entity type modules.
- Preferences centralized through `core.state` and passed through module pipelines.
- Render order matters and is intentionally explicit in plate queues.

## AI Assistant Notes
- Prefer existing working code over rewrites.
- Avoid hardcoded data whenever possible.
- Preserve existing behavior unless explicitly requested to change it.
- Keep `LibraPlates.lua` focused on orchestration.
- Place new functionality into dedicated modules when practical.
- Do not assume packet structures without evidence.
- Use real game data rather than placeholder values.
- Follow existing project patterns before introducing new ones.

## Cannot Be Determined from Code Alone
- Exact target user experience goals for every widget combination.
- Intended final UX polish targets (animations, transitions, branding).
- Complete external acceptance criteria for gameplay correctness.
- Final status of all pending data normalization tasks outside this codebase (e.g., external source-of-truth maintenance).
