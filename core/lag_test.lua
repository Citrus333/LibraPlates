local log = require('core.log');
local perfMeter = require('core.perf_meter');
local worldMarkerProbe = require('core.world_marker_probe');
local canvasTexture = require('core.canvas_texture');
local targeting = require('core.targeting');

local lagTest = {};
local active = false;
local phase = nil;
local phaseStartedAt = 0;
local phaseSeconds = 20;
local testMode = 'world';
local originalWorldEnabled = true;
local originalReplacePlates = true;
local originalDetailEnabled = false;
local originalSelfSuppressed = false;
local originalDrawSuppressed = false;
local originalAtlasDrawSuppressed = false;
local originalStackingEnabled = true;
local originalClickHitMode = 'legacy';
local originalPcMouseSnapMode = 'Off';
local originalEnemyMouseSnapMode = 'Off';
local originalNoGoZonesMask = false;
local startCanvasEvictions = 0;
local phaseFrames = 0;
local bottleneckResults = {};

local function GetSelfPlateModule()
    local ok, selfPlate = pcall(require, 'modules.plates.self');

    if (ok == true and type(selfPlate) == 'table') then
        return selfPlate;
    end

    return nil;
end

local function GetSelfSuppressed()
    local selfPlate = GetSelfPlateModule();

    if (selfPlate ~= nil and type(selfPlate.GetLagTestSuppressed) == 'function') then
        return selfPlate.GetLagTestSuppressed() == true;
    end

    return false;
end

local function SetSelfSuppressed(value)
    local selfPlate = GetSelfPlateModule();

    if (selfPlate ~= nil and type(selfPlate.SetLagTestSuppressed) == 'function') then
        selfPlate.SetLagTestSuppressed(value == true);
    end
end

local function FormatCanvasStats()
    local stats = canvasTexture.GetCacheStats();

    if (stats == nil) then
        return 'canvasCache=nil';
    end

    local evictions = tonumber(stats.evictions) or 0;

    return 'canvasCache=' .. tostring(stats.count) .. '/' .. tostring(stats.max) ..
        ' evictions=' .. tostring(stats.evictions) ..
        ' evictions_delta=' .. tostring(math.max(0, evictions - (tonumber(startCanvasEvictions) or 0)));
end

local function PrintSnapshot(label)
    log.Info('Lagtest ' .. label .. ': ' .. perfMeter.GetDiagnosticLine());
    log.Info('Lagtest ' .. label .. ': ' .. FormatCanvasStats() .. ' ' .. worldMarkerProbe.GetStatusText());
end

local function Restore()
    worldMarkerProbe.SetEnabled(originalWorldEnabled == true);
    worldMarkerProbe.SetReplacePlates(originalReplacePlates == true);
    worldMarkerProbe.SetDrawSuppressed(originalDrawSuppressed == true);
    worldMarkerProbe.SetAtlasDrawSuppressed(originalAtlasDrawSuppressed == true);
    perfMeter.SetDetailEnabled(originalDetailEnabled == true);
    SetSelfSuppressed(originalSelfSuppressed == true);
    local settings = targeting.GetSettings();
    if (settings ~= nil) then
        settings.plateStackingEnabled = originalStackingEnabled == true;
        settings.pcMouseSnapMode = originalPcMouseSnapMode;
        settings.enemyMouseSnapMode = originalEnemyMouseSnapMode;
        settings.plateClickNoGoZonesMask = originalNoGoZonesMask == true;
    end
    worldMarkerProbe.SetClickHitMode(originalClickHitMode);
end

local function BeginBottleneckPhase(name)
    phase = name;
    phaseStartedAt = os.clock();
    phaseFrames = 0;
    perfMeter.Reset();
end

local function FinishBottleneckPhase(label, elapsed)
    elapsed = math.max(0.001, tonumber(elapsed) or 0.001);
    local fps = phaseFrames / elapsed;
    bottleneckResults[label] = fps;
    log.Info(string.format('World diagnostic %s: %.1f FPS (%d frames / %.1fs)', label, fps, phaseFrames, elapsed));
end

