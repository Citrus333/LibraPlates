# LibraPlates Architecture

## Folder Structure
- `LibraPlates.lua`: addon bootstrap and event wiring
- `core/`: foundational systems (state, rendering, targeting, input, native integration)
- `modules/`: render pipeline, plate modules, widget modules, and settings UI orchestration
- `config/`: configuration defaults and global options
- `data/`: data tables used by rendering and lookups
- `assets/`: images/icons used by plates and markers
- `handlers/`: command/event handlers (currently minimal usage)
- `native/`: native interop helpers for Ashita/UI hooks
- `ui/`, `libs/`, `submodules/`, `tools/`: support / utility paths
- `TEMP WORK FOLDER/`: temporary working artifacts

## Major Modules and Responsibilities

### Addon entry
- `LibraPlates.lua`
  - Registers and unregisters Ashita event handlers
  - Delegates to `state`, `modules`, and lifecycle hooks
  - Drives per-frame and render callbacks

### Core systems
- `core/state.lua`
  - Profile-aware settings load/save
  - Merges user settings with defaults and profile fallbacks
- `core/canvas.lua`
  - Plate coordinate conversion and layout geometry
- `core/canvas_texture.lua`
  - Texture loading/caching and low-level draw helpers
- `core/world_marker_probe.lua`
  - Queues plates for world rendering
  - Performs hit-testing and click handling for world plates
- `core/targeting.lua`
  - Targeting behavior, click/no-go-zone handling, and selection state helpers
- `core/native_target_arrow.lua`, `core/native_ui_policy.lua`
  - Native UI/arrows policy and compatibility behavior
- `core/target_module_marker.lua`, `core/world_depth_plate.lua`
  - Additional target overlays and depth-based plate rendering paths

### Orchestration modules
- `modules/init.lua`
  - Central render/update loop orchestration for all modules
  - Links settings, rendering, targeting, and mouse control pathways
- `modules/plates/*`
  - Build and enqueue plate content for each supported entity type:
    - `self`, `pc`, `enemy`, `trust`, `pet`, `npc`
- `modules/widgets/*`
  - Composable plate elements (name, bars, cast bars, icons, status, etc.)
- `modules/settings/*`
  - Settings UI, tab management, copying presets, module toggles
- `modules/target_overlay.lua`
  - Supplemental target overlay renderer

### Data path
- `data/item_icons.lua`, `data/npc_icons.lua`, generated data under `data/generated/*`
- NPC/object metadata drives icon/type/note resolution and default behavior.

## Data Flow
1. Addon receives events (`packet_in`, `d3d_present`, `d3d_beginscene`, mouse/input events).
2. Orchestration (`modules.init`) updates native policy, targeting state, and plate queues.
3. Plate modules build entity plate models using `core.state`, `core.entities`/`core.targeting`, and configured widget visibility.
4. `core.world_marker_probe` receives queued plates.
5. Render pipeline draws plates and handles interaction in present/beginscene callbacks.

## Rendering Flow
- Render is split across callbacks:
  - `d3d_present`: per-frame setup and `modules.Render()` path
  - `d3d_beginscene`: world marker draw pass from `world_marker_probe`
- Canvas system computes bounds, positions, and conversions.
- Texture utility manages caching and draw batching style behavior.
- Widget rendering occurs inside plate-specific modules before being pushed to draw pipeline.

## Settings Flow
1. Defaults loaded from `config/*`.
2. `core.state` loads profile settings from config directory.
3. Settings UI updates `state` structures in memory.
4. Render/target modules query state each frame (or per event) and apply flags.
5. On unload, settings are persisted by `state.Save`.

## Preview System Architecture
- No dedicated standalone preview engine was clearly identified in source.
- “Preview-like” behavior appears to be handled by existing settings/overlay render paths rather than a fully separated preview subsystem.
- Uncertain/unknown: whether a dedicated detached preview mode exists beyond existing live rendering and settings controls.

## Widget System Architecture
- Widgets are modular render units under `modules/widgets/`.
- Each widget encapsulates:
  - a rendering function
  - expected settings/visibility
  - value extraction from plate/entity model
- Plate modules assemble active widgets according to entity/state-specific settings and push resulting visuals into marker queue.

## Dependencies Between Files
- `LibraPlates.lua` depends on:
  - `core.state`
  - `modules.init`
- `modules.init` depends on:
  - `core.*` subsystems
  - `modules.plates.*`
  - `modules.widgets.*`
  - settings module
- `core.world_marker_probe` is a shared dependency for `modules.init`, `core.mouse_controls`, and entity plate modules.
- `modules.settings` consumes and mutates `core.state`, then affects behavior in plate/widgets/targeting modules.

## Technical Limitations Discovered
- Heavy runtime behavior depends on data quality in Lua tables; malformed data can break module load.
- Some modules/features are present but gated/disengaged by settings or policy.
- Large generated data sets increase parse and maintenance burden.
- Full error validation for all external data rows is limited.
- Debug and compatibility hooks exist and can add complexity in troubleshooting.
