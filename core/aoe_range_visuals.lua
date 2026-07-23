local textureLoader = require('core.texture_loader');
local iconPack = require('core.icon_pack');

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
        iconPack.GetAssetPath('widget-icons', 'aoe\\' .. fileName),
        tostring(iconPack.GetRevision()) .. ':widget-icons/aoe/' .. fileName
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

    local anchorTo = settings.iconAnchorTo or 'Name';
    local anchorPoint = settings.iconAnchorPoint or 'Center';

    -- The AOE settings expose Position X/Y but not anchor controls. Older
    -- settings stored the hidden default as Name/Left, which made 0,0 place
    -- the icon beside the name and consumed most of the allowed X range just
    -- to reach the plate center. Treat that legacy hidden value as centered.
    if (anchorTo == 'Name' and anchorPoint == 'Left') then
        anchorPoint = 'Center';
    end

    plateData.icons = plateData.icons or {};
    plateData.icons[#plateData.icons + 1] = {
        kind = 'aoeRangeIcon',
        textureId = textureId,
        size = ClampNumber(settings.iconSize, 22, 4, 256),
        offsetX = tonumber(settings.iconOffsetX) or -42,
        offsetY = tonumber(settings.iconOffsetY) or -54,
        anchorTo = anchorTo,
        anchorPoint = anchorPoint,
        anchorCollapse = false,
    };
end

function aoeRangeVisuals.Apply(plateData, settings)
    if (plateData == nil or settings == nil or plateData.aoeNameActive ~= true) then
        return;
    end

    aoeRangeVisuals.AddIcon(plateData, settings);
end

return aoeRangeVisuals;
