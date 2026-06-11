local textScale = {};

local textureScale = 2.5;
local minVisualSize = 1;
local maxVisualSize = 96;

local function Clamp(value, minValue, maxValue)
    value = tonumber(value) or minValue;

    if (value < minValue) then
        return minValue;
    end

    if (value > maxValue) then
        return maxValue;
    end

    return value;
end

function textScale.GetMinVisualSize()
    return minVisualSize;
end

function textScale.GetMaxVisualSize()
    return maxVisualSize;
end

function textScale.NormalizeSetting(value, fallback)
    local current = tonumber(value);

    if (current == nil) then
        current = tonumber(fallback) or 10;
    end

    if (current > maxVisualSize) then
        current = math.floor((current / textureScale) + 0.5);
    end

    return Clamp(current, minVisualSize, maxVisualSize);
end

function textScale.ToTextureFontSize(value, fallback)
    local current = tonumber(value);

    if (current == nil) then
        current = tonumber(fallback) or 10;
    end

    if (current > maxVisualSize) then
        return math.max(1, math.floor(current + 0.5));
    end

    return math.max(1, math.floor((Clamp(current, minVisualSize, maxVisualSize) * textureScale) + 0.5));
end

function textScale.ToNameTextureFontSize(value, fallback)
    local current = tonumber(value);

    if (current == nil) then
        current = tonumber(fallback) or 10;
    end

    if (current > maxVisualSize) then
        return math.max(1, math.floor(current + 0.5));
    end

    local size = Clamp(current, minVisualSize, maxVisualSize);
    local scaledSize = size * textureScale;

    if (size > 18) then
        scaledSize = (18 * textureScale) + (size - 18);
    end

    return math.max(1, math.floor(scaledSize + 0.5));
end

return textScale;
