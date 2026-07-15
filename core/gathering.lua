local textureLoader = require('core.texture_loader');
local targeting = require('core.targeting');
local fonts = require('core.fonts');
local state = require('core.state');
local globalDefaults = require('config.global');

local gathering = {};
local iconTextureIds = {};
local iconFiles = {
    'hatchet.png',
    'pickaxe.png',
    'sickle.png',
};

local function GetIconTextureId(fileName)
    local iconFile = tostring(fileName or '');

    if (iconFile == '') then
        return nil;
    end

    if (iconTextureIds[iconFile] ~= nil) then
        return iconTextureIds[iconFile];
    end

    local path = addon.path .. '\\assets\\images\\gathering\\' .. iconFile;
    iconTextureIds[iconFile] = textureLoader.ToTextureId(textureLoader.Load(path));
    return iconTextureIds[iconFile];
end

function gathering.GetIconFiles()
    return iconFiles;
end

function gathering.AddWidget(plateData, settings)
    if (plateData == nil or settings == nil or settings.enabled == false) then
        return;
    end

    local display = settings.previewDisplay;

    if (display == nil and settings.previewResult ~= true) then
        display = targeting.GetGatheringDisplayInfo();
    end

    if (display == nil and settings.previewResult ~= true) then
        return;
    end

    if (display == nil) then
        display = {
            iconFile = 'hatchet.png',
            count = 12,
        };
    end

    local displayMode = tostring(settings.displayMode or 'Tool + count');
    local showIcon = displayMode ~= 'Count only';
    local showCount = settings.showCount == true and displayMode ~= 'Tool only';
    local textureId = showIcon == true and GetIconTextureId(display.iconFile) or nil;
    local globalSettings = state.GetGlobalSettings(globalDefaults);

    if (textureId == nil and showCount ~= true) then
        return;
    end

    plateData.icons = plateData.icons or {};
    plateData.icons[#plateData.icons + 1] = {
        kind = 'gathering',
        textureId = textureId,
        size = math.max(6, math.min(256, tonumber(settings.iconSize) or 42)),
        anchorTo = settings.anchorTo or 'Name',
        anchorPoint = settings.anchorPoint or 'Bottom',
        offsetX = tonumber(settings.offsetX) or 0,
        offsetY = tonumber(settings.offsetY) or 38,
        timerText = showCount == true and tostring(tonumber(display.count) or 0) or '',
        timerFontFamily = fonts.GetRole(globalSettings, settings.countUseSmallFont == true),
        timerFontFlags = fonts.GetRoleFlags(globalSettings, settings.countUseSmallFont == true),
        timerFontSize = math.max(4, tonumber(settings.countFontSize) or 12),
        timerOffsetX = tonumber(settings.countOffsetX) or 0,
        timerTextColor = settings.countColor or { 1.0, 1.0, 1.0, 1.0 },
        timerTextOutline = (tonumber(settings.countOutlineSize) or 2) > 0,
        timerTextOutlineColor = settings.countOutlineColor or { 0.0, 0.0, 0.0, 1.0 },
        timerTextOutlineSize = tonumber(settings.countOutlineSize) or 2,
        timerOffsetY = tonumber(settings.countOffsetY) or 0,
    };
end

return gathering;
