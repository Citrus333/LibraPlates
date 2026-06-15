# LibraPlates Shared Notes

This file is for shared testing notes between Lila, her husband, and Codex.

## Hard Rules

- LibraPlates must not read from, require, depend on, or assume files from any other installed addon folder at runtime. Bundled/imported assets are allowed only when they are copied into the LibraPlates folder and become LibraPlates-owned files.

## Reference

- Good restore point: `C:\catseyexi\catseyexi-client\Ashita\addons\LibraPlates\_rollback_safety_20260526-141407-perfect-engaged-overlay`.
- Do not broad rollback.
- Do not copy a whole old addon over the current one.
- Keep code changes small.
- Do not guess settings/options when requirements are unclear. Ask Lila first.
- Do not mutate `C:\catseyexi\catseyexi-client\Ashita\config\addons\LibraPlates\rebuild_profile.lua` unless Lila explicitly approves it.
- If two people are testing, only one person should edit addon code at a time.

## To DO

### Priority

- Luopan status icons: `core\luopan_statuses.lua` tracks own GEO job ability ids `346` Lasting Emanation as status `515`, `347` Ecliptic Attrition as status `516`, and `351` Dematerialize as status `518`. `modules\plates\pet.lua` renders these through `Luopan > Luopan > Buffs`. Lasting/Ecliptic use a provisional 300s display window because the job ability entries do not include durations. Probe command: `/lp luopanprobe on [seconds] | off | status` logs matching action packets for ability ids `346/347/351` and status action params `515/516/518`.
- Clean action queue logging format and remove duplicate spam before any logic changes.
- Keep `/st` range queue/packet parsing disabled until stability checks are green.
- Only next: rework action-range parsing if still needed.

### General / Settings

- Help tab: now uses a side menu with `User Guide`, `Find Settings`, and `Troubleshooter`. Find Settings combines curated entries with generated Plate widget entries and `Go` buttons. Troubleshooter has starter checklists and player-language synonyms such as enmity/hate/threat/aggro, AOE/radius/circle, and performance/fps/lag.
- Help follow-up: expand User Guide and Troubleshooter over time with exact row-level anchors, more synonyms, and common "why is X not showing/working?" cases as they come up in testing.
- Settings UI: `Modules` tab is hidden for now. Module code/settings remain in place, but user-facing access should happen through `Plates` contexts and Help search. Follow-up: remove the unused Modules-tab code/settings path entirely once we confirm no unique settings still depend on it.
- Replace native mouse.
- Game mode is not reading properly.
- Warning screen color scheme is still red.
- Some widget-list names are blue.
- Settings reset bug: resetting widget settings/position does not appear to reset anchor settings (`anchorTo` / `anchorPoint`).
- Disable nameplate click-through when clicking game UI such as action bars, chat windows, or menus.
- Release packaging cleanup: do not ship old debug depth probe plugins (`LibraDepthProbe` / `LibraDepthProbestatus`) with the release package.

### Enemy

- Add Enemy cast bar settings.
- Enemy preview needs long/short name examples.
- Enemy level/difficulty follow-up: decide what level text/color should show for mobs that are effectively impossible to gauge normally.
- Claim state color settings follow-up: add outline color controls for each Enemy claim state.
- Blood aggro icon is not showing; likely hidden underneath the links icon due to an anchoring/overlap issue.
- Catseye special native star icon is 99% done: Enemy plates replace the native special marker with the Catseye star across World/Target/Subtarget/Tactical states, with Enemy World/Tactical Special icon settings for size and X/Y placement. Needs more testing in other zones. Preview wiring still needs to be added later.
- Catseye special icon preview todo: add Special icon display/positioning to the Enemy settings preview so size and X/Y changes can be checked without live mobs.
- Enmity is currently in Enemy; find a better spot, possibly profile-dependent for Enemy vs Self.
- Move aggro.
- Blue magic is missing casting icons and is not showing AOE.

### NPC / Object

- NPC needs target/subtarget highlight settings; check whether Subtarget has range colors.
- NPC/Object targeting bug: husband saw a black billboard flashing over targeted NPCs while Settings was open; likely related to target marker background/canvas state or preview/settings interaction.
- NPC nameplate height idea: investigate race/model-family based plate height adjustment so short NPCs and tall NPCs do not need one blunt global NPC Y offset.
- NPC/Object data direction: future zone-scoped loading should wait until data has full zone coverage, then load by zone on zone change with exact-name lookup and cached results.
- Add a setting for `???`/search objects to show or hide names.
- Fishing/gathering interaction needs field testing and a decision on Clamming Point, Fish Trap, and other fishing-related objects.

### PC / Player

- Level sync icon is missing, and player HP/MP values are not updating after sync/resync.
- Peer level should be color-correct to level.

### Self

- Self castbar improvement: manual movement interrupts now stop LP's own castbar early and can show the remaining lockout on the same castbar. Cast bar settings now include `Interrupt bar`, optional interrupt color, and optional interrupt text with separate font/outline/position controls. This is intentionally better than native, which keeps the castbar running until the late interrupt message.
- Resting/logout follow-up: shutdown/logout timer is too short and needs tuning.
- Move Resting out of the dropdown to its own setting and check the timer bug.
- Self Quick Menu idea: add party invite actions/state, including accepting an invite and showing/handling invite pending.
- DoH/DoL activity idea: add a ring timer for the cooldown before the player can fish, craft, or gather again.

### Pet / Trust

- Remove BST chat spam.
- Trust status icons follow-up: decide whether Trust debuffs should remain supported/shown, or whether Trust plates should only show Trust buffs.
- Bug: other players' pets can be treated like PC or NPC/Object plates by name, e.g. summoned Carbuncle/Fenrir showed the yellow type line `Cutscene/Summoned Avatar`, and the DRG wyvern name `Lumiere` still showed as a green plate. This is a pet plate/classification issue, not the NPCs with matching names.

### Buffs / Debuffs

- Make buff filtering input smarter for time values, possibly a two-digit field plus S/M/H selectors.
- Debuff timers need a dedicated cleanup/test pass after Buffs.
- Debuff growth direction should still be tested in-game.
- Mounted buff timer appears during zoning but disappears afterward.
- GEO and maybe other auras have `0` duration, which triggers buff time color warnings.

