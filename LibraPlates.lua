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
local aoeNameHighlight = require('core.aoe_name_highlight');
local nativeTargetArrow = require('core.native_target_arrow');
local targetActionRange = require('core.target_action_range');
local targeting = require('core.targeting');
local engagedEnemies = require('core.engaged_enemies');
local enmity = require('core.enmity');
local enemyCasts = require('core.enemy_casts');
local enemyAlerts = require('core.enemy_alerts');
local alertSounds = require('core.alert_sounds');
local enemyStatuses = require('core.enemy_statuses');
local partyStatuses = require('core.party_statuses');
local trustStatusIcons = require('core.trust_status_icons');
local luopanStatuses = require('core.luopan_statuses');
local restingTick = require('core.resting_tick');
local petState = require('core.pet_state');
local bstCharmTimer = require('core.bst_charm_timer');
local fishing = require('core.fishing');
local crafting = require('core.crafting');
local textureLoader = require('core.texture_loader');
local npcObjectInfo = require('core.npc_object_info');
local quickMenu = require('core.quick_menu');
local mounts = require('core.mounts');
local anonStatus = require('core.anon_status');
local playerBlacklist = require('core.player_blacklist');
local blacklistModelReplace = require('core.blacklist_model_replace');
local diagnostics = require('core.diagnostics');
local adaptivePerformance = require('core.adaptive_performance');
local perfMeter = require('core.perf_meter');
local profileAutoSwitch = require('core.profile_auto_switch');
local mogJobDebug = require('core.mog_job_debug');
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
    textureLoader.ClearCache();
    npcObjectInfo.ClearTextureCache();
    quickMenu.ClearTextureCache();
    state.Load();
    profileAutoSwitch.Reset();
    modules.Load();
end);

ashita.events.register('unload', 'libraplates_unload', function()
    UnregisterNativeDrawHooks();
    diagnostics.Restore();
    state.SaveIfLoadedOrSaved();
    modules.Unload();
    alertSounds.Cleanup();
    textureLoader.ClearCache();
    npcObjectInfo.ClearTextureCache();
    quickMenu.ClearTextureCache();
end);

-- ============================================================
-- Events
-- ============================================================

ashita.events.register('command', 'libraplates_command', function(e)
    local eventTimer = perfMeter.BeginDetail('event.command');
    local actionRangeTimer = perfMeter.BeginDetail('command.actionRange');
    targetActionRange.HandleCommandText(e.command);
    perfMeter.EndDetail(actionRangeTimer);
    local aoeTimer = perfMeter.BeginDetail('command.aoe');
    aoeNameHighlight.HandleCommandText(e.command);
    perfMeter.EndDetail(aoeTimer);
    local mountsTimer = perfMeter.BeginDetail('command.mounts');
    mounts.HandleCommandText(e.command);
    perfMeter.EndDetail(mountsTimer);
    local otherTimer = perfMeter.BeginDetail('command.other');
    anonStatus.HandleCommandText(e.command);
    playerBlacklist.HandleCommandText(e.command);
    commands.Handle(e);
    perfMeter.EndDetail(otherTimer);
    perfMeter.EndDetail(eventTimer);
end);

ashita.events.register('mouse', 'libraplates_mouse', function(e)
    local eventTimer = perfMeter.BeginDetail('event.mouse');
    modules.HandleMouse(e);
    perfMeter.EndDetail(eventTimer);
end);

ashita.events.register('login', 'libraplates_login', function()
    targeting.HandleLogin();
    modules.HandleLogin();
end);

ashita.events.register('packet_in', 'libraplates_packet_in', function(e)
    local eventTimer = perfMeter.BeginDetail('event.packetIn');
    blacklistModelReplace.HandlePacketIn(e);
    mounts.HandlePacketIn(e);
    targeting.HandlePacketIn(e);
    mogJobDebug.HandlePacketIn(e);
    engagedEnemies.HandlePacketIn(e);
    enmity.HandlePacketIn(e);
    enemyCasts.HandlePacketIn(e);
    targetActionRange.HandlePacketIn(e);
    local alertsTimer = perfMeter.BeginDetail('alerts.packet');
    enemyAlerts.HandlePacketIn(e);
    perfMeter.EndDetail(alertsTimer);
    enemyStatuses.HandlePacketIn(e);
    partyStatuses.HandlePacketIn(e);
    trustStatusIcons.HandlePacketIn(e);
    luopanStatuses.HandlePacketIn(e);
    bstCharmTimer.HandlePacketIn(e);
    quickMenu.HandlePacketIn(e);
    fishing.HandlePacketIn(e);
    crafting.HandlePacketIn(e);
    perfMeter.EndDetail(eventTimer);
end);

ashita.events.register('packet_out', 'libraplates_packet_out', function(e)
    local eventTimer = perfMeter.BeginDetail('event.packetOut');
    mounts.HandlePacketOut(e);
    targetActionRange.HandlePacketOut(e);
    mogJobDebug.HandlePacketOut(e);
    petState.HandlePacketOut(e);
    bstCharmTimer.HandlePacketOut(e);
    quickMenu.HandlePacketOut(e);
    fishing.HandlePacketOut(e);
    perfMeter.EndDetail(eventTimer);
end);

local function ShouldIgnoreTextInForLibraPlates(e)
    local raw = tostring((e ~= nil and (e.message or e.text or e.original or e.modified or e.injected)) or '');
    local text = raw:gsub(string.char(0x1E) .. '.', ''):gsub('[%z\1-\31]', '');

    if (text == '') then
        return true;
    end

    local lower = text:lower();

    return
        lower:find('a command error occurred', 1, true) ~= nil or
        lower:find('[thotbar] swapped to palette:', 1, true) ~= nil or
        lower:find('^%s*>>%s*/ja%s+') ~= nil or
        lower:find('^%s*>>%s*/jobability%s+') ~= nil or
        lower:find('^%s*>>%s*/ma%s+') ~= nil or
        lower:find('^%s*>>%s*/magic%s+') ~= nil or
        lower:find('^%s*>>%s*/trust%s+') ~= nil;
end

ashita.events.register('text_in', 'libraplates_text_in', function(e)
    local eventTimer = perfMeter.BeginDetail('event.textIn');
    if (fishing.HandleTextIn(e) == true or (e ~= nil and e.blocked == true)) then
        perfMeter.EndDetail(eventTimer);
        return;
    end

    if (ShouldIgnoreTextInForLibraPlates(e) == true) then
        perfMeter.EndDetail(eventTimer);
        return;
    end

    restingTick.HandleTextIn(e);
    local alertsTimer = perfMeter.BeginDetail('alerts.text');
    enemyAlerts.HandleTextIn(e);
    perfMeter.EndDetail(alertsTimer);
    enemyStatuses.HandleTextIn(e);
    quickMenu.HandleTextIn(e);
    perfMeter.EndDetail(eventTimer);
end);

ashita.events.register('d3d_present', 'libraplates_present', function()
    local ok, err = pcall(function()
        adaptivePerformance.UpdateFrame();
        blacklistModelReplace.Update();
        mounts.Update();
        profileAutoSwitch.Update();
        nativeTargetArrow.SetTraceCapturePaused(false);
        nativeTargetArrow.EndTraceFrame();
        nativeTargetArrow.SetTraceCapturePaused(true);
        fishing.HandlePresent();
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
