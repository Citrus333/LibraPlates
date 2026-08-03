# LibraPlates

Clickable, customizable nameplates and quality-of-life tools for Final Fantasy XI.

LibraPlates is an Ashita addon for Final Fantasy XI, with extra CatseyeXI-focused features built in. It adds clickable nameplates directly inside the 3D game world, giving players, NPCs, objects, pets, and enemies useful info, quick actions, combat helpers, and everyday quality-of-life tools.

> Status: active work in progress. Expect ongoing polish, data fixes, and feature tuning.

<a href="docs/screenshots/features/main.png">
  <img src="docs/screenshots/features/main.png" alt="LibraPlates main showcase" width="900">
</a>

## Key features

- **Clickable nameplates** — click plates to target, inspect, open menus, gather, travel, and use supported Catseye systems faster.
- **Right-click combat** — right-click enemy plates to start attacking or quickly switch combat targets, even when mounted. LibraPlates can dismount you and begin the attack automatically.
- **Right-click gathering** — right-click gathering nodes and LibraPlates will pick the right tool for the job, using a Pickaxe, Hatchet, or Sickle from your inventory when available.
- **NPC and object library** — a large built-in library of NPCs and objects with titles, custom icon sets, services, quest starts, mission roles, special CatseyeXI markers, and clickable wiki links.
- **CatseyeXI quality-of-life markers** — special Catseye NPCs, services, events, HELM, weekly hunts, Adept Reforging, Voidwatch, Ephemeral Box, venture/incursion enemy markers, and more.
- **Combat information on plates** — enemy behavior, detection, links, weaknesses, resists, immunities, buffs, debuffs, cast alerts, claim colors, and AOE helpers.
- **Plate stacking** — reduces messy overlap in crowded areas so names, bars, and icons stay readable.
- **Special job plates** — custom plates and helpers for BST pets, SMN avatars/spirits, DRG wyverns, PUP automatons, and luopans, including timers, maneuvers, avatar/spirit bars, and pet action alerts.
- **Current target bar** — static target display for enemies, NPCs, objects, PCs, trusts, pets, and self.
- **Screen alerts** — built-in and custom alerts with optional sounds and separate visual lanes.
- **Blacklist tools** — keep notes on blacklisted players, hide or recolor them, change their displayed name locally, or turn them into Fomors on your screen.
- **Streamer Mode** — replace visible player names with privacy-friendly labels like `Player1` and `Player2`.
- **Highly customizable** — profiles, fonts, colors, textures, icons, anchors, auto-stacking, scaling, visibility rules, performance options, and clear file paths so users can freely change or swap assets.
- **Extra QoL modules** — resting tick/logout timer, fishing HUD, gathering tool count, crafting result display, teleport and Mog House exit helpers, mount cooldown, mount roulette, Ephemeral Box tools, quick menus, blacklist tools, and profile management.

## Feature gallery

Click any image to open it full-size.

