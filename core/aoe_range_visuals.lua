local textureLoader = require('core.texture_loader');

local aoeRangeVisuals = {};
local textureIds = {};

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

function aoeRangeVisuals.GetIconTextureId()
    return GetTextureId(GetAddonPath() .. 'assets\\images\\widget-icons\\aoe_range.png', 'widget-icons/aoe_range.png');
end

function aoeRangeVisuals.AddIcon(plateData, settings)
    if (plateData == nil or settings == nil or settings.iconEnabled ~= true) then
        return;
    end

    local textureId = aoeRangeVisuals.GetIconTextureId();

    if (textureId == nil) then
        return;
    end

    plateData.icons = plateData.icons or {};
    plateData.icons[#plateData.icons + 1] = {
        kind = 'aoeRangeIcon',
        textureId = textureId,
        size = ClampNumber(settings.iconSize, 22, 4, 128),
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

    aoeRangeVisuals.AddIcon(plateData, settings);
end

return aoeRangeVisuals;
