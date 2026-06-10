local modules = {};
local state = require('core.state');
local log = require('core.log');
local entities = require('core.entities');
local targeting = require('core.targeting');
local mouseControls = require('core.mouse_controls');
local worldMarkerProbe = require('core.world_marker_probe');
local nativeTargetArrow = require('core.native_target_arrow');
local quickMenu = require('core.quick_menu');
local peerInspector = require('modules.peer_inspector');
local perfMeter = require('core.perf_meter');
local diagnostics = require('core.diagnostics');
local lagTest = require('core.lag_test');
local cursorOverlay = require('core.cursor_overlay');
local imgui = require('imgui');

-- ============================================================
-- Module registry
-- ============================================================

modules.plates = require('modules.plates.init');
modules.widgets = require('modules.widgets.init');
modules.settings = require('modules.settings.init');
modules.targetOverlay = require('modules.target_overlay');

local previousHadAnyTarget = false;
local nativeTargetStartupBurstFrames = 0;
local nativeTargetStartupBurstMaxFrames = 6;
local nativeTargetStartupTransitions = 0;
local nativeTargetLastTransitionClock = 0;
local nativeTargetStartupBurstApplied = 0;
local nativeNamesLastHidden = nil;

local function HasAnyTarget()
    local targetIndex, subTargetIndex = targeting.GetCurrentTargetAndSubTargetIndexes();

    return targetIndex ~= nil or subTargetIndex ~= nil;
end

local function UpdateNativeTargetStartupBurst()
    local hasAnyTarget = HasAnyTarget();

    if (previousHadAnyTarget ~= true and hasAnyTarget == true) then
        nativeTargetStartupBurstFrames = nativeTargetStartupBurstMaxFrames;
        nativeTargetStartupTransitions = nativeTargetStartupTransitions + 1;
        nativeTargetLastTransitionClock = os.clock();
    elseif (hasAnyTarget ~= true) then
        nativeTargetStartupBurstFrames = 0;
    end

    previousHadAnyTarget = hasAnyTarget == true;
end

local function UpdateNativeTargetArrowVisibility()
    UpdateNativeTargetStartupBurst();

    local targetingSettings = targeting.GetSettings();
    local hasAnyTarget = HasAnyTarget();
    local mogHouseNativePassthrough = entities.IsMogHouseObjectSuppressionArea() == true;
    local nativeHideSettingEnabled =
        targetingSettings.hideNativeTargetArrow == true and
        mogHouseNativePassthrough ~= true;
    local hideNativePartyTargetUi =
        (
            targetingSettings.hideNativePartyTargetUi == true or
            targetingSettings.hideNativeTargetArrow == true
        ) and
        mogHouseNativePassthrough ~= true;
    local hideNativeTargetArrow =
        nativeHideSettingEnabled == true and
        hasAnyTarget == true and
        hideNativePartyTargetUi ~= true;
    local startupBurstActive =
        nativeHideSettingEnabled == true and
        hasAnyTarget == true and
        nativeTargetStartupBurstFrames > 0;

    nativeTargetArrow.SetHideAllPrimitivesEnabled(hideNativePartyTargetUi);
    nativeTargetArrow.SetHardHideEveryDrawEnabled(hideNativePartyTargetUi or hideNativeTargetArrow);
    nativeTargetArrow.SetTargetPrimitiveHideAllowed(mogHouseNativePassthrough ~= true or hasAnyTarget == true);
    nativeTargetArrow.SetEnabled(hideNativeTargetArrow or startupBurstActive);

    if (startupBurstActive == true) then
        nativeTargetArrow.SetHardHideBurstFrames(nativeTargetStartupBurstFrames);
    end

    nativeTargetArrow.Update();

    if (startupBurstActive == true) then
        if (hideNativePartyTargetUi == true) then
            nativeTargetArrow.HideAllPrimitivesOnce();
        else
            nativeTargetArrow.HideTargetPrimitiveOnce();
        end

        nativeTargetStartupBurstApplied = nativeTargetStartupBurstApplied + 1;
        nativeTargetStartupBurstFrames = nativeTargetStartupBurstFrames - 1;
    end
