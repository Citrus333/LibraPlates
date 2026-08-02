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
local errorBoundary = require('core.error_boundary');
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
local currentTargetDebuffs = require('core.current_target_debuffs');
local partyStatuses = require('core.party_statuses');
local trustStatusIcons = require('core.trust_status_icons');
local luopanStatuses = require('core.luopan_statuses');
local restingTick = require('core.resting_tick');
local petState = require('core.pet_state');
local bstCharmTimer = require('core.bst_charm_timer');
local fishing = require('core.fishing');
local crafting = require('core.crafting');
local textureLoader = require('core.texture_loader');
local canvasTexture = require('core.canvas_texture');
local npcObjectInfo = require('core.npc_object_info');
local quickMenu = require('core.quick_menu');
local mogHouseExit = require('core.mog_house_exit');
local questLogTest = require('core.quest_log_test');
local mounts = require('core.mounts');
local anonStatus = require('core.anon_status');
local playerBlacklist = require('core.player_blacklist');
local blacklistModelReplace = require('core.blacklist_model_replace');
local diagnostics = require('core.diagnostics');
local adaptivePerformance = require('core.adaptive_performance');
local perfMeter = require('core.perf_meter');
local profileAutoSwitch = require('core.profile_auto_switch');
local mogJobDebug = require('core.mog_job_debug');
local itemFlickerTrace = require('core.item_flicker_trace');
local nativeDrawHooksRegistered = false;

local function RegisterNativeDrawHooks()
    if (nativeDrawHooksRegistered == true) then
        return;
    end

    ashita.events.register('d3d_dp', 'libraplates_native_target_trace_dp', function(e)
        errorBoundary.Call('draw_hook.dp', 'Native target-arrow DrawPrimitive hook', nativeTargetArrow.HandleDrawPrimitive, e);
    end);

    ashita.events.register('d3d_dip', 'libraplates_native_target_trace_dip', function(e)
        errorBoundary.Call('draw_hook.dip', 'Native target-arrow DrawIndexedPrimitive hook', nativeTargetArrow.HandleDrawIndexedPrimitive, e);
    end);

    ashita.events.register('d3d_dpup', 'libraplates_native_target_trace_dpup', function(e)
        errorBoundary.Call('draw_hook.dpup', 'Native target-arrow DrawPrimitiveUp hook', nativeTargetArrow.HandleDrawPrimitiveUp, e);
    end);

    ashita.events.register('d3d_dipup', 'libraplates_native_target_trace_dipup', function(e)
        errorBoundary.Call('draw_hook.dipup', 'Native target-arrow DrawIndexedPrimitiveUp hook', nativeTargetArrow.HandleDrawIndexedPrimitiveUp, e);
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
    collectgarbage('collect');
end);

-- ============================================================
-- Events
-- ============================================================

ashita.events.register('command', 'libraplates_command', function(e)
    local eventTimer = perfMeter.BeginDetail('event.command');
    local actionRangeTimer = perfMeter.BeginDetail('command.actionRange');
    errorBoundary.Call('command.item_flicker', 'Item-flicker command handler', itemFlickerTrace.HandleCommandText, e.command);
    errorBoundary.Call('command.action_range', 'Action-range command handler', targetActionRange.HandleCommandText, e.command);
    errorBoundary.Call('command.pet', 'Pet command handler', modules.plates.pet.HandleCommandText, e.command);
    perfMeter.EndDetail(actionRangeTimer);
    local aoeTimer = perfMeter.BeginDetail('command.aoe');
    errorBoundary.Call('command.aoe', 'AoE-name command handler', aoeNameHighlight.HandleCommandText, e.command);
    perfMeter.EndDetail(aoeTimer);
    local mountsTimer = perfMeter.BeginDetail('command.mounts');
    errorBoundary.Call('command.mounts', 'Mount command handler', mounts.HandleCommandText, e.command);
    perfMeter.EndDetail(mountsTimer);
    local otherTimer = perfMeter.BeginDetail('command.other');
    errorBoundary.Call('command.anon', 'Anonymous-status command handler', anonStatus.HandleCommandText, e.command);
    errorBoundary.Call('command.blacklist', 'Blacklist command handler', playerBlacklist.HandleCommandText, e.command);
    errorBoundary.Call('command.general', 'LibraPlates command handler', commands.Handle, e);
    perfMeter.EndDetail(otherTimer);
    perfMeter.EndDetail(eventTimer);
end);

