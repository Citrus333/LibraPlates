local modules = {};
local state = require('core.state');
local log = require('core.log');
local errorBoundary = require('core.error_boundary');
local entities = require('core.entities');
local entityResolver = require('core.entity_resolver');
local targetPosition = require('core.target_position');
local occlusion = require('core.occlusion');
local targeting = require('core.targeting');
local mouseControls = require('core.mouse_controls');
local worldMarkerProbe = require('core.world_marker_probe');
local worldDepthPlate = require('core.world_depth_plate');
local nativeTargetArrow = require('core.native_target_arrow');
local targetModuleMarker = require('core.target_module_marker');
local quickMenu = require('core.quick_menu');
local canvasTexture = require('core.canvas_texture');
local backgroundTextures = require('core.background_textures');
local statusIconTextures = require('core.status_icon_textures');
local gdiText = require('ui.gdi_text');
local gdiTextTexture = require('ui.gdi_text_texture');
local peerInspector = require('modules.peer_inspector');
local perfMeter = require('core.perf_meter');
local diagnostics = require('core.diagnostics');
local lagTest = require('core.lag_test');
local cursorOverlay = require('core.cursor_overlay');
local currentTargetBar = require('core.current_target_bar');
local jobChange = require('core.job_change');
local enemyCasts = require('core.enemy_casts');
local enemyAlerts = require('core.enemy_alerts');
local imgui = require('imgui');
local fishing = require('core.fishing');
local fishingStaminaOverlay = require('core.fishing_stamina_overlay');
local warpMenu = require('core.warp_menu');
local restingTick = require('core.resting_tick');
local windowFocus = require('core.window_focus');

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
local suppressEmptyWorldLeftRelease = false;
local emptyWorldLeftClickFocusSuspended = false;
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
    if (previousHadAnyTarget ~= true and hasAnyTarget == true) then
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
    local fishingBarCaptureActive = fishing.ShouldCaptureFishBar ~= nil and fishing.ShouldCaptureFishBar() == true;
    local nativeHideSettingEnabled = targetingSettings.hideNativeTargetArrow == true;
    local hideNativePartyTargetUi =
        targetingSettings.hideNativePartyTargetUi == true and
        mogHouseNativePassthrough ~= true;
    local hideNativeTargetArrow =
        nativeHideSettingEnabled == true and
        hasAnyTarget == true;
    local startupBurstActive =
        nativeHideSettingEnabled == true and
        hasAnyTarget == true and
        nativeTargetStartupBurstFrames > 0;

    nativeTargetArrow.SetHideAllPrimitivesEnabled(hideNativePartyTargetUi == true and fishingBarCaptureActive ~= true);
    nativeTargetArrow.SetHardHideEveryDrawEnabled(hideNativeTargetArrow);
    nativeTargetArrow.SetFishingBarCaptureEnabled(fishingBarCaptureActive);
    nativeTargetArrow.SetTargetPrimitiveHideAllowed(mogHouseNativePassthrough ~= true or hasAnyTarget == true);
    nativeTargetArrow.SetEnabled(hideNativeTargetArrow or startupBurstActive or fishingBarCaptureActive);

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

    if (fishing.ShouldSuppressCommandErrorText() == true) then
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
    errorBoundary.Reset();
    entityResolver.Reset();
    jobChange.Cancel();
    canvasTexture.Clear();
    backgroundTextures.Clear();
    statusIconTextures.Clear();
    statusIconTextures.RefreshDevice();
    worldDepthPlate.RefreshDevice();
    entities.RefreshDevice();
    targetPosition.RefreshDevice();
    occlusion.RefreshDevice();
    canvasTexture.SetCacheLimit(targeting.GetSettings().textureCacheLimit);
    worldMarkerProbe.SetImgui(imgui);
    worldMarkerProbe.SetEnabled(true);
    worldMarkerProbe.SetReplacePlates(true);
    worldMarkerProbe.SetShowText(true);
    worldMarkerProbe.SetShowDistance(false);
    worldMarkerProbe.SetAnchorMode('bone');
    worldMarkerProbe.SetAnchorBone(2);
    worldMarkerProbe.SetVerticalOffset(0.16);
    worldMarkerProbe.SetNameVerticalOffset(0.54);

    modules.settings.Load();

    UpdateNativeNamesVisibility(true);
    ResetTargetModulePrewarmQueue();
end

