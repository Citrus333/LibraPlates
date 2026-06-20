local targeting = {};
local bit = require('bit');
local state = require('core.state');
local globalDefaults = require('config.global');
local pendingGatheringCommand = nil;
local pendingGatheringWatch = nil;
local lastGatheringInteractStatus = 'none';
local lastGatheringDisplay = nil;
local lastGatheringDisplayUntil = 0;
local gatheringToolCounts = nil;
local lastGatheringToolPoll = 0;
local suppressGatheringDisplayUntil = 0;
local lastFishCommandTime = 0;
local suppressFishRightMouse = false;

local defaultPlateClickNoGoZones = {
    { name = 'Chat', enabled = false, x = 0, y = 960, width = 760, height = 480, color = { 1.0, 0.15, 0.15, 1.0 } },
    { name = 'Bottom bar', enabled = false, x = 760, y = 1160, width = 1160, height = 280, color = { 0.15, 0.75, 1.0, 1.0 } },
    { name = 'Right UI', enabled = false, x = 1920, y = 0, width = 640, height = 1440, color = { 1.0, 0.80, 0.10, 1.0 } },
    { name = 'Left UI', enabled = false, x = 0, y = 0, width = 360, height = 960, color = { 0.40, 1.0, 0.25, 1.0 } },
};

local defaultPlateStackingPriority = { 'pc', 'enemy', 'trust', 'pet', 'npc', 'object' };
local defaultPlateStackingTypes = {
    pc = true,
    enemy = true,
    trust = false,
    pet = false,
    npc = false,
    object = false,
};

local function NormalizePlateClickNoGoZones(settings)
    if (type(settings.plateClickNoGoZones) ~= 'table') then
        settings.plateClickNoGoZones = {};
    end

    for index, defaults in ipairs(defaultPlateClickNoGoZones) do
        local zone = settings.plateClickNoGoZones[index];

        if (type(zone) ~= 'table') then
            zone = {};
            settings.plateClickNoGoZones[index] = zone;
        end

        if (zone.name == nil) then zone.name = defaults.name; end
        if (zone.enabled == nil) then zone.enabled = defaults.enabled; end
        if (zone.x == nil) then zone.x = defaults.x; end
        if (zone.y == nil) then zone.y = defaults.y; end
        if (zone.width == nil) then zone.width = defaults.width; end
        if (zone.height == nil) then zone.height = defaults.height; end
        if (type(zone.color) ~= 'table') then zone.color = {}; end

        zone.x = math.max(0, math.floor((tonumber(zone.x) or defaults.x) + 0.5));
        zone.y = math.max(0, math.floor((tonumber(zone.y) or defaults.y) + 0.5));
        zone.width = math.max(1, math.floor((tonumber(zone.width) or defaults.width) + 0.5));
        zone.height = math.max(1, math.floor((tonumber(zone.height) or defaults.height) + 0.5));
        zone.enabled = zone.enabled == true;
        zone.color[1] = math.max(0.0, math.min(1.0, tonumber(zone.color[1]) or defaults.color[1]));
        zone.color[2] = math.max(0.0, math.min(1.0, tonumber(zone.color[2]) or defaults.color[2]));
        zone.color[3] = math.max(0.0, math.min(1.0, tonumber(zone.color[3]) or defaults.color[3]));
        zone.color[4] = 1.0;
    end
end

