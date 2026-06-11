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

local function GetAutoPlaceAnchorKinds(value)
    if (tostring(value or '') == 'Name') then
        return { 'name' };
    end

    if (tostring(value or '') == 'HP Bar') then
        return { 'hp' };
    end

    return { 'name', 'hp' };
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

function aoeRangeVisuals.GetBackgroundTextureId(fileName)
    fileName = tostring(fileName or 'None'):gsub('^.*[\\/]', '');

    if (fileName == '' or fileName == 'None') then
        return nil;
    end

    return GetTextureId(
        GetAddonPath() .. 'assets\\images\\target\\backgrounds\\' .. fileName,
        'target/backgrounds/' .. fileName
    );
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

function aoeRangeVisuals.BuildHighlight(settings, hpBarSettings)
    if (settings == nil or settings.highlightEnabled ~= true) then
        return nil;
    end

    local textureId = aoeRangeVisuals.GetBackgroundTextureId(settings.backgroundFile);

    if (textureId == nil) then
        return nil;
    end

    local autoPlace = settings.autoPlaceBackground ~= false;
    local spacing = ClampNumber(settings.backgroundSpacing, 7, 0, 300);
    local hpWidth = tonumber(hpBarSettings ~= nil and hpBarSettings.width or nil) or 180;
    local hpHeight = tonumber(hpBarSettings ~= nil and hpBarSettings.height or nil) or 12;

    return {
        enabled = true,
        showBackground = true,
        showArrow = false,
        showLock = false,
        showChevrons = false,
        backgroundTextureId = textureId,
        backgroundAnchorToPlate = autoPlace,
        backgroundAnchorKinds = GetAutoPlaceAnchorKinds(settings.backgroundAutoPlaceAnchor),
        backgroundSpacing = spacing,
        backgroundWidth = autoPlace == true and math.max(1, hpWidth + (spacing * 2)) or ClampNumber(settings.backgroundWidth, 300, 1, 1000),
        backgroundHeight = autoPlace == true and math.max(1, hpHeight + (spacing * 2)) or ClampNumber(settings.backgroundHeight, 90, 1, 450),
        backgroundOffsetX = autoPlace == true and 0 or (tonumber(settings.backgroundOffsetX) or 0),
        backgroundOffsetY = autoPlace == true and 0 or (tonumber(settings.backgroundOffsetY) or 0),
        backgroundColor = settings.backgroundColor or { 0.00, 0.82, 0.88, 0.95 },
        anchorKinds = { 'name', 'hp' },
    };
end

function aoeRangeVisuals.AddHighlight(plateData, settings, hpBarSettings)
    local marker = aoeRangeVisuals.BuildHighlight(settings, hpBarSettings);

    if (marker == nil) then
        return;
    end

    if (plateData.targetMarker ~= nil and plateData.targetMarker.enabled == true) then
        marker.stackedMarkers = { plateData.targetMarker };
    end

    plateData.targetMarker = marker;
end

function aoeRangeVisuals.Apply(plateData, settings, hpBarSettings)
    if (plateData == nil or settings == nil or plateData.aoeNameActive ~= true) then
        return;
    end

    aoeRangeVisuals.AddIcon(plateData, settings);
end

return aoeRangeVisuals;