function modules.Unload()
    entityResolver.Reset();
    jobChange.Cancel();
    nativeTargetArrow.RestoreAll();
    mouseControls.Release();
    worldMarkerProbe.Shutdown();
    modules.settings.Unload();
    gdiTextTexture.Clear();
    gdiText.Shutdown();
    canvasTexture.Clear();
    backgroundTextures.Clear();
    statusIconTextures.Clear();
    worldDepthPlate.ResetDevice();
    occlusion.ResetDevice();
    targetPosition.ResetDevice();
    entities.ResetDevice();
end

function modules.Render()
    nativeNamesFrameCounter = nativeNamesFrameCounter + 1;
    perfMeter.BeginFrame();
    local totalStart = perfMeter.Start();

    if (perfIsolation.mouse == true) then
        errorBoundary.Call('render.mouse.release', 'Mouse-control release', mouseControls.Release);
    elseif (state.GetConfigOpen() ~= true) then
        errorBoundary.Call('render.mouse.update', 'Mouse-control update', mouseControls.Update);
    end

    local settingsStart = perfMeter.Start();
    errorBoundary.Call('render.settings', 'Settings render', modules.settings.Render);
    perfMeter.Stop('settings', settingsStart);

    local targetingStart = perfMeter.Start();
    if (perfIsolation.targeting ~= true) then
        errorBoundary.Call('render.targeting', 'Targeting update', targeting.Update);
    end
    perfMeter.Stop('targeting', targetingStart);

    local nativeStart = perfMeter.Start();
    if (perfIsolation.native ~= true) then
        errorBoundary.Call('render.native.arrow', 'Native target-arrow update', UpdateNativeTargetArrowVisibility);
        errorBoundary.Call('render.native.names.visibility', 'Native-name visibility update', UpdateNativeNamesVisibility, false);
        errorBoundary.Call('render.native.names.retry', 'Native-name retry update', UpdateNativeNamesRetry);
        errorBoundary.Call('render.target.prewarm', 'Target-module prewarm', UpdateTargetModulePrewarm);
        errorBoundary.Call('render.job_change', 'Job-change update', jobChange.Update);
        errorBoundary.Call('render.warp_menu', 'Warp-menu update', warpMenu.Update);
        errorBoundary.Call('render.enemy_cast_debug', 'Enemy-cast debug update', enemyCasts.TickDebug);
    end
    perfMeter.Stop('native', nativeStart);

    local selfEntity = entities.GetSelf();
    if (selfEntity ~= nil) then
        errorBoundary.Call('render.resting_status', 'Resting-status transition update', restingTick.HandlePlayerStatus, selfEntity.status);
    end

    if (state.GetConfigOpen() ~= true) then
        errorBoundary.Call('render.world.focus', 'World-marker focus update', worldMarkerProbe.UpdateFocusState);
        errorBoundary.Call(
            'render.world.click_handlers',
            'World-marker click-handler update',
            worldMarkerProbe.SetClickHandlers,
            targeting.SelectTarget,
            targeting.SelectEnemyTarget,
            targeting.AttackEnemyTarget
        );
        errorBoundary.Call('render.world.click_debug', 'World-marker click debug', worldMarkerProbe.DrawRawClickDebug);
    end

    local platesStart = perfMeter.Start();
    errorBoundary.Call('render.plates', 'Plate rendering', modules.plates.Render);
    perfMeter.Stop('plates.total', platesStart);

    local overlayStart = perfMeter.Start();
    if (perfIsolation.overlays ~= true) then
        errorBoundary.Call('render.target_overlay', 'Target-overlay render', modules.targetOverlay.Render);
    end
    perfMeter.Stop('target.overlay', overlayStart);

    local peerStart = perfMeter.Start();
    if (perfIsolation.overlays ~= true) then
        errorBoundary.Call('render.peer', 'Peer-inspector render', peerInspector.Render);
    end
    perfMeter.Stop('peer', peerStart);

    local quickStart = perfMeter.Start();
    if (perfIsolation.overlays ~= true) then
        errorBoundary.Call('render.quick_menu', 'Quick-menu render', quickMenu.Render);
    end
    perfMeter.Stop('quick.menu', quickStart);

    if (perfIsolation.overlays ~= true) then
        errorBoundary.Call('render.cursor', 'Cursor-overlay render', cursorOverlay.Render);
        errorBoundary.Call('render.current_target_bar', 'Current-target bar render', currentTargetBar.Render);
        errorBoundary.Call('render.fishing_stamina', 'Fishing-stamina render', fishingStaminaOverlay.Render);
        errorBoundary.Call('render.enemy_alerts', 'Enemy-alert render', enemyAlerts.Render);
    end

    perfMeter.Stop('total', totalStart);
    errorBoundary.Call('render.lag_test', 'Lag-test update', lagTest.Update);
    errorBoundary.Call('render.diagnostics', 'Diagnostics update', diagnostics.Update);
    errorBoundary.Call('render.perf_overlay', 'Performance-overlay render', perfMeter.RenderOverlay);