ashita.events.register('mouse', 'libraplates_mouse', function(e)
    local eventTimer = perfMeter.BeginDetail('event.mouse');
    errorBoundary.Call('event.mouse', 'Mouse event handler', modules.HandleMouse, e);
    perfMeter.EndDetail(eventTimer);
end);

ashita.events.register('login', 'libraplates_login', function()
    errorBoundary.Call('login.canvas_texture', 'Canvas login-transition handler', canvasTexture.HandleLogin);
    errorBoundary.Call('login.pet_plate', 'Pet-plate login-transition handler', modules.plates.pet.HandleLogin);
    errorBoundary.Call('login.targeting', 'Targeting login handler', targeting.HandleLogin);
    errorBoundary.Call('login.modules', 'Module login handler', modules.HandleLogin);
end);

ashita.events.register('packet_in', 'libraplates_packet_in', function(e)
    local eventTimer = perfMeter.BeginDetail('event.packetIn');
    errorBoundary.Call('packet_in.canvas_texture', 'Canvas zone-transition handler', canvasTexture.HandlePacketIn, e);
    errorBoundary.Call('packet_in.pet_plate', 'Pet-plate zone-transition handler', modules.plates.pet.HandlePacketIn, e);
    errorBoundary.Call('packet_in.item_flicker', 'Item-flicker incoming-packet handler', itemFlickerTrace.HandlePacketIn, e);
    errorBoundary.Call('packet_in.blacklist', 'Blacklist incoming-packet handler', blacklistModelReplace.HandlePacketIn, e);
    errorBoundary.Call('packet_in.mounts', 'Mount incoming-packet handler', mounts.HandlePacketIn, e);
    errorBoundary.Call('packet_in.targeting', 'Targeting incoming-packet handler', targeting.HandlePacketIn, e);
    errorBoundary.Call('packet_in.mog_job_debug', 'Mog-job debug incoming-packet handler', mogJobDebug.HandlePacketIn, e);
    errorBoundary.Call('packet_in.engaged_enemies', 'Engaged-enemy incoming-packet handler', engagedEnemies.HandlePacketIn, e);
    errorBoundary.Call('packet_in.enmity', 'Enmity incoming-packet handler', enmity.HandlePacketIn, e);
    errorBoundary.Call('packet_in.enemy_casts', 'Enemy-cast incoming-packet handler', enemyCasts.HandlePacketIn, e);
    errorBoundary.Call('packet_in.action_range', 'Action-range incoming-packet handler', targetActionRange.HandlePacketIn, e);
    local alertsTimer = perfMeter.BeginDetail('alerts.packet');
    errorBoundary.Call('packet_in.enemy_alerts', 'Enemy-alert incoming-packet handler', enemyAlerts.HandlePacketIn, e);
    perfMeter.EndDetail(alertsTimer);
    errorBoundary.Call('packet_in.enemy_statuses', 'Enemy-status incoming-packet handler', enemyStatuses.HandlePacketIn, e);
    errorBoundary.Call('packet_in.current_target_debuffs', 'Current-target debuff incoming-packet handler', currentTargetDebuffs.HandlePacketIn, e);
    errorBoundary.Call('packet_in.party_statuses', 'Party-status incoming-packet handler', partyStatuses.HandlePacketIn, e);
    errorBoundary.Call('packet_in.trust_statuses', 'Trust-status incoming-packet handler', trustStatusIcons.HandlePacketIn, e);
    errorBoundary.Call('packet_in.luopan_statuses', 'Luopan-status incoming-packet handler', luopanStatuses.HandlePacketIn, e);
    errorBoundary.Call('packet_in.bst_charm', 'BST charm-timer incoming-packet handler', bstCharmTimer.HandlePacketIn, e);
    errorBoundary.Call('packet_in.mog_house_exit', 'Mog-house exit incoming-packet handler', mogHouseExit.HandlePacketIn, e);
    errorBoundary.Call('packet_in.quest_log_test', 'Quest-log test incoming-packet handler', questLogTest.HandlePacketIn, e);
    errorBoundary.Call('packet_in.quick_menu', 'Quick-menu incoming-packet handler', quickMenu.HandlePacketIn, e);
    errorBoundary.Call('packet_in.fishing', 'Fishing incoming-packet handler', fishing.HandlePacketIn, e);
    errorBoundary.Call('packet_in.crafting', 'Crafting incoming-packet handler', crafting.HandlePacketIn, e);
    perfMeter.EndDetail(eventTimer);
end);

