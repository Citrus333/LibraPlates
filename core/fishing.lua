local textureLoader = require('core.texture_loader');

local fishing = {};
local iconTextureIds = {};
local lastResult = nil;
local lastResultClock = 0;
local resultTimeoutSeconds = 45;
local iconFiles = {
    'fishing_00.png',
    'fishing_01.png',
    'fishing_02.png',
    'fishing_03.png',
    'fishing_04.png',
    'fishing_05.png',
    'fishing_06.png',
};
local gutFeelingResults = {
    {
        pattern = "You didn't catch anything",
        label = "You didn't catch anything",
        iconFile = 'fishing_00.png',
    },
    {
        pattern = 'You have a good feeling about this one!',
        label = 'Easy catch',
        iconFile = 'fishing_01.png',
    },
    {
        pattern = "You don't know if you have enough skill to reel this one in.",
        label = 'Moderate catch',
        iconFile = 'fishing_02.png',
    },
    {
        pattern = "You're fairly sure you don't have enough skill to reel this one in.",
        label = 'Hard catch',
        iconFile = 'fishing_03.png',
    },
    {
        pattern = "You're positive you don't have enough skill to reel this one in!",
        label = 'Very difficult catch',
        iconFile = 'fishing_04.png',
    },
    {
        pattern = 'You have a bad feeling about this one.',
        label = 'Extreme catch',
        iconFile = 'fishing_05.png',
    },
    {
        pattern = 'You have a terrible feeling about this one...',
        label = 'Dangerous catch',
        iconFile = 'fishing_06.png',
    },
};

local fishingStatuses = {
    [38] = true,
    [39] = true,
    [40] = true,
    [41] = true,
    [42] = true,
    [43] = true,
    [50] = true,
    [51] = true,
    [52] = true,
    [53] = true,
    [56] = true,
    [57] = true,
    [58] = true,
    [59] = true,
    [60] = true,
    [61] = true,
    [62] = true,
};

function fishing.IsFishingStatus(status)
    return fishingStatuses[tonumber(status) or 0] == true;
end

local function StripControlCodes(text)
    return tostring(text or ''):gsub(string.char(0x1E) .. '.', ''):gsub('[%z\1-\31]', '');
end

function fishing.HandleTextIn(e)
    local message = StripControlCodes(
        (e ~= nil and (e.message or e.text or e.original or e.modified or e.injected)) or ''
    );

    if (message == '') then
        return;
    end

    for _, result in ipairs(gutFeelingResults) do
        if (message:find(result.pattern, 1, true) ~= nil) then
            lastResult = result;
            lastResultClock = os.clock();
            return;
        end
    end
end

function fishing.ClearResult()
    lastResult = nil;
    lastResultClock = 0;
end

function fishing.GetResult()
    if (lastResult == nil) then
        return nil;
    end

    if ((os.clock() - lastResultClock) > resultTimeoutSeconds) then
        fishing.ClearResult();
        return nil;
    end

    return lastResult;
end

local function IsKnownIcon(fileName)
    fileName = tostring(fileName or '');

    for _, iconFile in ipairs(iconFiles) do
        if (fileName == iconFile) then
            return true;
        end
    end

    return false;
end

local function GetIconTextureId(fileName)
    fileName = tostring(fileName or 'fishing_01.png');

    if (IsKnownIcon(fileName) ~= true) then
        fileName = 'fishing_01.png';
    end

    if (iconTextureIds[fileName] ~= nil) then
        return iconTextureIds[fileName];
    end

    local path = addon.path .. '\\assets\\images\\fishing\\' .. fileName;
    iconTextureIds[fileName] = textureLoader.ToTextureId(textureLoader.Load(path));
    return iconTextureIds[fileName];
end

function fishing.GetIconFiles()
    return iconFiles;
end

function fishing.GetTextureId(settings)
    settings = settings or {};

    local result = (settings.previewResult == true) and nil or fishing.GetResult();

    if (result == nil and settings.previewResult ~= true) then
        return nil;
    end

    local iconFile = (result ~= nil and result.iconFile) or settings.iconFile;

    return GetIconTextureId(iconFile);
end

function fishing.AddIcon(plateData, settings)
    local textureId = fishing.GetTextureId(settings);
    local result = (settings.previewResult == true) and nil or fishing.GetResult();

    if (plateData == nil or settings == nil or settings.enabled == false or textureId == nil) then
        return;
    end

    plateData.icons = plateData.icons or {};
    plateData.icons[#plateData.icons + 1] = {
        kind = 'fishing',
        textureId = textureId,
        size = math.max(6, math.min(200, tonumber(settings.iconSize) or 42)),
        offsetX = tonumber(settings.offsetX) or 0,
        offsetY = tonumber(settings.offsetY) or 38,
        timerText = (settings.showLabel ~= false and result ~= nil) and result.label or '',
        timerFontSize = math.max(4, tonumber(settings.labelFontSize) or 12),
        timerTextColor = settings.labelColor or { 1.0, 1.0, 1.0, 1.0 },
        timerTextOutline = (tonumber(settings.labelOutlineSize) or 2) > 0,
        timerTextOutlineColor = settings.labelOutlineColor or { 0.0, 0.0, 0.0, 1.0 },
        timerTextOutlineSize = tonumber(settings.labelOutlineSize) or 2,
        timerOffsetY = tonumber(settings.labelOffsetY) or 0,
    };
end

return fishing;