end

local function IsImguiCapturingMouse()
    if (imgui.GetIO == nil) then
        return false;
    end

    local ok, io = pcall(function()
        return imgui.GetIO();
    end);

    if (ok ~= true or io == nil) then
        return false;
    end

    return io.WantCaptureMouse == true or io.WantCaptureMouseUnlessPopupClose == true;
end

local function GetDisplaySize()
    if (imgui.GetIO == nil) then
        return 2560, 1440;
    end

    local ok, io = pcall(function()
        return imgui.GetIO();
    end);

    if (ok ~= true or io == nil or io.DisplaySize == nil) then
        return 2560, 1440;
    end

    local display = io.DisplaySize;
    return
        tonumber(display.x or display.X or display[1]) or 2560,
        tonumber(display.y or display.Y or display[2]) or 1440;
end

local function IsInNativeMenuSafeArea(x, y)
    local mouseX = tonumber(x);
    local mouseY = tonumber(y);

    if (mouseX == nil or mouseY == nil) then
        return true;
    end

    local _, displayHeight = GetDisplaySize();

    -- Temporary native FFXI safe area.  This keeps the bottom-left native
    -- menu/chat region clickable while we test blocking empty 3D-world clicks.
    return mouseX <= 420 and mouseY >= (displayHeight - 420);
end

local function ShouldBypassEmptyWorldLeftClickForFocus(e)
    if (e == nil) then
        return false;
    end

    local focused = windowFocus.IsGameWindowFocused();
    local message = tonumber(e.message);

    if (focused == false) then
        emptyWorldLeftClickFocusSuspended = true;
        suppressEmptyWorldLeftRelease = false;
        return true;
    end

    if (emptyWorldLeftClickFocusSuspended == true) then
        if (message == 514) then
            emptyWorldLeftClickFocusSuspended = false;
        end

        suppressEmptyWorldLeftRelease = false;
        return true;
    end

    return false;
end

local function BlockEmptyWorldLeftClick(e)
    if (e == nil) then
        return false;
    end

    local targetingSettings = targeting.GetSettings();
    if (targetingSettings.blockEmptyWorldLeftClick == false) then
        return false;
    end

    local message = tonumber(e.message);

    if (ShouldBypassEmptyWorldLeftClickForFocus(e) == true) then
        return false;
    end

    if (message == 514 and suppressEmptyWorldLeftRelease == true) then
        suppressEmptyWorldLeftRelease = false;
        e.blocked = true;
        return true;
    end

    if (message ~= 513) then
        return false;
    end

    if (worldMarkerProbe.IsGameWindowFocused ~= nil and worldMarkerProbe.IsGameWindowFocused() == false) then
        suppressEmptyWorldLeftRelease = false;
        return false;
    end

    if (
        state.GetConfigOpen() == true or
        IsImguiCapturingMouse() == true or
        (quickMenu.IsOpen ~= nil and quickMenu.IsOpen() == true) or
        IsInNativeMenuSafeArea(e.x, e.y) == true
    ) then
        return false;
    end

    suppressEmptyWorldLeftRelease = true;
    e.blocked = true;
    return true;
end