ashita.events.register('packet_out', 'libraplates_packet_out', function(e)
    local eventTimer = perfMeter.BeginDetail('event.packetOut');
    errorBoundary.Call('packet_out.item_flicker', 'Item-flicker outgoing-packet handler', itemFlickerTrace.HandlePacketOut, e);
    errorBoundary.Call('packet_out.mounts', 'Mount outgoing-packet handler', mounts.HandlePacketOut, e);
    errorBoundary.Call('packet_out.action_range', 'Action-range outgoing-packet handler', targetActionRange.HandlePacketOut, e);
    errorBoundary.Call('packet_out.mog_job_debug', 'Mog-job debug outgoing-packet handler', mogJobDebug.HandlePacketOut, e);
    errorBoundary.Call('packet_out.pet_state', 'Pet-state outgoing-packet handler', petState.HandlePacketOut, e);
    errorBoundary.Call('packet_out.bst_charm', 'BST charm-timer outgoing-packet handler', bstCharmTimer.HandlePacketOut, e);
    errorBoundary.Call('packet_out.quick_menu', 'Quick-menu outgoing-packet handler', quickMenu.HandlePacketOut, e);
    errorBoundary.Call('packet_out.fishing', 'Fishing outgoing-packet handler', fishing.HandlePacketOut, e);
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
    local itemFlickerTimer = perfMeter.BeginDetail('text.itemFlicker');
    errorBoundary.Call('text_in.item_flicker', 'Item-flicker text handler', itemFlickerTrace.HandleTextIn, e);
    perfMeter.EndDetail(itemFlickerTimer);

    local fishingTimer = perfMeter.BeginDetail('text.fishing');
    local _, fishingHandled = errorBoundary.Call('text_in.fishing', 'Fishing text handler', fishing.HandleTextIn, e);
    perfMeter.EndDetail(fishingTimer);
    if (fishingHandled == true or (e ~= nil and e.blocked == true)) then
        perfMeter.EndDetail(eventTimer);
        return;
    end

    if (ShouldIgnoreTextInForLibraPlates(e) == true) then
        perfMeter.EndDetail(eventTimer);
        return;
    end

    local restingTimer = perfMeter.BeginDetail('text.restingTick');
    errorBoundary.Call('text_in.resting_tick', 'Resting-tick text handler', restingTick.HandleTextIn, e);
    perfMeter.EndDetail(restingTimer);

    local petTimer = perfMeter.BeginDetail('text.pet');
    errorBoundary.Call('text_in.pet', 'Pet text handler', modules.plates.pet.HandleTextIn, e);
    perfMeter.EndDetail(petTimer);

    local alertsTimer = perfMeter.BeginDetail('alerts.text');
    errorBoundary.Call('text_in.enemy_alerts', 'Enemy-alert text handler', enemyAlerts.HandleTextIn, e);
    perfMeter.EndDetail(alertsTimer);

    local enemyStatusesTimer = perfMeter.BeginDetail('text.enemyStatuses');
    errorBoundary.Call('text_in.enemy_statuses', 'Enemy-status text handler', enemyStatuses.HandleTextIn, e);
    perfMeter.EndDetail(enemyStatusesTimer);

    local quickMenuTimer = perfMeter.BeginDetail('text.quickMenu');
    errorBoundary.Call('text_in.quick_menu', 'Quick-menu text handler', quickMenu.HandleTextIn, e);
    perfMeter.EndDetail(quickMenuTimer);
    perfMeter.EndDetail(eventTimer);
end);

