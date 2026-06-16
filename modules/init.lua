local modules = {};
local state = require('core.state');
local log = require('core.log');
local entities = require('core.entities');
local targeting = require('core.targeting');
local mouseControls = require('core.mouse_controls');
local worldMarkerProbe = require('core.world_marker_probe');
local nativeTargetArrow = require('core.native_target_arrow');
local targetModuleMarker = require('core.target_module_marker');
local quickMenu = require('core.quick_menu');
local peerInspector = require('modules.peer_inspector');
local perfMeter = require('core.perf_meter');
local diagnostics = require('core.diagnostics');
local lagTest = require('core.lag_test');
local cursorOverlay = require('core.cursor_overlay');
local jobChange = require('core.job_change');
local enemyCasts = require('core.enemy_casts');
local imgui = require('imgui');

-- ============================================================
-- Module registry
-- ============================================================

modules.plates = require('modules.plates.init');
modules.widgets = require('modules.widgets.init');
modules.settings = require('modules.settings.init');
modules.targetOverlay = require('modules.target_overlay');

local previousHadAnyTarget = false;
local previousTargetIndex = nil;
local previousSubTargetIndex = nil;
local nativeTargetStartupBurstFrames = 0;
local nativeTargetStartupBurstMaxFrames = 6;
local nativeTargetStartupTransitions = 0;
local nativeTargetLastTransitionClock = 0;
local nativeTargetStartupBurstApplied = 0;
local nativeNamesLastHidden = nil;
local nativeNamesPendingHidden = nil;
local nativeNamesRetryFrames = 0;
local nativeNamesRetryIntervalFrames = 120;
local nativeNamesNextRetryFrame = 0;
local nativeNamesFrameCounter = 0;
local nativeNamesPeriodicIntervalFrames = 600;
local nativeNamesNextPeriodicFrame = 0;
local targetModulePrewarmQueue = {};
local targetModulePrewarmWarned = false;
local perfIsolation = {
    targeting = false,
    native = false,
    mouse = false,
    overlays = false,
};

local function GetLoginStatus()
    local status = nil;

    pcall(function()
        local player = AshitaCore:GetMemoryManager():GetPlayer();
        if (player ~= nil) then
            status = player:GetLoginStatus();
        end
    end);

    return tonumber(status) or 0;
end

local function HasAnyTarget()
    local targetIndex, subTargetIndex = targeting.GetCurrentTargetAndSubTargetIndexes();

    return targetIndex ~= nil or subTargetIndex ~= nil;
end

local function UpdateNativeTargetStartupBurst()
    local targetIndex, subTargetIndex = targeting.GetCurrentTargetAndSubTargetIndexes();
    local hasAnyTarget = targetIndex ~= nil or subTargetIndex ~= nil;
    local targetChanged =
        tonumber(previousTargetIndex or 0) ~= tonumber(targetIndex or 0) or
        tonumber(previousSubTargetIndex or 0) ~= tonumber(subTargetIndex or 0);

    if ((previousHadAnyTarget ~= true or targetChanged == true) and hasAnyTarget == true) then
        nativeTargetStartupBurstFrames = nativeTargetStartupBurstMaxFrames;
        nativeTargetStartupTransitions = nativeTargetStartupTransitions + 1;
        nativeTargetLastTransitionClock = os.clock();
    elseif (hasAnyTarget ~= true) then
        nativeTargetStartupBurstFrames = 0;
    end

    previousHadAnyTarget = hasAnyTarget == true;
    previousTargetIndex = targetIndex;
    previousSubTargetIndex = subTargetIndex;
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
        ) and mogHouseNativePassthrough ~= true;
    local hideNativeTargetArrow =
        nativeHideSettingEnabled == true and
        hasAnyTarget == true and
        hideNativePartyTargetUi ~= true;
    local startupBurstActive =
        nativeHideSettingEnabled == true and
        hasAnyTarget == true and
        nativeTargetStartupBurstFrames > 0;

    nativeTargetArrow.SetHideAllPrimitivesEnabled(hideNativePartyTargetUi);
    nativeTargetArrow.SetHardHideEveryDrawEnabled(hideNativeTargetArrow);
    nativeTargetArrow.SetTargetPrimitiveHideAllowed(mogHouseNativePassthrough ~= true or hasAnyTarget == true);
    nativeTargetArrow.SetEnabled(hideNativeTargetArrow or startupBurstActive);

    if (startupBurstActive == true) then
        nativeTargetArrow.SetHardHideBurstFrames(nativeTargetStartupBurstFrames);
    end

    nativeTargetArrow.Update();

    if (startupBurstActive == true) then
        nativeTargetArrow.HideTargetPrimitiveOnce();

        nativeTargetStartupBurstApplied = nativeTargetStartupBurstApplied + 1;
        nativeTargetStartupBurstFrames = nativeTargetStartupBurstFrames - 1;
    end