function lagTest.Start(seconds, mode)
    if (active == true) then
        log.Warn('Lagtest already running: ' .. lagTest.GetStatusText());
        return;
    end

    testMode = tostring(mode or 'world'):lower();
    if (testMode ~= 'self') then
        testMode = 'world';
    end

    phaseSeconds = math.max(5, math.min(60, tonumber(seconds) or 20));
    originalWorldEnabled = worldMarkerProbe.GetEnabled() == true;
    originalReplacePlates = worldMarkerProbe.GetReplacePlates() == true;
    originalDetailEnabled = perfMeter.GetDetailEnabled() == true;
    originalSelfSuppressed = GetSelfSuppressed() == true;
    originalDrawSuppressed = worldMarkerProbe.GetDrawSuppressed() == true;
    originalAtlasDrawSuppressed = worldMarkerProbe.GetAtlasDrawSuppressed() == true;
    local currentSettings = targeting.GetSettings();
    originalStackingEnabled = currentSettings == nil or currentSettings.plateStackingEnabled ~= false;
    originalClickHitMode = worldMarkerProbe.GetClickHitMode();
    originalPcMouseSnapMode = currentSettings ~= nil and currentSettings.pcMouseSnapMode or 'Off';
    originalEnemyMouseSnapMode = currentSettings ~= nil and currentSettings.enemyMouseSnapMode or 'Off';
    originalNoGoZonesMask = currentSettings ~= nil and currentSettings.plateClickNoGoZonesMask == true;
    local stats = canvasTexture.GetCacheStats();
    startCanvasEvictions = tonumber(stats ~= nil and stats.evictions) or 0;
    active = true;
    phase = (testMode == 'self') and 'self-normal' or 'world-on';
    phaseStartedAt = os.clock();

    SetSelfSuppressed(false);
    worldMarkerProbe.SetEnabled(true);
    worldMarkerProbe.SetReplacePlates(true);
    perfMeter.SetDetailEnabled(true);
    perfMeter.Reset();

    if (testMode == 'self') then
        log.Info('Lagtest started: phase 1 normal world plates for ' .. tostring(phaseSeconds) .. 's, then Self plate OFF for ' .. tostring(phaseSeconds) .. 's. Keep playing; results print automatically.');
    else
        log.Info('Lagtest started: phase 1 world ON for ' .. tostring(phaseSeconds) .. 's, then world OFF for ' .. tostring(phaseSeconds) .. 's. Keep playing; results print automatically.');
    end
end

function lagTest.StartBottleneck(seconds)
    if (active == true) then
        log.Warn('Lagtest already running: ' .. lagTest.GetStatusText());
        return;
    end

    phaseSeconds = math.max(5, math.min(30, tonumber(seconds) or 8));
    testMode = 'bottleneck';
    originalWorldEnabled = worldMarkerProbe.GetEnabled() == true;
    originalReplacePlates = worldMarkerProbe.GetReplacePlates() == true;
    originalDetailEnabled = perfMeter.GetDetailEnabled() == true;
    originalSelfSuppressed = GetSelfSuppressed() == true;
    originalDrawSuppressed = worldMarkerProbe.GetDrawSuppressed() == true;
    originalAtlasDrawSuppressed = worldMarkerProbe.GetAtlasDrawSuppressed() == true;
    local settings = targeting.GetSettings();
    originalStackingEnabled = settings == nil or settings.plateStackingEnabled ~= false;
    originalClickHitMode = worldMarkerProbe.GetClickHitMode();
    originalPcMouseSnapMode = settings ~= nil and settings.pcMouseSnapMode or 'Off';
    originalEnemyMouseSnapMode = settings ~= nil and settings.enemyMouseSnapMode or 'Off';
    originalNoGoZonesMask = settings ~= nil and settings.plateClickNoGoZonesMask == true;
    bottleneckResults = {};
    active = true;

    worldMarkerProbe.SetEnabled(true);
    worldMarkerProbe.SetReplacePlates(true);
    worldMarkerProbe.SetDrawSuppressed(false);
    worldMarkerProbe.SetAtlasDrawSuppressed(false);
    SetSelfSuppressed(false);
    if (settings ~= nil) then
        settings.plateStackingEnabled = true;
    end
    worldMarkerProbe.SetClickHitMode('legacy');

    BeginBottleneckPhase('bottleneck-normal');
    log.Info('World diagnostic started. Five automatic phases run for ' .. tostring(phaseSeconds) .. 's each; do not move or open settings. Original states will be restored automatically.');
end