local function GetTargetingSettings()
    local global = state.GetGlobalSettings(globalDefaults);

    if (global.targeting == nil) then
        global.targeting = {};
    end

    if (global.targeting.enableRightClickAttack == nil) then
        global.targeting.enableRightClickAttack = true;
    end

    if (global.targeting.enableRightClickAttackWhileMounted == nil) then
        global.targeting.enableRightClickAttackWhileMounted = false;
    end

    if (global.targeting.enableLeftClickEnemyTargetIdle == nil) then
        global.targeting.enableLeftClickEnemyTargetIdle = true;
    end

    if (global.targeting.enableLeftClickEnemyTargetCombat == nil) then
        global.targeting.enableLeftClickEnemyTargetCombat = false;
    end

    if (global.targeting.rightClickAttackRange == nil) then
        global.targeting.rightClickAttackRange = 4.5;
    end

    if (global.targeting.enemyPlateRange == nil) then
        global.targeting.enemyPlateRange = 49.9;
    end

    if (global.targeting.enemyActiveDetailRange == nil) then
        global.targeting.enemyActiveDetailRange = 25.0;
    end

    if (global.targeting.pcDistanceScaleStart == nil) then
        global.targeting.pcDistanceScaleStart = 2.0;
    end

    if (global.targeting.pcDistanceScaleEnd == nil) then
        global.targeting.pcDistanceScaleEnd = 8.0;
    end

    if (global.targeting.pcDistanceScaleMax == nil) then
        global.targeting.pcDistanceScaleMax = 2.65;
    end

    if (global.targeting.customEntityDistanceScaling == nil) then
        global.targeting.customEntityDistanceScaling = false;
    end

    if (global.targeting.globalPlateOffsetX == nil) then
        global.targeting.globalPlateOffsetX = 0;
    end

    if (global.targeting.globalPlateOffsetY == nil) then
        global.targeting.globalPlateOffsetY = 0;
    end

    if (type(global.targeting.platePositionOffsets) ~= 'table') then
        global.targeting.platePositionOffsets = {};
    end

    if (type(global.targeting.plateDistanceScales) ~= 'table') then
        global.targeting.plateDistanceScales = {};
    end

    if (global.targeting.hideNativeTargetArrow == nil) then
        global.targeting.hideNativeTargetArrow = true;
    end

    if (global.targeting.hideNativePartyTargetUi == nil) then
        global.targeting.hideNativePartyTargetUi = true;
    end

    if (global.targeting.hideNativeNamesOnLoad == nil) then
        global.targeting.hideNativeNamesOnLoad = true;
    end

    if (global.targeting.overwriteNativeNameColors == nil) then
        global.targeting.overwriteNativeNameColors = true;
    end

    if (global.targeting.enablePetPlateTargeting == nil) then
        global.targeting.enablePetPlateTargeting = true;
    end

    if (global.targeting.hideOtherPlayerPetPlates == nil) then
        global.targeting.hideOtherPlayerPetPlates = true;
    end

    if (global.targeting.blockPlateClicksWhenImguiCapturesMouse == nil) then
        global.targeting.blockPlateClicksWhenImguiCapturesMouse = true;
    end

    if (global.targeting.plateClickNoGoZonesEnabled == nil) then
        global.targeting.plateClickNoGoZonesEnabled = false;
    end

    if (global.targeting.plateClickNoGoZonesVisible == nil) then
        global.targeting.plateClickNoGoZonesVisible = false;
    end

    if (global.targeting.performanceSafetyMode == nil) then
        global.targeting.performanceSafetyMode = false;
    end

    if (global.targeting.performanceSafetyCombatOnly == nil) then
        global.targeting.performanceSafetyCombatOnly = true;
    end

    if (global.targeting.performanceSafetySkipPc == nil) then
        global.targeting.performanceSafetySkipPc = false;
    end

    if (global.targeting.performanceSafetySkipTrust == nil) then
        global.targeting.performanceSafetySkipTrust = false;
    end

    if (global.targeting.performanceSafetySkipNpc == nil) then
        global.targeting.performanceSafetySkipNpc = false;
    end

    if (global.targeting.performanceSafetySkipPet == nil) then
        global.targeting.performanceSafetySkipPet = false;
    end

    if (global.targeting.performanceSafetyImportantEnemiesOnly == nil) then
        global.targeting.performanceSafetyImportantEnemiesOnly = false;
    end

    if (global.targeting.performanceSafetySkipPeer == nil) then
        global.targeting.performanceSafetySkipPeer = false;
    end

    if (global.targeting.performanceMode == nil) then
        global.targeting.performanceMode = 'Auto';
    end

    if (global.targeting.performancePreset == nil) then
        global.targeting.performancePreset = 'Custom';
    end

    if (global.targeting.gameFpsMode == nil) then
        global.targeting.gameFpsMode = 'Keep current';
    end

    if (global.targeting.performanceMonitorCompact == nil) then
        global.targeting.performanceMonitorCompact = true;
    end

    if (global.targeting.maxWorldPlateCount == nil) then
        global.targeting.maxWorldPlateCount = 0;
    end

    if (global.targeting.worldPlateUpdateRate == nil) then
        global.targeting.worldPlateUpdateRate = 'Full';
    end

    if (global.targeting.hideDistantWorldPlates == nil) then
        global.targeting.hideDistantWorldPlates = false;
    end

    if (global.targeting.worldPlateDistanceLimit == nil) then
        global.targeting.worldPlateDistanceLimit = 49.9;
    end

    if (global.targeting.disableExpensiveWorldWidgets == nil) then
        global.targeting.disableExpensiveWorldWidgets = false;
    end

    if (global.targeting.plateStackingEnabled == nil) then
        global.targeting.plateStackingEnabled = true;
    end

    if (global.targeting.plateStackingScope == nil) then
        global.targeting.plateStackingScope = 'PC + Enemy';
    end

    if (type(global.targeting.plateStackingTypes) ~= 'table') then
        global.targeting.plateStackingTypes = {};

        local scope = tostring(global.targeting.plateStackingScope or 'PC + Enemy');
        if (scope == 'PC only') then
            global.targeting.plateStackingTypes.pc = true;
        elseif (scope == 'Enemy only') then
            global.targeting.plateStackingTypes.enemy = true;
        elseif (scope == 'All except NPC/Object') then
            global.targeting.plateStackingTypes.pc = true;
            global.targeting.plateStackingTypes.enemy = true;
            global.targeting.plateStackingTypes.trust = true;
            global.targeting.plateStackingTypes.pet = true;
        else
            global.targeting.plateStackingTypes.pc = true;
            global.targeting.plateStackingTypes.enemy = true;
        end
    end

    if (type(global.targeting.plateStackingPriority) ~= 'table') then
        global.targeting.plateStackingPriority = {};
    end

    if (global.targeting.plateStackClosestOnTop == nil) then
        global.targeting.plateStackClosestOnTop = true;
    end

    if (global.targeting.plateStackKeepTacticalFixed == nil) then
        global.targeting.plateStackKeepTacticalFixed = true;
    end

    if (global.targeting.plateStackGap == nil) then
        global.targeting.plateStackGap = 4;
    end

    if (global.targeting.plateStackHorizontalOverlap == nil) then
        global.targeting.plateStackHorizontalOverlap = 2;
    end

    if (global.targeting.plateStackVerticalOverlap == nil) then
        global.targeting.plateStackVerticalOverlap = 2;
    end

    if (global.targeting.plateStackHorizontalSpreadPct == nil) then
        global.targeting.plateStackHorizontalSpreadPct = 125;
    end

    if (global.targeting.plateStackFixedBlockerWidthPct == nil) then
        global.targeting.plateStackFixedBlockerWidthPct = 72;
    end

    if (global.targeting.tacticalScreenClampEnabled == nil) then
        global.targeting.tacticalScreenClampEnabled = false;
    end

    if (global.targeting.tacticalScreenClampTopPadding == nil) then
        global.targeting.tacticalScreenClampTopPadding = 24;
    end

    if (global.targeting.textureCacheLimit == nil) then
        global.targeting.textureCacheLimit = 96;
    end

    global.targeting.rightClickAttackRange = math.max(3.0, math.min(29.9, tonumber(global.targeting.rightClickAttackRange) or 4.5));
    global.targeting.enemyPlateRange = math.max(5.0, math.min(64.4, tonumber(global.targeting.enemyPlateRange) or 49.9));
    global.targeting.enemyActiveDetailRange = math.max(10.0, math.min(49.9, tonumber(global.targeting.enemyActiveDetailRange) or 25.0));
    global.targeting.pcDistanceScaleStart = math.max(0.0, math.min(20.0, tonumber(global.targeting.pcDistanceScaleStart) or 2.0));
    global.targeting.pcDistanceScaleEnd = math.max(1.0, math.min(40.0, tonumber(global.targeting.pcDistanceScaleEnd) or 8.0));
    if (global.targeting.pcDistanceScaleEnd <= global.targeting.pcDistanceScaleStart) then
        global.targeting.pcDistanceScaleEnd = math.min(40.0, global.targeting.pcDistanceScaleStart + 1.0);
    end
    global.targeting.pcDistanceScaleMax = math.max(1.0, math.min(6.0, tonumber(global.targeting.pcDistanceScaleMax) or 2.65));
    global.targeting.customEntityDistanceScaling = global.targeting.customEntityDistanceScaling == true;
    global.targeting.globalPlateOffsetX = math.max(-100, math.min(100, math.floor((tonumber(global.targeting.globalPlateOffsetX) or 0) + 0.5)));
    global.targeting.globalPlateOffsetY = math.max(-100, math.min(100, math.floor((tonumber(global.targeting.globalPlateOffsetY) or 0) + 0.5)));
    if (type(global.targeting.pcRacePlateAdjustments) ~= 'table') then
        global.targeting.pcRacePlateAdjustments = {};
    end
    local pcRaceAdjustments = global.targeting.pcRacePlateAdjustments;
    pcRaceAdjustments.enabled = pcRaceAdjustments.enabled ~= false;
    local pcRaceBaselines = {
        tarutaru = 82,
        mithra = 77,
        hume = 60,
        elvaan = 55,
        galka = 67,
    };
    local pcRaceDefaults = {
        tarutaru = { y = 0, size = 0 },
        mithra = { y = 0, size = 0 },
        hume = { y = 0, size = 0 },
        elvaan = { y = 0, size = 0 },
        galka = { y = 0, size = 0 },
    };
    for key, defaults in pairs(pcRaceDefaults) do
        if (type(pcRaceAdjustments[key]) ~= 'table') then
            pcRaceAdjustments[key] = {};
        end

        local yValue = tonumber(pcRaceAdjustments[key].y) or defaults.y;
        if (pcRaceAdjustments.baselineVersion ~= 2) then
            local baseline = pcRaceBaselines[key] or 0;
            if (math.abs(yValue - baseline) <= 1) then
                yValue = 0;
            elseif (math.abs(yValue) > 50 and baseline > 0) then
                yValue = yValue - baseline;
            end
        end

        pcRaceAdjustments[key].y = math.max(-100, math.min(100, math.floor(yValue + 0.5)));
        pcRaceAdjustments[key].size = math.max(-100, math.min(100, math.floor((tonumber(pcRaceAdjustments[key].size) or defaults.size) + 0.5)));
    end
    pcRaceAdjustments.baselineVersion = 2;
    for _, entityName in ipairs({ 'self', 'pc', 'trust', 'enemy', 'npc', 'object', 'pet' }) do
        if (type(global.targeting.plateDistanceScales[entityName]) ~= 'table') then
            global.targeting.plateDistanceScales[entityName] = {};
        end
        local scale = global.targeting.plateDistanceScales[entityName];
        scale.start = math.max(0.0, math.min(20.0, tonumber(scale.start) or global.targeting.pcDistanceScaleStart));
        scale.finish = math.max(1.0, math.min(40.0, tonumber(scale.finish) or global.targeting.pcDistanceScaleEnd));
        if (scale.finish <= scale.start) then
            scale.finish = math.min(40.0, scale.start + 1.0);
        end
        scale.max = math.max(1.0, math.min(6.0, tonumber(scale.max) or global.targeting.pcDistanceScaleMax));

        if (type(global.targeting.platePositionOffsets[entityName]) ~= 'table') then
            global.targeting.platePositionOffsets[entityName] = {};
        end
        global.targeting.platePositionOffsets[entityName].x = math.max(-100, math.min(100, math.floor((tonumber(global.targeting.platePositionOffsets[entityName].x) or 0) + 0.5)));
        global.targeting.platePositionOffsets[entityName].y = math.max(-100, math.min(100, math.floor((tonumber(global.targeting.platePositionOffsets[entityName].y) or 0) + 0.5)));
    end
    global.targeting.blockPlateClicksWhenImguiCapturesMouse = global.targeting.blockPlateClicksWhenImguiCapturesMouse == true;
    global.targeting.hideOtherPlayerPetPlates = global.targeting.hideOtherPlayerPetPlates ~= false;
    global.targeting.plateClickNoGoZonesEnabled = global.targeting.plateClickNoGoZonesEnabled == true;
    global.targeting.plateClickNoGoZonesVisible = global.targeting.plateClickNoGoZonesVisible == true;
    global.targeting.performanceSafetyMode = global.targeting.performanceSafetyMode == true;
    global.targeting.performanceSafetyCombatOnly = global.targeting.performanceSafetyCombatOnly ~= false;
    global.targeting.performanceSafetySkipPc = global.targeting.performanceSafetySkipPc == true;
    global.targeting.performanceSafetySkipTrust = global.targeting.performanceSafetySkipTrust == true;
    global.targeting.performanceSafetySkipNpc = global.targeting.performanceSafetySkipNpc == true;
    global.targeting.performanceSafetySkipPet = global.targeting.performanceSafetySkipPet == true;
    global.targeting.performanceSafetyImportantEnemiesOnly = global.targeting.performanceSafetyImportantEnemiesOnly == true;
    global.targeting.performanceSafetySkipPeer = global.targeting.performanceSafetySkipPeer == true;
    local performancePreset = tostring(global.targeting.performancePreset or 'Custom');
    if (
        performancePreset ~= 'Performance' and
        performancePreset ~= 'Mid' and
        performancePreset ~= 'High' and
        performancePreset ~= 'Ultra' and
        performancePreset ~= 'Custom'
    ) then
        performancePreset = 'Custom';
    end
    global.targeting.performancePreset = performancePreset;
    local gameFpsMode = tostring(global.targeting.gameFpsMode or 'Keep current');
    if (
        gameFpsMode ~= 'Keep current' and
        gameFpsMode ~= 'Do not change' and
        gameFpsMode ~= 'FPS1 (60 FPS)' and
        gameFpsMode ~= 'FPS2 (30 FPS)'
    ) then
        if (gameFpsMode == 'FPS1' or gameFpsMode == '1') then
            gameFpsMode = 'FPS1 (60 FPS)';
        elseif (gameFpsMode == 'FPS2' or gameFpsMode == '2') then
            gameFpsMode = 'FPS2 (30 FPS)';
        else
            gameFpsMode = 'Keep current';
        end
    end
    if (gameFpsMode == 'Do not change') then
        gameFpsMode = 'Keep current';
    end
    global.targeting.gameFpsMode = gameFpsMode;
    global.targeting.performanceMonitorCompact = global.targeting.performanceMonitorCompact ~= false;
    global.targeting.maxWorldPlateCount = math.max(0, math.min(300, math.floor((tonumber(global.targeting.maxWorldPlateCount) or 0) + 0.5)));
    local updateRate = tostring(global.targeting.worldPlateUpdateRate or 'Full');
    if (updateRate ~= 'Full' and updateRate ~= 'Balanced' and updateRate ~= 'Low') then
        updateRate = 'Full';
    end
    global.targeting.worldPlateUpdateRate = updateRate;
    global.targeting.hideDistantWorldPlates = global.targeting.hideDistantWorldPlates == true;
    global.targeting.worldPlateDistanceLimit = math.max(5.0, math.min(64.4, tonumber(global.targeting.worldPlateDistanceLimit) or 49.9));
    global.targeting.disableExpensiveWorldWidgets = global.targeting.disableExpensiveWorldWidgets == true;
    global.targeting.plateStackingEnabled = global.targeting.plateStackingEnabled ~= false;
    local plateStackingScope = tostring(global.targeting.plateStackingScope or 'PC + Enemy');
    if (
        plateStackingScope ~= 'PC + Enemy' and
        plateStackingScope ~= 'PC only' and
        plateStackingScope ~= 'Enemy only' and
        plateStackingScope ~= 'All except NPC/Object'
    ) then
        plateStackingScope = 'PC + Enemy';
    end
    global.targeting.plateStackingScope = plateStackingScope;
    local stackingTypes = global.targeting.plateStackingTypes;
    for _, key in ipairs(defaultPlateStackingPriority) do
        if (stackingTypes[key] == nil) then
            stackingTypes[key] = defaultPlateStackingTypes[key] == true;
        else
            stackingTypes[key] = stackingTypes[key] == true;
        end
    end

    local seenPriority = {};
    local normalizedPriority = {};
    for _, key in ipairs(global.targeting.plateStackingPriority) do
        key = tostring(key or ''):lower();
        if (defaultPlateStackingTypes[key] ~= nil and seenPriority[key] ~= true) then
            normalizedPriority[#normalizedPriority + 1] = key;
            seenPriority[key] = true;
        end
    end
    for _, key in ipairs(defaultPlateStackingPriority) do
        if (seenPriority[key] ~= true) then
            normalizedPriority[#normalizedPriority + 1] = key;
            seenPriority[key] = true;
        end
    end
    global.targeting.plateStackingPriority = normalizedPriority;
    global.targeting.plateStackClosestOnTop = global.targeting.plateStackClosestOnTop == true;
    global.targeting.plateStackKeepTacticalFixed = global.targeting.plateStackKeepTacticalFixed ~= false;
    global.targeting.plateStackGap = math.max(0, math.min(160, math.floor((tonumber(global.targeting.plateStackGap) or 4) + 0.5)));
    local horizontalOverlap = tonumber(global.targeting.plateStackHorizontalOverlap);
    local verticalOverlap = tonumber(global.targeting.plateStackVerticalOverlap);
    if (horizontalOverlap == nil or horizontalOverlap < 1) then
        horizontalOverlap = 2;
    end
    if (verticalOverlap == nil or verticalOverlap < 1) then
        verticalOverlap = horizontalOverlap;
    end
    global.targeting.plateStackHorizontalOverlap = math.max(0, math.min(80, math.floor(horizontalOverlap + 0.5)));
    global.targeting.plateStackVerticalOverlap = math.max(0, math.min(80, math.floor(verticalOverlap + 0.5)));
    global.targeting.plateStackHorizontalSpreadPct = math.max(0, math.min(250, math.floor((tonumber(global.targeting.plateStackHorizontalSpreadPct) or 125) + 0.5)));
    global.targeting.plateStackFixedBlockerWidthPct = math.max(25, math.min(100, math.floor((tonumber(global.targeting.plateStackFixedBlockerWidthPct) or 72) + 0.5)));
    global.targeting.tacticalScreenClampEnabled = global.targeting.tacticalScreenClampEnabled == true;
    global.targeting.tacticalScreenClampTopPadding = math.max(0, math.min(200, math.floor((tonumber(global.targeting.tacticalScreenClampTopPadding) or 24) + 0.5)));
    global.targeting.textureCacheLimit = math.max(32, math.min(256, math.floor((tonumber(global.targeting.textureCacheLimit) or 96) + 0.5)));
    NormalizePlateClickNoGoZones(global.targeting);

    return global.targeting;
end

function targeting.GetWorldPlateRange()
    local settings = targeting.GetSettings();
    local range = tonumber(settings.enemyPlateRange) or 49.9;

    if (settings.hideDistantWorldPlates == true) then
        range = math.min(range, tonumber(settings.worldPlateDistanceLimit) or range);
    end

    return math.max(5.0, math.min(64.4, range));
end

function targeting.GetPlateDistanceScaleSettings(entityName)
    local settings = targeting.GetSettings();

    if (settings.customEntityDistanceScaling ~= true) then
        return {
            start = tonumber(settings.pcDistanceScaleStart) or 2.0,
            finish = tonumber(settings.pcDistanceScaleEnd) or 8.0,
            max = tonumber(settings.pcDistanceScaleMax) or 2.65,
        };
    end

    local key = tostring(entityName or ''):lower();
    local scale = type(settings.plateDistanceScales) == 'table' and settings.plateDistanceScales[key] or nil;

    if (type(scale) ~= 'table') then
        scale = {};
    end

    local start = math.max(0.0, math.min(20.0, tonumber(scale.start) or tonumber(settings.pcDistanceScaleStart) or 2.0));
    local finish = math.max(1.0, math.min(40.0, tonumber(scale.finish) or tonumber(settings.pcDistanceScaleEnd) or 8.0));

    if (finish <= start) then
        finish = math.min(40.0, start + 1.0);
    end

    return {
        start = start,
        finish = finish,
        max = math.max(1.0, math.min(6.0, tonumber(scale.max) or tonumber(settings.pcDistanceScaleMax) or 2.65)),
    };
end

function targeting.GetPlatePositionOffset(entityName)
    local settings = targeting.GetSettings();
    local key = tostring(entityName or ''):lower();
    local offsets = type(settings.platePositionOffsets) == 'table' and settings.platePositionOffsets[key] or nil;

    if (type(offsets) ~= 'table') then
        offsets = {};
    end

    return {
        x = (tonumber(settings.globalPlateOffsetX) or 0) + (tonumber(offsets.x) or 0),
        y = (tonumber(settings.globalPlateOffsetY) or 0) + (tonumber(offsets.y) or 0),
    };
end

function targeting.ApplyPlateScalingSettings(worldMarker, entityName, baseOffsetX, baseOffsetY)
    if (type(worldMarker) ~= 'table') then
        return worldMarker;
    end

    local scale = targeting.GetPlateDistanceScaleSettings(entityName);
    local offset = targeting.GetPlatePositionOffset(entityName);
    local offsetUnit = 0.01;

    worldMarker.plateWorldOffsetX = (tonumber(baseOffsetX) or tonumber(worldMarker.plateWorldOffsetX) or 0) + ((tonumber(offset.x) or 0) * offsetUnit);
    worldMarker.plateWorldOffsetY = (tonumber(baseOffsetY) or tonumber(worldMarker.plateWorldOffsetY) or 0.78) + ((tonumber(offset.y) or 0) * offsetUnit);
    worldMarker.plateDistanceScaleStart = scale.start;
    worldMarker.plateDistanceScaleEnd = scale.finish;
    worldMarker.plateDistanceScaleMax = scale.max;

    return worldMarker;
end

local function GetTargetManager()
    local memory = AshitaCore:GetMemoryManager();

    if (memory == nil) then
        return nil;
    end

    return memory:GetTarget();
end

function targeting.GetCurrentTargetIndex()
    local targetManager = GetTargetManager();

    if (targetManager == nil or targetManager.GetTargetIndex == nil) then
        return nil;
    end

    -- In FFXI subtarget mode, slot 0 is the moving subtarget cursor and
    -- slot 1 keeps the original/main target. Outside subtarget mode, slot 0
    -- is the main target.
    local okActive, active = pcall(function()
        return targetManager:GetIsSubTargetActive();
    end);

    local slot = (okActive == true and (active == 1 or active == true)) and 1 or 0;
    local ok, targetIndex = pcall(function()
        return targetManager:GetTargetIndex(slot);
    end);

    if (ok ~= true or targetIndex == nil or targetIndex == 0) then
        ok, targetIndex = pcall(function()
            return targetManager:GetTargetIndex(0);
        end);
    end

    if (ok ~= true or targetIndex == nil or targetIndex == 0) then
        return nil;
    end

    return targetIndex;
end

function targeting.GetCurrentSubTargetIndex()
    local targetManager = GetTargetManager();

    if (targetManager == nil or targetManager.GetTargetIndex == nil) then
        return nil;
    end

    local function GetTargetIndex(slot)
        local ok, value = pcall(function()
            return targetManager:GetTargetIndex(slot);
        end);

        if (ok ~= true or tonumber(value) == nil or tonumber(value) == 0) then
            return nil;
        end

        return tonumber(value);
    end

    local targetIndex0 = GetTargetIndex(0);
    local targetIndex1 = GetTargetIndex(1);

    -- In subtarget mode, slot 0 is the moving subtarget cursor. Slot 1 is
    -- the original/main target. If slot 0 is empty, fall back defensively.
    local ok, active = pcall(function()
        return targetManager:GetIsSubTargetActive();
    end);

    if (ok == true and (active == 1 or active == true)) then
        return targetIndex0 or targetIndex1;
    end

    if (targetManager.GetSubTargetFlags == nil or targetIndex0 == nil) then
        return nil;
    end

    local okFlags;
    local flags;

    okFlags, flags = pcall(function()
        return targetManager:GetSubTargetFlags();
    end);

    if (okFlags == true and tonumber(flags) ~= nil and tonumber(flags) ~= 0xFFFFFFFF) then
        return targetIndex0 or targetIndex1;
    end

    return nil;
end

function targeting.GetCurrentTargetAndSubTargetIndexes()
    local targetManager = GetTargetManager();

    if (targetManager == nil or targetManager.GetTargetIndex == nil) then
        return nil, nil;
    end

    local subTargetIndex = targeting.GetCurrentSubTargetIndex();
    local targetIndex = targeting.GetCurrentTargetIndex();

    if (subTargetIndex ~= nil and targetIndex ~= nil and subTargetIndex == targetIndex) then
        return nil, targetIndex;
    end

    return targetIndex, subTargetIndex;
end

function targeting.GetTargetStateName(index)
    index = tonumber(index);

    if (index == nil or index == 0) then
        return 'Idle';
    end

    local targetIndex = targeting.GetCurrentTargetIndex();
    local subTargetIndex = targeting.GetCurrentSubTargetIndex();
    local subTargetActive = targeting.IsSubTargetModeActive();

    if (tonumber(subTargetIndex) == index or (subTargetIndex == nil and subTargetActive == true and tonumber(targetIndex) == index)) then
        return 'Subtarget';
    end

    if (tonumber(targetIndex) == index) then
        return 'Target';
    end

    return 'Idle';
end

function targeting.GetDebugStatus()
    local targetManager = GetTargetManager();

    if (targetManager == nil) then
        return 'targetmgr=nil';
    end

    local active = 'noapi';
    local slot0 = 'noapi';
    local slot1 = 'noapi';
    local slotActive = 'noapi';

    if (targetManager.GetIsSubTargetActive ~= nil) then
        local ok, result = pcall(function()
            return targetManager:GetIsSubTargetActive();
        end);

        active = ok == true and tostring(result) or ('err:' .. tostring(result));
    end

    if (targetManager.GetTargetIndex ~= nil) then
        local ok, result = pcall(function()
            return targetManager:GetTargetIndex(0);
        end);

        slot0 = ok == true and tostring(result) or ('err:' .. tostring(result));

        ok, result = pcall(function()
            return targetManager:GetTargetIndex(1);
        end);

        slot1 = ok == true and tostring(result) or ('err:' .. tostring(result));

        ok, result = pcall(function()
            local activeSlot = targetManager:GetIsSubTargetActive();

            if (activeSlot == true) then
                activeSlot = 1;
            end

            return targetManager:GetTargetIndex(activeSlot);
        end);

        slotActive = ok == true and tostring(result) or ('err:' .. tostring(result));
    end

    return 'rawSubActive=' .. active .. ' rawTarget0=' .. slot0 .. ' rawTarget1=' .. slot1 .. ' rawTargetActive=' .. slotActive;
end

function targeting.IsSubTargetActive()
    return targeting.GetCurrentSubTargetIndex() ~= nil;
end

function targeting.IsSubTargetModeActive()
    local targetManager = GetTargetManager();

    if (targetManager == nil or targetManager.GetIsSubTargetActive == nil) then
        return false;
    end

    local ok, active = pcall(function()
        return targetManager:GetIsSubTargetActive();
    end);

    if (ok ~= true) then
        return false;
    end

    return active == 1 or active == true;
end

function targeting.GetIsTargetLockedOn()
    local targetManager = GetTargetManager();

    if (targetManager == nil) then
        return false;
    end

    if (targetManager.GetIsLockedOn ~= nil) then
        local ok, result = pcall(function()
            return targetManager:GetIsLockedOn();
        end);

        return ok == true and result == 1;
    end

    if (targetManager.GetLockedOnFlags ~= nil) then
        local ok, flags = pcall(function()
            return targetManager:GetLockedOnFlags();
        end);

        return ok == true and bit.band(flags or 0, 0x01) == 0x01;
    end

    return false;
end

function targeting.IsPlayerEngaged()
    local party = AshitaCore:GetMemoryManager():GetParty();
    local entity = AshitaCore:GetMemoryManager():GetEntity();

    if (party == nil or entity == nil) then
        return false;
    end

    local selfIndex = nil;
    local ok = pcall(function()
        selfIndex = party:GetMemberTargetIndex(0);
    end);

    if (ok ~= true or selfIndex == nil or selfIndex == 0) then
        return false;
    end

    local selfEntity = GetEntity(selfIndex);

    return selfEntity ~= nil and selfEntity.Status == 1;
end

function targeting.SelectTarget(targetIndex)
    if (targetIndex == nil or targetIndex == 0) then
        return false;
    end

    local memory = AshitaCore:GetMemoryManager();
    local targetManager = memory:GetTarget();

    if (targetManager == nil) then
        return false;
    end

    local ok = pcall(function ()
        targetManager:SetTarget(targetIndex, false);
    end);

    if (ok == true) then
        return true;
    end

    local entityManager = memory:GetEntity();

    if (entityManager == nil) then
        return false;
    end

    local serverId = nil;
    ok = pcall(function ()
        serverId = entityManager:GetServerId(targetIndex);
    end);

    if (ok ~= true or serverId == nil or serverId == 0) then
        return false;
    end

    ok = pcall(function ()
        targetManager:SetTarget(serverId, false);
    end);

    return (ok == true);
end

function targeting.SelectEnemyTarget(targetIndex, allowCombatSwitch)
    if (targetIndex == nil or targetIndex == 0) then
        return false;
    end

    if (allowCombatSwitch ~= true and targeting.IsSubTargetModeActive() ~= true) then
        local settings = GetTargetingSettings();

        if (targeting.IsPlayerEngaged() == true) then
            if (settings.enableLeftClickEnemyTargetCombat ~= true) then
                return false;
            end
        elseif (settings.enableLeftClickEnemyTargetIdle ~= true) then
            return false;
        end
    end

    local memory = AshitaCore:GetMemoryManager();
    local targetManager = memory:GetTarget();

    if (targetManager == nil) then
        return false;
    end

    local ok = pcall(function ()
        targetManager:SetTarget(targetIndex, false);
    end);

    if (ok == true) then
        return true;
    end

    ok = pcall(function ()
        targetManager:SetTarget(targetIndex, true);
    end);

    if (ok == true) then
        return true;
    end

    local entityManager = memory:GetEntity();

    if (entityManager == nil) then
        return false;
    end

    local serverId = nil;
    ok = pcall(function ()
        serverId = entityManager:GetServerId(targetIndex);
    end);

    if (ok ~= true or serverId == nil or serverId == 0) then
        return false;
    end

    ok = pcall(function ()
        targetManager:SetTarget(serverId, false);
    end);

    if (ok == true) then
        return true;
    end

    ok = pcall(function ()
        targetManager:SetTarget(serverId, true);
    end);

    return (ok == true);
end

function targeting.AttackEnemyTarget(targetIndex, serverId, distance, modelHitboxSize)
    if (targetIndex == nil or targetIndex == 0) then
        return false;
    end

    local settings = GetTargetingSettings();

    if (settings.enableRightClickAttack ~= true) then
        return false;
    end

    if (settings.enableRightClickAttackWhileMounted ~= true and targeting.IsPlayerMounted() == true) then
        return false;
    end

    local attackRange = tonumber(settings.rightClickAttackRange) or 4.5;
    local effectiveAttackRange = attackRange + 0.5 + (tonumber(modelHitboxSize) or 0.5);

    if (distance ~= nil and tonumber(distance) ~= nil and tonumber(distance) > effectiveAttackRange) then
        return false;
    end

    local selected = targeting.SelectEnemyTarget(targetIndex, true);

    local commandTarget = tonumber(serverId) or 0;

    if (commandTarget ~= 0) then
        AshitaCore:GetChatManager():QueueCommand(1, '/attack ' .. tostring(commandTarget));
    else
        AshitaCore:GetChatManager():QueueCommand(1, '/attack <t>');
    end

    return selected == true;
end

function targeting.IsPlayerMounted()
    local ok, status = pcall(function()
        local memory = AshitaCore:GetMemoryManager();
        local party = memory:GetParty();
        local selfIndex = party ~= nil and party:GetMemberTargetIndex(0) or nil;

        if (selfIndex == nil or selfIndex <= 0) then
            return nil;
        end

        local entity = memory:GetEntity();

        if (entity == nil or entity.GetStatus == nil) then
            return nil;
        end

        return entity:GetStatus(selfIndex);
    end);

    return ok == true and tonumber(status) == 85;
end

local gatheringActions = {
    ['Mining Point'] = { command = '/item "Pickaxe" <t>', tool = 'Pickaxe', settingKey = 'enableRightClickMining' },
    ['Excavation Point'] = { command = '/item "Pickaxe" <t>', tool = 'Pickaxe', settingKey = 'enableRightClickExcavation' },
    ['Excav. Point'] = { command = '/item "Pickaxe" <t>', tool = 'Pickaxe', settingKey = 'enableRightClickExcavation' },
    ['Logging Point'] = { command = '/item "Hatchet" <t>', tool = 'Hatchet', settingKey = 'enableRightClickLogging' },
    ['Harvest Point'] = { command = '/item "Sickle" <t>', tool = 'Sickle', settingKey = 'enableRightClickHarvesting' },
    ['Harvesting Point'] = { command = '/item "Sickle" <t>', tool = 'Sickle', settingKey = 'enableRightClickHarvesting' },
};

local function NormalizeObjectName(name)
    return tostring(name or ''):gsub(string.char(0x1E) .. '.', ''):gsub('[%z\1-\31]', ''):gsub('^%s+', ''):gsub('%s+$', '');
end

local function GetGatheringAction(name)
    return gatheringActions[NormalizeObjectName(name)];
end

local function GetGatheringToolIconFile(toolName)
    local normalized = NormalizeObjectName(toolName);

    if (normalized == 'Hatchet') then
        return 'hatchet.png';
    end

    if (normalized == 'Sickle') then
        return 'sickle.png';
    end

    return 'pickaxe.png';
end

local function GetResourceItemName(itemId)
    local resource = nil;

    pcall(function()
        resource = AshitaCore:GetResourceManager():GetItemById(itemId);
    end);

    if (resource == nil) then
        return '';
    end

    local candidates = {
        function() return resource.Name[1]; end,
        function() return resource.Name[0]; end,
        function() return resource.Name; end,
        function() return resource.NameSingular[1]; end,
        function() return resource.NameSingular[0]; end,
        function() return resource.NameSingular; end,
        function() return resource.LogNameSingular[1]; end,
        function() return resource.LogNameSingular[0]; end,
        function() return resource.LogNameSingular; end,
    };

    for _, getter in ipairs(candidates) do
        local ok, value = pcall(getter);

        if (ok == true and value ~= nil) then
            local text = tostring(value);

            if (text ~= '' and text:find('userdata:', 1, true) == nil) then
                return text;
            end
        end
    end

    return '';
end

local function HasInventoryItem(itemName)
    local inventory = AshitaCore:GetMemoryManager():GetInventory();
    local wanted = NormalizeObjectName(itemName):lower();
    local totalCount = 0;
    local firstContainer = nil;
    local firstIndex = nil;

    if (inventory == nil or wanted == '') then
        return false;
    end

    for container = 0, 17 do
        for index = 0, 80 do
            local item = nil;

            pcall(function()
                item = inventory:GetContainerItem(container, index);
            end);

            if (item ~= nil and tonumber(item.Id) ~= nil and tonumber(item.Id) ~= 0 and tonumber(item.Count) ~= 0) then
                local name = NormalizeObjectName(GetResourceItemName(item.Id)):lower();

                if (name == wanted) then
                    if (firstContainer == nil) then
                        firstContainer = container;
                        firstIndex = index;
                    end

                    totalCount = totalCount + (tonumber(item.Count) or 1);
                end
            end
        end
    end

    if (totalCount > 0) then
        return true, firstContainer, firstIndex, totalCount;
    end

    return false;
end

local function GetGatheringToolCount(toolName)
    local _, _, _, count = HasInventoryItem(toolName);
    return tonumber(count) or 0;
end

local function UpdateGatheringToolCounts()
    local now = os.clock();

    if ((now - lastGatheringToolPoll) < 0.35) then
        return;
    end

    lastGatheringToolPoll = now;

    local tools = { 'Hatchet', 'Sickle', 'Pickaxe' };

    if (gatheringToolCounts == nil) then
        gatheringToolCounts = {};

        for _, toolName in ipairs(tools) do
            gatheringToolCounts[toolName] = GetGatheringToolCount(toolName);
        end

        return;
    end

    for _, toolName in ipairs(tools) do
        local previous = tonumber(gatheringToolCounts[toolName]) or 0;
        local current = GetGatheringToolCount(toolName);
        gatheringToolCounts[toolName] = current;

        if (current < previous and now >= (tonumber(suppressGatheringDisplayUntil) or 0)) then
            lastGatheringDisplay = {
                targetName = nil,
                toolName = toolName,
                iconFile = GetGatheringToolIconFile(toolName),
                count = current,
                hasTool = current > 0,
            };
            lastGatheringDisplayUntil = now + 8.0;
            lastGatheringInteractStatus =
                'tool count dropped ' ..
                tostring(toolName) ..
                ' ' .. tostring(previous) ..
                ' -> ' .. tostring(current);
        end
    end
end

local function SuppressGatheringDisplay(seconds, reason)
    local now = os.clock();
    suppressGatheringDisplayUntil = math.max(
        tonumber(suppressGatheringDisplayUntil) or 0,
        now + math.max(1.0, tonumber(seconds) or 5.0)
    );
    lastGatheringDisplay = nil;
    lastGatheringDisplayUntil = 0;
    gatheringToolCounts = nil;
    lastGatheringToolPoll = 0;
    lastGatheringInteractStatus = 'display suppressed ' .. tostring(reason or 'zone');
end

local function NormalizeGatheringToolName(toolName)
    local value = NormalizeObjectName(toolName):lower();

    if (value == 'hatchet' or value == 'log' or value == 'logging') then
        return 'Hatchet';
    end

    if (value == 'sickle' or value == 'harvest' or value == 'harvesting') then
        return 'Sickle';
    end

    if (value == 'pickaxe' or value == 'pick' or value == 'mine' or value == 'mining' or value == 'excavation') then
        return 'Pickaxe';
    end

    return nil;
end

local function GetEquippedItemName(slot)
    local inventory = AshitaCore:GetMemoryManager():GetInventory();

    if (inventory == nil) then
        return nil;
    end

    local equippedItem = nil;
    pcall(function()
        equippedItem = inventory:GetEquippedItem(slot);
    end);

    if (equippedItem == nil or equippedItem.Index == nil) then
        return nil;
    end

    local index = bit.band(equippedItem.Index, 0x00FF);

    if (index <= 0) then
        return nil;
    end

    local container = bit.rshift(bit.band(equippedItem.Index, 0xFF00), 8);
    local item = nil;

    pcall(function()
        item = inventory:GetContainerItem(container, index);
    end);

    if (item == nil or tonumber(item.Id) == nil or tonumber(item.Id) == 0) then
        return nil;
    end

    return NormalizeObjectName(GetResourceItemName(item.Id));
end

function targeting.GetFishingEquipmentStatus()
    local rangedName = GetEquippedItemName(2) or '';
    local lower = rangedName:lower();
    local hasRod = lower:find('rod', 1, true) ~= nil;

    return 'ranged=' .. (rangedName ~= '' and rangedName or 'none') .. ' rod=' .. tostring(hasRod);
end

local function IsFishingRodEquipped()
    local rangedName = GetEquippedItemName(2) or '';

    return rangedName:lower():find('rod', 1, true) ~= nil, rangedName;
end

function targeting.TryRightClickFish(e)
    local message = tonumber(e ~= nil and e.message);

    if (suppressFishRightMouse == true) then
        if (message == 512 or message == 517) then
            e.blocked = true;

            if (message == 517) then
                suppressFishRightMouse = false;
                lastGatheringInteractStatus = 'fish mouse released';
            end

            return true;
        end
    end

    if (message ~= 516) then
        return false;
    end

    local global = state.GetGlobalSettings(globalDefaults);
    local fishingSettings = global.fishing or {};

    if (fishingSettings.enabled == false or fishingSettings.enableRightClickFish == false) then
        lastGatheringInteractStatus = 'fish disabled message=' .. tostring(message);
        return false;
    end

    local now = os.clock();

    if ((now - lastFishCommandTime) < 1.0) then
        suppressFishRightMouse = true;
        e.blocked = true;
        lastGatheringInteractStatus = 'fish cooldown message=' .. tostring(message);
        return true;
    end

    local hasRod, rangedName = IsFishingRodEquipped();

    if (hasRod ~= true) then
        lastGatheringInteractStatus = 'fish skipped no rod ranged=' .. tostring(rangedName or 'none') .. ' message=' .. tostring(message);
        return false;
    end

    lastFishCommandTime = now;
    suppressFishRightMouse = true;
    AshitaCore:GetChatManager():QueueCommand(1, '/fish');
    lastGatheringInteractStatus = 'sent /fish ranged=' .. tostring(rangedName or '') .. ' message=' .. tostring(message);
    e.blocked = true;
    return true;
end

function targeting.InteractFishingGatheringTarget(targetIndex, targetType, distance)
    if (targetIndex == nil or targetIndex == 0) then
        lastGatheringInteractStatus = 'invalid target';
        return false;
    end

    local global = state.GetGlobalSettings(globalDefaults);
    local fishingSettings = global.fishing or {};

    if (fishingSettings.enabled == false or fishingSettings.enableRightClickGathering ~= true) then
        lastGatheringInteractStatus = 'disabled';
        return false;
    end

    local normalizedType = tostring(targetType or '');

    if (normalizedType ~= 'object') then
        lastGatheringInteractStatus = 'ignored type=' .. normalizedType;
        return false;
    end

    local entity = GetEntity(targetIndex);
    local name = NormalizeObjectName(entity ~= nil and entity.Name or '');
    local action = GetGatheringAction(name);

    if (action == nil) then
        lastGatheringInteractStatus = 'no mapping name=' .. tostring(name) .. ' type=' .. normalizedType;
        return false;
    end

    local actionEnabled = fishingSettings[action.settingKey];

    if (actionEnabled == nil) then
        actionEnabled = true;
    end

    if (actionEnabled ~= true) then
        lastGatheringInteractStatus = 'disabled action=' .. tostring(action.settingKey) .. ' name=' .. tostring(name);
        return false;
    end

    local hasTool, container, index, count = HasInventoryItem(action.tool);

    if (hasTool ~= true) then
        lastGatheringInteractStatus = 'missing tool=' .. tostring(action.tool) .. ' name=' .. tostring(name);
        return false;
    end

    local selected = targeting.SelectTarget(targetIndex);

    if (selected == true) then
        pendingGatheringCommand = {
            command = action.command,
            due = os.clock() + 0.20,
            targetIndex = targetIndex,
            name = name,
        };
        pendingGatheringWatch = {
            targetName = name,
            toolName = action.tool,
            iconFile = GetGatheringToolIconFile(action.tool),
            previousCount = tonumber(count) or 0,
            started = os.clock(),
        };
        lastGatheringInteractStatus =
            'queued ' .. action.command ..
            ' name=' .. name ..
            ' tool=' .. tostring(action.tool) ..
            ' count=' .. tostring(count) ..
            ' c=' .. tostring(container) ..
            ' i=' .. tostring(index) ..
            ' target=' .. tostring(targetIndex);
    else
        lastGatheringInteractStatus = 'select failed name=' .. name .. ' target=' .. tostring(targetIndex);
    end

    return selected == true;
end

function targeting.IsGatheringPointName(name)
    return GetGatheringAction(name) ~= nil;
end

function targeting.GetGatheringDisplayInfo()
    if (lastGatheringDisplay ~= nil and os.clock() <= (tonumber(lastGatheringDisplayUntil) or 0)) then
        return lastGatheringDisplay;
    end

    lastGatheringDisplay = nil;
    lastGatheringDisplayUntil = 0;
    return nil;
end

function targeting.ForceGatheringDisplay(toolName, seconds)
    local normalizedTool = NormalizeGatheringToolName(toolName) or 'Hatchet';
    local count = GetGatheringToolCount(normalizedTool);

    lastGatheringDisplay = {
        targetName = 'debug',
        toolName = normalizedTool,
        iconFile = GetGatheringToolIconFile(normalizedTool),
        count = count,
        hasTool = count > 0,
    };
    lastGatheringDisplayUntil = os.clock() + math.max(1, math.min(30, tonumber(seconds) or 8));
    lastGatheringInteractStatus = 'forced display tool=' .. tostring(normalizedTool) .. ' count=' .. tostring(count);
end

function targeting.GetGatheringDebugStatus()
    local hatchet = GetGatheringToolCount('Hatchet');
    local sickle = GetGatheringToolCount('Sickle');
    local pickaxe = GetGatheringToolCount('Pickaxe');
    local displayActive = lastGatheringDisplay ~= nil and os.clock() <= (tonumber(lastGatheringDisplayUntil) or 0);
    local displayLeft = displayActive == true and math.max(0, (tonumber(lastGatheringDisplayUntil) or 0) - os.clock()) or 0;
    local watched = {};

    if (gatheringToolCounts ~= nil) then
        watched[#watched + 1] = 'Hatchet=' .. tostring(gatheringToolCounts.Hatchet);
        watched[#watched + 1] = 'Sickle=' .. tostring(gatheringToolCounts.Sickle);
        watched[#watched + 1] = 'Pickaxe=' .. tostring(gatheringToolCounts.Pickaxe);
    else
        watched[#watched + 1] = 'not initialized';
    end

    return
        'counts Hatchet=' .. tostring(hatchet) ..
        ' Sickle=' .. tostring(sickle) ..
        ' Pickaxe=' .. tostring(pickaxe) ..
        ' watched[' .. table.concat(watched, ' ') .. ']' ..
        ' displayActive=' .. tostring(displayActive) ..
        ' displayTool=' .. tostring(lastGatheringDisplay ~= nil and lastGatheringDisplay.toolName or nil) ..
        ' displayCount=' .. tostring(lastGatheringDisplay ~= nil and lastGatheringDisplay.count or nil) ..
        ' displayLeft=' .. string.format('%.1f', displayLeft) ..
        ' pending=' .. tostring(pendingGatheringWatch ~= nil and pendingGatheringWatch.toolName or nil) ..
        ' status=' .. tostring(lastGatheringInteractStatus);
end

function targeting.GetGatheringDisplaySignature()
    local display = targeting.GetGatheringDisplayInfo();

    if (display == nil) then
        return 'none';
    end

    return table.concat({
        tostring(display.toolName or ''),
        tostring(display.iconFile or ''),
        tostring(display.count or ''),
        tostring(math.floor((tonumber(lastGatheringDisplayUntil) or 0) * 10)),
    }, ':');
end

function targeting.ShouldShowGatheringPoint(name)
    local global = state.GetGlobalSettings(globalDefaults);
    local fishingSettings = global.fishing or {};

    if (fishingSettings.enabled == false or fishingSettings.showGatheringPoints == false) then
        return false;
    end

    local action = GetGatheringAction(name);

    if (action == nil) then
        return false;
    end

    if (fishingSettings.showGatheringPointsOnlyWithTool ~= true) then
        return true;
    end

    local hasTool = HasInventoryItem(action.tool);
    return hasTool == true;
end

function targeting.Update()
    UpdateGatheringToolCounts();

    if (pendingGatheringWatch ~= nil) then
        local hasTool, _, _, count = HasInventoryItem(pendingGatheringWatch.toolName);
        local currentCount = tonumber(count) or 0;
        local previousCount = tonumber(pendingGatheringWatch.previousCount) or 0;

        if (currentCount ~= previousCount) then
            lastGatheringDisplay = {
                targetName = pendingGatheringWatch.targetName,
                toolName = pendingGatheringWatch.toolName,
                iconFile = pendingGatheringWatch.iconFile,
                count = currentCount,
                hasTool = hasTool == true,
            };
            lastGatheringDisplayUntil = os.clock() + 8.0;
            lastGatheringInteractStatus =
                'tool count changed ' ..
                tostring(pendingGatheringWatch.toolName) ..
                ' ' .. tostring(previousCount) ..
                ' -> ' .. tostring(currentCount);
            pendingGatheringWatch = nil;
        elseif ((os.clock() - (pendingGatheringWatch.started or os.clock())) > 20.0) then
            pendingGatheringWatch = nil;
        end
    end

    if (pendingGatheringCommand == nil) then
        return;
    end

    if (os.clock() < pendingGatheringCommand.due) then
        return;
    end

    local command = pendingGatheringCommand.command;
    local name = pendingGatheringCommand.name;
    pendingGatheringCommand = nil;

    AshitaCore:GetChatManager():QueueCommand(1, command);
    lastGatheringInteractStatus = 'sent ' .. tostring(command) .. ' name=' .. tostring(name);
end

function targeting.GetGatheringInteractStatus()
    return lastGatheringInteractStatus;
end

function targeting.HandlePacketIn(e)
    if (e ~= nil and e.id == 0x000A) then
        SuppressGatheringDisplay(6.0, 'zone');
    end
end

function targeting.HandleLogin()
    SuppressGatheringDisplay(6.0, 'login');
end

function targeting.GetSettings()
    return GetTargetingSettings();
end

return targeting;