end

local function QueueNativeNamesCommand(hidden)
    if (GetLoginStatus() ~= 2) then
        return false;
    end

    pcall(function()
        AshitaCore:GetChatManager():QueueCommand(-1, hidden == true and '/names off' or '/names on');
    end);

    pcall(function()
        AshitaCore:GetChatManager():QueueCommand(1, hidden == true and '/names off' or '/names on');
    end);

    return true;
end

local function ScheduleNativeNamesSync(hidden, retryCount, retryIntervalFrames)
    nativeNamesPendingHidden = hidden == true;
    nativeNamesRetryFrames = math.max(0, tonumber(retryCount) or 0);
    nativeNamesRetryIntervalFrames = math.max(1, tonumber(retryIntervalFrames) or 120);
    nativeNamesNextRetryFrame = nativeNamesFrameCounter + nativeNamesRetryIntervalFrames;
    nativeNamesNextPeriodicFrame = nativeNamesFrameCounter + nativeNamesPeriodicIntervalFrames;
    QueueNativeNamesCommand(nativeNamesPendingHidden);
end

local function UpdateNativeNamesRetry()
    if (nativeNamesPendingHidden ~= nil and nativeNamesRetryFrames > 0 and nativeNamesFrameCounter >= nativeNamesNextRetryFrame) then
        QueueNativeNamesCommand(nativeNamesPendingHidden);
        nativeNamesRetryFrames = nativeNamesRetryFrames - 1;
        nativeNamesNextRetryFrame = nativeNamesFrameCounter + nativeNamesRetryIntervalFrames;

        if (nativeNamesRetryFrames <= 0) then
            nativeNamesPendingHidden = nil;
        end
    end

    if (nativeNamesLastHidden ~= nil and nativeNamesFrameCounter >= nativeNamesNextPeriodicFrame) then
        QueueNativeNamesCommand(nativeNamesLastHidden);
        nativeNamesNextPeriodicFrame = nativeNamesFrameCounter + nativeNamesPeriodicIntervalFrames;
    end
end

local function UpdateNativeNamesVisibility(force)
    local targetingSettings = targeting.GetSettings();
    local shouldHide = targetingSettings.hideNativeNamesOnLoad == true;

    if (force == true or nativeNamesLastHidden ~= shouldHide) then
        nativeNamesLastHidden = shouldHide;
        ScheduleNativeNamesSync(shouldHide, 12, 20);
    end
end

