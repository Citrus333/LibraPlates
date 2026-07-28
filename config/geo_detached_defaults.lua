local function CooldownSocket(offsetX, color)
    return {
        enabled = true,
        width = 34,
        height = 42,
        offsetX = offsetX,
        offsetY = 45,
        color = color,
        backgroundColor = { 0.02, 0.02, 0.02, 0.70 },
        borderColor = { 0.0, 0.0, 0.0, 1.0 },
        borderSize = 0,
        cornerRadius = 4,
        texture = 'Solid',
        textureStrength = 100,
        barOrientation = 'Vertical',
        fillDirection = 'Bottom to top',
        behindPlateArtwork = true,
        labelDisplayMode = 'Text',
        showValue = false,
        showPercent = true,
        textOffsetX = 0,
        textOffsetY = 0,
        useSmallFont = true,
        fontSize = 9,
        textColor = { 1.0, 1.0, 1.0, 1.0 },
        textOutlineEnabled = true,
        textOutlineColor = { 0.0, 0.0, 0.0, 1.0 },
        textOutlineSize = 2,
        labelIconOffsetX = 0,
        labelIconOffsetY = 31,
        labelIconSize = 9,
    };
end

local defaults = {
    enabled = true,
    width = 320,
    height = 145,
    offsetX = 0,
    offsetY = 0,
    texture = 'None',
    geoArtworkOpacity = 100,
    color = { 0.0, 0.0, 0.0, 0.0 },
    borderColor = { 0.0, 0.0, 0.0, 0.0 },
    borderSize = 0,

    geoNameSettings = {
        enabled = true,
        textSize = 20,
        color = { 1.0, 1.0, 1.0, 1.0 },
        outlineEnabled = true,
        outlineColor = { 0.0, 0.0, 0.0, 1.0 },
        outlineSize = 2,
        offsetX = 0,
        offsetY = -48,
        anchorTo = 'Plate',
        anchorPoint = 'Center',
    },
    geoHpBarSettings = {
        enabled = true,
        width = 230,
        height = 13,
        offsetX = 0,
        offsetY = -22,
        color = { 0.20, 0.95, 0.34, 0.95 },
        backgroundColor = { 0.02, 0.02, 0.02, 0.70 },
        borderColor = { 0.0, 0.0, 0.0, 1.0 },
        borderSize = 0,
        cornerRadius = 3,
        texture = 'Solid',
        textureStrength = 100,
        showValue = false,
        showPercent = true,
        showAtPercent = 100,
        lowColorEnabled = true,
        lowColorPercent = 50,
        lowColor = { 1.0, 0.55, 0.05, 1.0 },
        criticalColorEnabled = true,
        criticalColorPercent = 25,
        criticalColor = { 1.0, 0.15, 0.10, 1.0 },
        lowAnimationEnabled = false,
        textOffsetX = 0,
        textOffsetY = 0,
        useSmallFont = true,
        fontSize = 7,
        textColor = { 1.0, 1.0, 1.0, 1.0 },
        textOutlineEnabled = true,
        textOutlineColor = { 0.0, 0.0, 0.0, 1.0 },
        textOutlineSize = 1,
        anchorTo = 'Plate',
        anchorPoint = 'Center',
    },
    geoEnmitySettings = {
        enabled = true,
        allyIconFile = 'warning-dimond.png',
        allyColor = { 1.0, 0.25, 0.20, 1.0 },
        allyOffsetX = 145,
        allyOffsetY = -48,
        allyIconSize = 26,
    },
    geoBlazeSettings = CooldownSocket(-105, { 1.0, 0.35, 0.08, 1.0 }),
    geoEmanationSettings = CooldownSocket(-35, { 0.72, 0.35, 1.0, 1.0 }),
    geoDematerializeSettings = CooldownSocket(35, { 0.30, 0.80, 1.0, 1.0 }),
    geoLifeCycleSettings = CooldownSocket(105, { 0.25, 0.95, 0.45, 1.0 }),
    geoFullCircleSettings = {
        enabled = true,
        textSize = 11,
        color = { 1.0, 1.0, 1.0, 1.0 },
        outlineEnabled = true,
        outlineColor = { 0.0, 0.0, 0.0, 1.0 },
        outlineSize = 2,
        offsetX = 0,
        offsetY = 4,
        anchorTo = 'Plate',
        anchorPoint = 'Center',
    },
    geoActiveEffectsSettings = {
        enabled = true,
        iconSize = 24,
        offsetX = 0,
        offsetY = 8,
        iconSpacing = 4,
    },
};

local function Copy(value)
    if (type(value) ~= 'table') then
        return value;
    end

    local result = {};
    for key, child in pairs(value) do
        result[key] = Copy(child);
    end
    return result;
end

return {
    Get = function()
        return Copy(defaults);
    end,
};