### Bars / Text / Preview

- Check all previews, especially text and growth direction display values such as HP vs `1200/2000`.
- HP / MP / TP bars should have a free-form text option in settings/preview so value display formats can be checked without relying on live data.
- Set TP bar color when TP is full.
- HP bar color/alpha when out of range.

### Targeting / Tactical

- Copy target/subtarget module is not working.
- Distance meter should only show on Target/Subtarget.
- Range arrow color only works out of combat.
- AOE range/highlight visuals should only trigger from the player's own AOE actions/casts, and should not false-trigger on queued single-target heals.
- AOE offensive preview testing model:
  - LP AOE style should mirror native enlarged names during active `<st>` spell selection; direct `<t>` casts should not create an LP-only helper preview.
  - Offensive AOE only highlights enemies. Self, players, trusts, and pets do not get offensive AOE styling even when inside the circle.
  - The `<st>` mob is always affected for target-centered offensive AOE and should get the AOE style; other enemies only highlight when inside that spell's AOE radius.
  - AOE style must visually beat Enemy tactical/Combat/Target/Subtarget styling. Offensive AOE style belongs in Enemy Tactical settings; Enemy runtime reads only Enemy Tactical AOE settings, so hidden Self/Enemy Idle AOE buckets cannot leak colors into in-range enemies.
  - AOE highlight background was removed from the feature path because it looks bad on world enemies. AOE styling now supports font color/size and optional icon only.
  - Enemy Tactical `AOE range (module)` preview now shows the AOE font size/color and optional icon. Icon X/Y controls are exposed when `Show icon` is enabled.
  - Defensive/friendly AOE styling uses `Self > Tactical > AOE range (module)` for Self/PC/Trust plates. This row is visible again and previews the friendly plate/icon instead of the Enemy offensive preview.
  - Defensive AOE classification now also checks the active subtarget kind, so friendly-target casts such as Curaga stay on the friendly AOE path even if resource target flags look enemy-like.
  - Settings cleanup: offensive AOE range styling should not be configured from Self World/Tactical/Resting/Fishing/Crafting; those lists no longer show `AOE range (module)`.
  - Source rules to verify per spell/job: Black Magic -ga/Poisonga source is the `<st>` mob; Blue Magic offensive AOE source is self; pet BP/ability AOE source is pet; GEO Indi aura source is self/player and moves with the GEO.
  - Pet BP/ability AOE center lookup now uses the shared own-pet resolver and logs `centerMode`/`pet` in `/lp aoedebug`, so SMN tests can confirm whether LP is centering on the pet or falling back to the selected target.
  - SMN BP debug now also logs selected-target distance from the AOE center and prioritizes enemies in the nearby list; current Thunderspark test reported `centerMode=pet`/`center=Ramuh`, but the visible blue circle may still be the native game helper.
  - Subtarget range-arrow colors for loaded AOE spells should use the action's target/cast range, not the AOE radius. `target_module_marker` now falls back to the live AOE action target range when the normal queued action-range path has no value.
  - Candidate testing list from Lila: BLM true offensive AOE is the -ga line; WHM has Banishga/Banishga II; BLU has many self-centered offensive/status AOEs such as Sheep Song, Soporific, Yawn, Blastbomb, Grand Slam, Frypan, Maelstrom, Bomb Toss, Ice Break, Temporal Shift, Radiant Breath, Cold Wave, Corrosive Ooze; SMN needs BP/source testing such as Thunderspark and avatar AOEs; GEO enemy-affecting aura tests include Geo-Poison (5), Geo-Slow (52), Geo-Torpor (56), Geo-Slip (62), Geo-Languor (68), Geo-Paralysis (72), and Geo-Vex (74).
  - Pet-job AOE testing matrix from Lila: SMN Astral Flow AoEs include Searing Light, Howling Moon, Inferno, Earthen Fury, Tidal Wave, Aerial Blast, Diamond Dust, Judgment Bolt, Ruinous Omen, and Zantetsuken (75); regular SMN BP AoEs include Thunderspark, Sleepga, Lunar Cry, Somnolence, Nightmare, and possibly Meteorite depending on server behavior, while Nether Blast is not AoE.
  - BST AOE depends on pet/jug family; candidates include Sheep Song, Scream, Whirl Claws, Cursed Sphere, Seed Spray, and Spinning Top, while moves such as Power Attack are single target.
  - PUP AOE is mainly automaton spell behavior: Stormwaker -ga spells and Soulsoother Banishga; exact list depends on head/frame/attachments.
  - DRG wyvern breaths are generally single-target/cone style rather than true farming AoE, so DRG is low priority for LP AOE preview testing.
- Target/Subtarget module settings seem to be Enemy settings applying to all entity types.
- Target/Subtarget module ownership is not resolved. Do not remove Target/Subtarget from the Modules tab without Lila explicitly approving that direction.
- Lock-on icon anchoring/scoping needs review; keep future cleanup focused on Enemy-only scope unless Lila approves broader entity behavior.

### Profiles

- Continue profile work.

### Quick Menu / Mog House

- Quick Menu needs size settings or flexible sizing depending on visible selections.
- Mog House should have a different Quick Menu on the Moogle with handy actions such as job change.

### Peer

- Enemy Peer / MobDB icon follow-up: check whether any MobDB-style enemy info icons are still missing.
- Peer follow-up: consider whether Peer should also support Objects, not only Self / PC / Enemy.

### Performance / Debug

