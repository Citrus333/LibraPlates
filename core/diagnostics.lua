local diagnostics = {};

local log = require('core.log');
local state = require('core.state');
local targeting = require('core.targeting');
local perfMeter = require('core.perf_meter');
local nativeTargetArrow = require('core.native_target_arrow');
local targetModuleDefaults = require('config.widgets.target_module');
local subtargetModuleDefaults = require('config.widgets.subtarget_module');
local globalDefaults = require('config.global');

local running = false;
local filePath = nil;
local lastWriteClock = 0;
local startedClock = 0;
local lastTargetKey = '';
local restoreSnapshot = nil;
local autoRunning = false;
local autoPhaseIndex = 0;
local autoPhaseStartedClock = 0;
local autoPhaseSeconds = 15;
local detailRestoreValue = nil;
local autoPhases = {
    { name = 'baseline-off', scenario = 'native-off', targetModules = false },
    { name = 'target-on', scenario = 'target-on' },
    { name = 'native-arrow-on', scenario = 'native-arrow-on' },
    { name = 'native-party-on', scenario = 'native-party-on' },
    { name = 'restore-end', restore = true },
};

local targetEntities = {
    'Self',
    'PC',
    'Trust',
    'Enemy',
    'NPC',
    'Object',
    'Wyvern',
    'Pet (BST)',
    'Pet (SMN)',
    'Automaton',
};

local targetStates = {
    'Idle',
    'Combat',
    'Resting',
};

local function GetAddonRoot()
    local ok, path = pcall(function()
        return AshitaCore:GetInstallPath() .. '\\addons\\LibraPlates\\';
    end);

    if (ok == true and path ~= nil) then
        return tostring(path);
    end

    return '.\\';
end

local function EnsureTempFolder()
    local folder = GetAddonRoot() .. 'TEMP WORK FOLDER';
    local logFolder = folder .. '\\test-logs';

    pcall(function()
        if (ashita ~= nil and ashita.fs ~= nil and ashita.fs.exists ~= nil and ashita.fs.exists(folder) ~= true) then
            if (ashita.fs.create_dir ~= nil) then
                ashita.fs.create_dir(folder);
            elseif (ashita.fs.create_directory ~= nil) then
                ashita.fs.create_directory(folder);
            end
        end

        if (ashita ~= nil and ashita.fs ~= nil and ashita.fs.exists ~= nil and ashita.fs.exists(logFolder) ~= true) then
            if (ashita.fs.create_dir ~= nil) then
                ashita.fs.create_dir(logFolder);
            elseif (ashita.fs.create_directory ~= nil) then
                ashita.fs.create_directory(logFolder);
            end
        end
    end);

    return logFolder;
end

local function WriteLine(text)
    if (filePath == nil) then
        return;
    end

    local file = io.open(filePath, 'a');

    if (file == nil) then
        return;
    end

    file:write(string.format('%.3f ', os.clock() - startedClock));
    file:write(tostring(text or ''));
    file:write('\n');
    file:close();
end

local function RestoreDetailMode()
    if (detailRestoreValue == nil) then
        return;
    end

    perfMeter.SetDetailEnabled(detailRestoreValue == true);
    detailRestoreValue = nil;
end

local function GetEntityName(index)
    index = tonumber(index) or 0;

    if (index == 0) then
        return '';
    end

    local ok, name = pcall(function()
        return AshitaCore:GetMemoryManager():GetEntity():GetName(index);
    end);

    if (ok == true and name ~= nil) then
        return tostring(name);
    end

    return '';
end

local function GetTargetLine()
    local targetIndex, subTargetIndex = targeting.GetCurrentTargetAndSubTargetIndexes();
    local targetName = GetEntityName(targetIndex);
    local subTargetName = GetEntityName(subTargetIndex);

    return string.format(
        'target index=%s name=%q subIndex=%s subName=%q subMode=%s',
        tostring(targetIndex or 0),
        targetName,
        tostring(subTargetIndex or 0),
        subTargetName,
        tostring(targeting.IsSubTargetModeActive() == true)
    );
