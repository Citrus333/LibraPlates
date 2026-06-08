local anchorGeometry = {};

function anchorGeometry.GetRectPoint(rect, point)
    point = tostring(point or 'Center');

    if (point == 'Top Left') then return rect.x, rect.y; end
    if (point == 'Top') then return rect.x + math.floor(rect.width / 2), rect.y; end
    if (point == 'Top Right') then return rect.x + rect.width, rect.y; end
    if (point == 'Left') then return rect.x, rect.y + math.floor(rect.height / 2); end
    if (point == 'Right') then return rect.x + rect.width, rect.y + math.floor(rect.height / 2); end
    if (point == 'Bottom Left') then return rect.x, rect.y + rect.height; end
    if (point == 'Bottom') then return rect.x + math.floor(rect.width / 2), rect.y + rect.height; end
    if (point == 'Bottom Right') then return rect.x + rect.width, rect.y + rect.height; end

    return rect.x + math.floor(rect.width / 2), rect.y + math.floor(rect.height / 2);
end

function anchorGeometry.RectFromAnchorPoint(anchorX, anchorY, width, height, point)
    point = tostring(point or 'Center');
    width = tonumber(width) or 0;
    height = tonumber(height) or 0;

    if (point == 'Top Left') then return anchorX, anchorY; end
    if (point == 'Top') then return anchorX - math.floor(width / 2), anchorY; end
    if (point == 'Top Right') then return anchorX - width, anchorY; end
    if (point == 'Left') then return anchorX, anchorY - math.floor(height / 2); end
    if (point == 'Right') then return anchorX - width, anchorY - math.floor(height / 2); end
    if (point == 'Bottom Left') then return anchorX, anchorY - height; end
    if (point == 'Bottom') then return anchorX - math.floor(width / 2), anchorY - height; end
    if (point == 'Bottom Right') then return anchorX - width, anchorY - height; end

    return anchorX - math.floor(width / 2), anchorY - math.floor(height / 2);
end

function anchorGeometry.OppositeAnchorPoint(point)
    point = tostring(point or 'Center');

    if (point == 'Top Left') then return 'Bottom Right'; end
    if (point == 'Top') then return 'Bottom'; end
    if (point == 'Top Right') then return 'Bottom Left'; end
    if (point == 'Left') then return 'Right'; end
    if (point == 'Right') then return 'Left'; end
    if (point == 'Bottom Left') then return 'Top Right'; end
    if (point == 'Bottom') then return 'Top'; end
    if (point == 'Bottom Right') then return 'Top Left'; end

    return 'Center';
end

function anchorGeometry.ResolveAnchoredRect(elementLayout, elementKey, defaultRect, bounds, anchorMap)
    elementLayout = elementLayout or {};

    local anchorTo = tostring(elementLayout.anchorTo or 'Plate');
    local anchorPoint = tostring(elementLayout.anchorPoint or 'Center');

    if (anchorTo == 'Plate' or bounds == nil) then
        return defaultRect;
    end

    local targetKey = anchorMap ~= nil and anchorMap[anchorTo] or nil;
    local targetRect = (targetKey ~= nil and bounds[targetKey] or nil);

    if (targetRect == nil) then
        return defaultRect;
    end

    if (targetKey == elementKey) then
        return defaultRect;
    end

    local anchorX, anchorY = anchorGeometry.GetRectPoint(targetRect, anchorPoint);
    local offsetX = tonumber(elementLayout.offsetX) or 0;
    local offsetY = tonumber(elementLayout.offsetY) or 0;
    local x, y = anchorGeometry.RectFromAnchorPoint(
        anchorX + offsetX,
        anchorY + offsetY,
        defaultRect.width,
        defaultRect.height,
        anchorGeometry.OppositeAnchorPoint(anchorPoint)
    );

    return { x = x, y = y, width = defaultRect.width, height = defaultRect.height };
end

return anchorGeometry;
