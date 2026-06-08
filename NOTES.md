# LibraPlates Shared Notes

This file is for shared testing notes between Lila, her husband, and Codex.

### Quick Priority (latest)

- Start here first:
  - Clean action queue logging format and remove duplicate spam before any logic changes.
  - Keep `/st` range queue/packet parsing disabled until stability checks are green.
  - Only next: rework action-range parsing (if still needed).

## Current Good Restore Point

`C:\catseyexi\catseyexi-client\Ashita\addons\LibraPlates\_rollback_safety_20260526-141407-perfect-engaged-overlay`

Marked good after the engaged enemy overlay was tested as perfect.

## Rules While Testing

- Do not broad rollback.
- Do not copy a whole old addon over the current one.
- Keep code changes small.
- Do not guess settings/options when requirements are unclear. Ask Lila first.
- Do not mutate `C:\catseyexi\catseyexi-client\Ashita\config\addons\LibraPlates\rebuild_profile.lua` unless Lila explicitly approves it.
- If two people are testing, only one person should edit addon code at a time.

## User Notes
- replace native mouse
- Bug: Self Quick Menu is drawing in the wrong layer behind the Self plate; it should appear above the plate.
- Settings UI todo: add the copy-settings function back in, so settings can be copied from one entity/state/widget area to another instead of rebuilding them manually.
- Performance bug report: while staying in the same area, lag feels like it gets worse over time, as if some bucket/state/cache is filling. Treat as possible accumulation/leak behavior rather than broad performance tuning; investigate only after the current Al'Taieu fish visibility issue is settled or if Lila explicitly shifts focus.
- Mob name settings: add/support separate name display settings for mobs claimed by self/party/alliance vs claimed by others.
- Self Quick Menu idea: add party invite actions/state, including accepting an invite and showing/handling invite pending.
- Debuff timers need a dedicated cleanup/test pass after Buffs: match the finished Buff timer behavior and UI style where it makes sense, verify live PC/Self debuff detection, timer sorting, warning stages, icon pack discovery, icon background/border, timer text sizing, and reset-confirm safety.
- NPC/Object data direction: curated always-on NPC/Object lists are wired and working, and Lila is still editing the list/icons. Keep the curated lists (`catseye_npc_icons.lua`, `catseye_item_icons.lua`, `npc_icons.lua`, `item_icons.lua`) for special icons/types. Remaining future work is zone-scoped loading, but that should wait until the data has full zone coverage; then load by zone on zone change with exact-name lookup and cached results instead of scanning all entries every frame.
- ??? object spoiler setting: add a setting for `???`/search objects to show or hide their names, so LibraPlates can avoid spoiling hidden-object searching when desired.
- Add decision note: confirm if we still need the separate **`libra depth probe`** utility addon, or if this behavior can stay fully in LibraPlates once native hooks are stable.
- Done: Sea object `Lumoarian Gleam` is supported. It is used to trade/pick up sea organs, and players can access Vision storage through Lumorian Gleams (Loxley).
- Add screen "no-go zones" for LibraPlates click targeting: user-defined invisible rectangles over action bars, chat windows, menus, or other UI areas. If a mouse click is inside a no-go zone, LibraPlates should ignore plate click-targeting there while still letting the game/UI receive the click normally. This is safer than trying to block the game's mouse input.
- Disable nameplate click-through: add a way to prevent LibraPlates/nameplate click targeting when clicking through/behind game UI such as action bars, chat windows, or menus, so UI clicks do not accidentally target a plate behind them.
- Add an option in the Target Module to turn chevrons on/off for NPC/Object plates.
- Add controls for Target/Subtarget background opacity.
- Target/Subtarget module needs outline settings.
- Add toggles for native game names in the same areas where LibraPlates name settings live, such as Self, Enemy, PC, NPC, and Object name settings.
- Need a lock-target text/icon option. Likely belongs with Target/Subtarget modules, but decide exact home later.
- Fishing/gathering interaction first pass implemented under Fishing settings: right-click with a fishing rod equipped in the ranged slot queues `/fish` when the click does not hit a LibraPlates plate. Right-clicking known gathering object plates can target the object and use the matching tool. Current mappings are Mining Point -> Pickaxe, Excavation Point -> Pickaxe, Logging Point -> Hatchet, and Harvest/Harvesting Point -> Sickle. Still need test in the field and decide what, if anything, should happen for Clamming Point, Fish Trap, and other fishing-related objects.
- DoH/DoL activity idea: add a ring timer for the cooldown before the player can fish, craft, or gather again.
- Target/Subtarget module settings seem to be Enemy settings applying to all entity types. Need separate scoping or proper per-entity behavior.
- When enemy HP reaches 0, remove target/subtarget markers from that enemy.
- Target/Subtarget module ownership is not resolved. Do not remove Target/Subtarget from the Modules tab without Lila explicitly approving that direction. Need decide later how Plates > entity > state and Modules tab should coexist without feeling duplicated or confusing.

## Done List

- 2026-06-07 — Quickmenu links are now `bg-wiki`:
  - `All quickmenu links now use https://www.bg-wiki.com`
  - `Catseye NPC quickmenu links now use https://www.bg-wiki.com/ffxi/CatsEyeXI_NPCs#...`