function lagTest.Cancel()
    if (active ~= true) then
        log.Info('Lagtest is not running.');
        return;
    end

    active = false;
    phase = nil;
    Restore();
    log.Info('Lagtest cancelled and world-marker/detail settings restored.');
end

function lagTest.Update()
    if (active ~= true or phase == nil) then
        return;
    end

    phaseFrames = phaseFrames + 1;
    local elapsed = os.clock() - phaseStartedAt;

    if (elapsed < phaseSeconds) then
        return;
    end

    if (testMode == 'bottleneck') then
        if (phase == 'bottleneck-normal') then
            FinishBottleneckPhase('normal', elapsed);
            worldMarkerProbe.SetAtlasDrawSuppressed(true);
            BeginBottleneckPhase('bottleneck-atlas-off');
            return;
        end

        if (phase == 'bottleneck-atlas-off') then
            FinishBottleneckPhase('atlas hidden', elapsed);
            worldMarkerProbe.SetAtlasDrawSuppressed(false);
            local settings = targeting.GetSettings();
            if (settings ~= nil) then
                settings.plateStackingEnabled = false;
            end
            BeginBottleneckPhase('bottleneck-stacking-off');
            return;
        end

        if (phase == 'bottleneck-stacking-off') then
            FinishBottleneckPhase('stacking off', elapsed);
            local settings = targeting.GetSettings();
            if (settings ~= nil) then
                settings.plateStackingEnabled = false;
                settings.pcMouseSnapMode = 'Off';
                settings.enemyMouseSnapMode = 'Off';
                settings.plateClickNoGoZonesMask = false;
            end
            worldMarkerProbe.SetClickHitMode('ondemand');
            BeginBottleneckPhase('bottleneck-light-prepass');
            return;
        end

        if (phase == 'bottleneck-light-prepass') then
            FinishBottleneckPhase('light prepass', elapsed);
            local settings = targeting.GetSettings();
            if (settings ~= nil) then
                settings.plateStackingEnabled = true;
            end
            worldMarkerProbe.SetDrawSuppressed(true);
            BeginBottleneckPhase('bottleneck-world-off');
            return;
        end

        if (phase == 'bottleneck-world-off') then
            FinishBottleneckPhase('world off', elapsed);
            active = false;
            phase = nil;
            Restore();
            log.Info(string.format(
                'World diagnostic complete: normal=%.1f atlas-hidden=%.1f stacking-off=%.1f light-prepass=%.1f world-off=%.1f FPS. All original states restored.',
                tonumber(bottleneckResults['normal']) or 0,
                tonumber(bottleneckResults['atlas hidden']) or 0,
                tonumber(bottleneckResults['stacking off']) or 0,
                tonumber(bottleneckResults['light prepass']) or 0,
                tonumber(bottleneckResults['world off']) or 0
            ));
            return;
        end
    end

    if (phase == 'world-on') then
        PrintSnapshot('world ON');
        worldMarkerProbe.SetEnabled(false);
        perfMeter.Reset();
        phase = 'world-off';
        phaseStartedAt = os.clock();
        log.Info('Lagtest phase 2: world marker OFF for ' .. tostring(phaseSeconds) .. 's.');
        return;
    end

    if (phase == 'self-normal') then
        PrintSnapshot('self normal');
        SetSelfSuppressed(true);
        perfMeter.Reset();
        phase = 'self-off';
        phaseStartedAt = os.clock();
        log.Info('Lagtest phase 2: Self plate OFF for ' .. tostring(phaseSeconds) .. 's.');
        return;
    end

    if (phase == 'self-off') then
        PrintSnapshot('self OFF');
        active = false;
        phase = nil;
        Restore();
        log.Info('Lagtest finished; world-marker/detail/Self-test settings restored.');
        return;
    end

    if (phase == 'world-off') then
        PrintSnapshot('world OFF');
        active = false;
        phase = nil;
        Restore();
        log.Info('Lagtest finished; world-marker/detail settings restored.');
    end
end

function lagTest.GetStatusText()
    if (active ~= true or phase == nil) then
        return 'Lagtest not running.';
    end

    local remaining = math.max(0, phaseSeconds - (os.clock() - phaseStartedAt));

    return 'Lagtest running phase=' .. tostring(phase) ..
        ' mode=' .. tostring(testMode) ..
        ' remaining=' .. string.format('%.1f', remaining) .. 's';
end

return lagTest;