function modules.HandleMouse(e)
    if (perfIsolation.mouse == true) then
        errorBoundary.Call('mouse.release', 'Mouse-control release', mouseControls.Release);
        return;
    end

    if (
        e ~= nil and
        tonumber(e.message) == 513 and
        windowFocus.IsGameWindowFocused() == false
    ) then
        emptyWorldLeftClickFocusSuspended = true;
        suppressEmptyWorldLeftRelease = false;
        errorBoundary.Call('mouse.focus.activate', 'Game-window focus repair', windowFocus.FocusGameWindow);
        errorBoundary.Call('mouse.focus.release', 'Mouse-control focus release', mouseControls.Release);
        return;
    end

    errorBoundary.Call('mouse.cursor', 'Cursor-overlay mouse handler', cursorOverlay.HandleMouse, e);
    errorBoundary.Call('mouse.world_focus', 'World-marker mouse focus update', worldMarkerProbe.UpdateFocusState);

    if (state.GetConfigOpen() == true) then
        return;
    end

    local _, handled = errorBoundary.Call('mouse.world_marker', 'World-marker mouse handler', function()
        return
            state.GetWorldEnabled() == true and
            worldMarkerProbe.GetEnabled() == true and
            worldMarkerProbe.GetReplacePlates() == true and
            worldMarkerProbe.HandleMouse(
                e,
                targeting.SelectTarget,
                targeting.SelectEnemyTarget,
                targeting.AttackEnemyTarget,
                targeting.InteractFishingGatheringTarget,
                quickMenu.OpenForPlate
            ) == true;
    end);

    if (handled == true) then
        return;
    end

    local _, currentTargetHandled = errorBoundary.Call('mouse.current_target_bar', 'Current-target bar mouse handler', function()
        return currentTargetBar.HandleMouse(e) == true;
    end);

    if (currentTargetHandled == true) then
        return;
    end

    if (BlockEmptyWorldLeftClick(e) == true) then
        return;
    end

    errorBoundary.Call('mouse.controls', 'Mouse-control handler', mouseControls.HandleMouse, e);
end

function modules.SetPerfIsolation(name, value)
    name = tostring(name or ''):lower();

    if (modules.plates.SetPerfIsolation(name, value) == true) then
        return true;
    end

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

    if (modules.plates.GetPerfIsolation(name) == true) then
        return true;
    end

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
        ' overlays=' .. tostring(perfIsolation.overlays == true) ..
        ' plates: ' .. modules.plates.GetPerfIsolationStatus();
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
    errorBoundary.Call(
        'render.world_marker',
        'World-marker render',
        worldMarkerProbe.DrawQueued,
        entities.GetEntityManager,
        entities.GetBone
    );
    perfMeter.Stop('world.draw', drawStart);

    local stats = worldMarkerProbe.GetPerfStats();
    if (stats ~= nil) then
        perfMeter.SetCounter('queued', stats.queued);
        perfMeter.SetCounter('drawn', stats.drawn);
        perfMeter.SetCounter('clickRects', stats.clickRects);
        perfMeter.SetCounter('clickRects.self', stats.clickRectsSelf);
        perfMeter.SetCounter('clickRects.pc', stats.clickRectsPc);
        perfMeter.SetCounter('clickRects.enemy', stats.clickRectsEnemy);
        perfMeter.SetCounter('clickRects.npc', stats.clickRectsNpc);
        perfMeter.SetCounter('clickRects.object', stats.clickRectsObject);
        perfMeter.SetCounter('clickRects.trust', stats.clickRectsTrust);
        perfMeter.SetCounter('clickRects.pet', stats.clickRectsPet);
        perfMeter.SetCounter('clickRects.other', stats.clickRectsOther);
    end

end

function modules.UpdateNativeTargetArrow()
    UpdateNativeTargetStartupBurst();

    local targetingSettings = targeting.GetSettings();
    local hasAnyTarget = HasAnyTarget();
    local mogHouseNativePassthrough = entities.IsMogHouseObjectSuppressionArea() == true;
    local fishingBarCaptureActive = fishing.ShouldCaptureFishBar ~= nil and fishing.ShouldCaptureFishBar() == true;
    local hideNativePartyTargetUi =
        targetingSettings.hideNativePartyTargetUi == true and
        mogHouseNativePassthrough ~= true;
    local nativeHideSettingEnabled = targetingSettings.hideNativeTargetArrow == true;
    local hideNativeTargetArrow =
        nativeHideSettingEnabled == true and
        hasAnyTarget == true;
    local startupBurstActive =
        nativeHideSettingEnabled == true and
        hasAnyTarget == true and
        nativeTargetStartupBurstFrames > 0;

    nativeTargetArrow.SetHideAllPrimitivesEnabled(hideNativePartyTargetUi == true and fishingBarCaptureActive ~= true);
    nativeTargetArrow.SetHardHideEveryDrawEnabled(hideNativeTargetArrow);
    nativeTargetArrow.SetFishingBarCaptureEnabled(fishingBarCaptureActive);
    nativeTargetArrow.SetTargetPrimitiveHideAllowed(mogHouseNativePassthrough ~= true or hasAnyTarget == true);
    nativeTargetArrow.SetEnabled(hideNativeTargetArrow or startupBurstActive or fishingBarCaptureActive);

    if (hideNativePartyTargetUi == true or hideNativeTargetArrow == true or fishingBarCaptureActive == true) then
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
