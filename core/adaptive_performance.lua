local adaptivePerformance = {};
local state = require('core.state');
local globalDefaults = require('config.global');

local frameCount = 0;
local sampleStart = os.clock();
local lastSampleAt = sampleStart;
local estimatedFps = 0;
local averageFrameMs = 0;
local tier = 'warming';
local sampleSeconds = 1.0;
local enabled = true;
local frameSerial = 0;
local backgroundBudgetFrame = 0;
local backgroundBudgetCounts = {};

local function ResolveTier(fps, frameMs)
    fps = tonumber(fps) or 0;
    frameMs = tonumber(frameMs) or 0;

    if (fps <= 0) then
        return 'warming';
    end

    if (fps >= 55) then
        return 'fps1_stable';
    end

    if (fps >= 31) then
        return 'highfps_under_load';
    end

    if (fps >= 24) then
        return 'fps2_stable';
    end

    if (frameMs >= 45 or fps < 20) then
        return 'stressed';
    end

    return 'low';
end

local function NormalizeMode(mode)
    local text = tostring(mode or 'Auto'):lower();

    if (text == 'quality') then return 'Quality'; end
    if (text == 'balanced' or text == 'smooth' or text == 'fps1') then return 'Balanced'; end
    if (text == 'performance' or text == 'light') then return 'Performance'; end

    return 'Auto';
end

local function GetSelectedMode()
    local global = state.GetGlobalSettings(globalDefaults);
    local targeting = global ~= nil and global.targeting or {};

    return NormalizeMode(targeting.performanceMode);
end

local function GetEffectiveMode()
    local selected = GetSelectedMode();

    if (selected ~= 'Auto') then
        return selected;
    end

    if (tier == 'highfps_under_load' or tier == 'fps2_stable') then
        return 'Balanced';
    end

    if (tier == 'stressed' or tier == 'low') then
        return 'Performance';
    end

    return 'Quality';
end

function adaptivePerformance.UpdateFrame()
    frameSerial = frameSerial + 1;
    backgroundBudgetFrame = frameSerial;
    backgroundBudgetCounts = {};

    if (enabled ~= true) then
        return;
    end

    frameCount = frameCount + 1;

    local now = os.clock();
    local elapsed = now - lastSampleAt;

    if (elapsed < sampleSeconds) then
        return;
    end

    estimatedFps = frameCount / elapsed;
    averageFrameMs = estimatedFps > 0 and (1000 / estimatedFps) or 0;
    tier = ResolveTier(estimatedFps, averageFrameMs);
    frameCount = 0;
    lastSampleAt = now;
end

function adaptivePerformance.GetStatusText()
    local elapsedTotal = os.clock() - sampleStart;

    return string.format(
        'Adaptive performance: enabled=%s selected=%s effective=%s fps=%.1f frameMs=%.2f tier=%s samplesFor=%.1fs',
        tostring(enabled),
        GetSelectedMode(),
        GetEffectiveMode(),
        tonumber(estimatedFps) or 0,
        tonumber(averageFrameMs) or 0,
        tostring(tier),
        tonumber(elapsedTotal) or 0
    );
end

function adaptivePerformance.SetEnabled(value)
    enabled = value == true;
    frameCount = 0;
    sampleStart = os.clock();
    lastSampleAt = sampleStart;
    estimatedFps = 0;
    averageFrameMs = 0;
    tier = enabled == true and 'warming' or 'off';
end

function adaptivePerformance.GetEnabled()
    return enabled;
end

function adaptivePerformance.GetTier()
    return tier;
end

function adaptivePerformance.GetEstimatedFps()
    return estimatedFps;
end

function adaptivePerformance.GetAverageFrameMs()
    return averageFrameMs;
end

function adaptivePerformance.GetSelectedMode()
    return GetSelectedMode();
end

function adaptivePerformance.GetEffectiveMode()
    return GetEffectiveMode();
end

function adaptivePerformance.SetSelectedMode(mode)
    local normalized = NormalizeMode(mode);
    local global = state.GetGlobalSettings(globalDefaults);

    global.targeting = global.targeting or {};
    global.targeting.performanceMode = normalized;
    state.Save();

    return normalized;
