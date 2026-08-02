local targeting = {};
local bit = require('bit');
local state = require('core.state');
local mounted = require('core.mounted');
local globalDefaults = require('config.global');
local pendingGatheringCommand = nil;
local pendingGatheringWatch = nil;
local lastGatheringInteractStatus = 'none';
local lastGatheringDisplay = nil;
local lastGatheringDisplayUntil = 0;
local gatheringToolCounts = nil;
local lastGatheringToolPoll = 0;
local suppressGatheringDisplayUntil = 0;
local defaultPlateClickNoGoZones = {
    { name = 'Screen 1', enabled = false, x = 0, y = 960, width = 760, height = 480, color = { 1.0, 0.15, 0.15, 1.0 } },
    { name = 'Screen 2', enabled = false, x = 760, y = 1160, width = 1160, height = 280, color = { 0.15, 0.75, 1.0, 1.0 } },
    { name = 'Screen 3', enabled = false, x = 1920, y = 0, width = 640, height = 1440, color = { 1.0, 0.80, 0.10, 1.0 } },
    { name = 'Screen 4', enabled = false, x = 0, y = 0, width = 360, height = 960, color = { 0.40, 1.0, 0.25, 1.0 } },
};
local oldPlateClickNoGoZoneNames = {
    Chat = true,
    ['Bottom bar'] = true,
    ['Right UI'] = true,
    ['Left UI'] = true,
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

local pcHeightBucketKeys = {
    'tarutaru_male_small', 'tarutaru_male_medium', 'tarutaru_male_large',
    'tarutaru_female_small', 'tarutaru_female_medium', 'tarutaru_female_large',
    'hume_male_small', 'hume_male_medium', 'hume_male_large',
    'hume_female_small', 'hume_female_medium', 'hume_female_large',
    'mithra_female_small', 'mithra_female_medium', 'mithra_female_large',
    'elvaan_male_small', 'elvaan_male_medium', 'elvaan_male_large',
    'elvaan_female_small', 'elvaan_female_medium', 'elvaan_female_large',
    'galka_male_small', 'galka_male_medium', 'galka_male_large',
};
local pcHeightRaceKeys = { 'tarutaru', 'mithra', 'hume', 'elvaan', 'galka' };

local function NormalizeCurrentTargetBar(settings)
    local defaults = globalDefaults.targeting.currentTargetBar or {};

    if (type(settings.currentTargetBar) ~= 'table') then
        settings.currentTargetBar = {};
    end

    local bar = settings.currentTargetBar;

    local function NumberField(key, minValue, maxValue)
        local value = tonumber(bar[key]);
        if (value == nil) then
            value = tonumber(defaults[key]) or 0;
        end

        bar[key] = math.max(minValue, math.min(maxValue, math.floor(value + 0.5)));
    end

    local function ColorField(key)
        local fallback = defaults[key] or { 1.0, 1.0, 1.0, 1.0 };
        if (type(bar[key]) ~= 'table') then
            bar[key] = {};
        end

        for index = 1, 4 do
            local value = tonumber(bar[key][index]);
            if (value == nil) then
                value = tonumber(fallback[index]) or (index == 4 and 1.0 or 0.0);
            end

            if (value < 0) then value = 0; end
            if (value > 1) then value = 1; end
            bar[key][index] = value;
        end
    end

    local function NormalizeTextGroup(key, useLegacy)
        local groupDefaults = defaults[key] or {};
        if (type(bar[key]) ~= 'table') then
            bar[key] = {};
        end

        local group = bar[key];

        local function GroupNumberField(field, legacyField, minValue, maxValue)
            local value = tonumber(group[field]);
            if (value == nil and useLegacy == true) then
                value = tonumber(bar[legacyField or field]);
            end
            if (value == nil) then
                value = tonumber(groupDefaults[field]) or 0;
            end

            group[field] = math.max(minValue, math.min(maxValue, math.floor(value + 0.5)));
        end

        local function GroupColorField(field, legacyField)
            local fallback = groupDefaults[field] or defaults[legacyField or field] or { 1.0, 1.0, 1.0, 1.0 };
            local legacy = useLegacy == true and type(bar[legacyField or field]) == 'table' and bar[legacyField or field] or nil;
            if (type(group[field]) ~= 'table') then
                group[field] = {};
            end

            for index = 1, 4 do
                local value = tonumber(group[field][index]);
                if (value == nil and legacy ~= nil) then
                    value = tonumber(legacy[index]);
                end
                if (value == nil) then
                    value = tonumber(fallback[index]) or (index == 4 and 1.0 or 0.0);
                end

                if (value < 0) then value = 0; end
                if (value > 1) then value = 1; end
                group[field][index] = value;
            end
        end

        GroupNumberField('fontSize', 'fontSize', 6, 80);
        GroupNumberField('nameOffsetX', 'nameOffsetX', -500, 500);
        GroupNumberField('nameOffsetY', 'nameOffsetY', -500, 500);
        GroupNumberField('distanceOffsetX', 'distanceOffsetX', -500, 500);
        GroupNumberField('distanceOffsetY', 'distanceOffsetY', -500, 500);
        GroupNumberField('hpPercentOffsetX', 'hpPercentOffsetX', -500, 500);
        GroupNumberField('hpPercentOffsetY', 'hpPercentOffsetY', -500, 500);
        group.inheritColors = true;
        GroupColorField('textColor', 'textColor');
        GroupColorField('outlineColor', 'outlineColor');
    end

    local function NormalizeStatusGroup(key)
        local groupDefaults = defaults[key] or {};
        if (type(bar[key]) ~= 'table') then
            bar[key] = {};
        end

        local group = bar[key];

        local function GroupNumberField(field, minValue, maxValue)
            local value = tonumber(group[field]);
            if (value == nil) then
                value = tonumber(groupDefaults[field]) or 0;
            end

            group[field] = math.max(minValue, math.min(maxValue, math.floor(value + 0.5)));
        end

        if (group.enabled == nil) then group.enabled = groupDefaults.enabled == true; end

        if (key == 'buffs' and group.enabled == false and tonumber(group.offsetY) == -44) then
            group.enabled = true;
            group.offsetY = 22;
        end
        if (key == 'debuffs' and tonumber(group.offsetY) == 22) then
            group.offsetY = 44;
        end

        group.enabled = group.enabled == true;
        group.showTimers = group.showTimers == true;
        GroupNumberField('offsetX', -2000, 2000);
        GroupNumberField('offsetY', -2000, 2000);
        GroupNumberField('maxIcons', 1, 32);
        GroupNumberField('iconsPerRow', 1, 32);
        GroupNumberField('iconSize', 6, 96);
        GroupNumberField('iconSpacing', 0, 32);
        GroupNumberField('rowSpacing', 0, 48);
    end

    local function NormalizeMobInfoGroup()
        local groupDefaults = defaults.mobInfo or {};
        if (type(bar.mobInfo) ~= 'table') then
            bar.mobInfo = {};
        end

        local group = bar.mobInfo;

        local function GroupColorField(field)
            local fallback = groupDefaults[field] or { 1.0, 1.0, 1.0, 1.0 };
            if (type(group[field]) ~= 'table') then
                group[field] = {};
            end

            for index = 1, 4 do
                local value = tonumber(group[field][index]);
                if (value == nil) then
                    value = tonumber(fallback[index]) or (index == 4 and 1.0 or 0.0);
                end

                if (value < 0) then value = 0; end
                if (value > 1) then value = 1; end
                group[field][index] = value;
            end
        end

        local function GroupNumberField(field, minValue, maxValue)
            local value = tonumber(group[field]);
            if (value == nil) then
                value = tonumber(groupDefaults[field]) or 0;
            end

            group[field] = math.max(minValue, math.min(maxValue, math.floor(value + 0.5)));
        end

        if (group.enabled == nil) then group.enabled = groupDefaults.enabled == true; end
        if (group.showJobLevel == nil) then group.showJobLevel = groupDefaults.showJobLevel ~= false; end
        if (group.showBehavior == nil) then group.showBehavior = groupDefaults.showBehavior ~= false; end
        if (group.showLinks == nil) then group.showLinks = groupDefaults.showLinks ~= false; end
        if (group.showDetects == nil) then group.showDetects = groupDefaults.showDetects ~= false; end
        if (group.showWeakResist == nil) then group.showWeakResist = groupDefaults.showWeakResist ~= false; end
        if (group.showImmunities == nil) then group.showImmunities = groupDefaults.showImmunities == true; end

        group.enabled = group.enabled == true;
        group.showJobLevel = group.showJobLevel == true;
        group.showBehavior = group.showBehavior == true;
        group.showLinks = group.showLinks == true;
        group.showDetects = group.showDetects == true;
        group.showWeakResist = group.showWeakResist == true;
        group.showImmunities = group.showImmunities == true;

        GroupNumberField('offsetX', -2000, 2000);
        GroupNumberField('offsetY', -2000, 2000);
        GroupNumberField('fontSize', 6, 80);
        GroupNumberField('outlineSize', 0, 12);
        GroupNumberField('maxIcons', 1, 32);
        GroupNumberField('iconSize', 6, 96);
        GroupNumberField('iconSpacing', 0, 32);
        GroupColorField('textColor');
        GroupColorField('outlineColor');
    end

    local function NormalizeSharedText()
        local textDefaults = defaults.text or {};
        if (type(bar.text) ~= 'table') then
            bar.text = {};
        end

        local text = bar.text;
        local fallbackGroup = type(bar.enemyText) == 'table' and bar.enemyText or {};

        local function SharedNumberField(field, legacyField, minValue, maxValue)
            local value = tonumber(text[field]);
            if (value == nil) then
                value = tonumber(fallbackGroup[field]) or tonumber(bar[legacyField or field]) or tonumber(textDefaults[field]);
            end

            text[field] = math.max(minValue, math.min(maxValue, math.floor((tonumber(value) or 0) + 0.5)));
        end

        SharedNumberField('fontSize', 'fontSize', 6, 80);
        SharedNumberField('nameOffsetX', 'nameOffsetX', -500, 500);
        SharedNumberField('nameOffsetY', 'nameOffsetY', -500, 500);
        SharedNumberField('distanceOffsetX', 'distanceOffsetX', -500, 500);
        SharedNumberField('distanceOffsetY', 'distanceOffsetY', -500, 500);
        SharedNumberField('hpPercentOffsetX', 'hpPercentOffsetX', -500, 500);
        SharedNumberField('hpPercentOffsetY', 'hpPercentOffsetY', -500, 500);
    end

    if (bar.enabled == nil) then bar.enabled = defaults.enabled == true; end
    bar.enabled = bar.enabled == true;

    NumberField('x', 0, 4000);
    NumberField('y', 0, 4000);
    NumberField('width', 20, 2000);
    NumberField('height', 1, 200);
    NumberField('radius', 0, 40);
    NumberField('borderSize', 0, 20);
    NumberField('nameOffsetX', -500, 500);
    NumberField('nameOffsetY', -500, 500);
    NumberField('distanceOffsetX', -500, 500);
    NumberField('distanceOffsetY', -500, 500);
    NumberField('hpPercentOffsetX', -500, 500);
    NumberField('hpPercentOffsetY', -500, 500);

    ColorField('backgroundColor');
    ColorField('fillColor');
    ColorField('borderColor');
    ColorField('textColor');
    ColorField('outlineColor');

    local mode = tostring(bar.hpPercentMode or defaults.hpPercentMode or 'Enemies only');
    if (mode ~= 'Hidden' and mode ~= 'Enemies only' and mode ~= 'Always') then
        mode = 'Enemies only';
    end

    bar.hpPercentMode = mode;

    NormalizeTextGroup('enemyText', true);
    NormalizeTextGroup('nonEnemyText', true);
    NormalizeTextGroup('claimedText', false);
    NormalizeTextGroup('objectText', false);
    NormalizeTextGroup('selfText', false);
    NormalizeTextGroup('playerText', false);
    NormalizeSharedText();
    NormalizeMobInfoGroup();
    NormalizeStatusGroup('buffs');
    NormalizeStatusGroup('debuffs');
end

local function NormalizeHpPrediction(settings)
    local defaults = globalDefaults.targeting.hpPrediction or {};

    if (type(settings.hpPrediction) ~= 'table') then
        settings.hpPrediction = {};
    end

    local hpPrediction = settings.hpPrediction;
    if (hpPrediction.smoothHpMovement == nil) then hpPrediction.smoothHpMovement = defaults.smoothHpMovement ~= false; end
    if (hpPrediction.damagePrediction == nil) then hpPrediction.damagePrediction = defaults.damagePrediction ~= false; end
    if (hpPrediction.healingPrediction == nil) then hpPrediction.healingPrediction = defaults.healingPrediction ~= false; end

    hpPrediction.smoothHpMovement = hpPrediction.smoothHpMovement ~= false;
    hpPrediction.damagePrediction = hpPrediction.damagePrediction ~= false;
    hpPrediction.healingPrediction = hpPrediction.healingPrediction ~= false;
end

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

        if (zone.name == nil or oldPlateClickNoGoZoneNames[tostring(zone.name)] == true) then zone.name = defaults.name; end
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

    if (global.targeting.globalPlateOffsetY == nil) then
        global.targeting.globalPlateOffsetY = 0;
    end

    if (global.targeting.customEntityPlatePosition == nil) then
        global.targeting.customEntityPlatePosition = false;
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

    NormalizeCurrentTargetBar(global.targeting);
    NormalizeHpPrediction(global.targeting);

    if (global.targeting.streamerModeEnabled == nil) then
        global.targeting.streamerModeEnabled = false;
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

    if (global.targeting.pcMouseSnapMode == nil) then
        global.targeting.pcMouseSnapMode = 'Off';
    end

    if (global.targeting.enemyMouseSnapMode == nil) then
        global.targeting.enemyMouseSnapMode = 'Off';
    end

    local legacyMouseSnapStrength = math.max(1, math.min(5, math.floor((tonumber(global.targeting.mouseSnapStrength) or 5) + 0.5)));
    if (global.targeting.pcMouseSnapStrength == nil) then
        global.targeting.pcMouseSnapStrength = legacyMouseSnapStrength;
    end

    if (global.targeting.enemyMouseSnapStrength == nil) then
        global.targeting.enemyMouseSnapStrength = legacyMouseSnapStrength;
    end

    if (global.targeting.plateClickNoGoZonesEnabled == nil) then
        global.targeting.plateClickNoGoZonesEnabled = false;
    end

    if (global.targeting.plateClickNoGoZonesVisible == nil) then
        global.targeting.plateClickNoGoZonesVisible = false;
    end

    if (global.targeting.plateClickNoGoZonesMask == nil) then
        global.targeting.plateClickNoGoZonesMask = false;
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

    if (global.targeting.worldPlateUpdateRate == nil) then
        global.targeting.worldPlateUpdateRate = 'Full';
    end

    if (global.targeting.pcWorldRefreshRate == nil) then
        global.targeting.pcWorldRefreshRate = 1.0;
    end

    if (global.targeting.enemyWorldRefreshRate == nil) then
        global.targeting.enemyWorldRefreshRate = 1.0;
    end

    if (global.targeting.npcWorldRefreshRate == nil) then
        global.targeting.npcWorldRefreshRate = 1.0;
    end

    if (global.targeting.objectWorldRefreshRate == nil) then
        global.targeting.objectWorldRefreshRate = 1.0;
    end

    if (global.targeting.worldCriticalRefreshRate == nil) then
        global.targeting.worldCriticalRefreshRate = 3.0;
    end

    if (global.targeting.worldMediumRefreshRate == nil) then
        global.targeting.worldMediumRefreshRate = 2.0;
    end

    if (global.targeting.worldStaticRefreshRate == nil) then
        global.targeting.worldStaticRefreshRate = 1.0;
    end

    if (global.targeting.tacticalCriticalRefreshRate == nil) then
        global.targeting.tacticalCriticalRefreshRate = 5.0;
    end

    if (global.targeting.tacticalMediumRefreshRate == nil) then
        global.targeting.tacticalMediumRefreshRate = 5.0;
    end

    if (global.targeting.tacticalStaticRefreshRate == nil) then
        global.targeting.tacticalStaticRefreshRate = 1.0;
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

    if (global.targeting.otherPlayerDetail == nil) then
        local preset = tostring(global.targeting.performancePreset or 'Custom');
        if (preset == 'Performance') then
            global.targeting.otherPlayerDetail = 'Name only';
            global.targeting.otherPlayerApplyAlways = true;
        elseif (preset == 'Mid') then
            global.targeting.otherPlayerDetail = 'Name + HP';
            global.targeting.otherPlayerApplyCombat = true;
            global.targeting.otherPlayerApplyLevelSync = true;
            global.targeting.otherPlayerApplyCrowdedTown = true;
            global.targeting.otherPlayerApplyCrowdedNonTown = true;
        elseif (preset == 'High') then
            global.targeting.otherPlayerDetail = 'Name + HP + Game mode';
            global.targeting.otherPlayerApplyLevelSync = true;
            global.targeting.otherPlayerApplyCrowdedTown = true;
            global.targeting.otherPlayerApplyCrowdedNonTown = true;
        else
            global.targeting.otherPlayerDetail = 'Full configured plate';
        end
    end

    if (global.targeting.otherPlayerApplyAlways == nil) then
        global.targeting.otherPlayerApplyAlways = false;
    end

    if (global.targeting.otherPlayerApplyCombat == nil) then
        global.targeting.otherPlayerApplyCombat = false;
    end

    if (global.targeting.otherPlayerApplyLevelSync == nil) then
        global.targeting.otherPlayerApplyLevelSync = false;
    end

    local legacyCrowdedEnabled = global.targeting.otherPlayerApplyCrowded == true;
    local legacyCrowdedThreshold = tonumber(global.targeting.otherPlayerCrowdedThreshold) or 20;

    if (global.targeting.otherPlayerApplyCrowdedTown == nil) then
        global.targeting.otherPlayerApplyCrowdedTown = legacyCrowdedEnabled;
    end

    if (global.targeting.otherPlayerCrowdedTownThreshold == nil) then
        global.targeting.otherPlayerCrowdedTownThreshold = legacyCrowdedThreshold;
    end

    if (global.targeting.otherPlayerApplyCrowdedNonTown == nil) then
        global.targeting.otherPlayerApplyCrowdedNonTown = legacyCrowdedEnabled;
    end

    if (global.targeting.otherPlayerCrowdedNonTownThreshold == nil) then
        global.targeting.otherPlayerCrowdedNonTownThreshold = legacyCrowdedThreshold;
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
        global.targeting.plateStackGap = 10;
    end

    if (global.targeting.plateStackSubtargetLiftOffset == nil) then
        global.targeting.plateStackSubtargetLiftOffset = 0;
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

    if (global.targeting.tacticalScreenClampBottomPadding == nil) then
        global.targeting.tacticalScreenClampBottomPadding = 24;
    end

    if (global.targeting.tacticalScreenClampLeftPadding == nil) then
        global.targeting.tacticalScreenClampLeftPadding = 0;
    end

    if (global.targeting.tacticalScreenClampRightPadding == nil) then
        global.targeting.tacticalScreenClampRightPadding = 0;
    end

    if (global.targeting.textureCacheLimit == nil) then
        global.targeting.textureCacheLimit = 128;
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
    global.targeting.globalPlateOffsetY = math.max(-100, math.min(100, math.floor((tonumber(global.targeting.globalPlateOffsetY) or 0) + 0.5)));
    global.targeting.customEntityPlatePosition = global.targeting.customEntityPlatePosition == true;
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
        if ((tonumber(pcRaceAdjustments.baselineVersion) or 0) < 2) then
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
    if (type(pcRaceAdjustments.buckets) ~= 'table') then
        pcRaceAdjustments.buckets = {};
    end
    local pcHeightBaselineVersion = tonumber(pcRaceAdjustments.baselineVersion) or 0;
    for _, key in ipairs(pcHeightBucketKeys) do
        if (type(pcRaceAdjustments.buckets[key]) ~= 'table') then
            pcRaceAdjustments.buckets[key] = { y = 0 };
        elseif (pcHeightBaselineVersion < 3) then
            pcRaceAdjustments.buckets[key].y = 0;
        else
            pcRaceAdjustments.buckets[key].y = math.max(-100, math.min(100, math.floor((tonumber(pcRaceAdjustments.buckets[key].y) or 0) + 0.5)));
        end
    end
    pcRaceAdjustments.baselineVersion = 3;
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
    if (
        global.targeting.pcMouseSnapMode ~= 'Off' and
        global.targeting.pcMouseSnapMode ~= 'Name' and
        global.targeting.pcMouseSnapMode ~= 'HP bar' and
        global.targeting.pcMouseSnapMode ~= 'Name + HP bar'
    ) then
        global.targeting.pcMouseSnapMode = 'Off';
    end
    if (
        global.targeting.enemyMouseSnapMode ~= 'Off' and
        global.targeting.enemyMouseSnapMode ~= 'Name' and
        global.targeting.enemyMouseSnapMode ~= 'HP bar' and
        global.targeting.enemyMouseSnapMode ~= 'Name + HP bar'
    ) then
        global.targeting.enemyMouseSnapMode = 'Off';
    end
    global.targeting.pcMouseSnapStrength = math.max(1, math.min(5, math.floor((tonumber(global.targeting.pcMouseSnapStrength) or 5) + 0.5)));
    global.targeting.enemyMouseSnapStrength = math.max(1, math.min(5, math.floor((tonumber(global.targeting.enemyMouseSnapStrength) or 5) + 0.5)));
    global.targeting.hideOtherPlayerPetPlates = global.targeting.hideOtherPlayerPetPlates ~= false;
    global.targeting.plateClickNoGoZonesEnabled = global.targeting.plateClickNoGoZonesEnabled == true;
    global.targeting.plateClickNoGoZonesVisible = global.targeting.plateClickNoGoZonesVisible == true;
    global.targeting.plateClickNoGoZonesMask = global.targeting.plateClickNoGoZonesMask == true;
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
    if (performancePreset == 'Mid' and tonumber(global.targeting.textureCacheLimit) == 96) then
        global.targeting.textureCacheLimit = 128;
    end
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
    -- Count-based plate limiting was removed.  Old profiles may still carry
    -- maxWorldPlateCount; clear it so the next normal profile save removes it.
    global.targeting.maxWorldPlateCount = nil;
    local updateRate = tostring(global.targeting.worldPlateUpdateRate or 'Full');
    if (updateRate ~= 'Full' and updateRate ~= 'Balanced' and updateRate ~= 'Low') then
        updateRate = 'Full';
    end
    global.targeting.worldPlateUpdateRate = updateRate;
    global.targeting.pcWorldRefreshRate = math.max(0.2, math.min(10.0, tonumber(global.targeting.pcWorldRefreshRate) or 1.0));
    global.targeting.enemyWorldRefreshRate = math.max(0.2, math.min(10.0, tonumber(global.targeting.enemyWorldRefreshRate) or 1.0));
    global.targeting.npcWorldRefreshRate = math.max(0.2, math.min(10.0, tonumber(global.targeting.npcWorldRefreshRate) or 1.0));
    global.targeting.objectWorldRefreshRate = math.max(0.2, math.min(10.0, tonumber(global.targeting.objectWorldRefreshRate) or 1.0));
    global.targeting.worldCriticalRefreshRate = math.max(0.2, math.min(15.0, tonumber(global.targeting.worldCriticalRefreshRate) or 3.0));
    global.targeting.worldMediumRefreshRate = math.max(0.2, math.min(15.0, tonumber(global.targeting.worldMediumRefreshRate) or 2.0));
    global.targeting.worldStaticRefreshRate = math.max(0.2, math.min(15.0, tonumber(global.targeting.worldStaticRefreshRate) or 1.0));
    global.targeting.tacticalCriticalRefreshRate = math.max(0.2, math.min(15.0, tonumber(global.targeting.tacticalCriticalRefreshRate) or 5.0));
    global.targeting.tacticalMediumRefreshRate = math.max(0.2, math.min(15.0, tonumber(global.targeting.tacticalMediumRefreshRate) or 5.0));
    global.targeting.tacticalStaticRefreshRate = math.max(0.2, math.min(15.0, tonumber(global.targeting.tacticalStaticRefreshRate) or 1.0));
    global.targeting.hideDistantWorldPlates = global.targeting.hideDistantWorldPlates == true;
    global.targeting.worldPlateDistanceLimit = math.max(5.0, math.min(64.4, tonumber(global.targeting.worldPlateDistanceLimit) or 49.9));
    global.targeting.disableExpensiveWorldWidgets = global.targeting.disableExpensiveWorldWidgets == true;
    local otherPlayerDetail = tostring(global.targeting.otherPlayerDetail or 'Full configured plate');
    if (
        otherPlayerDetail ~= 'Full configured plate' and
        otherPlayerDetail ~= 'Name + HP + Game mode' and
        otherPlayerDetail ~= 'Name + HP' and
        otherPlayerDetail ~= 'Name only'
    ) then
        otherPlayerDetail = 'Full configured plate';
    end
    global.targeting.otherPlayerDetail = otherPlayerDetail;
    global.targeting.otherPlayerApplyAlways = global.targeting.otherPlayerApplyAlways == true;
    global.targeting.otherPlayerApplyCombat = global.targeting.otherPlayerApplyCombat == true;
    global.targeting.otherPlayerApplyLevelSync = global.targeting.otherPlayerApplyLevelSync == true;
    global.targeting.otherPlayerApplyCrowdedTown = global.targeting.otherPlayerApplyCrowdedTown == true;
    global.targeting.otherPlayerCrowdedTownThreshold = math.max(5, math.min(100, math.floor((tonumber(global.targeting.otherPlayerCrowdedTownThreshold) or 20) + 0.5)));
    global.targeting.otherPlayerApplyCrowdedNonTown = global.targeting.otherPlayerApplyCrowdedNonTown == true;
    global.targeting.otherPlayerCrowdedNonTownThreshold = math.max(5, math.min(100, math.floor((tonumber(global.targeting.otherPlayerCrowdedNonTownThreshold) or 20) + 0.5)));
    global.targeting.otherPlayerApplyCrowded =
        global.targeting.otherPlayerApplyCrowdedTown == true or
        global.targeting.otherPlayerApplyCrowdedNonTown == true;
    global.targeting.otherPlayerCrowdedThreshold = math.min(
        global.targeting.otherPlayerCrowdedTownThreshold,
        global.targeting.otherPlayerCrowdedNonTownThreshold
    );
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
    global.targeting.plateStackGap = math.max(0, math.min(20, math.floor((tonumber(global.targeting.plateStackGap) or 10) + 0.5)));
    global.targeting.plateStackTravelSpeed = math.max(1, math.min(40, math.floor((tonumber(global.targeting.plateStackTravelSpeed) or 14) + 0.5)));
    global.targeting.plateStackSubtargetLiftOffset = math.max(-160, math.min(160, math.floor((tonumber(global.targeting.plateStackSubtargetLiftOffset) or 0) + 0.5)));
    local horizontalOverlap = tonumber(global.targeting.plateStackHorizontalOverlap);
    local verticalOverlap = tonumber(global.targeting.plateStackVerticalOverlap);
    if (horizontalOverlap == nil) then
        horizontalOverlap = 2;
    end
    if (verticalOverlap == nil) then
        verticalOverlap = horizontalOverlap;
    end
    global.targeting.plateStackHorizontalOverlap = math.max(0, math.min(80, math.floor(horizontalOverlap + 0.5)));
    global.targeting.plateStackVerticalOverlap = math.max(0, math.min(80, math.floor(verticalOverlap + 0.5)));
    global.targeting.plateStackHorizontalSpreadPct = math.max(0, math.min(250, math.floor((tonumber(global.targeting.plateStackHorizontalSpreadPct) or 125) + 0.5)));
    global.targeting.plateStackFixedBlockerWidthPct = math.max(25, math.min(100, math.floor((tonumber(global.targeting.plateStackFixedBlockerWidthPct) or 72) + 0.5)));
    global.targeting.tacticalScreenClampEnabled = global.targeting.tacticalScreenClampEnabled == true;
    global.targeting.tacticalScreenClampTopPadding = math.max(0, math.min(200, math.floor((tonumber(global.targeting.tacticalScreenClampTopPadding) or 24) + 0.5)));
    global.targeting.tacticalScreenClampBottomPadding = math.max(0, math.min(400, math.floor((tonumber(global.targeting.tacticalScreenClampBottomPadding) or 24) + 0.5)));
    global.targeting.tacticalScreenClampLeftPadding = math.max(0, math.min(400, math.floor((tonumber(global.targeting.tacticalScreenClampLeftPadding) or 0) + 0.5)));
    global.targeting.tacticalScreenClampRightPadding = math.max(0, math.min(400, math.floor((tonumber(global.targeting.tacticalScreenClampRightPadding) or 0) + 0.5)));
    global.targeting.textureCacheLimit = math.max(32, math.min(256, math.floor((tonumber(global.targeting.textureCacheLimit) or 128) + 0.5)));
    NormalizePlateClickNoGoZones(global.targeting);

    return global.targeting;
end

function targeting.GetWorldPlateRange(settings)
    settings = settings or targeting.GetSettings();
    local range = tonumber(settings.enemyPlateRange) or 49.9;

    if (settings.hideDistantWorldPlates == true) then
        range = math.min(range, tonumber(settings.worldPlateDistanceLimit) or range);
    end

    return math.max(5.0, math.min(64.4, range));
end

function targeting.GetPlateDistanceScaleSettings(entityName, settings)
    settings = settings or targeting.GetSettings();

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

function targeting.GetPlatePositionOffset(entityName, settings)
    settings = settings or targeting.GetSettings();
    local key = tostring(entityName or ''):lower();
    local offsets = type(settings.platePositionOffsets) == 'table' and settings.platePositionOffsets[key] or nil;

    if (settings.customEntityPlatePosition == true and type(offsets) == 'table') then
        return {
            x = 0,
            y = tonumber(offsets.y) or 0,
        };
    end

    return {
        x = 0,
        y = tonumber(settings.globalPlateOffsetY) or 0,
    };
end

function targeting.HasActivePcHeightAdjustments()
    local settings = targeting.GetSettings();
    local adjustments = settings ~= nil and settings.pcRacePlateAdjustments or nil;

    if (type(adjustments) ~= 'table' or adjustments.enabled == false) then
        return false;
    end

    -- A visible zero must really mean no correction.  Do this settings-only
    -- check before any actor/skeleton data is read.
    for _, key in ipairs(pcHeightBucketKeys) do
        local bucket = type(adjustments.buckets) == 'table' and adjustments.buckets[key] or nil;
        if (math.abs(tonumber(type(bucket) == 'table' and bucket.y) or 0) > 0) then
            return true;
        end
    end

    -- Keep older race-only profile values working too.
    for _, key in ipairs(pcHeightRaceKeys) do
        local race = adjustments[key];
        if (math.abs(tonumber(type(race) == 'table' and race.y) or 0) > 0) then
            return true;
        end
    end

    return false;
end

function targeting.ApplyPlateScalingSettings(worldMarker, entityName, baseOffsetX, baseOffsetY, settings)
    if (type(worldMarker) ~= 'table') then
        return worldMarker;
    end

    settings = settings or targeting.GetSettings();
    local scale = targeting.GetPlateDistanceScaleSettings(entityName, settings);
    local offset = targeting.GetPlatePositionOffset(entityName, settings);
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
    return mounted.IsSelfMounted();
end

local gatheringActions = {
    ['Mining Point'] = { command = '/item "Pickaxe" <t>', tool = 'Pickaxe', settingKey = 'enableRightClickMining' },
    ['Mythril Seam'] = { command = '/item "Pickaxe" <t>', tool = 'Pickaxe', settingKey = 'enableRightClickMining' },
    ['Gold Seam'] = { command = '/item "Pickaxe" <t>', tool = 'Pickaxe', settingKey = 'enableRightClickMining' },
    ['Rock Outcropping'] = { command = '/item "Pickaxe" <t>', tool = 'Pickaxe', settingKey = 'enableRightClickMining' },
    ['Ergon Locus'] = { command = '/item "Pickaxe" <t>', tool = 'Pickaxe', settingKey = 'enableRightClickMining' },
    ['Coalition Mining Point'] = { command = '/item "Pickaxe" <t>', tool = 'Pickaxe', settingKey = 'enableRightClickMining' },
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

local function GetGatheringActionForTarget(targetIndex, name)
    local normalizedName = NormalizeObjectName(name);
    local action = GetGatheringAction(normalizedName);

    if (action ~= nil) then
        return action, normalizedName;
    end

    return nil, normalizedName;
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

local function GetGatheringSettings(global)
    global = global or state.GetGlobalSettings(globalDefaults);

    local gatheringSettings = global.gathering or {};
    local oldFishingSettings = global.fishing or {};

    return setmetatable(gatheringSettings, {
        __index = function(_, key)
            return oldFishingSettings[key];
        end,
    });
end

function targeting.InteractFishingGatheringTarget(targetIndex, targetType, distance)
    if (targetIndex == nil or targetIndex == 0) then
        lastGatheringInteractStatus = 'invalid target';
        return false;
    end

    local global = state.GetGlobalSettings(globalDefaults);
    local gatheringSettings = GetGatheringSettings(global);

    if (gatheringSettings.enabled == false) then
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
    local action, actionName = GetGatheringActionForTarget(targetIndex, name);

    if (action == nil) then
        lastGatheringInteractStatus = 'no mapping name=' .. tostring(name) .. ' type=' .. normalizedType;
        return false;
    end

    local actionEnabled = gatheringSettings[action.settingKey];

    if (actionEnabled == nil) then
        actionEnabled = true;
    end

    if (actionEnabled ~= true) then
        lastGatheringInteractStatus = 'disabled action=' .. tostring(action.settingKey) .. ' name=' .. tostring(name) .. ' actionName=' .. tostring(actionName);
        return false;
    end

    local hasTool, container, index, count = HasInventoryItem(action.tool);

    if (hasTool ~= true) then
        lastGatheringInteractStatus = 'missing tool=' .. tostring(action.tool) .. ' name=' .. tostring(name) .. ' actionName=' .. tostring(actionName);
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
            nextPoll = os.clock() + 0.35,
        };
        lastGatheringInteractStatus =
            'queued ' .. action.command ..
            ' name=' .. name ..
            ' actionName=' .. tostring(actionName) ..
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

function targeting.IsGatheringTarget(targetIndex, name)
    local action = GetGatheringActionForTarget(targetIndex, name);
    return action ~= nil;
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
    local gatheringSettings = GetGatheringSettings(global);

    if (gatheringSettings.enabled == false or gatheringSettings.showGatheringPoints == false) then
        return false;
    end

    local action = GetGatheringAction(name);

    if (action == nil) then
        return false;
    end

    if (gatheringSettings.showGatheringPointsOnlyWithTool ~= true) then
        return true;
    end

    local hasTool = HasInventoryItem(action.tool);
    return hasTool == true;
end

function targeting.Update()
    if (pendingGatheringWatch ~= nil) then
        local now = os.clock();

        if (now < (tonumber(pendingGatheringWatch.nextPoll) or 0)) then
            return;
        end

        pendingGatheringWatch.nextPoll = now + 0.35;

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
        elseif ((now - (pendingGatheringWatch.started or now)) > 20.0) then
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
