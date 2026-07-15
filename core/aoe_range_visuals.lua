local textureLoader = require('core.texture_loader');
local targetTextures = require('core.target_textures');

local aoeRangeVisuals = {};
local textureIds = {};
local iconFiles = nil;

local function GetAddonPath()
    local ok, path = pcall(function()
        return AshitaCore:GetInstallPath() .. '\\addons\\LibraPlates\\';
    end);

    if (ok == true and path ~= nil) then
        return tostring(path);
    end

    return '.\\';
end

local function GetTextureId(path, key)
    if (textureIds[key] ~= nil) then
        return textureIds[key];
    end

    textureIds[key] = textureLoader.ToTextureId(textureLoader.Load(path));
    return textureIds[key];
end

local function ClampNumber(value, fallback, minValue, maxValue)
    local number = tonumber(value) or fallback;

    if (number < minValue) then
        return minValue;
    end

    if (number > maxValue) then
        return maxValue;
    end

    return number;
end

function aoeRangeVisuals.GetIconFiles()
    if (iconFiles ~= nil) then
        return iconFiles;
    end

    iconFiles = {};
    local folder = aoeRangeVisuals.GetIconFolderPath();
    local pipe = io.popen('dir /b "' .. folder .. '*.png" 2>nul');

    if (pipe ~= nil) then
        for fileName in pipe:lines() do
            iconFiles[#iconFiles + 1] = tostring(fileName);
        end
        pipe:close();
    end

    table.sort(iconFiles);
    return iconFiles;
end

function aoeRangeVisuals.GetIconFolderPath()
    return GetAddonPath() .. 'assets\\images\\widget-icons\\aoe\\';
end

function aoeRangeVisuals.GetIconTextureId(fileName)
    fileName = tostring(fileName or 'aoe_range_00.png'):gsub('^.*[\\/]', '');
    return GetTextureId(
        GetAddonPath() .. 'assets\\images\\widget-icons\\aoe\\' .. fileName,
        'widget-icons/aoe/' .. fileName
    );
end

function aoeRangeVisuals.AddIcon(plateData, settings)
    if (plateData == nil or settings == nil or settings.iconEnabled ~= true) then
        return;
    end

    local textureId = aoeRangeVisuals.GetIconTextureId(settings.iconFile);

    if (textureId == nil) then
        return;
    end

    plateData.icons = plateData.icons or {};
    plateData.icons[#plateData.icons + 1] = {
        kind = 'aoeRangeIcon',
        textureId = textureId,
        size = ClampNumber(settings.iconSize, 22, 4, 256),
        offsetX = tonumber(settings.iconOffsetX) or -42,
        offsetY = tonumber(settings.iconOffsetY) or -54,
        anchorTo = settings.iconAnchorTo or 'Name',
        anchorPoint = settings.iconAnchorPoint or 'Left',
    };
end

function aoeRangeVisuals.Apply(plateData, settings)
    if (plateData == nil or settings == nil or plateData.aoeNameActive ~= true) then
        return;
    end

    local highlightFile = tostring(settings.highlightFile or 'None');

    if (highlightFile ~= 'None') then
        local anchorKinds = { 'background', 'name', 'hp', 'mp', 'tp', 'cast' };
        local autoPlaceBy = tostring(settings.highlightAutoPlaceBy or 'Widest element');

        if (autoPlaceBy == 'Background') then
            anchorKinds = { 'background' };
        elseif (autoPlaceBy == 'Name') then
            anchorKinds = { 'name' };
        elseif (autoPlaceBy == 'HP Bar') then
            anchorKinds = { 'hp' };
        end

        local tint = settings.highlightColor or { 0.00, 0.82, 0.88, 1.0 };
        local opacity = ClampNumber(settings.highlightOpacity, 95, 0, 100) / 100;
        plateData.aoeHighlight = {
            textureId = targetTextures.GetTextureId('backgrounds', highlightFile),
            color = { tonumber(tint[1]) or 1.0, tonumber(tint[2]) or 1.0, tonumber(tint[3]) or 1.0, opacity },
            autoPlace = settings.highlightAutoPlace ~= false,
            anchorKinds = anchorKinds,
            spacing = ClampNumber(settings.highlightSpacing, 7, 0, 40),
            offsetX = tonumber(settings.highlightOffsetX) or 0,
            offsetY = tonumber(settings.highlightOffsetY) or 0,
            width = ClampNumber(settings.highlightWidth, 220, 1, 1000),
            height = ClampNumber(settings.highlightHeight, 74, 1, 450),
            clickable = settings.highlightClickable ~= false,
        };
    end

    aoeRangeVisuals.AddIcon(plateData, settings);
end

return aoeRangeVisuals;