end

local function QueueNativeNamesCommand(hidden)
    pcall(function()
        AshitaCore:GetChatManager():QueueCommand(1, hidden == true and '/names off' or '/names on');
    end);
end

local function UpdateNativeNamesVisibility(force)
    local targetingSettings = targeting.GetSettings();
    local shouldHide = true;

    if (force == true or nativeNamesLastHidden ~= shouldHide) then
        nativeNamesLastHidden = shouldHide;
        QueueNativeNamesCommand(shouldHide);
    end
end

-- ============================================================
-- Lifecycle
-- ============================================================

function modules.Load()
    worldMarkerProbe.SetImgui(imgui);
    worldMarkerProbe.SetEnabled(true);
    worldMarkerProbe.SetReplacePlates(true);
    worldMarkerProbe.SetShowText(true);
    worldMarkerProbe.SetShowDistance(false);
    worldMarkerProbe.SetAnchorMode('bone');
    worldMarkerProbe.SetAnchorBone(2);
    worldMarkerProbe.SetVerticalOffset(0.16);
    worldMarkerProbe.SetNameVerticalOffset(0.54);

    modules.plates.Load();
    modules.settings.Load();

    UpdateNativeNamesVisibility(true);
end

function modules.Unload()
    nativeTargetArrow.RestoreAll();
    mouseControls.Release();
    modules.settings.Unload();
    modules.plates.Unload();
end

function modules.Render()
    perfMeter.BeginFrame();
    local totalStart = perfMeter.Start();

    if (state.GetConfigOpen() ~= true) then
        mouseControls.Update();
    else
        mouseControls.Release();
    end

    local settingsStart = perfMeter.Start();
    modules.settings.Render();
    perfMeter.Stop('settings', settingsStart);

    local targetingStart = perfMeter.Start();
    targeting.Update();
    perfMeter.Stop('targeting', targetingStart);

    local nativeStart = perfMeter.Start();
    UpdateNativeTargetArrowVisibility();
    UpdateNativeNamesVisibility(false);
    perfMeter.Stop('native', nativeStart);

    if (state.GetConfigOpen() ~= true) then
        worldMarkerProbe.UpdateFocusState();
        worldMarkerProbe.SetClickHandlers(targeting.SelectTarget, targeting.SelectEnemyTarget, targeting.AttackEnemyTarget);
        worldMarkerProbe.DrawRawClickDebug();
    end

    local platesStart = perfMeter.Start();
    local ok, err = pcall(function()
        modules.plates.Render();
    end);
    perfMeter.Stop('plates.total', platesStart);

    if (ok ~= true) then
        state.SetWorldRuntimeDisabled(true);
        log.Warn('World render disabled after error: ' .. tostring(err));
    end

    local overlayStart = perfMeter.Start();
    modules.targetOverlay.Render();
    perfMeter.Stop('target.overlay', overlayStart);

    local peerStart = perfMeter.Start();
    peerInspector.Render();
    perfMeter.Stop('peer', peerStart);

    local quickStart = perfMeter.Start();
    quickMenu.Render();
    perfMeter.Stop('quick.menu', quickStart);

    cursorOverlay.Render();

    perfMeter.Stop('total', totalStart);
    lagTest.Update();
    diagnostics.Update();
    perfMeter.RenderOverlay();
end

function modules.HandleMouse(e)
    cursorOverlay.HandleMouse(e);
    worldMarkerProbe.UpdateFocusState();

    if (state.GetConfigOpen() == true) then
        mouseControls.Release();
        return;
    end

    if (
        state.GetWorldEnabled() == true and
        worldMarkerProbe.GetEnabled() == true and
        worldMarkerProbe.GetReplacePlates() == true and
        worldMarkerProbe.HandleMouse(e, targeting.SelectTarget, targeting.SelectEnemyTarget, targeting.AttackEnemyTarget, targeting.InteractFishingGatheringTarget, quickMenu.OpenForPlate) == true
    ) then
        return;
    end

    if (targeting.TryRightClickFish(e) == true) then
        return;
    end

    mouseControls.HandleMouse(e);
end