- Targeting module changes do not affect anything.
- Pet targeting test result: `/target <pet>` works for Lila's own pet, `/subtarget <pet>` does nothing, and `/ignorepet on` appears to prevent targeting other players' pets rather than own pet. In Plates, pet states should expose `Target (module)` only, not `Subtarget (module)`. Runtime overlay should not draw pet Subtarget module unless a real native pet-subtarget case is later found.
- Future pet targeting setting idea: many pet players may have little/no reason to target their own pet because normal actions are pet-command based and players generally cannot cast normal spells directly on pets. Consider a toggle to keep pet plates visible but disable pet targeting/click rects/target module selection, similar in spirit to the native-hidden/non-targetable fish handling. This could prevent accidental tab/click targeting of own pets while preserving pet HP/timer info.
- Pet targeting test toggle implemented for addon-side testing: `/lp pettargeting off` (alias `/lp petclick off`) keeps own pet plates visible but disables LibraPlates pet click targeting and suppresses pet Target module overlay; `/lp pettargeting on` restores it; `/lp pettargeting status` prints current state. This does not change native FFXI tab targeting yet.
- The pet targeting test toggle is now exposed as `Allow pet plate targeting` in pet Target-module settings. It appears in Plates > pet entity > pet state > Target (module), and also in Modules > pet entity > pet state > Target. It applies to BST, SMN, Wyvern/DRG, and Automaton/PUP.
- At a certain width, the chevrons and arrows stop stretching, around 80 X and 100 Y.
- Look into a way to model-swap blacklisted players into Fomor models of the same race with funny placeholder names like "Forgotten Blabber Mouth" or "Party Saboteur".
- Target module is not drawing the chevrons for self-targeting far enough apart on the X axis to contain the width of a 500 wide HP bar.
- Add Zoom/Libra state and settings for all entity types, not only enemies.
- TP bar is currently one bar with two black spacers, not three true sections, and it does not yet have separate three-section colors. This is for TP-capable plates such as Self/players, not Enemy/NPC/Object.
- Newly added files in `assets\images\widget-bars` are not appearing in the bar texture/options list. Check texture discovery/cache/listing for widget bar assets.
- Need party/alliance role/status icons such as party leader.
- Clicking an element in the preview window should open/select that element's settings.
- The inspect/Libra window should be called Peer.
- Peer module/entity coverage updated: Peer should live in Plates for Self, PC, and Enemy. NPC/Object Peer was considered and intentionally skipped because Quick Menu is the better place for clickable NPC/Object actions. Do not add Peer to NPC/Object, Trust, or pet entities unless Lila changes this later.
- Furniture/Object note: Aura pots in Sky are way too high.
- Furniture/Object note: In the middle of the Mog House there is a nameplate that reads "FURNITURE."
- Consider putting the distance number on the targeting layer so it remains constant size and visible through walls.
- Left-click targeting while engaged still seems partly active: with weapon drawn and an enemy engaged, self can still be targeted by left click, while other enemies seemingly cannot.
- NPC/Object plates need an option to show function text instead of, or alongside, an icon, such as "Map Dealer" or "Weather Forecaster".
- All plate families need the Peer state included when the full state set is added back, not only Idle/Combat/Target/Subtarget.
- BST pet state: Fight should be treated as temporary; when fighting ends, return to the last resting state such as Heel or Stay. If no resting state is known, hide the state.

## Recovered Context From Archived Chat

- Engaged enemy overlay was working perfectly at the restore point above.
- `/lp engaged` was added as a debug command to show tracked engaged enemies.
- This section is reconstructed context, not notes typed by Lila.

## Testing Log

Add new notes below. Newest notes can go at the top.

### 2026-06-07

- Small/simple fixes selected first (for next pass, low risk):
  - Keep `/st` range queue/packet parsing disabled at runtime until we resume that feature intentionally (already controlled by `enableTargetActionRange = false` in `libraplates.lua`).
  - Remove hardcoded player-name fallback text in `modules/widgets/name.lua` (fallback should remain a neutral placeholder, not `Lumenlee`).
  - Cut noisy duplicate queue logging noise and add one deterministic format before any future re-enable of action queue parsing.
  - Prefer "target-action behavior untouched" when stability tests are ongoing; no more experimental native arrow logic until current `/st`/target stability is stable for >20 minutes.

- `/st` freeze fixed by rolling back target range queue feature from runtime hooks:
  - `libraplates.lua`: `enableTargetActionRange = false` and all `targetActionRange` event hookups are now guarded.
  - Runtime no longer calls `HandleCommandText`, `HandlePacketOut`, or `HandlePacketIn` for range queue unless the feature flag is explicitly turned on.
  - Result: freeze no longer appears when starting `/st` actions.
- Quick note for future re-enable: this feature is intentionally left off by default and must be explicitly re-enabled in code; do not treat it as a setting default.
- Husband / NAS testing notes:
  - Husband config observed at: `C:\catseyexi\catseyexi-client\Ashita\config\addons\LibraPlates\Torkson_36088\settings.lua`.
  - The temp copy at `C:\catseyexi\catseyexi-client\Ashita\addons\LibraPlates\TEMP WORK FOLDER\Torkson_36088` was only for review; it is not his live profile.
  - On his machine, `C:\catseyexi\catseyexi-client\Ashita\config\addons\LibraPlates\Default\cfg.lua` was absent while profile settings still existed in `config\addons\LibraPlates\<profile>\settings.lua`.
  - Zip extract warning `"Destination Path Too Long"` happened while copying/packaging; this can create incomplete transfers and should be treated as a deployment/package-risk item before testing.
  - He had both native switches enabled at the same time (`Use native party/target UI` and `Use native names`), which caused targeting/color confusion during testing; both were reset later.
  - During that period he also reported unstable behavior around `/st` and color picker/UI interactions, so those sessions should be treated as polluted by multiple simultaneously changed settings.