- Performance bug report: lag feels like it gets worse over time while staying in the same area; investigate as possible accumulation/leak behavior.
- Runtime lag diagnostic: PC plates dominated latest sample; investigate PC plate path/caching first if lag remains bad.
- DirectX wrapper clue: Atom0s DX9 wrapper z-fighting fix greatly reduces LibraPlates lag, but makes Ashita addons click-through.
- Accessibility/testing workflow: use `/lp lag` as the short one-command lag diagnostic.
- Idle texture eviction follow-up: if `Evictions/min` climbs with low `Used` count, check for same-key canvas size churn or repeated plate-cache clears before chasing visible plate count.
- Husband subtarget report `20260614-142652` showed `canvasRenders=0` but high `Evictions/min` with only `33/96` textures used; this was cleanup accounting from released plate-cache keys, not real cache pressure. `canvasTexture.ReleaseKey()` no longer counts manual plate-cache releases as texture evictions; only cache-limit trims do.
- FPS mode setting follow-up: direct FPS divisor memory write caused an Ashita crash when it was attempted during load, so FPS mode must only be applied from an explicit user action.
- FPS mode UI now gives a short chat confirmation when the saved FPS setting is changed, and Check only updates the Current mode text without changing the selected setting.
- Performance settings follow-up: wire `World plate update rate` and `Disable expensive widgets on world plates` to actual world-only throttling/preset behavior after in-game testing confirms the new Performance page layout.
- Plate stacking follow-up: the world-marker stacking movement path was removed after it lifted plates into the sky. Do not convert 2D stack deltas back into world Y. The old `Nameplates` addon stacks only because it draws final plates in 2D ImGui windows using `baseX/baseY/drawX/drawY`.

## Done

- 2026-06-15 - Status icon theme cleanup:
  - Settings `Font` is now `Theme`, and status icons have one global `Status icon pack` there instead of separate Buff/Debuff pack dropdowns on every plate.
  - The visible status pack list is local pack based (`HD`, `Tetsouou`, `xiPrime`, `XIView` when present); `Native` remains only an internal fallback path.
  - Castbar spell icons now use LibraPlates-owned `data\spell_status_ids.lua` before falling back to spell icons, so spells such as Protect/Shell can render the same selected status-pack icon as the buff after the cast lands.
  - GEO/Indi cast fallback now resolves through the same global status pack, and `assets\images\geo-statuses` is reserved for Luopan preview art instead of duplicate numbered status icons.
- 2026-06-14 - Moved Resting settings to Self World:
  - `Resting (module)` is now listed under `Self > World` instead of the separate Self Resting plate dropdown.
  - Live resting still detects player status `33`, but uses the Self World layout and adds the Resting module overlay instead of reading a separate Resting plate layout.
- 2026-06-15 - Resting tick timer first-cycle sync:
  - Resting displays the normal first 20s countdown, but if the first meaningful HP/MP gain is observed early/late it immediately starts the 10s repeat countdown from that observed tick.
  - Removed the `First offset` setting because the first cycle is now data-synced instead of guessed; `Repeat offset` remains for small post-sync tuning.
  - When both `Hide at full HP` and `Hide at full MP` are checked, Resting hides only when both are full. If only one is checked, that single condition still hides it.
- 2026-06-14 - Removed abandoned Enemy Name difficulty colors:
  - Enemy World/Tactical Name settings no longer show the old `Difficulty font colors` block.
  - Name defaults and Enemy name rendering no longer use Name difficulty color keys; Level difficulty colors remain unchanged.
- 2026-06-14 - Target/Subtarget ownership moved out of World:
  - Self, PC, Enemy, and Trust World settings no longer list Target/Subtarget module rows.
  - NPC/Object keep Target/Subtarget module rows inside the single visible World plate list, but those rows edit hidden Combat/Tactical storage.
  - NPC/Object do not expose a Tactical or Targeted plate dropdown state.
  - Target/Subtarget module lookup is forced through Tactical/Combat for those normal entity types, so targeting an idle/world plate no longer reads World target settings.
  - Removed the temporary Self target-module fallback between World and Tactical because it could crosswire settings.
  - Native target UI hide hooks are primed again when native target hiding is enabled so the old first-target native arrow flash should stay suppressed.
- 2026-06-14 - NPC/staff capture output moved out of the live addon folder:
  - `/lp` NPC missing capture and staff capture now write to `C:\Users\Lila\Documents\ffxi Addon Work\WORK` instead of the removed `TEMP WORK FOLDER`.
- 2026-06-14 - Reduced no-target to target/subtarget native-hide freeze risk:
  - Cast tracking now clears/ignores interrupted-cast action messages, including observed `type=8 message=0` packets, instead of treating them as a fresh cast start; this is the first step before any separate interrupt recovery/donut indicator.
  - Aura-style self buffs whose memory timer resolves to zero/expired no longer draw permanent `0s`; status timer text is only drawn when the timer value is above zero.
  - The native target startup burst no longer hard-hides party primitives through the draw hook; the burst is target-primitive only.
  - The hard-hide draw hook is enabled while Libra replaces native party/target UI so keyboard targeting cannot show the native arrow for the first few milliseconds, but the hook now writes only the target primitive.
  - Target/Subtarget module markers are prewarmed one per frame after load/login so the first real `/st` should not pay every arrow/background/chevron texture setup cost at once.
  - Self Subtarget no longer uses or shows Subtarget range colors; Self distance is always 0, so runtime now skips action-range lookup for Self and uses the normal arrow tint.
- 2026-06-14 - Other-player pet plate filter added:
  - PC and NPC/Object scans now skip non-owned known pet names when `hideOtherPlayerPetPlates` is enabled, covering SMN avatars/spirits, observed wyvern names, and known BST jug pet names while leaving the player's own pet path intact.
  - Settings > Visibility now exposes this as `Hide other players' pet plates`, default on.
- 2026-06-14 - Moved oversized backup/work artifacts out of the live addon folder:
  - `TEMP WORK FOLDER` and `LibraPlates.rar` were moved to `C:\Users\Lila\Documents\ffxi Addon Work\_LibraPlates_large_files_removed_20260614` so launcher/game backup creation does not scan roughly 20 GB of non-runtime files.
- 2026-06-14 - Moved old Libra backup/reference folders out of `Ashita\addons`:
  - `LibraPlates-last` and `Libra Backups` were moved to `C:\Users\Lila\Documents\ffxi Addon Work\_Ashita_addons_backup_folders_20260614`, removing another roughly 8.8 GB from the launcher backup scan path.