end

local function GetSettingsLine()
    local settings = targeting.GetSettings();

    return string.format(
        'settings nativeParty=%s nativeArrow=%s nativeNames=%s overwriteNativeNameColors=%s nativeHookNeeded=%s %s',
        tostring(settings.hideNativePartyTargetUi == true),
        tostring(settings.hideNativeTargetArrow == true),
        tostring(settings.hideNativeNamesOnLoad == true),
        tostring(settings.overwriteNativeNameColors ~= false),
        tostring(nativeTargetArrow.ShouldUseDrawHooks() == true),
        nativeTargetArrow.GetHardHideEveryDrawStatusText()
    );
end

local function SnapshotSetting(entity, stateName, widgetName, defaults, out)
    local settings = state.GetWidgetSettings(entity, stateName, widgetName, defaults);

    out[#out + 1] = {
        settings = settings,
        enabled = settings.enabled == true,
    };
end

local function EnsureRestoreSnapshot()
    if (restoreSnapshot ~= nil) then
        return;
    end

    local global = state.GetGlobalSettings(globalDefaults);
    local targetingSettings = global.targeting or {};
    restoreSnapshot = {
        native = {
            hideNativePartyTargetUi = targetingSettings.hideNativePartyTargetUi == true,
            hideNativeTargetArrow = targetingSettings.hideNativeTargetArrow == true,
        },
        modules = {},
    };

    for _, entity in ipairs(targetEntities) do
        for _, stateName in ipairs(targetStates) do
            SnapshotSetting(entity, stateName, 'Target Module', targetModuleDefaults, restoreSnapshot.modules);
            SnapshotSetting(entity, stateName, 'Subtarget Module', subtargetModuleDefaults, restoreSnapshot.modules);
        end
    end
end

local function SetTargetModulesEnabled(enabled)
    EnsureRestoreSnapshot();

    for _, entity in ipairs(targetEntities) do
        for _, stateName in ipairs(targetStates) do
            state.GetWidgetSettings(entity, stateName, 'Target Module', targetModuleDefaults).enabled = enabled == true;
            state.GetWidgetSettings(entity, stateName, 'Subtarget Module', subtargetModuleDefaults).enabled = enabled == true;
        end
    end
end

function diagnostics.Restore()
    if (restoreSnapshot == nil) then
        return false;
    end

    local global = state.GetGlobalSettings(globalDefaults);
    global.targeting = global.targeting or {};
    global.targeting.hideNativePartyTargetUi = restoreSnapshot.native.hideNativePartyTargetUi == true;
    global.targeting.hideNativeTargetArrow = restoreSnapshot.native.hideNativeTargetArrow == true;

    for _, entry in ipairs(restoreSnapshot.modules or {}) do
        if (entry.settings ~= nil) then
            entry.settings.enabled = entry.enabled == true;
        end
    end

    WriteLine('restore applied');
    restoreSnapshot = nil;
    autoRunning = false;

    return true;
end

function diagnostics.Start(label)
    local logFolder = EnsureTempFolder();

    local stamp = os.date('%Y%m%d-%H%M%S');
    filePath = logFolder .. '\\diagnostics_' .. stamp .. '.txt';
    running = true;
    startedClock = os.clock();
    lastWriteClock = 0;
    lastTargetKey = '';

    local file = io.open(filePath, 'w');

    if (file ~= nil) then
        file:write('LibraPlates diagnostics ');
        file:write(tostring(label or ''));
        file:write('\n');
        file:close();
    end

    WriteLine('start label=' .. tostring(label or ''));
    WriteLine(GetSettingsLine());
    WriteLine(GetTargetLine());

    return filePath;
end

function diagnostics.Stop()
    if (running == true) then
        WriteLine('stop');
    end

    autoRunning = false;
    running = false;
    RestoreDetailMode();

    return filePath;
end

function diagnostics.Mark(text)
    WriteLine('mark ' .. tostring(text or ''));
end