### Small, low-risk fixes to do first (lowest complexity)

- Add a single startup debug note: `/st` queueing path disabled by default because it was causing hangs.
- Add a short in-game safe command or temporary log line only when `/lp` debug mode is on for action range (currently not active because feature flag is off).
- Add a tiny “do not log action-range spam” default to avoid accidental per-queue debug spam on normal casts.
- Add a guard around any future command-parsing helpers that could re-run every packet/text event.
- Keep `core.target_action_range.lua` untouched until we are ready to rework with a dedicated, narrow parser path.
- Before re-enable: add one fixed test script for queue capture (`provoke`, `dia iii`, `sleep ii`) and one deterministic command log format, then re-enable only in debug sessions.
- Next priority: fix remaining small UX note items only after `/st` is stable for multiple full minutes (e.g., preview-click selection, quick menu website corrections, and module copy button behavior).

### 2026-06-06

- Target module auto-place option: Highlight and Chevrons now have an `Auto place by` dropdown with `Widest element` (existing/default behavior using name or HP, whichever is wider) and `Name` (anchor only to the name rect). This is wired in both the full Target Module editor and the placement editor, and applies to normal canvas markers plus the older Object/NPC target overlay path.
- Target module auto-place follow-up: full editor `Auto place by` dropdowns now use unique ImGui IDs for Highlight and Chevrons so the Chevrons dropdown can select `Name` independently. Highlight Position X/Y is hidden while auto-place is enabled because auto-place owns the anchor; manual mode shows Position X/Y.
- Target module auto-place redo after emergency rollback: reconnected Highlight/Chevrons `Auto place by` to marker build, canvas draw, and target overlay using existing safe plate rects only. Did not reapply projected draw-bound changes, name Y bias, or NPC highlight.
- Chevron target-module bug: chevrons were not drawing when an arrow image was also enabled because both the normal target-module marker and older target-overlay path treated chevrons as an arrow fallback (`showChevrons = showArrow ~= true and texture exists`). Fixed so chevrons can draw alongside arrows. Also added the missing `Show chevrons` toggle to the full Target Module editor; previously only placement mode exposed `chevronEnabled`, so the visible Chevron image/size settings could still be disabled by a hidden flag. Do not touch native target-arrow flicker timing while testing this.
- Target overlay cleanup todo: `modules/target_overlay.lua` still contains an older/separate targeted Object/NPC overlay path for fallback target visuals. The latest native targeting policy gates it correctly, and Lila confirmed the behavior works, but the structure is messy because Object target info bypasses the normal plate target-module path. When returning to cleanup, map whether this overlay can become a thin fallback wrapper around the same Target/Subtarget module policy/settings instead of acting as a parallel renderer.
- Native game UI settings cleanup: the old `Hide native party/target UI`, `Hide native target UI/arrow`, and `Hide native names` labels were inverted/confusing. UI now presents native party/target as one `Use native party/target UI` switch and names as `Use native names`; internally they still map to the existing hide flags so saved settings keep working. The party/target switch is real: when enabled, Libra target/subtarget modules do not draw; when disabled, Libra replaces the native party/target UI and target arrow through the stable hideparty-style path to avoid target-arrow flicker. `Use native names` is also a real switch: when enabled, Libra name text does not draw on plate canvases; when disabled, `/names off` is applied and Libra names draw. Mog House furniture/door areas force native targeting only; native names remain controlled by `Use native names`.
- Settings cleanup: old `Always-visible important plates` section was misleading. `Self` was a dead/stale control, and engaged enemies can also be visible through other tactical/target paths. UI now labels this as `Engaged enemy overlay`, with controls for the extra engaged-enemy overlay path only. Target/subtarget and tactical party-style plates use separate rules.
- Mog House native/object behavior: exact generic `Furniture` placeholder labels are hidden, but do not suppress all Mog House Object targeting because gardening may require Object targets. If Mog House furniture placeholders are present, force native party/target UI for that area so the native door/gardening target path can work. Do not force native names; `/names` remains controlled by `Use native names`. Confirmed furniture signature from Lila scans: name `Furniture`, type `3`, spawn `0x22`, render0 `0x200`, render1 `0x880`. `/lp doorscan` should still report these entries for debugging with `mogFurniture=true` and `mogHouseObjectSuppression=true`.
- Mog House Object/Furniture testing: husband's feedback reported `In the middle of the mog house there is a nameplate that reads: FURNITURE.` and `No targeting module for mog house door.` Lila is visiting/checking Mog Houses to verify whether this happens in all Mog Houses or only specific layouts. Current scans saw many generic visible `Furniture` type-3 objects around the Mog House and a special door/native-target case that does not report as a normal current/subtarget index.
- Native target UI/Mog House door note: with native hiding enabled, the Mog House door can still need the native target primitive even when Ashita reports `current=nil sub=nil`. Current fix gates hiding of the native target primitive on having a real target/subtarget index, so hide-party/target UI can stay enabled without breaking the door.

### 2026-06-05