- 2026-06-13 - Performance settings page added:
  - Settings now has a dedicated Performance page after Scaling.
  - Performance monitor can be shown/hidden from settings and now has a compact overlay mode plus optional detailed timing.
  - Performance page now starts with user-facing presets: Performance, Mid, High, Ultra, and Custom.
  - Performance page now includes a game FPS mode selector for `Keep current`, `FPS1 (60 FPS)`, and `FPS2 (30 FPS)`; when set, LibraPlates applies the FPS divisor on load without needing the separate fps addon.
  - Non-Custom performance presets apply the grouped world plate count, distance limit, update rate, adaptive mode, expensive-widget, and texture-cache settings; Custom reveals the individual controls.
  - World plate performance controls were added for max world plate count, update rate, distant world plate hiding, expensive world widget preset, and texture cache limit.
  - Max world plate count is wired at draw time with priority for Self, target, subtarget, and tactical plates before nearby world plates.
  - Hide distant world plates is wired into PC, Trust, Enemy, and NPC/Object world scans through an effective world plate range.
  - Texture cache limit is wired to the canvas texture cache and trims the cache when lowered.
  - Performance monitor now opens as a draggable ImGui window with a title-bar close button instead of a fixed foreground text block.
  - Texture cache display now shows current eviction pressure as `Evictions/min`; lifetime total evictions are only shown in detailed performance monitor mode.
  - Detailed performance monitor timing rows now use a sortable table; clicking Name, Avg, Peak, or Last changes the sort column and clicking again flips direction.
- 2026-06-13 - Scaling settings wired per entity:
  - Settings > Scaling per-entity distance scale rows now feed live Self, PC, Trust, Enemy, NPC, Object, and Pet plate queues instead of every live plate using the global PC distance scale.
  - Global plate position plus per-entity plate position rows now apply to live world marker offsets with small one-step nudges.
  - Global distance scaling now asks before applying to all entity distance rows, because applying global values overwrites individual entity distance scaling.
  - Entity distance rows are hidden behind `Custom entity distance scaling`; when custom mode is off, live plates use the global distance scaling values.
  - Scaling entity sections use the normal yellow section header style and order entity rows by practical importance: PC, Enemy, Trust, Pet, NPC, Object.
  - Scaling sliders now use compact label-first rows with `-`/`+` buttons, shorter bars, and value text drawn inside the bar; distance values use dot decimals.
  - Entity plate position rows are condensed to one line per entity: label plus X and Y controls on the same row.
- 2026-06-13 - Linkshell icon color restored:
  - Player and Self linkshell icons now read the live entity `LinkshellColor`, unpack it as BGR, expand XI-style low shell color channels, and pass that tint into canvas icon rendering using the old-addon linkshell mask behavior.
- 2026-06-13 - NPC/Object double target arrows fixed:
  - Unknown raw Objects that fall back to NPC behavior no longer draw a second target overlay arrow when a world plate already exists.
  - This keeps incomplete NPC/Object data rows from causing duplicate Libra target arrows while data entry is still in progress.
- 2026-06-13 - First-pass world plate stacking added:
  - Overlapping selected texture world plates now get a temporary upward lift before both click-rect generation and drawing, so mouse targeting should stay aligned with the moved plate.
  - Loading priority now has a practical fallback order after Self/target/subtarget/tactical: PC, Enemy, Trust, Pet, NPC, Object.
  - Settings > Visibility now has Plate stacking controls for enabling stacking, per-type participation, priority order, closest-on-top range stacking, tactical fixed behavior, stack spacing, and overlap sensitivity.
  - Settings > Visibility also has Tactical screen limits as an off-by-default option to keep Target/Subtarget/tactical marker plates from going above the top edge of the screen.
  - Stacking was reworked toward the old-addon behavior: plates are placed by screen position and only move when their actual rectangles overlap already placed plates. Stack gap is real pixel space, and horizontal/vertical overlap controls are pixel allowances instead of percentages. Follow-up PC crowd testing is still needed.
  - PC plate caching now includes the linkshell tint so color changes redraw instead of reusing an old white icon.
  - Plate render policy version was bumped so already-rendered dark linkshell plate textures are forced to refresh after reload.
  - Linkshell icon tint is brightened only for the linkshell icon render path because the gray shell PNG is multiplied by the tint in the render-target pipeline.
  - Linkshell mask is kept at 64x64 from the old addon so it stays smooth without adding unnecessary texture size.
- 2026-06-14 - Removed broken world-marker stacking movement:
  - The attempted projected-rectangle-to-world-Y stack resolver was removed from `core/world_marker_probe.lua`; enabling stacking no longer applies `_stackOffsetY` or moves world plates.
  - Settings > Visibility no longer shows `Max stack lift`.
  - The old `Nameplates` stacking behavior was inspected: it sorts screen-space plates by `baseY`, checks simple rectangle overlap, and changes only `drawY` for 2D ImGui plate windows. A real replacement should use that same 2D final-draw model instead of moving world anchors.
- 2026-06-14 - Screen-space plate stacking restored:
  - Plate stacking now uses the pass-1 click rectangle/invisible-box data, resolves overlaps in 2D screen pixels, shifts the matching click rects, then draws moved plates with a screen-space texture offset.
  - The resolver now tries left/right horizontal lanes before raising a plate vertically, so tight packs should spread more like WoW-style nameplate stacks instead of forming a tall column first.
  - World actor anchors are not moved; this avoids the old failure where enabling stacking lifted every world plate upward.
  - `Stack spacing` and `Allowed overlap` are normalized as pixels, so values like spacing `20` and overlap `2` map directly to about 20 px gap and 2 px allowed overlap.
  - Target/subtarget/tactical plates stay fixed when `Keep target fixed` is enabled, but still act as blockers for regular world plates.
  - Settings now expose `Horizontal spread` and `Target blocker width` so users can choose between tighter vertical stacks, wider WoW-style fanning, and softer/harder fixed target blockers.