end

function adaptivePerformance.ShouldThrottleBackground()
    local effective = GetEffectiveMode();

    if (enabled ~= true and GetSelectedMode() == 'Auto') then
        return false;
    end

    return effective == 'Balanced' or
        effective == 'Performance' or
        adaptivePerformance.GetWorldPlateUpdateInterval() > 1;
end

function adaptivePerformance.GetWorldPlateUpdateInterval()
    local global = state.GetGlobalSettings(globalDefaults);
    local targeting = global ~= nil and global.targeting or {};
    local rate = tostring(targeting.worldPlateUpdateRate or 'Full');

    if (rate == 'Low') then
        return 4;
    end

    if (rate == 'Balanced') then
        return 2;
    end

    return 1;
end

function adaptivePerformance.GetWorldRefreshSeconds(kind)
    local global = state.GetGlobalSettings(globalDefaults);
    local targeting = global ~= nil and global.targeting or {};
    local legacyKey = tostring(kind or 'pc'):lower() .. 'WorldRefreshRate';
    local refreshPerSecond = tonumber(targeting.worldStaticRefreshRate) or tonumber(targeting[legacyKey]) or 1.0;

    refreshPerSecond = math.max(0.2, math.min(10.0, refreshPerSecond));

    return 1.0 / refreshPerSecond;
end

function adaptivePerformance.GetPlateRefreshSeconds(context, group)
    local global = state.GetGlobalSettings(globalDefaults);
    local targeting = global ~= nil and global.targeting or {};
    local contextText = tostring(context or 'world'):lower();
    local groupText = tostring(group or 'static'):lower();
    local defaults = {
        world = {
            critical = 3.0,
            medium = 2.0,
            static = 1.0,
        },
        tactical = {
            critical = 5.0,
            medium = 5.0,
            static = 1.0,
        },
    };

    if (contextText ~= 'tactical') then
        contextText = 'world';
    end

    if (groupText ~= 'critical' and groupText ~= 'medium' and groupText ~= 'static') then
        groupText = 'static';
    end

    local key = contextText .. groupText:gsub('^%l', string.upper) .. 'RefreshRate';
    local refreshPerSecond = tonumber(targeting[key]) or defaults[contextText][groupText] or 1.0;

    refreshPerSecond = math.max(0.2, math.min(15.0, refreshPerSecond));

    return 1.0 / refreshPerSecond;
end

function adaptivePerformance.ShouldUpdateWorldPlate(key, protected)
    if (protected == true) then
        return true;
    end

    local interval = adaptivePerformance.GetWorldPlateUpdateInterval();

    if (interval <= 1) then
        return true;
    end

    local seed = 0;
    local text = tostring(key or '');

    for i = 1, #text do
        seed = (seed + string.byte(text, i)) % interval;
    end

    return ((frameSerial + seed) % interval) == 0;
end

function adaptivePerformance.ShouldDisableExpensiveWorldWidgets(protected)
    if (protected == true) then
        return false;
    end

    local global = state.GetGlobalSettings(globalDefaults);
    local targeting = global ~= nil and global.targeting or {};

    return targeting.disableExpensiveWorldWidgets == true;
end

function adaptivePerformance.AllowBackgroundBuild(key, limit)
    if (adaptivePerformance.ShouldThrottleBackground() ~= true) then
        return true;
    end

    if (adaptivePerformance.ShouldUpdateWorldPlate(key, false) ~= true) then
        return false;
    end

    if (backgroundBudgetFrame ~= frameSerial) then
        backgroundBudgetFrame = frameSerial;
        backgroundBudgetCounts = {};
    end

    key = tostring(key or 'default');
    limit = math.max(0, tonumber(limit) or 1);

    local count = tonumber(backgroundBudgetCounts[key]) or 0;
    if (count >= limit) then
        return false;
    end

    backgroundBudgetCounts[key] = count + 1;
    return true;
end

return adaptivePerformance;