- Performance checkpoint after combat-area diagnostics: active range slider is working and the remaining cost is active Enemy detail rendering, not NPC/Object. Latest sampled run averaged about `4.28ms` total, `1.91ms` Enemy, and `0.23ms` NPC/Object. Stop broad performance work for now unless a fresh diagnostic shows a new hotspot.
- Trust recognition fix: `core.trust_names` now aliases generated trust names with parenthetical suffixes, such as `Trust: Sylvie (UC)`, to their plain live entity name, such as `Sylvie`. This fixes nearby other-player trusts that showed native green names but no Libra plate.
- Native target arrow checkpoint: F-key and command first-target native flash was fixed by keeping the native hard-hide path active when native party/target UI hiding is enabled. Do not touch native arrow timing/hard-hide unless a new targeted bug requires it.
- Object fallback fixed: unknown objects now follow the same rule as unknown NPCs. If no curated icon/data exists, still draw the object target/subtarget marker/name; do not invent icon/type/details.
- Chat spam cleanup done: removed the temporary Self Quick Menu debug line like `[LibraPlates] Quick menu self toggle ... command=...`.
- Trust TP note resolved for now: the apparent 100% TP issue was caused by TP fill and background defaulting to the same color, making an empty bar look full. Future pass should set safer default bar background colors, such as a dark gray `#414141F2`, for any bar whose fill and background can accidentally match.
- Bar settings todo: check bar border settings. Some bars appear to have old-Libra borders, but border controls may be missing or inconsistent in current settings.
- Fixed: Libra name outlines looked like black drips/feet on small world plates, especially green trust names such as Koru-Moru. The failed backing-box attempt was removed. Final fix: Name widgets with outline size `0-2` use the normal GDI outline path; Name widgets with outline size above `2`, such as Lila's `5`, draw text-shaped outline copies around the clean name instead of using a giant GDI outline. This keeps readability without brown boxes or dripping.
- Bug: Self Quick Menu is drawing on the wrong layer/z-order and can appear behind the Self plate/name/bars. Seen on Self; not seen on Trusts so far. Need test whether PC/NPC/Object quick menus have the same layering issue before fixing broadly.
- Self Buffs/Debuffs todo: live Self buffs/debuffs can appear and work, but the settings preview does not show them. Add them to Self World/Tactical preview like PC where appropriate.
- Target/Subtarget placement bug: Plates > Self/PC/Trust/etc. > World/Tactical Target/Subtarget arrow Position X/Y still did not visibly affect live arrows in testing. Check whether modules/settings scoping is still coupled or overwritten by Target/Subtarget module placement logic.
- Native targeting test note: if native targeting and Libra target modules are both forced visible during diagnostics, duplicate arrows are expected because native and Libra arrows are both visible. Normal settings should avoid this by switching between the native targeting system and Libra's replacement.
- CatsEye data labeling rule: use `type` as player-facing identification. For event pages, prefer the specific event name such as `Holiday Event`, `Halloween Event`, `Easter Event`, or `Colossal Clamming Competition` over vague labels like `Seasonal Event`.
- CatsEye source pages can mention non-CatsEye/native NPCs that are only involved in CatsEye quests or events. Do not put those in `catseye_npc_icons.lua` just because the page mentions them. Put native/event-involved NPCs in `npc_icons.lua` with exact zone scoping and the player-facing event/quest type.

### 2026-06-04

- PC/Player Peer first pass: Plates > PC > World/Tactical now exposes `Peer (module)`. Preview uses the compact player layout: name + distance, HP, optional linkshell/mode rows, and optional target row. Runtime opens from PC plate hover and uses nearby-player data for name/distance/HP, linkshell color presence for the linkshell row, game mode (`CW`/`ACE`/`WEW`/`UCW`) for Mode, and a conservative target-name lookup that hides the row when unavailable.
- Self Peer first pass: Plates > Self > World/Tactical now exposes `Peer (module)`. The preview uses a character-stat panel, and runtime Shift-hover on the Self plate reads live player job levels, stats/modifiers, attack/defense, and elemental resists from Ashita player/party memory. This is a Plates widget path, not a Modules-tab option.

### 2026-06-02

- Background/highlight conditional display idea: add "show only on..." conditions for Background/Highlight style visuals, so a background or highlight can appear only for specific states/events such as Target, Subtarget, combat/tactical, aggro, low HP/MP, enmity warnings, or other alert conditions. This should be a reusable conditional system instead of hardcoding one-off background behavior into each widget.
- PUP Maneuvers timer formatting: maneuver timer labels should stay as plain seconds numbers under each socket, with no suffix/background box; examples are `71`, `84`, `43`, `56`.
- PUP/Automaton pet pass: old addon PUP source was checked. Current addon now detects own PUP automaton through `PetTargetIndex`, queues a tactical `Automaton` plate, and uses existing Automaton settings for Background, Name, Distance, HP Bar, MP Bar, TP Bar, Enmity, and Target. Added the `Maneuvers` widget using player status icons 299-307: Overload uses `overload.png`, active maneuvers use Fire/Ice/Wind/Earth/Thunder/Water/Light/Dark icons, and empty slots use `empty.png`. Maneuver icons live in `assets/images/maneuvers/default`; preview and settings are wired under Plates > Pet (PUP) > Automaton > Maneuvers.

### 2026-05-30