function diagnostics.ApplyScenario(name)
    name = tostring(name or ''):lower();
    name = name:gsub('_', '-');
    EnsureRestoreSnapshot();

    local global = state.GetGlobalSettings(globalDefaults);
    global.targeting = global.targeting or {};

    if (name == 'native-off') then
        global.targeting.hideNativePartyTargetUi = false;
        global.targeting.hideNativeTargetArrow = false;
    elseif (name == 'native-arrow-on') then
        global.targeting.hideNativePartyTargetUi = false;
        global.targeting.hideNativeTargetArrow = true;
    elseif (name == 'native-party-on') then
        global.targeting.hideNativePartyTargetUi = true;
        global.targeting.hideNativeTargetArrow = true;
    elseif (name == 'target-off') then
        SetTargetModulesEnabled(false);
    elseif (name == 'target-on') then
        SetTargetModulesEnabled(true);
    else
        return false, 'unknown scenario';
    end

    WriteLine('scenario ' .. name);
    WriteLine(GetSettingsLine());

    return true, name;
end

local function ApplyAutoPhase(index)
    local phase = autoPhases[index];

    if (phase == nil) then
        diagnostics.Restore();
        diagnostics.Stop();
        return 'done';
    end

    if (phase.restore == true) then
        diagnostics.Restore();
        WriteLine('auto phase=' .. tostring(phase.name));
        return phase.name;
    end

    if (phase.scenario ~= nil) then
        diagnostics.ApplyScenario(phase.scenario);
    end

    if (phase.targetModules ~= nil) then
        SetTargetModulesEnabled(phase.targetModules == true);
    end

    WriteLine('auto phase=' .. tostring(phase.name));
    return phase.name;
end

function diagnostics.StartAuto(secondsPerPhase)
    local seconds = tonumber(secondsPerPhase);

    if (seconds ~= nil and seconds >= 5 and seconds <= 60) then
        autoPhaseSeconds = seconds;
    else
        autoPhaseSeconds = 15;
    end

    if (running ~= true) then
        diagnostics.Start('auto');
    end

    if (detailRestoreValue == nil) then
        detailRestoreValue = perfMeter.GetDetailEnabled();
    end

    perfMeter.SetDetailEnabled(true);
    perfMeter.Reset();

    autoRunning = true;
    autoPhaseIndex = 1;
    autoPhaseStartedClock = os.clock();

    local phaseName = ApplyAutoPhase(autoPhaseIndex);

    return filePath, phaseName, autoPhaseSeconds;
end

function diagnostics.StopAuto()
    autoRunning = false;
    diagnostics.Restore();
    diagnostics.Stop();

    return filePath;
end

function diagnostics.GetStatusText()
    return 'diag running=' .. tostring(running == true) ..
        ' auto=' .. tostring(autoRunning == true) ..
        ' phase=' .. tostring(autoPhaseIndex) ..
        ' file=' .. tostring(filePath);
end

function diagnostics.GetFilePath()
    return filePath;
end

function diagnostics.Update()
    if (running ~= true) then
        return;
    end

    local now = os.clock();

    if (autoRunning == true and (now - autoPhaseStartedClock) >= autoPhaseSeconds) then
        autoPhaseIndex = autoPhaseIndex + 1;
        autoPhaseStartedClock = now;

        local phaseName = ApplyAutoPhase(autoPhaseIndex);

        if (phaseName == 'restore-end') then
            autoRunning = false;
            WriteLine('auto complete');
            diagnostics.Stop();
            log.Info('Lag diagnostics done. Check the generated diagnostics log for details.');
            return;
        end
    end

    local targetLine = GetTargetLine();
    local targetKey = targetLine;

    if (targetKey ~= lastTargetKey) then
        lastTargetKey = targetKey;
        WriteLine(targetLine);
    end

    if ((now - lastWriteClock) < 1.0) then
        return;
    end

    lastWriteClock = now;
    WriteLine(GetSettingsLine());
    WriteLine(perfMeter.GetDiagnosticLine());
end

return diagnostics;