ashita.events.register('d3d_present', 'libraplates_present', function()
    local eventStart = perfMeter.Start();
    errorBoundary.Call('present.adaptive_performance', 'Adaptive-performance frame update', adaptivePerformance.UpdateFrame);
    errorBoundary.Call('present.blacklist', 'Blacklist frame update', blacklistModelReplace.Update);
    errorBoundary.Call('present.mounts', 'Mount frame update', mounts.Update);
    errorBoundary.Call('present.profile_switch', 'Profile auto-switch update', profileAutoSwitch.Update);
    errorBoundary.Call('present.item_flicker', 'Item-flicker frame update', itemFlickerTrace.HandlePresent);
    errorBoundary.Call('present.native_trace_resume', 'Native target trace resume', nativeTargetArrow.SetTraceCapturePaused, false);
    errorBoundary.Call('present.native_trace_end', 'Native target trace finalization', nativeTargetArrow.EndTraceFrame);
    errorBoundary.Call('present.native_trace_pause', 'Native target trace pause', nativeTargetArrow.SetTraceCapturePaused, true);
    errorBoundary.Call('present.fishing', 'Fishing frame update', fishing.HandlePresent);
    errorBoundary.Call('present.native_target', 'Native target-arrow frame update', modules.UpdateNativeTargetArrow);
    errorBoundary.Call('present.native_hooks.before', 'Native draw-hook update', UpdateNativeDrawHooks);
    errorBoundary.Call('present.world_reset', 'World-marker pass reset', modules.ResetWorldMarker);
    errorBoundary.Call('present.modules', 'LibraPlates module render', modules.Render);
    errorBoundary.Call('present.native_hooks.after', 'Native draw-hook post-render update', UpdateNativeDrawHooks);
    errorBoundary.Call('present.world_font', 'World-marker font preparation', modules.PrepareWorldMarkerFont);
    perfMeter.Stop('present.frame', eventStart);
end);

ashita.events.register('d3d_beginscene', 'libraplates_world_marker_beginscene', function()
    local eventStart = perfMeter.Start();
    errorBoundary.Call('beginscene.native_target', 'Begin-scene native target-arrow update', modules.UpdateNativeTargetArrow);
    errorBoundary.Call('beginscene.native_hooks', 'Begin-scene native draw-hook update', UpdateNativeDrawHooks);
    errorBoundary.Call('beginscene.trace_pause', 'Begin-scene native trace pause', nativeTargetArrow.SetTraceCapturePaused, true);
    errorBoundary.Call('beginscene.world_marker', 'Begin-scene world-marker render', modules.DrawWorldMarker);
    errorBoundary.Call('beginscene.trace_resume', 'Begin-scene native trace resume', nativeTargetArrow.SetTraceCapturePaused, false);
    perfMeter.Stop('beginscene.frame', eventStart);
end);

ashita.events.register('d3d_endscene', 'libraplates_native_target_endscene', function()
    local eventStart = perfMeter.Start();
    errorBoundary.Call('endscene.native_target', 'End-scene native target-arrow update', modules.UpdateNativeTargetArrow);
    errorBoundary.Call('endscene.native_hooks', 'End-scene native draw-hook update', UpdateNativeDrawHooks);
    perfMeter.Stop('endscene.frame', eventStart);
end);