- Crafting module first rebuilt pass: old-addon source was checked for `core\crafting_result.lua`. Crafting result is packet-driven, not chat-driven: incoming packet `0x0030` for the player maps animation `0` to Normal Quality, `1` to Break, and `2/3/4` to High-Quality; packet `0x006F` clears the active result. Current addon uses Self Idle layout as the base, overlays the result as Icon or Text, and stores icons in `assets/images/crafting` as `craft_01.png`, `craft_02.png`, and `craft_03.png`.
- Peer module settings started: Modules > Peer now exposes shared behavior settings for modifier key, max range, and one simple fixed Zoom slider. The earlier min/max/per-yalm zoom settings were too confusing and removed from the UI. Existing Peer behavior reads these settings from `global.peer`. Enabled/disabled remains a per-plate concern, not a Peer module setting. Current Peer coverage is Self, PC, and Enemy; NPC/Object is intentionally skipped in favor of Quick Menu.
- Done: NPC/Object fallback behavior is now covered. Unknown NPCs and objects should still show name/target marker behavior without requiring curated icon/info data.
- Enemy Peer content options added in Modules > Peer: Job, Level, Range, Aggro/passive, Detection/link, Immunities, Damage modifiers, and Modifier values. Enemy Peer uses these to decide which mobdb info appears in the expanded inspect row and whether the distance badge remains visible while Peer is open; the normal plate still supplies name, HP bar/percent, and other current plate widgets. Modifier value text has Peer-specific font size, color, outline color, and outline size controls.
- Peer enemy info UI direction changed from a long checkbox pile to a component dropdown. Modules > Peer > Enemy info component now selects Background, Name, HP bar, Job, Level, Range, ID, Aggro/passive, Detection/link, Immunities, or Damage modifiers; the selected component shows its Active toggle and its own X/Y plus font, background, bar, or icon-size controls. ID owns its optional box controls; HP bar owns HP percent controls; Damage modifiers owns the separate Modifier values controls under the same selected component.
- Peer todo: add/show passive vs aggressive info clearly in Enemy Peer. Lila noticed this info is missing from the current Peer display.
- Peer preview wiring: selecting Modules > Peer or Plates > Enemy > Idle/Combat > Peer (module) renders sample Enemy Peer info using the same global Peer settings as live Enemy Peer. Plates > Self > World/Tactical > Peer renders the Self stat panel preview, and Plates > PC > World/Tactical > Peer renders the compact Player Peer preview. NPC/Object Peer is intentionally skipped in favor of Quick Menu.
- Peer preview click-through to settings: clicking Peer preview elements now selects the matching Peer component in the dropdown. Background -> Background, HP bar/percent -> HP bar, Job -> Job, Level -> Level, Range -> Range, aggro icon -> Aggro/passive, detection icons -> Detection/link, immunity icons -> Immunities, and modifier icons/values -> Damage modifiers.
- Peer icon asset todo: upscale/clean Peer icon packs, especially the currently used `round`/mobdb-style enemy info icons, so they remain crisp at the in-game Peer display sizes. Target practical export size is likely 64x64 PNG with real alpha, consistent filenames, and simple high-contrast shapes.
- Future preview interaction idea: look into different cursor pointers for preview interactions, such as hover/select/move cursors. This should pair with a possible drag-to-position prototype, first for Peer preview components and later for general preview widgets if it feels good.
- Peer preview drag prototype: preview now has a `Drag` toggle beside the zoom selector. When enabled in Peer preview, dragging Peer elements updates that component's X/Y settings directly. Current scope is Peer only: Background, Name, HP bar, Job, Level, Range, Aggro/passive, Detection/link, Immunities, and Damage modifiers. If it feels good, generalize to normal preview widgets later.
- Background settings layout direction: make one polished background editor pattern and reuse it everywhere. Desired order is Width/Height, Position X/Y, then Fill color + Opacity on one row, then Border color + Border size on one row. Applied to Peer > Background and the shared normal plate Background editor.
- Peer Job component layout direction: Peer > Job uses compact paired rows. Display is a dropdown; Icon theme appears on the same row only when Icon display is selected; Position X/Y share one row; Icon mode shows Icon size and live/preview Peer renders the selected job icon; Text mode shows font size/color and outline settings. A similar shared normal Job editor pass was started too, but current testing focus remains Peer.
- Peer Level component now includes difficulty font colors in the Peer style: Use difficulty font colors toggle plus TW/EP/DC/EM/T/VT/IT color rows. Live Enemy Peer colors Level from mob level versus viewer level; preview uses the T color as the sample.
- Enmity module now follows the old addon Healer/Tank behavior while staying icon-only for now. The icon asset lives at `assets/images/enmity_icon.png`; Modules > Enmity exposes Active, Mode, Position X/Y, and Icon size. Healer mode marks the ally plate currently targeted by an enemy; Tank mode marks the enemy currently targeting self. Do not put background/highlight controls in Enmity yet; make those part of the future reusable highlight/effect system.
- Resting module first rebuilt pass: live Self now treats entity `Status == 33` as Resting, keeps the regular Self layout sourced from Idle, and overlays a Resting tick bar from `global.resting`. Discord research says perfect accuracy is not possible from normal client state because rest gains are delivered on imperfect server update ticks. The tracker now syncs only from meaningful MP jumps (`mpTickThreshold`, default 12), not HP, because cures/regen can fake HP ticks. If the expected tick is late, the bar waits at `0s`; once the MP jump arrives, the next cycle is shortened by the overrun. At full MP it falls back to normal timer wrapping.
- Fishing module first rebuilt pass: old addon only had an empty `ui/widgets/fishing.lua`; useful source was the old Self module mapping plus worksheet status IDs. Current module treats statuses 38-43, 50-53, and 56-62 as Fishing, reuses the Self Idle layout as the base, and listens for fishing gut-feeling chat lines. Result mapping: didn't catch anything -> `fishing_00.png` + `You didn't catch anything`; good feeling -> `fishing_01.png` + `Easy catch`; don't know enough skill -> `fishing_02.png` + `Moderate catch`; fairly sure -> `fishing_03.png` + `Hard catch`; positive not enough -> `fishing_04.png` + `Very difficult catch`; bad feeling -> `fishing_05.png` + `Extreme catch`; terrible feeling -> `fishing_06.png` + `Dangerous catch`. These images are separate result icons, not animation frames, and live in `assets/images/fishing`. Settings live in Modules > Fishing and Plates > Self > Idle > Fishing (module).
- Enemy Peer icon packs live under `assets/images/peer-icons`: Lila's circular icon pack is named `round`, and the square/original mobdb pack is named `mobdb`. Modules > Peer exposes icon style, icon size, and icon X/Y controls for the enemy info row. Runtime now loads Peer icons from the selected local pack instead of any old-addon temp icon folder.
- Enemy plate Peer setting added: Enemy > Idle/Combat now lists `Peer (module)` with an Active toggle. Enemy runtime checks the Peer plate setting before opening the existing Peer/old-Libra hover view.
- Settings UI direction: reset actions should live at the bottom of each settings panel like the existing "Reset X position/settings" pattern, but Lila prefers actual buttons over yellow text links. Preserve the modal/dimmed confirmation behavior. First cleanup done in Plates > Target/Subtarget placement by removing the top "Reset placement nudges" button and adding bottom reset-position/settings buttons with confirmation. Follow-up pass should convert the remaining yellow reset links to bottom buttons without changing their behavior.
- Focus pivot: prioritize getting all settings represented for all entities/states before continuing deep native-position investigations. First low-risk slice completed: PC settings now expose Background and Distance; NPC/Object settings now expose Subtarget module; live PC and NPC/Object plates now consume Background and Distance settings; settings preview shows Distance for PC/NPC/Object as well as Enemy.
- Fixed likely cause of Avatar Target module not working: `modules.target_overlay` now recognizes the player's own SMN pet as `Pet (SMN)` and chooses `Avatar` or `Spirit` layout state before reading Target/Subtarget module settings. After reload, target Titan/avatar and use `/lp targetdebug`; expected debug should include `entity=Pet (SMN) layout=Avatar`.
- Target/Subtarget settings UI cleanup: the Modules tab still contains Target/Subtarget and owns broader options such as Auto place plus info/tooltips. Plates > entity > state > Target/Subtarget should be focused on placement and should not repeat the same Auto place controls. The Target/Subtarget placement drawer uses paired slider rows for Position X/Y and Width/Height like the approved BST-style controls. This changes editor layout only; it does not mutate saved `rebuild_profile.lua` values or force-copy the approved BST visual values into every entity/state.
- Future highlight/background system idea: look into making reusable highlight/background visuals that can be assigned to certain states or warnings, such as aggro, low HP, and other alert conditions. This should probably fit into the broader all-entities/all-states settings pass rather than being hardcoded per widget.
- Current transition terminology: `World Context` means true 3D world-marker plates drawn in `core.world_marker_probe`; `Tactical Context` / `important overlay` / `always-visible plates` means the 2D overlay path drawn by `modules.target_overlay` from `worldMarkerProbe.GetAlwaysVisiblePlates()`. In code, tactical plates are generally marked with `plateAlwaysOnTop = true` and `plateTacticalOverlayOnly = true`.
- Todo: add a setting to disable right-click enemy attack while mounted. Mounted right-clicks should not accidentally try to attack from LibraPlates when Lila is riding.
- Done: live-tested Self quick menu trust toggles around other players' trusts. `Ignore Other Trusts`, `Hide Other Trusts`, and `Emote Trust` command/state sync works correctly.
- Done: after stabilization, removed temporary Self Quick Menu toggle chat spam.
- Todo: add out-of-range HP bar color settings for PC and Enemy plates so active-detail/range-limited plates can communicate that their HP display is out of live detail range instead of normal live HP.
- Bug: Trust plate settings are not taking effect live. Settings UI exposes Trust > World and Trust > Tactical widget toggles such as Name, HP Bar, MP Bar, TP Bar, Quick Menu, Enmity, Target, and Subtarget, but in-game trust plates continue showing/hiding elements inconsistently with those settings. Need inspect trust render path and verify whether it reads Trust World/Tactical settings or uses PC/party defaults/hardcoded tactical layout.
- Current tactical/overlay entities confirmed in code: Self tactical/overlay behavior is not controlled by the removed `importantOverlaySelf` setting; engaged enemies can use the extra engaged-enemy overlay path when `importantOverlayEnabled` and `importantOverlayEngagedEnemies` are enabled; Trust plates are tactical; BST pet plates are tactical; SMN pet plates are tactical. Pet tactical anchors currently use `anchorBone = 12` and `plateWorldOffsetY = 0.16` while the global/default world anchor remains bone `2`. Titan testing lined the tactical canvas center up with the native name at this value.
- Current world-context entities still using normal world-marker behavior: PCs, NPCs, Objects, non-important enemies, and any plate not marked `plateTacticalOverlayOnly`. These still need review before any broad anchor or overlay changes.
- Not yet fully moved/finished in the tactical/world transition: party/alliance players, party/alliance trusts beyond the current trust path, party/alliance pets, non-party pets/trusts, PUP automaton, DRG wyvern, and future SMN Spirit/Avatar edge cases should each be checked deliberately so no entity family is forgotten. Party/alliance member pets are specifically not tested yet and are not part of the current BST/SMN pet tactical path, which only queues Lila's own pet from the player's `PetTargetIndex`.
- Native-hidden visibility rule is now always on and not user-toggleable. Confirmed with Ul'hpemde: when native name/targeting is hidden underwater, LibraPlates hides the plate and click rect too. Keep `/lp visdebug [target/pet/index]` for capturing more hidden patterns such as Chigoes or Shikigami Weapon.
- `/lp visdebug` now supports saved comparisons for Ul'xzomit large/small model-size testing after reload: target large and run `/lp visdebug save large`, target small and run `/lp visdebug save small`, then run `/lp visdebug compare large small`. The compare output includes changed regular fields and changed `af/ai/of/oi` offset candidates so scale/hitbox/attachment differences are easier to spot than in two full dumps.
- Sea fish caveat: if an Ul'hpemde/fish mob is already underwater when LibraPlates first sees it, and Lila did not witness the dive transition, the Libra plate can start above water instead of hidden. If Lila sees the mob dive/go under, the plate hides properly afterward. Need to detect the initial underwater/native-hidden state too, not only the observed transition state.
- Canvas debug command exists for alignment testing: `/lp canvasdebug on/off`. Because tactical pets draw through `modules.target_overlay`, the debug rectangle/center marker must be visible in the overlay path, not only in the 3D world-marker draw path.
- Future tactical overlay setting idea: when an in-view tactical entity is still visible but its plate would be offscreen, optionally adjust/clamp the plate back into view. This should apply to tactical/important entities only and should not imply drawing plates for entities that are not visible/native-hidden.
- Need to implement enmity support for pet plates later.

### 2026-05-28

- BST pet old-addon source of truth checked in the old addon files `ui\plates\player.lua`, `ui\settings\player_settings.lua`, `LibraPlates.lua`, and `data\pet_durations.lua`. `Pet (BST)` states are `Charmed Pet` and `Jug Pet`; Charmed widgets: Background, Name, Distance, HP bar, TP bar, Sic; Jug widgets: Background, Name, Distance, HP bar, TP bar, Ready bar, Reward, Pet timer. Draw defaults include Name X -38/Y -34, Distance X 66/Y -52, HP X 0/Y -16, TP X 0/Y 4, Ready/Sic Y 28, Reward Y 52, Pet timer X -52/Y -52.
- TP bar old-addon source of truth checked in the old addon files `ui\bars.lua` and `ui\settings\self_settings.lua`: TP should render as three separate progress-bar sections, not one outer bar with dividers. Old defaults/settings include X, Y, width, height, three section colors, fill texture/style, background color, border size/color, show TP value, show TP percent, text X/Y, text font size/color, show at TP, text outline toggle/size/color.
- Trust vitals reintroduction step 1: `core/entities.lua` now restores only the current HP value for party trust slots via `party:GetMemberHP(slot)`, cached per slot for 0.5s. Trust MaxHP, HPPercent party read, MP, MaxMP, MPPercent, and TP remain disabled; HP percent still comes from the entity. Test this slice in Ashita before adding the next party read group.
- New rendering model direction: split entities into World Context and Tactical Context. Tactical Context lives in the 2D overlay path and includes enemies engaged with the player/party/alliance, party/alliance players, party/alliance trusts, and party/alliance pets. World Context lives in 3D world plates and includes NPCs, items/objects, other players, non-party trusts/pets, and enemies not engaged with the player/party/alliance.
- Terminology direction: normal `Background` means the functional/readability plate background. `Highlight` means decorative target/subtarget image/effect, usually a transparent-center glow/frame. Large full-fill highlights are visually risky in 2D because they sit over the 3D scene.
- Future settings UI direction: eventually reshape settings around World Plates vs Tactical Plates, with Target/Subtarget indicators as selection UI. Do runtime behavior first, then UI cleanup later.
- Future bug: some underwater/surfacing enemies show LibraPlates while the native name is hidden underwater, and after the model rises the Libra plate can remain anchored below the water. Likely needs a native-name visibility check or a better actor/nameplate anchor for special surfacing mobs.

### 2026-05-27

- Target/Subtarget arrow settings cleanup: the arrow model is now Arrow image plus optional Animate. Pulse was removed. Animate only appears for images with matching animation frames such as `arrow_classic_01.png`, and Animation speed controls the frame rate. Static normal arrows were renamed to one-digit names such as `arrow_1.png`. Removed unused `assets\images\target\arrow-animations`.
- Arrow animation naming rule updated: static arrows should use a one-digit suffix such as `arrow_1.png`, `arrow_2.png`; animated frame sets use a two-digit suffix such as `arrow_01.png`, `arrow_02.png`, `arrow_03.png`. The old hardcoded `arrow_` exception was removed.
- Plates > entity > state > Target/Subtarget (module) placement now has separate active headers for Background, Arrow, and Chevrons, with X/Y first and slider-style value controls with `-`/`+` nudges. Background and Chevrons auto-place still allow X/Y nudging; active toggles are render-backed. The shared Modules tab editor should stay on its normal full settings layout.
- Crash safety note: Ashita crashed after experimenting with preview-only Target Module foreground reordering and background-frame chevron anchoring in `core/canvas_texture.lua` plus preview name-width measurement in `modules/settings/preview.lua`. Those experiments were reverted. Do not retry that approach without isolating it outside the live canvas render path.
- Testing Self plate lag-behind: current-frame bone pass-through and Self-only exact/nameplate-helper anchor both made no visible difference, so the lag is probably not the chosen anchor. The remaining likely cause is world-marker render timing/space versus the native/game marker pass.
- Self plate lag diagnostic result: 2D foreground drawing follows movement correctly, but is not usable because it is no longer a true 3D/world plate and does not depth-hide or distance-scale properly. Reverted the 2D diagnostic; focus should stay on fixing `world_marker_probe` timing/3D draw behavior.
- Reverted timing test immediately: moving world plate queueing into `d3d_beginscene` corrupted the scene/water render state when the addon was disabled/reloaded. Keep queue/reset in `d3d_present`; do not repeat this approach without much stricter render-state isolation.
- Reverted timing test 2: drawing world markers in `d3d_present` made the plate behave like a 2D overlay. Keep actual world-marker drawing in `d3d_beginscene`.
- Leaving Self plate lag-behind alone for now. Current safe behavior is restored: `d3d_present` resets/queues plates and `d3d_beginscene` draws world markers. Tests that did not solve it: current-frame bone anchor pass-through, Self-only exact/nameplate-helper anchor, 2D foreground diagnostic, queueing in `d3d_beginscene`, and drawing world markers in `d3d_present`. Future work should inspect `world_marker_probe.DrawQueued()`/two-pass draw behavior without changing D3D event phase.
- Completed: Target/Subtarget module preview now supports positioning arrows, chevrons, and background in settings, so the old note about disabled 2D arrows/chevrons needing a proper preview is resolved.
- Modules tab now uses the same left selector plus preview/settings split as Plates, so Target/Subtarget module edits can be previewed for the selected entity/state before applying live.

### 2026-05-26

- Enemy live castbar was wired from the old addon behavior instead of guessing: packet `0x0028`, action type `8` starts a spell cast from the first target action param, action types `4`/`11` clear it, and zoning clears all casts. The castbar uses Enemy > Combat > Cast bar settings.
- Text size/font size settings were normalized. Settings now use visual-size numbers `6`-`24`, while rendering converts them to the larger texture font sizes needed for world plates. Old saved raw values above `24` still render at their old size and normalize when edited. Live enemy plates no longer switch the whole Name/HP layout to Combat while engaged; Combat currently owns the castbar only.
- Fixed settings preview cropping: Enemy preview no longer secretly adds extra zoom. Zoom now enlarges the rendered nameplate inside the preview instead of only zooming the background image or changing widget sizes.
- Enemy Job settings now mirror the old addon: Display Text/Icon, Icon theme FFXI/FFXIV/Classic, Icon size, Text size/color/outline, and X/Y position. Enemy plates read the mobdb Job value and render the job text/icon when enabled.
- Removed the unrequested Enemy plate limit. Plate eligibility is controlled by range; active code no longer count-limits enemy, player, NPC, or object plates.
- Added a model/skeleton readiness guard so character plates do not briefly draw names at floor level before the character model finishes loading.
- Mounted characters use FFXI status `85`; self/player plates get an extra vertical lift while mounted so plates clear the mount/rider body.
- Enemy Level now has a dedicated old-addon-style settings panel: position, text size/color/outline, and optional TW/EP/DC/EM/T/VT/IT difficulty font colors. The drawn square/rounded background box belongs to Enemy ID instead of Level.
- Enemy Name also has optional old-addon TW/EP/DC/EM/T/VT/IT difficulty font colors. The live enemy renderer colors Name and Level font/text from mob level versus the player's level when each widget's toggle is enabled.
- Enemy ID shows only the last two digits and uses no prefix unless Lila explicitly asks for one.
- Enemy ID has a Use small font option.
- Enemy ID box has optional level-difficulty box colors.
- Enemy Distance now renders on live Enemy > Idle plates and in the settings preview when enabled.
- Enemy Background now renders behind live Enemy plates and in the settings preview when enabled.
- Enemy > Combat should only expose Cast bar. The base enemy plate layout comes from Enemy > Idle so Combat settings do not stack a second plate on top.
- Enemy settings panel now has editors for Background, Job, Level, Distance, HP Bar, Cast bar, Buffs, Debuffs, ID, Target module, and Subtarget module. Cast bar is only listed under Enemy > Combat. Cast bar settings were cleaned up to remove generic HP-style value/percent/behavior/low-color controls and keep spell-name controls. Some settings are UI/profile-ready before the live enemy renderer consumes them.
- Native target arrow suppression attempt 2 was revised to use the exact `FFXiMain.dll` form from the `hideparty.lua` snippet Lila found. Test with `/addon reload LibraPlates`, then `/lp nativearrow status`. If `targetPtr=0x0`, the pointer was not found. If the pointer is non-zero but the native triangle still shows, the hideparty target primitive is not the arrow primitive on this build/timing.
- Native target arrow suppression attempt 1 using entity `Render.Flags2` bit `0x08` did not hide the native target triangle. That failed entity-flag command path was removed; keep `/lp nativearrow status` only for pointer diagnostics.
- Native target arrow suppression attempt 2 uses the `hideparty.lua` target UI primitive pointer and visibility bytes `+0x69/+0x6A`. This may also hide the bottom-right native target UI because the Discord notes say the arrow is attached to / rendered with the target window.
- Native arrow first-target flash fix: the working path is Lua timing, not DAT replacement. XIPivot tests against `ROM\119\51.DAT` (`anc`/`btwait` and all `3TXD` payloads) did not affect the white flash. The flash stopped when `modules.UpdateNativeTargetArrow()` was changed to run `nativeTargetArrow.Update()` early whenever `hideNativePartyTargetUi` is enabled, matching the hideparty-style setting before the normal render pass.
- `customtarget.lua` only draws an additional custom cursor using target index + world-to-screen math. It does not include a native-hide method.
- Corrected overlay suppression: Target/Subtarget overlay should hide for map/event/interface-hidden states, but not merely because the LibraPlates settings UI is open. While LibraPlates settings are open, broad event/interface-hidden flags are ignored and only the map menu still suppresses it. Added `/lp overlaystatus` for debugging this.
- Added a settings preview path for Target/Subtarget module arrows, chevrons, and background. This is meant to let positioning be checked in the preview panel instead of disabling the live overlay while settings are open.
- Shared notes file created.