- 2026-06-14 - Reduced idle canvas texture cache churn:
  - Canvas render textures now include their render size in the internal cache key, so a plate key changing between canvas sizes no longer releases and recreates the same cache entry every frame.
  - Husband crowded-player report `20260614-185549` showed `Plate PC avg=33.09ms` and `canvasRenders=31` while `World draw avg=0.10ms`; the lag was cold PC canvas construction, not the stacking resolver.
  - Idle non-party PC plate canvas builds are now capped per frame in crowded areas, so large groups warm in over several frames instead of building every nearby PC texture at once.
  - PC, NPC/Object, Enemy, and Trust plate caches now clear once when Settings opens instead of clearing every rendered frame while the config window is open.
  - Detailed performance monitor now shows the last canvas render key/size and last evicted texture key to make the remaining FPS drop easier to isolate.
  - Performance monitor now has a `Save report` button that writes a `.txt` snapshot to `config\addons\LibraPlates\performance`.
  - Stale engaged enemy tracking no longer queues hidden/non-visible world enemy plates; current target/subtarget still allow hidden lookup for responsiveness.
  - Stable engaged Enemy plates can now reuse their cached canvas texture; they still redraw when HP, cast/status rows, settings, or visual signature changes.
  - Performance reports now include enemy cache skip reasons so remaining enemy canvas redraws can be tied to target state, casts, status rows, config, or hover.
  - Enemy canvas caching is allowed while Settings/performance monitor is open; the enemy cache signature already includes plate settings, so edits still invalidate cached textures.
  - Self world plate caching is also allowed while Settings/performance monitor is open, and performance reports include self cache hit/smooth/miss counters.
  - `/lp perf report` now saves the same performance snapshot without opening the monitor, so testing can avoid UI overhead.
  - Click debug is now truly off by default and `/lp clickdebug off` disables both hidden raw rect drawing and debug rect baking in plate canvases.
  - Detailed performance mode no longer keeps native D3D draw hooks active by itself; reports now include `shouldUseDrawHooks` to verify hook state.
  - Native party/target UI hide hooks now require an actual target before activating, so no-target idle testing should report `shouldUseDrawHooks=false`.
  - Gathering tool-count display is suppressed briefly on login/zone packets and its count baseline is reset, preventing the false `0` tool-count flash during zoning. Confirmed fixed in-game.
- 2026-06-13 - Profile visibility and auto-switch cleanup:
  - Settings now always shows the current profile in a compact top row, with direct profile switching available from any Settings/Plates/Modules view.
  - Confirmed profile auto-switch support already exists for main job plus sub job, including `Any` subjob matching any or no subjob.
- 2026-06-13 - Item icon data sorted by zone:
  - Reorganized `data/item_icons.lua` so single-zone object entries are grouped under their zone headers, making zone cleanup easier.
  - Verified the file still loads with 615 entries and no duplicate top-level keys.
- 2026-06-13 - Door object item icon cleanup:
  - Updated Door-like entries in `data/item_icons.lua` so generic generated `type = 'Object'` labels become readable door/shop labels derived from the key.
  - Updated those Door-like entries to use `Door.png`; verified no Door entry remains with generic Object type.
- 2026-06-13 - NPC/Object Quick Menu right-click restored:
  - Fixed right-click flow so NPC and icon NPC plates can open Quick Menu again.
  - Object gathering/tool right-click still runs first for known gathering points, then falls through to Quick Menu when it is not a gathering action.
  - Corrected gathering right-click scope: it is only for known gathering Object nodes, not NPC plates.
  - Added the live short name `Excav. Point` as an Excavation Point alias so right-click excavation uses Pickaxe like the full-name node.
- 2026-06-13 - Reload crash guard for NPC/Object icons:
  - Cleared shared texture caches, NPC/Object icon texture ids, and Quick Menu icon caches on addon load/unload.
  - NPC/Object icon loading now fails closed to no icon if a texture load fails, instead of reusing bad/stale texture ids after reload.
- 2026-06-13 - NPC/Object icon merged data promoted:
  - Validated and promoted `tools/item_icons_merged.lua` into `data/item_icons.lua`.
  - Validated and promoted `tools/npc_icons_merged.lua` into `data/npc_icons.lua`.
  - Fixed generated Lua table issues before promotion: bad quote escaping, misplaced NPC table return, duplicate keys, and one blank Logging Point type.
- 2026-06-13 - BST pet Distance removed:
  - Pet (BST) Charmed Pet and Jug Pet settings no longer list Distance.
  - Live BST pet plates and BST pet settings preview no longer build a Distance badge.
- 2026-06-13 - Pet (DRG) settings preview crash fixed:
  - Clicking Pet (DRG)/Wyvern settings no longer crashes the config renderer from missing preview icon fallback locals.
- 2026-06-13 - Distance/range badges limited to targeted plates:
  - PC, Enemy, NPC/Object, BST pet, Wyvern, and Automaton distance badges now render only when the entity is the current Target or Subtarget.
  - Target/subtarget marker distance behavior still receives live distance internally, but normal world plates no longer build visible distance text for every entity at once.
  - Settings now present the widget as `Distance (/t -/st)` with target/subtarget-only tooltip text, while preserving the existing saved `Distance` profile keys.
  - Enemy and PC World widget lists no longer show Distance; their target/subtarget distance settings live under Tactical. Settings preview now only shows the distance badge while editing Distance.
- 2026-06-12 - Mog House job-change backend first pass completed:
  - LibraPlates now has an internal job-change backend modeled after Windower `JobChange`.
  - It can queue direct `0x100` main/sub job packets while near a valid job-change Moogle, with a `0x01A` poke for Nomad/Pilgrim Moogles.
  - A first test command path was added: `/lp jobchange WAR`, `/lp jobchange main WAR`, `/lp jobchange sub NIN`, `/lp jobchange PUP/COR`, plus `status` and `cancel`.
- 2026-06-12 - Native names auto-apply on auto-load fixed:
  - `Use native names` off now reapplies native-name state on a real login-ready path instead of relying only on early addon load timing.
  - This fixed the case where some auto-load users still had to type `/names` manually after logging in.
- 2026-06-12 - Lock-on icon option completed:
  - A lock-on icon option was added under the Target Module path, which is the home chosen for this feature.
- 2026-06-12 - Native game name toggles exposed with name settings:
  - Native-name controls were added into the same general settings areas where LibraPlates name settings are managed.
- 2026-06-12 - Self cast bar support/settings completed:
  - Self has cast bar support/settings in Self World/Tactical, including placement and styling controls.
- 2026-06-12 - Enemy level fallback difficulty brackets adjusted:
  - Enemy level difficulty coloring fallback was changed away from the old overly-green bracket table.
  - Current fallback now treats TW as 8+ below, EP as 5-7 below, DC as 3-4 below, EM as 2 below to 2 above, T as 3-5 above, VT as 6-8 above, and IT as 9+ above.
