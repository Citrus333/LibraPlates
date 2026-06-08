local canvas = {};

-- ============================================================
-- Coordinates
-- ============================================================

function canvas.GetBounds(settings, originX, originY)
    local width = tonumber(settings.width) or 620;
    local height = tonumber(settings.height) or 200;
    local left = (tonumber(originX) or 0) - (width / 2);
    local top = (tonumber(originY) or 0) - (height / 2);

    return {
        left = left,
        top = top,
        width = width,
        height = height,
        centerX = left + (width / 2),
        centerY = top + (height / 2),
    };
end

function canvas.ToScreen(bounds, localX, localY)
    return bounds.centerX + (tonumber(localX) or 0), bounds.centerY + (tonumber(localY) or 0);
end

function canvas.GetLocalRect(bounds, settings)
    local width = tonumber(settings.width) or 0;
    local height = tonumber(settings.height) or 0;
    local centerX, centerY = canvas.ToScreen(bounds, settings.offsetX, settings.offsetY);

    return {
        left = centerX - (width / 2),
        top = centerY - (height / 2),
        width = width,
        height = height,
    };
end

function canvas.ClampPoint(bounds, x, y)
    local clampedX = tonumber(x) or bounds.centerX;
    local clampedY = tonumber(y) or bounds.centerY;

    if (clampedX < bounds.left) then
        clampedX = bounds.left;
    elseif (clampedX > bounds.left + bounds.width) then
        clampedX = bounds.left + bounds.width;
    end

    if (clampedY < bounds.top) then
        clampedY = bounds.top;
    elseif (clampedY > bounds.top + bounds.height) then
        clampedY = bounds.top + bounds.height;
    end

    return clampedX, clampedY;
end

return canvas;
