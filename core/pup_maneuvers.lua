local playerStatuses = require('core.player_statuses');
local statusTimerFormat = require('core.status_timer_format');
local textureLoader = require('core.texture_loader');

local pupManeuvers = {};
local textureCache = {};
local maneuverIconSets = {
    'default',
    'boarderless',
};
local maneuverIconSetLookup = {
    default = true,
    boarderless = true,
};

local maneuverIcons = {
    [300] = 'fire.png',
    [301] = 'ice.png',
    [302] = 'wind.png',
    [303] = 'earth.png',
    [304] = 'thunder.png',
    [305] = 'water.png',
    [306] = 'light.png',
    [307] = 'dark.png',
    empty = 'empty.png',
    overload = 'overload.png',
};

local function NormalizeIconSet(value)
    local iconSet = tostring(value or 'default'):lower():gsub('[\\/]', '');
    return maneuverIconSetLookup[iconSet] == true and iconSet or 'default';
end

local function GetIconTextureId(iconKey, iconSet)
    local fileName = maneuverIcons[iconKey];

    if (fileName == nil) then
        return nil;
    end

    iconSet = NormalizeIconSet(iconSet);
    local cacheKey = iconSet .. ':' .. tostring(iconKey);

    if (textureCache[cacheKey] ~= nil) then
        return textureCache[cacheKey];
    end

    local path = addon.path .. '\\assets\\images\\maneuvers\\' .. iconSet .. '\\' .. fileName;
    textureCache[cacheKey] = textureLoader.ToTextureId(textureLoader.Load(path));
    return textureCache[cacheKey];
end

function pupManeuvers.GetIconSets()
    local result = {};
    for _, iconSet in ipairs(maneuverIconSets) do
        result[#result + 1] = iconSet;
    end
    return result;
end

function pupManeuvers.GetIconSetsFolderPath()
    return addon.path .. '\\assets\\images\\maneuvers\\';
end

function pupManeuvers.GetState()
    local result = {
        overload = false,
        overloadSeconds = nil,
        maneuvers = {},
    };

    for _, row in ipairs(playerStatuses.GetSelfRows('all') or {}) do
        local statusId = tonumber(row.id);

        if (statusId == 299) then
            result.overload = true;
            result.overloadSeconds = tonumber(row.seconds);
        elseif (statusId ~= nil and statusId >= 300 and statusId <= 307) then
            result.maneuvers[#result.maneuvers + 1] = {
                statusId = statusId,
                seconds = tonumber(row.seconds),
            };
        end
    end

    table.sort(result.maneuvers, function(a, b)
        local aTime = tonumber(a.seconds) or 999999;
        local bTime = tonumber(b.seconds) or 999999;

        if (aTime ~= bTime) then
            return aTime < bTime;
        end

        return (tonumber(a.statusId) or 0) < (tonumber(b.statusId) or 0);
    end);

    return result;
end

function pupManeuvers.AddIcons(plateData, settings, globalSettings, previewRows)
    if (plateData == nil or settings == nil or settings.enabled ~= true) then
        return;
    end

    local iconSize = math.max(6, math.min(256, tonumber(settings.iconSize) or 26));
    local spacing = math.max(0, math.min(80, tonumber(settings.iconSpacing) or 10));
    local totalWidth = (iconSize * 3) + (spacing * 2);
    local baseX = (tonumber(settings.offsetX) or 0) - (totalWidth * 0.5) + (iconSize * 0.5);
    local baseY = tonumber(settings.offsetY) or 34;
    local state = previewRows or pupManeuvers.GetState();

    plateData.icons = plateData.icons or {};

    for slot = 1, 3 do
        local iconKey = 'empty';
        local seconds = nil;

        if (state.overload == true) then
            iconKey = 'overload';
            seconds = tonumber(state.overloadSeconds);
        elseif (state.maneuvers ~= nil and state.maneuvers[slot] ~= nil) then
            iconKey = tonumber(state.maneuvers[slot].statusId);
            seconds = tonumber(state.maneuvers[slot].seconds);
        end

        local textureId = GetIconTextureId(iconKey, settings.iconSet);

        if (textureId ~= nil) then
            plateData.icons[#plateData.icons + 1] = {
                kind = 'maneuvers',
                textureId = textureId,
                size = iconSize,
                offsetX = baseX + ((slot - 1) * (iconSize + spacing)),
                offsetY = baseY,
                timerText = (settings.showTimers == true) and statusTimerFormat.Format(seconds) or '',
                timerSeconds = seconds,
                timerOffsetY = tonumber(settings.timerOffsetY) or 0,
                timerFontFamily = globalSettings ~= nil and require('core.fonts').GetRole(globalSettings, settings.timerUseSmallFont == true) or nil,
                timerFontFlags = globalSettings ~= nil and require('core.fonts').GetRoleFlags(globalSettings, settings.timerUseSmallFont == true) or nil,
                timerFontSize = require('core.text_scale').ToTextureFontSize(settings.timerFontSize, 7),
                timerTextColor = settings.timerTextColor,
                timerTextOutlineColor = settings.timerTextOutlineColor,
                timerTextOutlineSize = tonumber(settings.timerTextOutlineSize) or 1,
            };
        end
    end
end

function pupManeuvers.GetPreviewState()
    return {
        overload = false,
        overloadSeconds = nil,
        maneuvers = {
            { statusId = 300, seconds = 142 },
            { statusId = 304, seconds = 92 },
            { statusId = 306, seconds = 39 },
        },
    };
end

return pupManeuvers;
