local pcTargetMarkerSignature = {};
local visualDistanceCache = {};

local function BoolKey(value)
    return value == true and '1' or '0';
end

local function ColorKey(color)
    color = color or {};

    return table.concat({
        string.format('%.3f', tonumber(color[1]) or 0),
        string.format('%.3f', tonumber(color[2]) or 0),
        string.format('%.3f', tonumber(color[3]) or 0),
        string.format('%.3f', tonumber(color[4]) or 0),
    }, ',');
end

function pcTargetMarkerSignature.GetMarkerKey(marker, includeFrameTextures)
    marker = marker or {};

    if (marker.enabled ~= true) then
        return 'target=0';
    end

    return table.concat({
        'target=1',
        'showBackground=' .. BoolKey(marker.showBackground == true),
        'showArrow=' .. BoolKey(marker.showArrow == true),
        'showLock=' .. BoolKey(marker.showLock == true),
        'showChevrons=' .. BoolKey(marker.showChevrons == true),
        'backgroundTextureId=' .. tostring(marker.backgroundTextureId or ''),
        'arrowTextureId=' .. (includeFrameTextures == true and tostring(marker.arrowTextureId or '') or ''),
        'lockTextureId=' .. (includeFrameTextures == true and tostring(marker.lockTextureId or '') or ''),
        'chevronTextureId=' .. tostring(marker.chevronTextureId or ''),
        'backgroundOffsetX=' .. tostring(marker.backgroundOffsetX or 0),
        'backgroundOffsetY=' .. tostring(marker.backgroundOffsetY or 0),
        'arrowOffsetX=' .. tostring(marker.arrowOffsetX or 0),
        'arrowOffsetY=' .. tostring(marker.arrowOffsetY or 0),
        'lockOffsetX=' .. tostring(marker.lockOffsetX or 0),
        'lockOffsetY=' .. tostring(marker.lockOffsetY or 0),
        'backgroundWidth=' .. tostring(marker.backgroundWidth or 0),
        'backgroundHeight=' .. tostring(marker.backgroundHeight or 0),
        'arrowWidth=' .. tostring(marker.arrowWidth or 0),
        'arrowHeight=' .. tostring(marker.arrowHeight or 0),
        'lockWidth=' .. tostring(marker.lockWidth or 0),
        'lockHeight=' .. tostring(marker.lockHeight or 0),
        'distance=' .. tostring(math.floor(((tonumber(marker.distance) or 0) * 10) + 0.5)),
        'arrowScaleWithDistance=' .. BoolKey(marker.arrowScaleWithDistance == true),
        'arrowMinScale=' .. tostring(marker.arrowMinScale or ''),
        'arrowMaxScale=' .. tostring(marker.arrowMaxScale or ''),
        'arrowLockFarMinSize=' .. BoolKey(marker.arrowLockFarMinSize == true),
        'arrowFarMinDistance=' .. tostring(marker.arrowFarMinDistance or ''),
        'arrowFarMinScale=' .. tostring(marker.arrowFarMinScale or ''),
        'arrowFarFullDistance=' .. tostring(marker.arrowFarFullDistance or ''),
        'color=' .. ColorKey(marker.color),
        'backgroundColor=' .. ColorKey(marker.backgroundColor),
        'arrowColor=' .. ColorKey(marker.arrowColor),
        'lockColor=' .. ColorKey(marker.lockColor),
        'chevronColor=' .. ColorKey(marker.chevronColor),
    }, ';');
end

function pcTargetMarkerSignature.HasAnimatedMarker(marker)
    return marker ~= nil and marker.enabled == true and (
        marker.arrowAnimated == true or
        marker.lockAnimated == true
    );
end

function pcTargetMarkerSignature.GetVisualDistance(index, identityKey, targetStateName, distance)
    if (tostring(targetStateName or 'Idle') == 'Idle') then
        return tonumber(distance);
    end

    index = tonumber(index) or 0;
    identityKey = tostring(identityKey or '');
    local now = os.clock();
    local cached = visualDistanceCache[index];

    if (
        cached == nil or
        cached.identityKey ~= identityKey or
        (now - (tonumber(cached.updatedAt) or 0)) >= 0.20
    ) then
        cached = {
            identityKey = identityKey,
            distance = tonumber(distance),
            updatedAt = now,
        };
        visualDistanceCache[index] = cached;
    end

    return cached.distance;
end

function pcTargetMarkerSignature.Reset()
    visualDistanceCache = {};
end

function pcTargetMarkerSignature.BuildCanvasMarker(marker)
    local copy = {};

    for key, value in pairs(marker or {}) do
        copy[key] = value;
    end

    copy.suppressAnimatedArrowDraw = copy.arrowAnimated == true;
    copy.suppressAnimatedLockDraw = copy.lockAnimated == true;
    return copy;
end

function pcTargetMarkerSignature.BuildLiveOverlay(marker, elementRects)
    if (pcTargetMarkerSignature.HasAnimatedMarker(marker) ~= true) then
        return nil;
    end

    local overlay = {};

    for _, rect in ipairs(elementRects or {}) do
        local kind = tostring(rect ~= nil and rect.kind or '');
        local component = nil;

        if (kind == 'targetModuleArrow' and marker.arrowAnimated == true and marker.showArrow == true) then
            component = {
                textureId = marker.arrowTextureId,
                color = marker.arrowColor or marker.color,
            };
            overlay.arrow = component;
        elseif (kind == 'targetModuleLock' and marker.lockAnimated == true and marker.showLock == true) then
            component = {
                textureId = marker.lockTextureId,
                color = marker.lockColor or marker.color,
            };
            overlay.lock = component;
        end

        if (component ~= nil) then
            component.x1 = tonumber(rect.drawX1) or tonumber(rect.x1);
            component.y1 = tonumber(rect.drawY1) or tonumber(rect.y1);
            component.x2 = tonumber(rect.drawX2) or tonumber(rect.x2);
            component.y2 = tonumber(rect.drawY2) or tonumber(rect.y2);
        end
    end

    if (overlay.arrow == nil and overlay.lock == nil) then
        return nil;
    end

    return overlay;
end

return pcTargetMarkerSignature;