- 2026-06-12 - Background widget textures completed:
  - The normal Background widget can now pick texture images from `assets/images/backgrounds`.
  - Live plates and settings preview both carry the selected background texture through the shared background render path.
- 2026-06-12 - Target/Subtarget background opacity controls completed:
  - Target Module and Subtarget Module highlight settings now expose an explicit Opacity control.
  - The control drives the existing highlight tint alpha instead of introducing a separate render-only opacity path.
- 2026-06-12 - Target Module chevron cleanup completed:
  - Removed the extra chevron on/off toggle from Target Module editing.
  - Chevron image `None` is now the single off state, including for NPC/Object Target Module settings.
- 2026-06-12 - Depth probe addon decision resolved:
  - The separate `LibraDepthProbe` utility addon is not needed as part of normal LibraPlates use.
  - Keep the behavior in LibraPlates, and do not ship the old depth probe helper plugins in release packages.
- 2026-06-12 - Mob name claimed-state split completed:
  - Enemy mob name settings now support separate display behavior for mobs claimed by self/party/alliance versus mobs claimed by others.
- 2026-06-09 - Buff/Debuff growth direction added:
  - Buffs and Debuffs now have a `Growth direction` setting under the anchor controls.
  - `Right` and `Left` preserve timer/order sorting while changing which way the row grows.
  - Buffs were live-tested; Debuffs use the same mirrored status-icon layout path and are considered covered unless a specific debuff-only issue appears.
- 2026-06-08 - Settings copy-settings function restored:
  - Settings can be copied from one entity/state/widget area to another instead of rebuilding them manually.
- 2026-06-08 - Enemy HP 0 target/subtarget marker suppression confirmed:
  - Target/Subtarget markers stop drawing on defeated enemies when enemy HP reaches 0.
- 2026-06-08 - Sea object `Lumoarian Gleam` support note moved to completed:
  - `Lumoarian Gleam` is supported for sea organ trade/pickup behavior.
  - Lumorian Gleams can also provide access to Vision storage, per Loxley note.
- 2026-06-08 - Name font size settings capped consistently:
  - Name widget font size now caps at `40` for all entities, matching the existing PC cap.
- 2026-06-08 - Quick Menu settings are scoped in Plates view:
  - Self Quick Menu settings show Self actions/trust filters without PC, Trust, or NPC/Object groups.
  - PC, Trust, NPC, and Object Quick Menu settings show only their relevant action/info groups when opened from Plates.
  - Modules > Quick Menu still shows the full shared configuration.
- 2026-06-08 - Quick Menu preview follows settings more closely:
  - Preview rows now respect enabled/disabled Quick Menu action settings such as Follow.
  - Preview row text uses the same readable color fallback as the live Quick Menu.
  - Quick Menu preview no longer renders an unnecessary plate texture behind the menu every settings frame.
- 2026-06-08 - PC Peer preview cleaned up after Linkshell removal:
  - Removed the stale Linkshell row from the PC Peer preview to match live PC Peer.
- 2026-06-08 - Screen no-go zones for click targeting completed:
  - User-defined invisible rectangles can be placed over action bars, chat windows, menus, or other UI areas.
  - Clicks inside a no-go zone are ignored by LibraPlates plate click-targeting while still letting the game/UI receive the click normally.
- 2026-06-08 - NPC/Object Target Module chevron toggle completed:
  - NPC/Object plates have an option to turn Target Module chevrons on/off.
  - Follow-up cleanup remains active because the checkbox may be unnecessary when the chevron dropdown can be set to `None`.
- 2026-06-08 - NPC/Object fallback behavior is covered:
  - Unknown NPCs and objects still show name/target marker behavior without requiring curated icon/info data.
- 2026-06-08 - Self Quick Menu trust toggles live-tested:
  - `Ignore Other Trusts`, `Hide Other Trusts`, and `Emote Trust` command/state sync works correctly around other players' trusts.
  - Temporary Self Quick Menu toggle chat spam was removed after stabilization.
- 2026-06-08 - Name outline cleanup completed:
  - Small world-plate name outlines no longer look like black drips/feet.
  - Larger outline sizes now use clean text-shaped outline copies instead of a giant GDI outline.
- 2026-06-08 - Enemy preview cropping fixed:
  - Enemy preview no longer secretly adds extra zoom.
  - Zoom now enlarges the rendered nameplate inside the preview instead of only zooming the background image or changing widget sizes.
- 2026-06-08 - Target/Subtarget module preview positioning completed:
  - Preview supports positioning arrows, chevrons, and background in settings.
  - The old disabled-2D-arrow/chevron preview note is resolved.
- 2026-06-08 - Native target-arrow first-target flash fixed:
  - F-key and command first-target native flash was fixed by keeping the native hard-hide path active when native party/target UI hiding is enabled.
  - Do not touch native arrow timing/hard-hide unless a new targeted bug requires it.
- 2026-06-08 - Trust TP apparent 100% display cause resolved:
  - The apparent full TP bar was caused by TP fill and background defaulting to the same color.
  - Future default-color cleanup remains tracked separately.
- 2026-06-08 - PC and Self Peer first passes completed:
  - PC World/Tactical exposes `Peer (module)` with compact player preview and live hover behavior.
  - Self World/Tactical exposes `Peer (module)` with a character-stat preview and live Shift-hover player data.
- 2026-06-08 - PUP/Automaton Maneuvers first pass completed:
  - Own PUP automaton is detected through `PetTargetIndex` and queued as a tactical `Automaton` plate.
  - Maneuvers widget uses player status icons 299-307 with icons under `assets/images/maneuvers/default`.
- 2026-06-08 - Crafting result module first rebuilt pass completed:
  - Crafting result is packet-driven from incoming packet `0x0030`, with packet `0x006F` clearing the active result.
  - Current addon overlays the result on the Self Idle layout as Icon or Text using `assets/images/crafting`.
- 2026-06-08 - Peer preview interaction first passes completed:
  - Clicking Peer preview elements selects the matching Peer component in the dropdown.
  - Peer preview has a `Drag` toggle for directly updating Peer component X/Y settings.