function modules.ResetWorldMarker()
    worldMarkerProbe.ResetPass();
end

function modules.PrepareWorldMarkerFont()
    worldMarkerProbe.PrepareFontAtlas();
end

function modules.DrawWorldMarker()
    if (state.GetWorldEnabled() ~= true or worldMarkerProbe.GetEnabled() ~= true) then
        return;
    end

    local drawStart = perfMeter.Start();
    local ok, err = pcall(function()
        worldMarkerProbe.DrawQueued(entities.GetEntityManager, entities.GetBone);
    end);
    perfMeter.Stop('world.draw', drawStart);

    local stats = worldMarkerProbe.GetPerfStats();
    if (stats ~= nil) then
        perfMeter.SetCounter('queued', stats.queued);
        perfMeter.SetCounter('drawn', stats.drawn);
        perfMeter.SetCounter('clickRects', stats.clickRects);
    end

    if (ok ~= true) then
        state.SetWorldRuntimeDisabled(true);
        log.Warn('World marker render disabled after error: ' .. tostring(err));
    end
end

function modules.UpdateNativeTargetArrow()
    UpdateNativeTargetStartupBurst();

    local targetingSettings = targeting.GetSettings();
    local hasAnyTarget = HasAnyTarget();
    local mogHouseNativePassthrough = entities.IsMogHouseObjectSuppressionArea() == true;
    local hideNativePartyTargetUi =
        (
            targetingSettings.hideNativePartyTargetUi == true or
            targetingSettings.hideNativeTargetArrow == true
        ) and
        mogHouseNativePassthrough ~= true;
    local nativeHideSettingEnabled =
        targetingSettings.hideNativeTargetArrow == true and
        mogHouseNativePassthrough ~= true;
    local hideNativeTargetArrow =
        nativeHideSettingEnabled == true and
        hasAnyTarget == true and
        hideNativePartyTargetUi ~= true;
    local startupBurstActive =
        nativeHideSettingEnabled == true and
        hasAnyTarget == true and
        nativeTargetStartupBurstFrames > 0;

    nativeTargetArrow.SetHideAllPrimitivesEnabled(hideNativePartyTargetUi);
    nativeTargetArrow.SetHardHideEveryDrawEnabled(hideNativePartyTargetUi or hideNativeTargetArrow);
    nativeTargetArrow.SetTargetPrimitiveHideAllowed(mogHouseNativePassthrough ~= true or hasAnyTarget == true);
    nativeTargetArrow.SetEnabled(hideNativeTargetArrow or startupBurstActive);

    if (hideNativePartyTargetUi == true or hideNativeTargetArrow == true) then
        nativeTargetArrow.Update();
    elseif (startupBurstActive == true) then
        nativeTargetArrow.SetHardHideBurstFrames(nativeTargetStartupBurstFrames);
        nativeTargetArrow.HideTargetPrimitiveOnce();
    end
end

function modules.GetNativeTargetArrowDebugStatus()
    local hasAnyTarget = HasAnyTarget();
    local settingEnabled = targeting.GetSettings().hideNativeTargetArrow == true;
    local mogHouseNativePassthrough = entities.IsMogHouseObjectSuppressionArea() == true;
    local gateOk = modules.targetOverlay.CanHideNativeTargetUi() == true;

    return 'setting=' .. tostring(settingEnabled) ..
        ' hasTarget=' .. tostring(hasAnyTarget) ..
        ' mogNativePass=' .. tostring(mogHouseNativePassthrough) ..
        ' gate=' .. tostring(gateOk) ..
        ' burst=' .. tostring(nativeTargetStartupBurstFrames) ..
        ' transitions=' .. tostring(nativeTargetStartupTransitions) ..
        ' lastTransition=' .. string.format('%.2f', tonumber(nativeTargetLastTransitionClock) or 0) ..
        ' burstApplied=' .. tostring(nativeTargetStartupBurstApplied) ..
        ' hideGateReason=' .. tostring(modules.targetOverlay.GetNativeHideDebugStatus()) ..
        ' previousHadAnyTarget=' .. tostring(previousHadAnyTarget);
end

return modules;