local function ResetTargetModulePrewarmQueue()
    targetModulePrewarmQueue = {};
    targetModulePrewarmWarned = false;

    for _, entityName in ipairs({ 'Self', 'Trust', 'PC', 'Enemy', 'NPC', 'Object' }) do
        targetModulePrewarmQueue[#targetModulePrewarmQueue + 1] = { entity = entityName, target = 'Target' };
        targetModulePrewarmQueue[#targetModulePrewarmQueue + 1] = { entity = entityName, target = 'Subtarget' };
    end
end

local function UpdateTargetModulePrewarm()
    if (#targetModulePrewarmQueue == 0) then
        return;
    end

    local item = table.remove(targetModulePrewarmQueue, 1);
    local ok, err = pcall(function()
        targetModuleMarker.Build(item.entity, 'Combat', item.target, { enabled = true, width = 180, height = 12, offsetX = 0, offsetY = 0 }, 0);
    end);

    if (ok ~= true and targetModulePrewarmWarned ~= true) then
        targetModulePrewarmWarned = true;
        log.Warn('Target module prewarm failed: ' .. tostring(err));
    end
end

function modules.HandleLogin()
    nativeNamesLastHidden = nil;
    UpdateNativeNamesVisibility(true);
    ResetTargetModulePrewarmQueue();
end

-- ============================================================
-- Lifecycle
-- ============================================================

function modules.Load()
    jobChange.Cancel();
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
    ResetTargetModulePrewarmQueue();
end

function modules.Unload()
    jobChange.Cancel();
    nativeTargetArrow.RestoreAll();
    mouseControls.Release();
    modules.settings.Unload();
    modules.plates.Unload();
end

function modules.Render()
    nativeNamesFrameCounter = nativeNamesFrameCounter + 1;
    perfMeter.BeginFrame();
    local totalStart = perfMeter.Start();

    if (perfIsolation.mouse == true) then
        mouseControls.Release();
    elseif (state.GetConfigOpen() ~= true) then
        mouseControls.Update();
    else
        mouseControls.Release();
    end

    local settingsStart = perfMeter.Start();
    modules.settings.Render();
    perfMeter.Stop('settings', settingsStart);

    local targetingStart = perfMeter.Start();
    if (perfIsolation.targeting ~= true) then
        targeting.Update();
    end
    perfMeter.Stop('targeting', targetingStart);

    local nativeStart = perfMeter.Start();
    if (perfIsolation.native ~= true) then
        UpdateNativeTargetArrowVisibility();
        UpdateNativeNamesVisibility(false);
        UpdateNativeNamesRetry();
        UpdateTargetModulePrewarm();
        jobChange.Update();
        enemyCasts.TickDebug();
    end
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
    if (perfIsolation.overlays ~= true) then
        modules.targetOverlay.Render();
    end
    perfMeter.Stop('target.overlay', overlayStart);

    local peerStart = perfMeter.Start();
    if (perfIsolation.overlays ~= true) then
        peerInspector.Render();
    end
    perfMeter.Stop('peer', peerStart);

    local quickStart = perfMeter.Start();
    if (perfIsolation.overlays ~= true) then
        quickMenu.Render();
    end
    perfMeter.Stop('quick.menu', quickStart);

    if (perfIsolation.overlays ~= true) then
        cursorOverlay.Render();
    end

    perfMeter.Stop('total', totalStart);
    lagTest.Update();
    diagnostics.Update();
    perfMeter.RenderOverlay();
end

function modules.HandleMouse(e)
    if (perfIsolation.mouse == true) then
        mouseControls.Release();
        return;
    end

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

function modules.SetPerfIsolation(name, value)
    name = tostring(name or ''):lower();

    if (name == 'all') then
        local enabled = value == true;
        for key, _ in pairs(perfIsolation) do
            perfIsolation[key] = enabled;
        end
        if (enabled == true) then
            mouseControls.Release();
            nativeTargetArrow.RestoreAll();
        end
        return true;
    end

    if (perfIsolation[name] == nil) then
        return false;
    end

    perfIsolation[name] = value == true;

    if (name == 'mouse' and value == true) then
        mouseControls.Release();
    elseif (name == 'native' and value == true) then
        nativeTargetArrow.RestoreAll();
    end

    return true;
end

function modules.GetPerfIsolation(name)
    name = tostring(name or ''):lower();

    if (name == 'all') then
        for _, enabled in pairs(perfIsolation) do
            if (enabled == true) then
                return true;
            end
        end
        return false;
    end

    return perfIsolation[name] == true;
end

function modules.GetPerfIsolationStatus()
    return 'targeting=' .. tostring(perfIsolation.targeting == true) ..
        ' native=' .. tostring(perfIsolation.native == true) ..
        ' mouse=' .. tostring(perfIsolation.mouse == true) ..
        ' overlays=' .. tostring(perfIsolation.overlays == true);
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
        ) and mogHouseNativePassthrough ~= true;
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
    nativeTargetArrow.SetHardHideEveryDrawEnabled(hideNativeTargetArrow);
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