- 2026-06-08 - Peer module setup and Enemy Peer content completed:
  - Modules > Peer exposes shared behavior settings, Enemy info components, preview wiring, and icon pack selection.
  - Enemy Peer reads local icon packs from `assets/images/peer-icons`, and Enemy > Idle/Combat exposes `Peer (module)`.
- 2026-06-08 - Cleared stale hardcoded-name fallback note:
  - Confirmed `modules/widgets/name.lua` and nearby name render paths no longer contain the old `Lumenlee` fallback text.
  - No runtime code change was needed.
- 2026-06-08 — Self Quick Menu no longer opens directly under the Self plate:
  - Added a self-only popup offset so the Self Quick Menu opens down/right from the click point instead of overlapping the Self world plate.
  - This avoids changing plate rendering behavior or global quick-menu behavior.
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
- Next priority: fix remaining small UX note items only after `/st` is stable for multiple full minutes (e.g., preview-click selection and module copy button behavior).

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
- Bar settings todo: check bar border settings. Some bars appear to have old-Libra borders, but border controls may be missing or inconsistent in current settings.
- Self Buffs/Debuffs todo: live Self buffs/debuffs can appear and work, but the settings preview does not show them. Add them to Self World/Tactical preview like PC where appropriate.
- Target/Subtarget placement bug: Plates > Self/PC/Trust/etc. > World/Tactical Target/Subtarget arrow Position X/Y still did not visibly affect live arrows in testing. Check whether modules/settings scoping is still coupled or overwritten by Target/Subtarget module placement logic.
- Native targeting test note: if native targeting and Libra target modules are both forced visible during diagnostics, duplicate arrows are expected because native and Libra arrows are both visible. Normal settings should avoid this by switching between the native targeting system and Libra's replacement.
- CatsEye data labeling rule: use `type` as player-facing identification. For event pages, prefer the specific event name such as `Holiday Event`, `Halloween Event`, `Easter Event`, or `Colossal Clamming Competition` over vague labels like `Seasonal Event`.
- CatsEye source pages can mention non-CatsEye/native NPCs that are only involved in CatsEye quests or events. Do not put those in `catseye_npc_icons.lua` just because the page mentions them. Put native/event-involved NPCs in `npc_icons.lua` with exact zone scoping and the player-facing event/quest type.

### 2026-06-04


### 2026-06-02

- Background/highlight conditional display idea: add "show only on..." conditions for Background/Highlight style visuals, so a background or highlight can appear only for specific states/events such as Target, Subtarget, combat/tactical, aggro, low HP/MP, enmity warnings, or other alert conditions. This should be a reusable conditional system instead of hardcoding one-off background behavior into each widget.
- PUP Maneuvers timer formatting: maneuver timer labels should stay as plain seconds numbers under each socket, with no suffix/background box; examples are `71`, `84`, `43`, `56`.

### 2026-05-30

