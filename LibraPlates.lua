addon.name = 'LibraPlates';
addon.author = 'Lunem';
addon.version = '0.1.0';
addon.desc = 'Clean modular world plates.';

-- ============================================================
-- Imports
-- ============================================================

require('common');

local state = require('core.state');
local commands = require('handlers.commands');
local log = require('core.log');
local modules = require('modules.init');
local nativeTargetArrow = require('core.native_target_arrow');
local engagedEnemies = require('core.engaged_enemies');
local enmity = require('core.enmity');
local enemyCasts = require('core.enemy_casts');
local enemyStatuses = require('core.enemy_statuses');
local partyStatuses = require('core.party_statuses');
local trustStatusIcons = require('core.trust_status_icons');
local restingTick = require('core.resting_tick');
local petState = require('core.pet_state');
local bstCharmTimer = require('core.bst_charm_timer');
local fishing = require('core.fishing');
local crafting = require('core.crafting');
local quickMenu = require('core.quick_menu');
local diagnostics = require('core.diagnostics');
local nativeDrawHooksRegistered = false;

local function RegisterNativeDrawHooks()
    if (nativeDrawHooksRegistered == true) then
        return;
    end

    ashita.events.register('d3d_dp', 'libraplates_native_target_trace_dp', function(e)
        nativeTargetArrow.HandleDrawPrimitive(e);
    end);

    ashita.events.register('d3d_dip', 'libraplates_native_target_trace_dip', function(e)
        nativeTargetArrow.HandleDrawIndexedPrimitive(e);
    end);

    ashita.events.register('d3d_dpup', 'libraplates_native_target_trace_dpup', function(e)
        nativeTargetArrow.HandleDrawPrimitiveUp(e);
    end);

    ashita.events.register('d3d_dipup', 'libraplates_native_target_trace_dipup', function(e)
        nativeTargetArrow.HandleDrawIndexedPrimitiveUp(e);
    end);

    nativeDrawHooksRegistered = true;
end

local function UnregisterNativeDrawHooks()
    if (nativeDrawHooksRegistered ~= true) then
        return;
    end

    ashita.events.unregister('d3d_dp', 'libraplates_native_target_trace_dp');
    ashita.events.unregister('d3d_dip', 'libraplates_native_target_trace_dip');
    ashita.events.unregister('d3d_dpup', 'libraplates_native_target_trace_dpup');
    ashita.events.unregister('d3d_dipup', 'libraplates_native_target_trace_dipup');

    nativeDrawHooksRegistered = false;
end

local function UpdateNativeDrawHooks()
    if (nativeTargetArrow.ShouldUseDrawHooks() == true) then
        RegisterNativeDrawHooks();
    else
        UnregisterNativeDrawHooks();
    end
end

-- ============================================================
-- Addon lifecycle
-- ============================================================

ashita.events.register('load', 'libraplates_load', function()
    state.Load();
    modules.Load();
    log.Info('Loaded clean LibraPlates.');
end);

ashita.events.register('unload', 'libraplates_unload', function()
    UnregisterNativeDrawHooks();
    diagnostics.Restore();
    state.Save();
    modules.Unload();
    log.Info('Unloaded clean LibraPlates.');
end);

-- ============================================================
-- Events
-- ============================================================

ashita.events.register('command', 'libraplates_command', function(e)
    commands.Handle(e);
end);

ashita.events.register('mouse', 'libraplates_mouse', function(e)
    modules.HandleMouse(e);
end);

ashita.events.register('packet_in', 'libraplates_packet_in', function(e)
    engagedEnemies.HandlePacketIn(e);
    enmity.HandlePacketIn(e);
    enemyCasts.HandlePacketIn(e);
    enemyStatuses.HandlePacketIn(e);
    partyStatuses.HandlePacketIn(e);
    trustStatusIcons.HandlePacketIn(e);
    bstCharmTimer.HandlePacketIn(e);
    crafting.HandlePacketIn(e);
end);

ashita.events.register('packet_out', 'libraplates_packet_out', function(e)
    petState.HandlePacketOut(e);
    bstCharmTimer.HandlePacketOut(e);
end);

ashita.events.register('text_in', 'libraplates_text_in', function(e)
    fishing.HandleTextIn(e);
    restingTick.HandleTextIn(e);
    quickMenu.HandleTextIn(e);
end);

ashita.events.register('d3d_present', 'libraplates_present', function()
    local ok, err = pcall(function()
        nativeTargetArrow.SetTraceCapturePaused(false);
        nativeTargetArrow.EndTraceFrame();
        nativeTargetArrow.SetTraceCapturePaused(true);
        modules.UpdateNativeTargetArrow();
        UpdateNativeDrawHooks();
        modules.ResetWorldMarker();
        modules.Render();
        UpdateNativeDrawHooks();
        modules.PrepareWorldMarkerFont();
    end);

    if (ok ~= true) then
        state.SetConfigOpen(false);
        log.Warn('Config render disabled after error: ' .. tostring(err));
    end
end);

ashita.events.register('d3d_beginscene', 'libraplates_world_marker_beginscene', function()
    modules.UpdateNativeTargetArrow();
    UpdateNativeDrawHooks();
    nativeTargetArrow.SetTraceCapturePaused(true);
    modules.DrawWorldMarker();
    nativeTargetArrow.SetTraceCapturePaused(false);
end);

ashita.events.register('d3d_endscene', 'libraplates_native_target_endscene', function()
    modules.UpdateNativeTargetArrow();
    UpdateNativeDrawHooks();
end);