<table>
  <tr>
    <td width="33%" align="center"><strong>Clickable Combat Plates</strong><br><a href="docs/screenshots/features/combat-nameplates.png"><img src="docs/screenshots/features/combat-nameplates.png" alt="Combat feature card" width="100%"></a><br><sub>Target, attack, and switch enemies fast.</sub></td>
    <td width="33%" align="center"><strong>Detailed NPC Interaction</strong><br><a href="docs/screenshots/features/npc-info-plate.png"><img src="docs/screenshots/features/npc-info-plate.png" alt="NPC info feature card" width="100%"></a><br><sub>Icons, titles, notes, quests, and links.</sub></td>
    <td width="33%" align="center"><strong>Blacklist Tools</strong><br><a href="docs/screenshots/features/blacklist-fomor.png"><img src="docs/screenshots/features/blacklist-fomor.png" alt="Blacklist feature card" width="100%"></a><br><sub>Notes, local renames, colors, hiding, and Fomors.</sub></td>
  </tr>
  <tr>
    <td width="33%" align="center"><strong>CatseyeXI Systems</strong><br><a href="docs/screenshots/features/catseye-systems.png"><img src="docs/screenshots/features/catseye-systems.png" alt="Catseye quality-of-life feature card" width="100%"></a><br><sub>Markers and shortcuts for custom systems.</sub></td>
    <td width="33%" align="center"><strong>NPC &amp; Object Library</strong><br><a href="docs/screenshots/features/npc-object-library.png"><img src="docs/screenshots/features/npc-object-library.png" alt="NPC and object library feature card" width="100%"></a><br><sub>Quest, mission, service, and object data.</sub></td>
    <td width="33%" align="center"><strong>Fishing HUD</strong><br><a href="docs/screenshots/features/fishing-hud.png"><img src="docs/screenshots/features/fishing-hud.png" alt="Fishing feature card" width="100%"></a><br><sub>Fishing state, fatigue, catches, and bait tips.</sub></td>
  </tr>
  <tr>
    <td width="33%" align="center"><strong>Live Settings Preview</strong><br><a href="docs/screenshots/features/settings-ui.png"><img src="docs/screenshots/features/settings-ui.png" alt="Settings UI feature card" width="100%"></a><br><sub>Customize layouts with an in-game preview.</sub></td>
    <td width="33%" align="center"><strong>Enemy Awareness</strong><br><a href="docs/screenshots/features/enemy-awareness.png"><img src="docs/screenshots/features/enemy-awareness.png" alt="Enemy awareness feature card" width="100%"></a><br><sub>Behavior, detects, links, resists, and casts.</sub></td>
    <td width="33%" align="center"><strong>Service NPCs</strong><br><a href="docs/screenshots/features/service-npcs.png"><img src="docs/screenshots/features/service-npcs.png" alt="Service NPCs feature card" width="100%"></a><br><sub>Vendors and services labeled before clicking.</sub></td>
  </tr>
  <tr>
    <td width="33%" align="center"><strong>SMN pet frame</strong><br><a href="docs/screenshots/features/smn-avatar-plate.png"><img src="docs/screenshots/features/smn-avatar-plate.png" alt="SMN pet frame feature card" width="100%"></a><br><sub>Avatar/spirit bars, timers, and alerts.</sub></td>
    <td width="33%" align="center"><strong>PUP automaton</strong><br><a href="docs/screenshots/features/pup-automaton.gif"><img src="docs/screenshots/features/pup-automaton.gif" alt="PUP automaton animation" width="100%"></a><br><sub>Automaton bars, maneuvers, burden, and risk.</sub></td>
    <td width="33%" align="center"><strong>DRG wyvern</strong><br><a href="docs/screenshots/features/drg-wyvern.png"><img src="docs/screenshots/features/drg-wyvern.png" alt="DRG wyvern feature card" width="100%"></a><br><sub>Wyvern status, timers, and pet-action helpers.</sub></td>
  </tr>
  <tr>
    <td width="33%" align="center"><strong>Quick Menus</strong><br><a href="docs/screenshots/features/quick-menus.png"><img src="docs/screenshots/features/quick-menus.png" alt="Quick menu feature card" width="100%"></a><br><sub>Context actions from right-click plates.</sub></td>
    <td width="33%" align="center"><strong>Travel Helpers</strong><br><a href="docs/screenshots/features/travel-helpers.png"><img src="docs/screenshots/features/travel-helpers.png" alt="Travel helpers feature card" width="100%"></a><br><sub>Teleports, guides, manuals, and exits.</sub></td>
    <td width="33%" align="center"><strong>Blacklist Settings</strong><br><a href="docs/screenshots/features/blacklist-settings.png"><img src="docs/screenshots/features/blacklist-settings.png" alt="Blacklist settings feature card" width="100%"></a><br><sub>Manage notes, names, colors, and privacy.</sub></td>
  </tr>
</table>

## What LibraPlates does

### Clickable nameplates

This is one of the biggest differences from a normal nameplate addon: LibraPlates plates are not just labels.

- Left-click plates to target directly instead of cycling through targets.
- Right-click enemies to start combat.
- Right-click gathering points to use the correct tool.
- Right-click players, self, trusts, NPCs, and objects to open supported quick actions.
- Open teleport, Mog House exit, Ephemeral Box, blacklist, mount, job-change, and Catseye service actions from contextual menus.
- Use plate information before clicking: icon, title, distance, type, behavior, quest/mission role, or service category.

### Nameplates

LibraPlates can show different plate layouts for different entity types and situations.

- Self, PC, enemy, trust, BST pet, SMN avatar/spirit, DRG wyvern, PUP automaton, luopan, NPC, and object plates.
- Name, background, HP/MP/TP bars, cast bars, job, level, ID, distance, target markers, type lines, icons, buffs, and debuffs.
- Anchoring and auto-stacking so widgets can attach to the plate, name, HP bar, or another widget.
- Per-entity styling for fonts, colors, outlines, textures, bar warnings, opacity, scale, and distance behavior.
- Plate stacking and screen clamping helpers to reduce overlap.

### Current target bar

A static target bar for whatever you are targeting: enemies, NPCs, objects, PCs, trusts, pets, and self.

- Name, distance, HP percent, and optional mob/status information.
- Smooth HP movement.
- Damage prediction.
- Healing prediction where data is available.
- Enemy status icons, weaknesses, resists, detects, links, and behavior indicators.
- Reuses LibraPlates plate colors/styles so it feels like part of the same UI.

### Enemy awareness

Enemy plates are built to reduce the “what am I looking at?” tax during combat.

- Claim colors for unclaimed, party claim, other claim, and call-for-help states.
- Mob info icons for aggression/passive behavior, detection methods, links, special traits, weaknesses, resists, and immunities.
- Cast bars and alerts for dangerous enemy magic or readied abilities.
- AOE range highlighting for supported actions.
- Enmity markers for enemies targeting you or allies.
- Peer Inspector details for deeper enemy information.

### NPC and object library