- Peer todo: add/show passive vs aggressive info clearly in Enemy Peer. Lila noticed this info is missing from the current Peer display.
- Peer icon asset todo: upscale/clean Peer icon packs, especially the currently used `round`/mobdb-style enemy info icons, so they remain crisp at the in-game Peer display sizes. Target practical export size is likely 64x64 PNG with real alpha, consistent filenames, and simple high-contrast shapes.
- Future preview interaction idea: look into different cursor pointers for preview interactions, such as hover/select/move cursors. This should pair with a possible drag-to-position prototype, first for Peer preview components and later for general preview widgets if it feels good.
- Background settings layout direction: make one polished background editor pattern and reuse it everywhere. Desired order is Width/Height, Position X/Y, then Fill color + Opacity on one row, then Border color + Border size on one row. Applied to Peer > Background and the shared normal plate Background editor.
- Peer Job component layout direction: Peer > Job uses compact paired rows. Display is a dropdown; Icon theme appears on the same row only when Icon display is selected; Position X/Y share one row; Icon mode shows Icon size and live/preview Peer renders the selected job icon; Text mode shows font size/color and outline settings. A similar shared normal Job editor pass was started too, but current testing focus remains Peer.
- Peer Level component now includes difficulty font colors in the Peer style: Use difficulty font colors toggle plus TW/EP/DC/EM/T/VT/IT color rows. Live Enemy Peer colors Level from mob level versus viewer level; preview uses the T color as the sample.
- Enmity module now follows the old addon Healer/Tank behavior while staying icon-only for now. The icon asset lives at `assets/images/enmity_icon.png`; Modules > Enmity exposes Active, Mode, Position X/Y, and Icon size. Healer mode marks the ally plate currently targeted by an enemy; Tank mode marks the enemy currently targeting self. Do not put background/highlight controls in Enmity yet; make those part of the future reusable highlight/effect system.
- Resting module first rebuilt pass: live Self now treats entity `Status == 33` as Resting, keeps the regular Self layout sourced from Idle, and overlays a Resting tick bar from `global.resting`. Discord research says perfect accuracy is not possible from normal client state because rest gains are delivered on imperfect server update ticks. Current tracker shows the first 20s countdown, starts the 10s repeat countdown from the first meaningful HP/MP gain, then resyncs later repeats from meaningful MP jumps (`mpTickThreshold`, default 12). At full MP it falls back to normal timer wrapping.
- Fishing module first rebuilt pass: old addon only had an empty `ui/widgets/fishing.lua`; useful source was the old Self module mapping plus worksheet status IDs. Current module treats statuses 38-43, 50-53, and 56-62 as Fishing, reuses the Self Idle layout as the base, and listens for fishing gut-feeling chat lines. Result mapping: didn't catch anything -> `fishing_00.png` + `You didn't catch anything`; good feeling -> `fishing_01.png` + `Easy catch`; don't know enough skill -> `fishing_02.png` + `Moderate catch`; fairly sure -> `fishing_03.png` + `Hard catch`; positive not enough -> `fishing_04.png` + `Very difficult catch`; bad feeling -> `fishing_05.png` + `Extreme catch`; terrible feeling -> `fishing_06.png` + `Dangerous catch`. These images are separate result icons, not animation frames, and live in `assets/images/fishing`. Settings live in Modules > Fishing and Plates > Self > Idle > Fishing (module).
- Settings UI direction: reset actions should live at the bottom of each settings panel like the existing "Reset X position/settings" pattern, but Lila prefers actual buttons over yellow text links. Preserve the modal/dimmed confirmation behavior. First cleanup done in Plates > Target/Subtarget placement by removing the top "Reset placement nudges" button and adding bottom reset-position/settings buttons with confirmation. Follow-up pass should convert the remaining yellow reset links to bottom buttons without changing their behavior.
- Focus pivot: prioritize getting all settings represented for all entities/states before continuing deep native-position investigations. First low-risk slice completed: PC settings now expose Background and Distance; NPC/Object settings now expose Subtarget module; live PC and NPC/Object plates now consume Background and Distance settings; settings preview shows Distance for PC/NPC/Object as well as Enemy.
- Fixed likely cause of Avatar Target module not working: `modules.target_overlay` now recognizes the player's own SMN pet as `Pet (SMN)` and chooses `Avatar` or `Spirit` layout state before reading Target/Subtarget module settings. After reload, target Titan/avatar and use `/lp targetdebug`; expected debug should include `entity=Pet (SMN) layout=Avatar`.
- Target/Subtarget settings UI cleanup: the Modules tab still contains Target/Subtarget and owns broader options such as Auto place plus info/tooltips. Plates > entity > state > Target/Subtarget should be focused on placement and should not repeat the same Auto place controls. The Target/Subtarget placement drawer uses paired slider rows for Position X/Y and Width/Height like the approved BST-style controls. This changes editor layout only; it does not mutate saved `rebuild_profile.lua` values or force-copy the approved BST visual values into every entity/state.
- Future highlight/background system idea: look into making reusable highlight/background visuals that can be assigned to certain states or warnings, such as aggro, low HP, and other alert conditions. This should probably fit into the broader all-entities/all-states settings pass rather than being hardcoded per widget.
- Current transition terminology: `World Context` means true 3D world-marker plates drawn in `core.world_marker_probe`; `Tactical Context` / `important overlay` / `always-visible plates` means the 2D overlay path drawn by `modules.target_overlay` from `worldMarkerProbe.GetAlwaysVisiblePlates()`. In code, tactical plates are generally marked with `plateAlwaysOnTop = true` and `plateTacticalOverlayOnly = true`.
- Todo: add a setting to disable right-click enemy attack while mounted. Mounted right-clicks should not accidentally try to attack from LibraPlates when Lila is riding.
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

### 2026-06-11

- User backlog: game mode is not reading properly.
- User backlog: NPC is missing target/subtarget highlight settings; check whether subtarget has range colors.
- User backlog: Copy target/subtarget module is not working.
- User backlog: Check all previews, especially text and growth direction display values such as HP vs `1200/2000`.
- User backlog: Move aggro.
- User backlog: Continue profile work.
- User backlog: Quick menu needs size settings or flexible sizing depending on visible selections.
- User backlog: Keep the current profile always visible in settings, possibly with a top bar.
- User backlog: Add enemy cast bar settings.
- User backlog: Make buff filtering input smarter for time values, possibly a 2-digit field plus S/M/H radio buttons.
- User backlog: Enmity is currently in Enemy; find a better place, possibly profile-dependent for Enemy vs Self.
- User backlog: Remove BST chat spam.
- User backlog: Some widget-list names are blue.
- User backlog: Distance meter should only show on target/subtarget.
- User backlog: Move resting out of dropdown to its own setting and check its timer bug.
- User backlog: Enemy preview needs long/short name examples.
- User backlog: Blue magic is missing casting icons and is not showing AOE.
- User backlog: Add stacking plate priority list so users can choose which plates show in which order.
- User backlog: GEO and maybe other auras have `0` duration, which triggers buff time color warnings.
- User backlog: Warning screen color scheme is still red.
- User backlog: Range arrow color only works out of combat.
- Mog House / Nomad Moogle quick menu presets: mostly done, needs a little more testing.
  - Mog House Moogle now shows a dedicated job-preset section in the quick menu.
  - Presets are configured from `Plates > Self > World > Quick Menu`.
  - Non-Ru'Lude `Nomad Moogle` locations now use the same job-change preset behavior.
  - `Ru'Lude Gardens` `Nomad Moogle` keeps its special quest/info identity instead of using the generic preset menu.
  - Backend `/lp jobchange ...` support remains valid for Mog House / Nomad / Pilgrim job-change paths.
  - Follow-up idea: add Lockstyle access/action into the Moogle job-change / preset flow.
- User backlog: Profile auto-switch by main job and subjob, with subjob `Any` including no subjob.
- User backlog: Set TP bar color when TP is full.
- User backlog: HP bar color/alpha when out of range.
- User backlog: Peer level should be color-correct to level.
- User backlog: Check Conquest War and Union Conquest War naming/colors; CW and UCW have orange names.
- User backlog: Husband reports `[C]` subtarget causes stutter.

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
- Modules tab now uses the same left selector plus preview/settings split as Plates, so Target/Subtarget module edits can be previewed for the selected entity/state before applying live.

### 2026-05-26

- Enemy live castbar was wired from the old addon behavior instead of guessing: packet `0x0028`, action type `8` starts a spell cast from the first target action param, action types `4`/`11` clear it, and zoning clears all casts. The castbar uses Enemy > Combat > Cast bar settings.
- Text size/font size settings were normalized. Settings now use visual-size numbers `6`-`24`, while rendering converts them to the larger texture font sizes needed for world plates. Old saved raw values above `24` still render at their old size and normalize when edited. Live enemy plates no longer switch the whole Name/HP layout to Combat while engaged; Combat currently owns the castbar only.
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

- Bug follow-up: Mog House moogle classification/data is mostly resolved.
  - Quick Menu now promotes the Mog House Moogle out of the Trust action path into the intended job-change menu behavior.
  - Keep a little more live testing on Mog House Moogle, Nomad Moogle, and Ru'Lude special-case behavior before calling this fully done.

- TODO: Investigate urgent performance issue: FPS 1 setting is very laggy.

- TODO: PC World plates show range/distance on every plate and there is currently no way to turn it off.

- TODO: Retest targeting matrix after next input fix: especially right-click during subtarget mode while not engaged/engaged should select subtarget and not open quick menu.

- TODO: Check lock-on settings after target/subtarget marker updates; confirm placement, visibility, and whether settings location/labels are clear.
