local state = require('core.state');
local textureLoader = require('core.texture_loader');
local arrowAnimation = require('core.target_arrow_animation');
local targetTextures = require('core.target_textures');
local targetModuleDefaults = require('config.widgets.target_module');
local subtargetModuleDefaults = require('config.widgets.subtarget_module');
local perfMeter = require('core.perf_meter');
local nativeUiPolicy = require('core.native_ui_policy');
local targeting = require('core.targeting');
local targetActionRange = require('core.target_action_range');
local aoeNameHighlight = require('core.aoe_name_highlight');

local targetModuleMarker = {};
local actionRangeAllowance = 0.7;
local textureIds = {};
local lastDebug = 'target module marker has not built yet';
local lastActiveDebug = 'target module marker has not built an active target/subtarget yet';
local recentActiveDebug = {};
local legacyTextureNames = {
    backgrounds = {
        ['glow-100.png'] = 'Soft_Glow_Rectangle.png',
        ['glow_100.png'] = 'Soft_Glow_Rectangle.png',
        ['background_01.png'] = 'Soft_Glow_Rectangle.png',
        ['brackets.png'] = 'Brackets_Short.png',
    },
};

local function PushActiveDebug(text)
    text = tostring(text or '');

    if (text == '') then
        return;
    end

    recentActiveDebug[#recentActiveDebug + 1] = text;

    while (#recentActiveDebug > 8) do
        table.remove(recentActiveDebug, 1);
    end
end

local function GetAddonPath()
    local ok, path = pcall(function()
        return AshitaCore:GetInstallPath() .. '\\addons\\LibraPlates\\';
    end);

    if (ok == true and path ~= nil) then
        return tostring(path);
    end

    return '.\\';
end

local function GetTextureId(category, fileName)
    fileName = tostring(fileName or 'None'):gsub('^.*[\\/]', '');

    if (fileName == '' or fileName == 'None') then
        return nil;
    end

    local categoryName = tostring(category or '');
    local legacyCategory = legacyTextureNames[categoryName];
    if (legacyCategory ~= nil) then
        fileName = legacyCategory[string.lower(fileName)] or fileName;
    end

    local key = categoryName .. '/' .. fileName;

    if (textureIds[key] ~= nil) then
        return textureIds[key];
    end

    textureIds[key] = textureLoader.ToTextureId(textureLoader.Load(
        GetAddonPath() .. 'assets\\images\\target\\' .. categoryName .. '\\' .. fileName
    ));

    return textureIds[key];
end

local function Number(settings, key, fallback)
    if (settings == nil) then
        return fallback;
    end

    local value = tonumber(settings[key]);

    if (value == nil) then
        return fallback;
    end

    return value;
end

local function SafeNumber(fn)
    local ok, value = pcall(fn);

    if (ok ~= true) then
        return nil;
    end

    return tonumber(value);
end

local function GetSubtargetActionRange()
    if (targeting.IsSubTargetModeActive() ~= true) then
        return nil;
    end

    local memory = AshitaCore:GetMemoryManager();
    local targetManager = memory ~= nil and memory:GetTarget() or nil;

    if (targetManager == nil or targetManager.GetActionId == nil) then
        return nil;
    end

    local actionId = SafeNumber(function() return targetManager:GetActionId(); end);

    if (actionId == nil or actionId <= 0) then
        return nil;
    end

    local resourceManager = AshitaCore:GetResourceManager();

    if (resourceManager ~= nil and resourceManager.GetSpellRange ~= nil) then
        local spellRange = SafeNumber(function() return resourceManager:GetSpellRange(actionId, false); end);

        if (spellRange ~= nil and spellRange > 0) then
            return spellRange;
        end
    end

    if (resourceManager ~= nil and resourceManager.GetAbilityRange ~= nil) then
        local abilityRange = SafeNumber(function() return resourceManager:GetAbilityRange(actionId, false); end);

        if (abilityRange ~= nil and abilityRange > 0) then
            return abilityRange;
        end
    end

    return nil;
end

local function ClampNumber(value, fallback, minValue, maxValue)
    local number = tonumber(value);

    if (number == nil) then
        number = fallback;
    end

    if (number < minValue) then
        return minValue;
    end

    if (number > maxValue) then
        return maxValue;
    end

    return number;
end

local function GetChevronFile(settings)
    if (settings == nil or settings.chevronEnabled == false) then
        return 'None';
    end

    return tostring(settings.chevronFile or 'None');
end

local function IsBackgroundEnabled(settings)
    if (settings == nil) then
        return false;
    end

    if (tostring(settings.backgroundFile or 'None') == 'None') then
        return false;
    end

    return true;
end

local function CloneColor(source, fallback)
    if (type(source) ~= 'table') then
        source = fallback;
    end

    fallback = type(fallback) == 'table' and fallback or { 1.0, 1.0, 1.0, 1.0 };

    if (type(source) ~= 'table') then
        return {
            fallback[1],
            fallback[2],
            fallback[3],
            fallback[4],
        };
    end

    return {
        tonumber(source[1]) or fallback[1],
        tonumber(source[2]) or fallback[2],
        tonumber(source[3]) or fallback[3],
        tonumber(source[4]) or fallback[4],
    };
end

local function ResolveArrowDistanceColor(distance, settings, markerColor, targetStateName, entityName, options)
    if (settings == nil) then
        return CloneColor(nil, markerColor);
    end

    if (tostring(entityName or '') == 'Self') then
        return CloneColor(settings.arrowColor, markerColor);
    end

    if (targetStateName ~= 'Subtarget') then
        if (settings.arrowDistanceColoring ~= true) then
            return CloneColor(settings.arrowColor, markerColor);
        end

        return CloneColor(settings.arrowInRangeColor, markerColor);
    end

    local actionRange = nil;

    if (options == nil or options.previewMode ~= true) then
        actionRange = targetModuleMarker.GetCurrentActionRange();
    end

    local currentDistance = tonumber(distance);

    if (actionRange == nil or currentDistance == nil) then
        return CloneColor(settings.arrowInRangeColor, markerColor);
    end

    local effectiveActionRange = tonumber(actionRange) + actionRangeAllowance;
    local warningRange = effectiveActionRange + 3.0;

    if (currentDistance <= effectiveActionRange) then
        return CloneColor(settings.arrowInRangeColor, markerColor);
    end

    if (currentDistance <= warningRange) then
        return CloneColor(settings.arrowWarningColor, markerColor);
    end

    return CloneColor(settings.arrowOutOfRangeColor, markerColor);
end

function targetModuleMarker.GetCurrentActionRange()
    if (
        aoeNameHighlight.IsSuppressed ~= nil and
        aoeNameHighlight.IsSuppressed() == true
    ) then
        return targetActionRange.GetCurrentRange();
    end

    return GetSubtargetActionRange() or aoeNameHighlight.GetCurrentActionTargetRange() or targetActionRange.GetCurrentRange();
end

function targetModuleMarker.GetEffectiveActionRange()
    local range = targetModuleMarker.GetCurrentActionRange();

    if (range == nil) then
        return nil;
    end

    return tonumber(range) + actionRangeAllowance;
end

function targetModuleMarker.GetEffectiveLiveSubtargetActionRange()
    local range = GetSubtargetActionRange();

    if (range == nil) then
        return nil;
    end

    return tonumber(range) + actionRangeAllowance;
end

local function GetAutoPlaceAnchorKinds(value)
    if (tostring(value or '') == 'Name') then
        return { 'name' };
    end

    if (tostring(value or '') == 'HP Bar') then
        return { 'hp' };
    end

    return { 'name', 'hp' };
end

local tacticalTargetEntities = {
    Self = true,
    Enemy = true,
    NPC = true,
    Object = true,
    PC = true,
    Trust = true,
};

local function ResolveTargetModuleState(entityName, layoutStateName, targetStateName)
    if (
        (targetStateName == 'Target' or targetStateName == 'Subtarget') and
        tacticalTargetEntities[tostring(entityName or '')] == true
    ) then
        return 'Combat';
    end

    return layoutStateName or 'Idle';
end

function targetModuleMarker.HasDrawableSettings(entityName, settings)
    if (settings == nil or settings.enabled ~= true) then
        return false;
    end

    local hasBackground = IsBackgroundEnabled(settings) == true;
    local hasArrow = settings.arrowEnabled ~= false and tostring(settings.arrowFile or 'None') ~= 'None';
    local hasChevrons = GetChevronFile(settings) ~= 'None';

    return hasBackground == true or hasArrow == true or hasChevrons == true;
end

function targetModuleMarker.GetSettings(entityName, layoutStateName, targetStateName)
    local defaults = (targetStateName == 'Subtarget') and subtargetModuleDefaults or targetModuleDefaults;
    local widgetName = tostring(targetStateName or 'Target') .. ' Module';
    local resolvedStateName = ResolveTargetModuleState(entityName or 'Enemy', layoutStateName or 'Idle', targetStateName);
    local settings = state.GetWidgetSettings(entityName or 'Enemy', resolvedStateName, widgetName, defaults);

    arrowAnimation.UpgradeLegacySettings(settings);

    return settings, defaults;
end

function targetModuleMarker.Build(entityName, layoutStateName, targetStateName, hpBarSettings, distance, options)
    local perfToken = perfMeter.BeginDetail('target.marker.build');

    local function Finish(result)
        perfMeter.EndDetail(perfToken);
        return result;
    end

    if (targetStateName ~= 'Target' and targetStateName ~= 'Subtarget') then
        lastDebug = string.format(
            'target marker skipped entity=%s layout=%s target=%s reason=not-target-state',
            tostring(entityName),
            tostring(layoutStateName),
            tostring(targetStateName)
        );
        return Finish({ enabled = false });
    end

    if ((options == nil or options.previewMode ~= true) and nativeUiPolicy.ShouldDrawLibraTargetingSystem() ~= true) then
        lastDebug = string.format(
            'target marker skipped entity=%s layout=%s target=%s reason=native-targeting-system',
            tostring(entityName),
            tostring(layoutStateName),
            tostring(targetStateName)
        );
        return Finish({ enabled = false });
    end

    local settings, defaults = targetModuleMarker.GetSettings(entityName, layoutStateName, targetStateName);
    local markerColor = settings.color or defaults.color;
    local arrowColor = ResolveArrowDistanceColor(distance, settings, markerColor, targetStateName, entityName, options);

    if (settings.enabled == false or markerColor == nil) then
        lastDebug = string.format(
            'target marker skipped entity=%s layout=%s target=%s enabled=%s color=%s',
            tostring(entityName),
            tostring(layoutStateName),
            tostring(targetStateName),
            tostring(settings.enabled),
            tostring(markerColor ~= nil)
        );
        return Finish({ enabled = false });
    end

    hpBarSettings = hpBarSettings or {};

    local autoPlaceBackground = settings.autoPlaceBackground ~= false;
    local autoPlaceArrow = settings.autoPlaceArrow ~= false;
    local backgroundEnabled = IsBackgroundEnabled(settings) and not (options ~= nil and options.suppressBackground == true);
    local hpWidth = tonumber(hpBarSettings.width) or 180;
    local hpHeight = tonumber(hpBarSettings.height) or 12;
    local hpOffsetX = tonumber(hpBarSettings.offsetX) or 0;
    local hpOffsetY = tonumber(hpBarSettings.offsetY) or 0;
    local backgroundSpacing = math.max(0, Number(settings, 'backgroundSpacing', 7));
    local arrowAnimated = settings.arrowEnabled ~= false and settings.arrowSprite == true and arrowAnimation.HasSpriteFrames(settings.arrowFile) == true;
    local arrowTextureId = settings.arrowEnabled ~= false and arrowAnimation.GetTextureId(settings.arrowFile, arrowAnimated, Number(settings, 'arrowAnimationSpeed', 12)) or nil;
    local lockOn = false;

    if (options ~= nil and options.previewLockOn ~= nil) then
        lockOn = options.previewLockOn == true;
    else
        lockOn = targeting.GetIsTargetLockedOn() == true;
    end

    local lockAnimated = settings.lockEnabled ~= false and settings.lockSprite == true and targetTextures.HasSpriteFrames('lock', settings.lockFile) == true;
    local lockTextureId = (tostring(entityName or '') == 'Enemy' and targetStateName == 'Target' and settings.lockEnabled ~= false and lockOn == true)
        and targetTextures.GetAnimatedTextureId('lock', settings.lockFile or 'lock.png', lockAnimated, Number(settings, 'lockAnimationSpeed', 12))
        or nil;
    local backgroundTextureId = backgroundEnabled == true and GetTextureId('backgrounds', settings.backgroundFile) or nil;
    local chevronFile = GetChevronFile(settings);
    local chevronTextureId = GetTextureId('chevrons', chevronFile);
    local showArrow = arrowTextureId ~= nil;
    local showLock = lockTextureId ~= nil;
    local showChevrons = chevronTextureId ~= nil;
    local targetWidth = ClampNumber(settings.width, 220, 1, 1000);
    local targetHeight = ClampNumber(settings.height, 74, 1, 450);

    lastDebug = string.format(
        'target marker entity=%s layout=%s target=%s enabled=%s bgEnabled=%s bgFile=%s bgTex=%s showBg=%s arrowFile=%s arrowTex=%s chevFile=%s chevTex=%s',
        tostring(entityName),
        tostring(layoutStateName),
        tostring(targetStateName),
        tostring(settings.enabled ~= false),
        tostring(backgroundEnabled),
        tostring(settings.backgroundFile),
        tostring(backgroundTextureId),
        tostring(backgroundEnabled == true),
        tostring(settings.arrowFile),
        tostring(arrowTextureId),
        tostring(settings.chevronFile),
        tostring(chevronTextureId)
    );
    lastActiveDebug = lastDebug;
    PushActiveDebug(lastDebug);

    local result = {
        enabled = true,
        showBackground = backgroundEnabled == true,
        showArrow = showArrow,
        showLock = showLock,
        showChevrons = showChevrons,
        backgroundOffsetX = Number(settings, 'backgroundOffsetX', 0),
        backgroundOffsetY = Number(settings, 'backgroundOffsetY', 0),
        arrowOffsetX = Number(settings, 'arrowOffsetX', 0),
        arrowOffsetY = Number(settings, 'arrowOffsetY', 0),
        chevronOffsetX = settings.autoPlaceChevrons ~= false and 0 or Number(settings, 'chevronOffsetX', 0),
        chevronOffsetY = settings.autoPlaceChevrons ~= false and 0 or Number(settings, 'chevronOffsetY', 0),
        backgroundTextureId = backgroundTextureId,
        backgroundClickable = settings.backgroundClickable ~= false,
        arrowTextureId = arrowTextureId,
        lockTextureId = lockTextureId,
        chevronTextureId = chevronTextureId,
        backgroundFile = tostring(settings.backgroundFile or 'None'),
        arrowFile = tostring(settings.arrowFile or 'None'),
        arrowAnimated = arrowAnimated == true,
        arrowAnimationSpeed = Number(settings, 'arrowAnimationSpeed', 12),
        lockFile = tostring(settings.lockFile or 'lock.png'),
        lockAnimated = lockAnimated == true,
        lockAnimationSpeed = Number(settings, 'lockAnimationSpeed', 12),
        chevronFile = tostring(chevronFile or 'None'),
        backgroundAnchorToPlate = autoPlaceBackground == true,
        backgroundAnchorKinds = GetAutoPlaceAnchorKinds(settings.backgroundAutoPlaceAnchor),
        arrowAnchorToName = autoPlaceArrow == true,
        arrowAnchorKinds = { 'name' },
        backgroundSpacing = backgroundSpacing,
        backgroundWidth = autoPlaceBackground == true and math.max(1, hpWidth + (backgroundSpacing * 2)) or ClampNumber(settings.backgroundWidth, 300, 1, 1000),
        backgroundHeight = autoPlaceBackground == true and math.max(1, hpHeight + (backgroundSpacing * 2)) or ClampNumber(settings.backgroundHeight, 90, 1, 450),
        arrowWidth = ClampNumber(settings.arrowWidth, 20, 1, 200),
        arrowHeight = ClampNumber(settings.arrowHeight, 20, 1, 200),
        lockWidth = ClampNumber(settings.lockWidth, 18, 1, 200),
        lockHeight = ClampNumber(settings.lockHeight, 18, 1, 200),
        lockOffsetX = Number(settings, 'lockOffsetX', 0),
        lockOffsetY = Number(settings, 'lockOffsetY', -24),
        arrowSpacing = ClampNumber(settings.arrowSpacing, 10, 0, 300),
        arrowScaleWithDistance = settings.arrowScaleWithDistance ~= false,
        arrowMinScale = Number(settings, 'arrowMinScale', 0.45),
        arrowMaxScale = Number(settings, 'arrowMaxScale', 10.00),
        arrowLockFarMinSize = settings.arrowLockFarMinSize ~= false,
        arrowFarMinDistance = Number(settings, 'arrowFarMinDistance', 10.0),
        arrowFarMinScale = Number(settings, 'arrowFarMinScale', 8.0),
        arrowFarFullDistance = Number(settings, 'arrowFarFullDistance', 50.0),
        distance = tonumber(distance) or 0,
        chevronWidth = ClampNumber(settings.chevronWidth, 24, 1, 200),
        chevronHeight = ClampNumber(settings.chevronHeight, 32, 1, 200),
        chevronAnchorToPlate = settings.autoPlaceChevrons ~= false,
        chevronAnchorKinds = GetAutoPlaceAnchorKinds(settings.chevronAutoPlaceAnchor),
        anchorKinds = { 'name', 'hp' },
        chevronSpacing = ClampNumber(settings.chevronSpacing, 220, 0, 900),
        chevronLeftX = Number(settings, 'chevronLeftX', -110),
        chevronRightX = Number(settings, 'chevronRightX', 110),
        color = markerColor,
        backgroundColor = settings.backgroundColor or markerColor,
        arrowColor = arrowColor,
        lockColor = settings.lockColor or markerColor,
        chevronColor = settings.chevronColor or markerColor,
        debugAutoPlaceRect = false,
        width = targetWidth,
        height = targetHeight,
        offsetX = hpOffsetX,
        offsetY = -18,
        thickness = 2,
        cornerLength = 12,
    };

    return Finish(result);
end

function targetModuleMarker.GetDebugStatus()
    if (#recentActiveDebug > 0) then
        return 'recent target markers: ' .. table.concat(recentActiveDebug, ' || ') .. ' last=' .. lastDebug;
    end

    return lastActiveDebug .. ' last=' .. lastDebug;
end

return targetModuleMarker;