LibraPlates includes a large built-in library of NPC and object data across Vana'diel, with custom icon sets for different NPC types, services, quests, missions, and special CatseyeXI content. It can show who starts a quest, who is tied to a mission, what service an NPC offers, and which objects matter — with direct wiki links when available.

- Clear type lines such as vendor, quest giver, mission associate, survival guide, home point, event NPC, and Catseye service NPC.
- Icon categories for common NPC/object roles.
- Concise notes for important services.
- Quest and mission entries with clickable wiki links that open directly to the related wiki page where supported.
- Special Catseye markers for custom systems, NPCs, and venture/incursion enemies.
- Object support for boxes, guides, books, doors, gathering points, and other interactables.

### Quick menu

Right-click supported plates for useful actions.

- Player actions: examine, follow, invite, request invite, party/alliance actions, Catseye profile, and blacklist.
- Self actions: accept/decline invite, leave party/alliance, mount/dismount, job favorites, and travel helpers.
- Trust actions: dismiss one trust, dismiss all trusts, and trust visibility helpers.
- Teleport helpers for supported Home Points, Survival Guides, Field Manuals, Mog House exits, and related systems.
- Ephemeral Box actions for storing, browsing, searching, favoriting, and extracting items.

### Job, mount, and travel helpers

- One-click job-change favorites at supported Moogles.
- Optional lockstyle, macro book, and macro page steps after job change.
- Main/sub job swap handling.
- Mount and random mount actions.
- Remount cooldown display.
- Mog House exit helpers where unlocked.

### Resting, fishing, gathering, and crafting

- Resting tick bar/ring and logout countdown helper.
- Fishing result display.
- Fishing HUD for stamina/readiness, recent catches, rod, bait, target, fatigue, and Catseye fishing ventures where supported.
- Right-click fishing when a rod is equipped.
- Gathering tool display and one-click mining, excavation, logging, and harvesting.
- Crafting result display for NQ, HQ, and breaks.

### Buffs, debuffs, pets, and luopans

- Self, party/player, trust, enemy, pet, and luopan status icons.
- Trust buff/debuff tracking.
- PUP maneuvers.
- BST charm timer, pet state, Sic, Ready, and Reward helpers.
- SMN Ward/Rage helpers, avatar/spirit plates, detached frames, and cast bars where available.
- DRG wyvern support and breath alerts.

### Alerts and diagnostics

- On-screen alerts with optional sounds.
- Enemy spell/readied action alerts.
- Pet action alerts.
- Custom text alerts.
- Built-in alert categories for common CatseyeXI and FFXI event flows.
- Performance monitor, reports, FPS/adaptive modes, diagnostic captures, and lag testing tools.

### Privacy and player controls

- Blacklist players from commands or quick menus.
- Mirror native blacklist add/remove commands.
- Add blacklist reasons.
- Replace blacklisted player names or colors.
- Optional blacklisted player model replacement.
- Streamer Mode can anonymize local player names with safe labels.

## Settings and profiles

Open settings with:

```txt
/lp config
```

The settings UI is split into:

- `Settings` — profiles, fonts, native UI, mouse behavior, scaling, visibility, performance, and global options.
- `Plates` — visual setup per entity and plate state.
- `Help` — user guide, setting search, and troubleshooting.

Profile features:

- Create, copy, rename, delete, reset, and switch profiles.
- Auto-switch profiles by job assignment.
- Per-character profile storage.
- Automatic backups before destructive profile actions.

## Installation

1. Place the `LibraPlates` folder in your Ashita addons folder:

   ```txt
   Ashita/addons/LibraPlates
   ```

2. Load the addon:

   ```txt
   /addon load LibraPlates
   ```

3. Open settings:

   ```txt
   /lp config
   ```

## Useful commands

```txt
/lp config          Open settings
/lp reload          Reload settings/data
/lp perf on         Show performance monitor
/lp perf report     Save a performance report
```

Most normal setup should happen through the settings window instead of commands.

## Performance notes

LibraPlates does a lot for an older game client, so performance is treated as a feature.

- Adaptive performance mode can reduce background work when FPS drops.
- Nameplate updates are split into critical, medium, and static refresh work.
- Important plates stay prioritized: self, target, subtarget, tactical, engaged, casting, hovered, and important enemies.
- NPC/object info is loaded per zone.
- Textures and generated plates are cached.
- Distant or expensive plate features can be reduced through settings.

## Suggested README image order

If you only want to make a few images first, make these:

1. `hero-target-bar-and-plates.png`
2. `enemy-mob-info.png`
3. `npc-object-info.png`
4. `settings-preview.png`
5. `quick-menu.png`

That gives the page a strong first impression without needing screenshots for every subsystem.

## Credits

LibraPlates is a love-of-the-game project by Lunem.

Special thanks to the Ashita community, including atom0s and Thorny, and to public addon authors whose shared work helped guide parts of LibraPlates.

Feedback, corrections, bug reports, missing NPC/object data, and UI polish suggestions are welcome.
