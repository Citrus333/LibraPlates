require('common');

local d3d = require('d3d8');
local ffi = require('ffi');
local C = ffi.C;
local gdiTextTexture = require('ui.gdi_text_texture');
local fonts = require('core.fonts');
local anchorGeometry = require('core.anchor_geometry');
local nativeUiPolicy = require('core.native_ui_policy');

ffi.cdef[[
    typedef struct {
        float x, y, z, rhw;
        unsigned int color;
    } lp_canvas_color_vertex_t;

    typedef struct {
        float x, y, z, rhw;
        unsigned int color;
        float tu, tv;
    } lp_canvas_texture_vertex_t;
]];

local canvasTexture = {};
local perfMeter = require('core.perf_meter');
local textures = {};
local textureInfo = {};
local textureOrder = {};
local textureIdToKey = {};
local textureCount = 0;
local textureEvictions = 0;
local maxTextures = 96;
local width = 1024;
local height = 512;
local renderVersion = 4;

local D3DPT_TRIANGLELIST = 4;
local D3DFVF_XYZRHW_DIFFUSE = 0x044;
local D3DFVF_XYZRHW_DIFFUSE_TEX1 = 0x144;
local D3DRS_ZENABLE = 7;
local D3DRS_SRCBLEND = 19;
local D3DRS_DESTBLEND = 20;
local D3DRS_ALPHABLENDENABLE = 27;
local D3DRS_LIGHTING = 137;
local D3DTSS_COLOROP = 1;
local D3DTSS_COLORARG1 = 2;
local D3DTSS_COLORARG2 = 3;
local D3DTSS_ALPHAOP = 4;
local D3DTSS_ALPHAARG1 = 5;
local D3DTSS_ALPHAARG2 = 6;
local D3DTOP_SELECTARG1 = 2;
local D3DTOP_MODULATE = 4;
local D3DTA_DIFFUSE = 0;
local D3DTA_TEXTURE = 2;

local function ClampColorChannel(value)
    value = tonumber(value) or 0;

    if (value <= 1) then
        value = value * 255;
    end

    return math.max(0, math.min(255, math.floor(value + 0.5)));
end

local function ColorToD3D(color, fallback)
    color = color or fallback or { 1.0, 1.0, 1.0, 1.0 };

    local r = ClampColorChannel(color[1] or 1);
    local g = ClampColorChannel(color[2] or 1);
    local b = ClampColorChannel(color[3] or 1);
    local a = ClampColorChannel(color[4] or 1);

    return (a * 0x1000000) + (r * 0x10000) + (g * 0x100) + b;
end

local function TextureId(value)
    if (value == nil) then
        return nil;
    end

    return tonumber(ffi.cast('uintptr_t', value));
end

local function RemoveTextureOrderKey(key)
    for i = #textureOrder, 1, -1 do
        if (textureOrder[i] == key) then
            table.remove(textureOrder, i);
            return;
        end
    end
end

local function TouchTextureKey(key)
    key = tostring(key or '');

    if (key == '' or textures[key] == nil) then
        return false;
    end

    local info = textureInfo[key] or {};
    info.lastTouch = os.clock();
    textureInfo[key] = info;
    RemoveTextureOrderKey(key);
    textureOrder[#textureOrder + 1] = key;
    return true;
end

local function ReleaseTextureKey(key)
    key = tostring(key or '');

    if (key == '' or textures[key] == nil) then
        return false;
    end

    local id = TextureId(textures[key]);

    if (id ~= nil) then
        textureIdToKey[id] = nil;
    end

    textures[key] = nil;
    textureInfo[key] = nil;
    RemoveTextureOrderKey(key);
    textureCount = math.max(0, textureCount - 1);
    textureEvictions = textureEvictions + 1;
    collectgarbage('step', 32);
    return true;
end

local function TrimTextureCache()
    while (textureCount > maxTextures and #textureOrder > 0) do
        ReleaseTextureKey(textureOrder[1]);
    end
end

local function GetManualNameOutlineRadius(value)
    local size = math.max(0, tonumber(value) or 0);

    if (size <= 2) then
        return 0;
    end

    return math.min(8, math.floor(size + 0.5));
end

local function BuildOutlineOffsets(radius)
    local r = math.max(0, tonumber(radius) or 0);

    if (r <= 0) then
        return {};
    end

    local inner = math.max(1, math.floor((r * 0.55) + 0.5));

    return {
        { -r, 0 }, { r, 0 }, { 0, -r }, { 0, r },
        { -r, -r }, { r, -r }, { -r, r }, { r, r },
        { -inner, 0 }, { inner, 0 }, { 0, -inner }, { 0, inner },
        { -inner, -inner }, { inner, -inner }, { -inner, inner }, { inner, inner },
    };
end

local function ResolveFontFamily(value)
    local fontName = tostring(value or 'Arial');

    if (fontName == '' or fontName == 'Default') then
        return 'Arial';
    end

    return fontName;
end

local function GetNameRenderFontSize(fontSize)
    local size = math.max(1, tonumber(fontSize) or 16);

    return math.min(44, math.floor(size + 0.5));
end

local function GetNameRenderScale(fontSize, renderFontSize)
    local renderSize = math.max(1, tonumber(renderFontSize) or 16);

    return math.max(1.0, (tonumber(fontSize) or renderSize) / renderSize);
end

local function GetNameFontSize(plate, plateName)
    local fontSize = math.max(1, tonumber(plate.nameFontSize) or 16);
    local renderFontSize = GetNameRenderFontSize(fontSize);
    local renderScale = GetNameRenderScale(fontSize, renderFontSize);
    local text = tostring(plateName or '');

    if (text == '') then
        return fontSize;
    end

    local manualOutlineRadius = GetManualNameOutlineRadius(plate.nameOutlineSize);
    local safeWidth = width - 96;
    local _, nameW = gdiTextTexture.GetTexture(text, {
        fontFamily = ResolveFontFamily(plate.nameFontFamily),
        fontFlags = tonumber(plate.nameFontFlags) or 0,
        fontSize = renderFontSize,
        color = plate.nameColor or { 1.0, 1.0, 1.0, 1.0 },
        outlineEnabled = plate.nameOutlineEnabled == true and manualOutlineRadius <= 0,
        outlineColor = plate.nameOutlineColor or { 0.0, 0.0, 0.0, 1.0 },
        outlineSize = tonumber(plate.nameOutlineSize) or 0,
    });

    local neededWidth = ((tonumber(nameW) or 0) * renderScale) + (manualOutlineRadius * 2 * renderScale);

    if (neededWidth <= safeWidth or neededWidth <= 0) then
        return fontSize;
    end

    return math.max(1, math.floor((fontSize * (safeWidth / neededWidth)) + 0.5));
end

local function DrawRect(device, x, y, w, h, color)
    local x1 = tonumber(x) or 0;
    local y1 = tonumber(y) or 0;
    local x2 = x1 + (tonumber(w) or 0);
    local y2 = y1 + (tonumber(h) or 0);
    local z = 0;
    local rhw = 1;
    local vertices = ffi.new('lp_canvas_color_vertex_t[6]', {
        { x1, y1, z, rhw, color },
        { x2, y1, z, rhw, color },
        { x2, y2, z, rhw, color },
        { x1, y1, z, rhw, color },
        { x2, y2, z, rhw, color },
        { x1, y2, z, rhw, color },
    });

    device:SetTexture(0, nil);
    device:SetVertexShader(D3DFVF_XYZRHW_DIFFUSE);
    device:SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_SELECTARG1);
    device:SetTextureStageState(0, D3DTSS_COLORARG1, D3DTA_DIFFUSE);
    device:SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_SELECTARG1);
    device:SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_DIFFUSE);
    device:DrawPrimitiveUP(D3DPT_TRIANGLELIST, 2, vertices, ffi.sizeof('lp_canvas_color_vertex_t'));
end

local function DrawRingSegment(device, centerX, centerY, outerRadius, innerRadius, startAngle, endAngle, color, segmentCount)
    local outer = math.max(1, tonumber(outerRadius) or 1);
    local inner = math.max(0, math.min(outer - 1, tonumber(innerRadius) or 0));
    local start = tonumber(startAngle) or 0;
    local finish = tonumber(endAngle) or start;
    local span = finish - start;

    if (span <= 0 or outer <= inner) then
        return;
    end

    local segments = math.max(3, math.ceil((tonumber(segmentCount) or 64) * math.min(1, span / (math.pi * 2))));
    local vertices = ffi.new('lp_canvas_color_vertex_t[?]', segments * 6);
    local z = 0;
    local rhw = 1;
    local index = 0;

    for i = 0, segments - 1 do
        local a1 = start + (span * (i / segments));
        local a2 = start + (span * ((i + 1) / segments));
        local o1x = centerX + (math.cos(a1) * outer);
        local o1y = centerY + (math.sin(a1) * outer);
        local o2x = centerX + (math.cos(a2) * outer);
        local o2y = centerY + (math.sin(a2) * outer);
        local i1x = centerX + (math.cos(a1) * inner);
        local i1y = centerY + (math.sin(a1) * inner);
        local i2x = centerX + (math.cos(a2) * inner);
        local i2y = centerY + (math.sin(a2) * inner);

        vertices[index] = { o1x, o1y, z, rhw, color }; index = index + 1;
        vertices[index] = { o2x, o2y, z, rhw, color }; index = index + 1;
        vertices[index] = { i2x, i2y, z, rhw, color }; index = index + 1;
        vertices[index] = { o1x, o1y, z, rhw, color }; index = index + 1;
        vertices[index] = { i2x, i2y, z, rhw, color }; index = index + 1;
        vertices[index] = { i1x, i1y, z, rhw, color }; index = index + 1;
    end

    device:SetTexture(0, nil);
    device:SetVertexShader(D3DFVF_XYZRHW_DIFFUSE);
    device:SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_SELECTARG1);
    device:SetTextureStageState(0, D3DTSS_COLORARG1, D3DTA_DIFFUSE);
    device:SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_SELECTARG1);
    device:SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_DIFFUSE);
    device:DrawPrimitiveUP(D3DPT_TRIANGLELIST, segments * 2, vertices, ffi.sizeof('lp_canvas_color_vertex_t'));
end

local function DrawRectOutline(device, x, y, w, h, color, thickness)
    local line = math.max(1, tonumber(thickness) or 1);

    DrawRect(device, x, y, w, line, color);
    DrawRect(device, x, y + h - line, w, line, color);
    DrawRect(device, x, y, line, h, color);
    DrawRect(device, x + w - line, y, line, h, color);
end

local function DrawRoundedRect(device, x, y, w, h, color, radius)
    local rectW = math.max(0, tonumber(w) or 0);
    local rectH = math.max(0, tonumber(h) or 0);
    local r = math.max(0, math.min(tonumber(radius) or 0, math.floor(math.min(rectW, rectH) * 0.5)));

    if (rectW <= 0 or rectH <= 0) then
        return;
    end

    if (r <= 0) then
        DrawRect(device, x, y, rectW, rectH, color);
        return;
    end

    local top = math.floor(tonumber(y) or 0);
    local left = math.floor(tonumber(x) or 0);
    local heightInt = math.max(1, math.floor(rectH + 0.5));

    for row = 0, heightInt - 1 do
        local inset = 0;

        if (row < r) then
            local dy = r - row - 0.5;
            inset = math.max(0, math.ceil(r - math.sqrt(math.max(0, (r * r) - (dy * dy)))));
        elseif (row >= heightInt - r) then
            local dy = row - (heightInt - r) + 0.5;
            inset = math.max(0, math.ceil(r - math.sqrt(math.max(0, (r * r) - (dy * dy)))));
        end

        DrawRect(device, left + inset, top + row, math.max(0, rectW - (inset * 2)), 1, color);
    end
end

local function DrawRoundedRectWithBorder(device, x, y, w, h, backgroundColor, borderColor, borderSize, radius)
    local border = math.max(0, tonumber(borderSize) or 0);

    if (border > 0) then
        DrawRoundedRect(device, x, y, w, h, borderColor, radius);
        DrawRoundedRect(device, x + border, y + border, w - (border * 2), h - (border * 2), backgroundColor, math.max(0, (tonumber(radius) or 0) - border));
        return;
    end

    DrawRoundedRect(device, x, y, w, h, backgroundColor, radius);
end

local function GetTimerBackgroundColor(icon)
    local seconds = tonumber(icon.timerSeconds);

    if (seconds == nil) then
        return icon.timerBackgroundColor;
    end

    local normalSeconds = tonumber(icon.timerNormalSeconds) or 60;
    local soonSeconds = tonumber(icon.timerSoonSeconds) or 20;

    if (seconds > normalSeconds) then
        return icon.timerNormalBackgroundColor or icon.timerBackgroundColor;
    end

    if (seconds > soonSeconds) then
        return icon.timerSoonBackgroundColor or icon.timerBackgroundColor;
    end

    return icon.timerUrgentBackgroundColor or icon.timerBackgroundColor;
end

local function GetTimerWarningStage(icon)
    if (icon.timerWarningEnabled ~= true) then
        return nil;
    end

    local seconds = tonumber(icon.timerSeconds);

    if (seconds == nil or seconds < 0) then
        return nil;
    end

    local stage1 = tonumber(icon.timerWarningStage1Seconds) or 10;
    local stage2 = tonumber(icon.timerWarningStage2Seconds) or 8;
    local stage3 = tonumber(icon.timerWarningStage3Seconds) or 5;

    if (stage1 < stage2 or stage2 < stage3) then
        local values = { stage1, stage2, stage3 };
        table.sort(values, function(a, b) return (tonumber(a) or 0) > (tonumber(b) or 0); end);
        stage1 = values[1] or 60;
        stage2 = values[2] or 30;
        stage3 = values[3] or 10;
    end

    if (seconds <= stage3) then
        return 3;
    end

    if (seconds <= stage2) then
        return 2;
    end

    if (seconds <= stage1) then
        return 1;
    end

    return nil;
end

local function GetTimerWarningColor(icon, target)
    local stage = GetTimerWarningStage(icon);

    if (stage == nil) then
        return nil;
    end

    target = tostring(target or '');

    if (target == 'font') then
        if (stage == 3) then return icon.timerWarningFontStage3Color or icon.timerWarningStage3Color or { 1.0, 1.0, 1.0, 1.0 }; end
        if (stage == 2) then return icon.timerWarningFontStage2Color or icon.timerWarningStage2Color or { 1.0, 1.0, 1.0, 1.0 }; end
        return icon.timerWarningFontStage1Color or icon.timerWarningStage1Color or { 1.0, 1.0, 1.0, 1.0 };
    end

    if (target == 'box') then
        if (stage == 3) then return icon.timerWarningBoxStage3Color or icon.timerWarningStage3Color or { 1.0, 0.15, 0.15, 1.0 }; end
        if (stage == 2) then return icon.timerWarningBoxStage2Color or icon.timerWarningStage2Color or { 1.0, 0.50, 0.05, 1.0 }; end
        return icon.timerWarningBoxStage1Color or icon.timerWarningStage1Color or { 1.0, 0.90, 0.20, 1.0 };
    end

    if (target == 'iconBackground') then
        local color = nil;
        if (stage == 3) then color = icon.timerWarningIconBackgroundStage3Color or icon.timerWarningStage3Color or { 1.0, 0.15, 0.15, 1.0 };
        elseif (stage == 2) then color = icon.timerWarningIconBackgroundStage2Color or icon.timerWarningStage2Color or { 1.0, 0.50, 0.05, 1.0 };
        else color = icon.timerWarningIconBackgroundStage1Color or icon.timerWarningStage1Color or { 1.0, 0.90, 0.20, 1.0 }; end

        return { color[1] or 1.0, color[2] or 0.0, color[3] or 0.0, 1.0 };
    end

    if (target == 'iconBorder') then
        if (stage == 3) then return icon.timerWarningIconBorderStage3Color or icon.timerWarningStage3Color or { 1.0, 0.15, 0.15, 1.0 }; end
        if (stage == 2) then return icon.timerWarningIconBorderStage2Color or icon.timerWarningStage2Color or { 1.0, 0.50, 0.05, 1.0 }; end
        return icon.timerWarningIconBorderStage1Color or icon.timerWarningStage1Color or { 1.0, 0.90, 0.20, 1.0 };
    end

    return nil;
end

local DrawTexture = nil;

local function DrawTargetMarker(device, centerX, centerY, marker, pass)
    marker = marker or {};
    pass = tostring(pass or 'all');

    if (marker.enabled ~= true) then
        return;
    end

    local targetW = tonumber(marker.width) or 220;
    local targetH = tonumber(marker.height) or 74;
    local baseX = centerX - (targetW * 0.5) + (tonumber(marker.offsetX) or 0);
    local baseY = centerY - (targetH * 0.5) + (tonumber(marker.offsetY) or -20);
    local x = baseX + (tonumber(marker.chevronOffsetX) or 0);
    local y = baseY + (tonumber(marker.chevronOffsetY) or 0);
    local color = ColorToD3D(marker.color, { 1.0, 0.82, 0.10, 0.90 });
    local backgroundColor = ColorToD3D(marker.backgroundColor or marker.color, { 1.0, 0.82, 0.10, 0.90 });
    local arrowColor = ColorToD3D(marker.arrowColor or marker.color, { 1.0, 0.82, 0.10, 0.90 });
    local lockColor = ColorToD3D(marker.lockColor or marker.arrowColor or marker.color, { 1.0, 0.82, 0.10, 0.90 });
    local chevronColor = ColorToD3D(marker.chevronColor or marker.color, { 1.0, 0.82, 0.10, 0.90 });
    local thickness = math.max(1, tonumber(marker.thickness) or 3);
    local corner = math.max(8, tonumber(marker.cornerLength) or 18);
    local distance = tonumber(marker.distance);
    local distanceScale = 1.0;

    if (distance ~= nil and distance > 0) then
        local minScale = tonumber(marker.arrowMinScale) or 0.45;
        local farMinDistance = math.max(1.0, tonumber(marker.arrowFarMinDistance) or 10.0);
        local farMinScale = math.max(minScale, math.min(tonumber(marker.arrowFarMinScale) or 6.0, 6.0));
        local farFullDistance = math.max(farMinDistance, tonumber(marker.arrowFarFullDistance) or 50.0);
        local maxScale = math.max(tonumber(marker.arrowMaxScale) or 10.00, farMinScale);

        maxScale = math.max(minScale, math.min(maxScale, 64.0));

        if (marker.arrowLockFarMinSize ~= false) then
            local t = math.max(0.0, math.min(1.0, (distance - 1.0) / (farFullDistance - 1.0)));
            distanceScale = math.min(maxScale, minScale + ((farMinScale - minScale) * t));
        elseif (marker.arrowScaleWithDistance == true) then
            distanceScale = math.max(minScale, math.min(maxScale, distance / farMinDistance));
        end
    end

    if (pass ~= 'foreground' and marker.showBackground == true) then
        local bgW = tonumber(marker.backgroundWidth) or targetW;
        local bgH = tonumber(marker.backgroundHeight) or targetH;
        local bgX = centerX - (bgW * 0.5) + (tonumber(marker.backgroundOffsetX) or 0);
        local bgY = centerY - (bgH * 0.5) + (tonumber(marker.backgroundOffsetY) or 0);
        local anchorRect = marker.backgroundAnchorRect or marker.anchorRect;

        if (
            marker.backgroundAnchorToPlate == true and
            anchorRect ~= nil and
            tonumber(anchorRect.x1) ~= nil and
            tonumber(anchorRect.y1) ~= nil and
            tonumber(anchorRect.x2) ~= nil and
            tonumber(anchorRect.y2) ~= nil and
            tonumber(anchorRect.x2) > tonumber(anchorRect.x1) and
            tonumber(anchorRect.y2) > tonumber(anchorRect.y1)
        ) then
            local spacing = math.max(0, tonumber(marker.backgroundSpacing) or 0);
            bgX = tonumber(anchorRect.x1) - spacing + (tonumber(marker.backgroundOffsetX) or 0);
            bgY = tonumber(anchorRect.y1) - spacing + (tonumber(marker.backgroundOffsetY) or 0);
            bgW = math.max(1, (tonumber(anchorRect.x2) - tonumber(anchorRect.x1)) + (spacing * 2));
            bgH = math.max(1, (tonumber(anchorRect.y2) - tonumber(anchorRect.y1)) + (spacing * 2));
        end

        if (marker.backgroundTextureId ~= nil) then
            DrawTexture(device, marker.backgroundTextureId, bgX, bgY, bgW, bgH, backgroundColor);
        end
    end

    if (pass == 'background') then
        return;
    end

    if (marker.showArrow == true or marker.showLock == true) then
        local arrowX = centerX + (tonumber(marker.arrowOffsetX) or 0);
        local arrowY = baseY - (tonumber(marker.arrowSpacing) or 10) + (tonumber(marker.arrowOffsetY) or 0);
        local arrowW = (tonumber(marker.arrowWidth) or 20) * distanceScale;
        local arrowH = (tonumber(marker.arrowHeight) or 20) * distanceScale;
        local lockW = tonumber(marker.lockWidth) or 18;
        local lockH = tonumber(marker.lockHeight) or 18;
        local arrowAnchorRect = marker.arrowAnchorRect;

        if (
            marker.arrowAnchorToName == true and
            arrowAnchorRect ~= nil and
            tonumber(arrowAnchorRect.x1) ~= nil and
            tonumber(arrowAnchorRect.y1) ~= nil and
            tonumber(arrowAnchorRect.x2) ~= nil and
            tonumber(arrowAnchorRect.x2) > tonumber(arrowAnchorRect.x1)
        ) then
            local spacing = math.max(0, tonumber(marker.arrowSpacing) or 0);

            arrowX = ((tonumber(arrowAnchorRect.x1) + tonumber(arrowAnchorRect.x2)) * 0.5) + (tonumber(marker.arrowOffsetX) or 0);
            arrowY = tonumber(arrowAnchorRect.y1) - spacing - (arrowH * 0.5) + (tonumber(marker.arrowOffsetY) or 0);
        end

        local canvasH = centerY * 2;
        local margin = 4;
        arrowY = math.max((arrowH * 0.5) + margin, math.min(canvasH - (arrowH * 0.5) - margin, arrowY));

        if (marker.showLock == true and marker.lockTextureId ~= nil) then
            local lockX = arrowX + (tonumber(marker.lockOffsetX) or 0);
            local lockY = math.max((lockH * 0.5) + margin, arrowY - (arrowH * 0.5) - (lockH * 0.5) + (tonumber(marker.lockOffsetY) or -24));
            DrawTexture(device, marker.lockTextureId, lockX - (lockW * 0.5), lockY - (lockH * 0.5), lockW, lockH, lockColor);
        end

        if (marker.showArrow == true and marker.arrowTextureId ~= nil) then
            DrawTexture(device, marker.arrowTextureId, arrowX - (arrowW * 0.5), arrowY - (arrowH * 0.5), arrowW, arrowH, arrowColor);
        end
    end

    if (marker.showChevrons ~= false) then
        if (marker.chevronTextureId ~= nil) then
            local chevW = tonumber(marker.chevronWidth) or 24;
            local chevH = tonumber(marker.chevronHeight) or 32;
            local chevY = centerY - (chevH * 0.5) + (tonumber(marker.chevronOffsetY) or 0);
            local spacing = tonumber(marker.chevronSpacing);
            local manualOffsetX = tonumber(marker.chevronOffsetX) or 0;
            local leftX = nil;
            local rightX = nil;
            local anchorRect = marker.chevronAnchorRect or marker.anchorRect;

            if (
                marker.chevronAnchorToPlate == true and
                anchorRect ~= nil and
                tonumber(anchorRect.y1) ~= nil and
                tonumber(anchorRect.y2) ~= nil and
                tonumber(anchorRect.y2) > tonumber(anchorRect.y1)
            ) then
                chevY = ((tonumber(anchorRect.y1) + tonumber(anchorRect.y2)) * 0.5) - (chevH * 0.5) + (tonumber(marker.chevronOffsetY) or 0);
            end

            if (spacing ~= nil) then
                spacing = math.max(0, spacing);

                if (marker.chevronAnchorToPlate == true) then
                    local gap = spacing * 0.05;
                    local leftEdge = anchorRect ~= nil and tonumber(anchorRect.x1) or nil;
                    local rightEdge = anchorRect ~= nil and tonumber(anchorRect.x2) or nil;

                    if (leftEdge == nil or rightEdge == nil or rightEdge <= leftEdge) then
                        leftEdge = centerX - (targetW * 0.5);
                        rightEdge = centerX + (targetW * 0.5);
                    end

                    leftX = leftEdge - gap - (chevW * 0.5) + manualOffsetX;
                    rightX = rightEdge + gap + (chevW * 0.5) + manualOffsetX;
                else
                    local gap = spacing * 0.05;
                    local edgeSpacing = math.max(28, (targetW * 0.5) + gap + (chevW * 0.5));

                    edgeSpacing = math.min(edgeSpacing, 280);
                    leftX = centerX - edgeSpacing + manualOffsetX;
                    rightX = centerX + edgeSpacing + manualOffsetX;
                end
            else
                leftX = centerX + (tonumber(marker.chevronLeftX) or -110) + manualOffsetX;
                rightX = centerX + (tonumber(marker.chevronRightX) or 110) + manualOffsetX;
            end

            DrawTexture(device, marker.chevronTextureId, leftX - (chevW * 0.5), chevY, chevW, chevH, chevronColor);
            DrawTexture(device, marker.chevronTextureId, rightX - (chevW * 0.5), chevY, chevW, chevH, chevronColor, nil, nil, true);
        end
    end

end

DrawTexture = function(device, textureId, x, y, w, h, color, u2, v2, flipX)
    textureId = tonumber(textureId);

    if (textureId == nil or textureId == 0) then
        return;
    end

    local x1 = tonumber(x) or 0;
    local y1 = tonumber(y) or 0;
    local x2 = x1 + (tonumber(w) or 0);
    local y2 = y1 + (tonumber(h) or 0);
    local texU1 = (flipX == true) and (tonumber(u2) or 1) or 0;
    local texU2 = (flipX == true) and 0 or (tonumber(u2) or 1);
    local texV2 = tonumber(v2) or 1;
    local z = 0;
    local rhw = 1;
    local vertices = ffi.new('lp_canvas_texture_vertex_t[6]', {
        { x1, y1, z, rhw, color, texU1, 0 },
        { x2, y1, z, rhw, color, texU2, 0 },
        { x2, y2, z, rhw, color, texU2, texV2 },
        { x1, y1, z, rhw, color, texU1, 0 },
        { x2, y2, z, rhw, color, texU2, texV2 },
        { x1, y2, z, rhw, color, texU1, texV2 },
    });

    device:SetTexture(0, ffi.cast('IDirect3DBaseTexture8*', ffi.cast('uintptr_t', textureId)));
    device:SetVertexShader(D3DFVF_XYZRHW_DIFFUSE_TEX1);
    device:SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_MODULATE);
    device:SetTextureStageState(0, D3DTSS_COLORARG1, D3DTA_TEXTURE);
    device:SetTextureStageState(0, D3DTSS_COLORARG2, D3DTA_DIFFUSE);
    device:SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_MODULATE);
    device:SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_TEXTURE);
    device:SetTextureStageState(0, D3DTSS_ALPHAARG2, D3DTA_DIFFUSE);
    device:DrawPrimitiveUP(D3DPT_TRIANGLELIST, 2, vertices, ffi.sizeof('lp_canvas_texture_vertex_t'));
end

local function DrawScrollingBarOverlay(device, barX, barY, barW, barH, progress, bar)
    local textureId = tonumber(bar.animationTextureId);

    if (textureId == nil or textureId == 0 or barW <= 0 or barH <= 0) then
        return;
    end

    if (progress <= 0) then
        progress = 1;
    end

    local fillW = barW * progress;
    local tileW = math.max(barH, barH * 3.64);
    local speed = tonumber(bar.animationSpeed) or 40;
    local offset = (os.clock() * speed) % tileW;
    local x = barX - offset;
    local color = ColorToD3D(bar.animationColor, { 1.0, 1.0, 1.0, 0.35 });

    while (x < (barX + fillW)) do
        local drawX = math.max(x, barX);
        local drawRight = math.min(x + tileW, barX + fillW);
        local drawW = drawRight - drawX;

        if (drawW > 0) then
            local u2 = drawW / tileW;
            DrawTexture(device, textureId, drawX, barY, drawW, barH, color, u2, 1);
        end

        x = x + tileW;
    end
end

local function EnsureTexture(device, key)
    key = tostring(key or 'world');

    if (textures[key] ~= nil) then
        local info = textureInfo[key] or {};

        if (tonumber(info.width) == width and tonumber(info.height) == height) then
            TouchTextureKey(key);
            return textures[key];
        end

        ReleaseTextureKey(key);
    end

    local ok, hr, created = pcall(function()
        return device:CreateTexture(width, height, 1, 1, C.D3DFMT_A8R8G8B8, C.D3DPOOL_DEFAULT);
    end);

    if (ok ~= true or hr ~= C.S_OK or created == nil) then
        return nil;
    end

    textures[key] = d3d.gc_safe_release(created);
    textureInfo[key] = {
        createdAt = os.clock(),
        lastTouch = os.clock(),
        width = width,
        height = height,
    };
    textureCount = textureCount + 1;

    local id = TextureId(textures[key]);

    if (id ~= nil) then
        textureIdToKey[id] = key;
    end

    TouchTextureKey(key);
    TrimTextureCache();
    return textures[key];
end

local function DrawBarLabel(device, barX, barY, barW, barH, bar)
    local barText = tostring(bar.text or '');
    local labelText = tostring(bar.labelText or '');

    if (barText == '' and labelText == '' and bar.iconTextureId == nil) then
        return;
    end

    local textOptions = {
        fontFamily = ResolveFontFamily(bar.fontFamily),
        fontFlags = tonumber(bar.fontFlags) or 0,
        fontSize = math.max(1, tonumber(bar.fontSize) or 12),
        color = bar.textColor or { 1.0, 1.0, 1.0, 1.0 },
        outlineEnabled = bar.textOutlineEnabled == true,
        outlineColor = bar.textOutlineColor or { 0.0, 0.0, 0.0, 1.0 },
        outlineSize = tonumber(bar.textOutlineSize) or 1,
    };
    local textTextureId, textW, textH = gdiTextTexture.GetTexture(barText, textOptions);
    local labelTextureId, labelW, labelH = gdiTextTexture.GetTexture(labelText, textOptions);

    if (barText == '') then
        textW = 0;
        textH = 0;
    end

    if (labelText == '') then
        labelW = 0;
        labelH = 0;
    end

    local iconSize = (bar.iconTextureId ~= nil) and math.max(1, tonumber(bar.iconSize) or textH or barH) or 0;
    local iconGap = (iconSize > 0 and textW ~= nil and textW > 0) and math.max(0, tonumber(bar.iconGap) or 4) or 0;
    local contentW = (tonumber(textW) or 0) + iconSize + iconGap;
    local contentH = math.max(tonumber(textH) or 0, iconSize);
    local contentX = barX + ((barW - contentW) * 0.5);
    local contentY = barY + ((barH - contentH) * 0.5);
    local iconX = contentX;
    local textX = contentX + iconSize + iconGap;
    local iconY = contentY + ((contentH - iconSize) * 0.5);
    local textY = contentY + ((contentH - (tonumber(textH) or 0)) * 0.5);

    if (bar.separateLabelOffsets == true) then
        iconX = barX + ((barW - iconSize) * 0.5) + (tonumber(bar.iconOffsetX) or 0);
        iconY = barY + ((barH - iconSize) * 0.5) + (tonumber(bar.iconOffsetY) or 0);
        textX = barX + ((barW - (tonumber(textW) or 0)) * 0.5) + (tonumber(bar.textOffsetX) or 0);
        textY = barY + ((barH - (tonumber(textH) or 0)) * 0.5) + (tonumber(bar.textOffsetY) or 0);
    else
        local sharedOffsetX = tonumber(bar.textOffsetX) or 0;
        iconX = iconX + sharedOffsetX;
        textX = textX + sharedOffsetX;
        local sharedOffsetY = tonumber(bar.textOffsetY) or 0;
        iconY = iconY + sharedOffsetY;
        textY = textY + sharedOffsetY;
    end

    if (iconSize > 0) then
        DrawTexture(device, bar.iconTextureId, iconX, iconY, iconSize, iconSize, 0xFFFFFFFF);
    elseif (bar.separateLabelOffsets == true and labelText ~= '' and labelTextureId ~= nil and labelW ~= nil and labelH ~= nil and labelW > 0 and labelH > 0) then
        DrawTexture(
            device,
            labelTextureId,
            barX + ((barW - labelW) * 0.5) + (tonumber(bar.iconOffsetX) or 0),
            barY + ((barH - labelH) * 0.5) + (tonumber(bar.iconOffsetY) or 0),
            labelW,
            labelH,
            0xFFFFFFFF
        );
    end

    if (barText ~= '' and textTextureId ~= nil and textW ~= nil and textH ~= nil and textW > 0 and textH > 0) then
        DrawTexture(device, textTextureId, textX, textY, textW, textH, 0xFFFFFFFF);
    end
end

local function DrawBar(device, centerX, centerY, bar, progress, defaultColor, resolvedRect)
    bar = bar or {};
    progress = math.max(0, math.min(100, tonumber(progress) or 100)) / 100;

    local barW = tonumber(bar.width) or 180;
    local barH = tonumber(bar.height) or 12;
    local barX = centerX - (barW * 0.5) + (tonumber(bar.offsetX) or 0);
    local barY = centerY - (barH * 0.5) + (tonumber(bar.offsetY) or 0);
    local borderSize = math.max(0, tonumber(bar.borderSize) or 0);
    local showAtPercent = math.max(1, math.min(100, tonumber(bar.showAtPercent) or 100));

    if (bar.enabled ~= true or (progress * 100) > showAtPercent) then
        return;
    end

    if (resolvedRect ~= nil) then
        local x1 = tonumber(resolvedRect.drawX1);
        local y1 = tonumber(resolvedRect.drawY1);
        local x2 = tonumber(resolvedRect.drawX2);
        local y2 = tonumber(resolvedRect.drawY2);

        if (x1 ~= nil and y1 ~= nil and x2 ~= nil and y2 ~= nil and x2 > x1 and y2 > y1) then
            barX = x1 + borderSize;
            barY = y1 + borderSize;
            barW = math.max(1, (x2 - x1) - (borderSize * 2));
            barH = math.max(1, (y2 - y1) - (borderSize * 2));
        end
    end

    if (borderSize > 0) then
        DrawRect(
            device,
            barX - borderSize,
            barY - borderSize,
            barW + (borderSize * 2),
            barH + (borderSize * 2),
            ColorToD3D(bar.borderColor, { 0.0, 0.0, 0.0, 1.0 })
        );
    end

    DrawRect(device, barX, barY, barW, barH, ColorToD3D(bar.backgroundColor, { 0.05, 0.05, 0.05, 0.85 }));

    if (bar.textureId ~= nil and tonumber(bar.textureId) ~= nil and tonumber(bar.textureId) ~= 0) then
        DrawTexture(device, bar.textureId, barX, barY, barW * progress, barH, ColorToD3D(bar.color, defaultColor), progress, 1);
    else
        DrawRect(device, barX, barY, barW * progress, barH, ColorToD3D(bar.color, defaultColor));
    end

    if (bar.animationEnabled == true) then
        DrawScrollingBarOverlay(device, barX, barY, barW, barH, progress, bar);
    end

    DrawBarLabel(device, barX, barY, barW, barH, bar);
end

local function DrawRingProgress(device, centerX, centerY, ring, progress, defaultColor, resolvedRect)
    ring = ring or {};
    progress = math.max(0, math.min(100, tonumber(progress) or 100)) / 100;

    if (ring.enabled ~= true) then
        return;
    end

    local size = math.max(8, tonumber(ring.ringSize) or tonumber(ring.width) or 88);
    local thickness = math.max(1, math.min(size * 0.45, tonumber(ring.ringThickness) or tonumber(ring.height) or 10));
    local ringX = centerX + (tonumber(ring.offsetX) or 0);
    local ringY = centerY + (tonumber(ring.offsetY) or 0);

    if (resolvedRect ~= nil) then
        local x1 = tonumber(resolvedRect.drawX1);
        local y1 = tonumber(resolvedRect.drawY1);
        local x2 = tonumber(resolvedRect.drawX2);
        local y2 = tonumber(resolvedRect.drawY2);

        if (x1 ~= nil and y1 ~= nil and x2 ~= nil and y2 ~= nil) then
            ringX = (x1 + x2) * 0.5;
            ringY = (y1 + y2) * 0.5;
        end
    end

    local outerRadius = size * 0.5;
    local innerRadius = outerRadius - thickness;
    local borderSize = math.max(0, tonumber(ring.borderSize) or 0);
    local startAngle = -math.pi * 0.5;
    local endAngle = startAngle + (math.pi * 2);

    if (borderSize > 0) then
        DrawRingSegment(
            device,
            ringX,
            ringY,
            outerRadius + borderSize,
            math.max(0, innerRadius - borderSize),
            startAngle,
            endAngle,
            ColorToD3D(ring.borderColor, { 0.0, 0.0, 0.0, 1.0 }),
            96
        );
    end

    DrawRingSegment(device, ringX, ringY, outerRadius, innerRadius, startAngle, endAngle, ColorToD3D(ring.backgroundColor, { 0.80, 0.82, 0.86, 0.80 }), 96);
    DrawRingSegment(device, ringX, ringY, outerRadius, innerRadius, startAngle, startAngle + ((math.pi * 2) * progress), ColorToD3D(ring.color, defaultColor), 96);

    local ringText = tostring(ring.text or '');
    if (ringText ~= '') then
        local textTextureId, textW, textH = gdiTextTexture.GetTexture(ringText, {
            fontFamily = ResolveFontFamily(ring.fontFamily),
            fontFlags = tonumber(ring.fontFlags) or 0,
            fontSize = math.max(1, tonumber(ring.fontSize) or 12),
            color = ring.textColor or { 1.0, 1.0, 1.0, 1.0 },
            outlineEnabled = ring.textOutlineEnabled == true,
            outlineColor = ring.textOutlineColor or { 0.0, 0.0, 0.0, 1.0 },
            outlineSize = tonumber(ring.textOutlineSize) or 1,
        });

        if (textTextureId ~= nil and textW ~= nil and textH ~= nil and textW > 0 and textH > 0) then
            DrawTexture(
                device,
                textTextureId,
                ringX - (textW * 0.5) + (tonumber(ring.textOffsetX) or 0),
                ringY - (textH * 0.5) + (tonumber(ring.textOffsetY) or 0),
                textW,
                textH,
                0xFFFFFFFF
            );
        end
    end
end

local function DrawPlateBackground(device, centerX, centerY, background, resolvedRect)
    background = background or {};

    if (background.enabled ~= true) then
        return;
    end

    local bgW = tonumber(background.width) or 220;
    local bgH = tonumber(background.height) or 74;
    local bgX = centerX - (bgW * 0.5) + (tonumber(background.offsetX) or 0);
    local bgY = centerY - (bgH * 0.5) + (tonumber(background.offsetY) or 0);
    local borderSize = math.max(0, tonumber(background.borderSize) or 0);

    if (resolvedRect ~= nil) then
        bgX = tonumber(resolvedRect.drawX1) or bgX;
        bgY = tonumber(resolvedRect.drawY1) or bgY;
        bgW = math.max(1, (tonumber(resolvedRect.drawX2) or (bgX + bgW)) - bgX);
        bgH = math.max(1, (tonumber(resolvedRect.drawY2) or (bgY + bgH)) - bgY);
    end

    if (background.textureId ~= nil) then
        local textureAlpha = tonumber(background.color ~= nil and background.color[4] or nil);
        DrawTexture(device, background.textureId, bgX, bgY, bgW, bgH, ColorToD3D({ 1.0, 1.0, 1.0, textureAlpha }, { 1.0, 1.0, 1.0, 0.45 }));
    else
        DrawRect(device, bgX, bgY, bgW, bgH, ColorToD3D(background.color, { 0.0, 0.0, 0.0, 0.45 }));
    end

    if (borderSize > 0) then
        local borderColor = ColorToD3D(background.borderColor, { 0.0, 0.0, 0.0, 0.80 });
        local border = math.min(borderSize, math.floor(math.min(bgW, bgH) * 0.5));

        DrawRect(device, bgX, bgY, bgW, border, borderColor);
        DrawRect(device, bgX, bgY + bgH - border, bgW, border, borderColor);
        DrawRect(device, bgX, bgY + border, border, bgH - (border * 2), borderColor);
        DrawRect(device, bgX + bgW - border, bgY + border, border, bgH - (border * 2), borderColor);
    end
end

local function DrawTpBar(device, centerX, centerY, bar, progress, defaultColor, resolvedRect)
    bar = bar or {};
    progress = math.max(0, math.min(300, tonumber(progress) or 0));

    if (bar.segmented ~= true) then
        DrawBar(device, centerX, centerY, bar, progress / 3, defaultColor, resolvedRect);
        return;
    end

    local barW = tonumber(bar.width) or 180;
    local barH = tonumber(bar.height) or 6;
    local barX = centerX - (barW * 0.5) + (tonumber(bar.offsetX) or 0);
    local barY = centerY - (barH * 0.5) + (tonumber(bar.offsetY) or 0);
    local borderSize = math.max(0, tonumber(bar.borderSize) or 0);
    local showAtPercent = math.max(1, math.min(300, tonumber(bar.showAtPercent) or 300));
    local gap = math.max(6, tonumber(bar.segmentGap) or 6);
    local segmentW = math.max(1, (barW - (gap * 2)) / 3);
    local section2Color = bar.color2 or { 0.80, 0.45, 1.0, 0.95 };
    local section3Color = bar.color3 or { 0.35, 0.75, 1.0, 0.95 };

    if (bar.enabled ~= true or progress > showAtPercent) then
        return;
    end

    if (resolvedRect ~= nil) then
        local x1 = tonumber(resolvedRect.drawX1);
        local y1 = tonumber(resolvedRect.drawY1);
        local x2 = tonumber(resolvedRect.drawX2);
        local y2 = tonumber(resolvedRect.drawY2);

        if (x1 ~= nil and y1 ~= nil and x2 ~= nil and y2 ~= nil and x2 > x1 and y2 > y1) then
            barX = x1 + borderSize;
            barY = y1 + borderSize;
            barW = math.max(1, (x2 - x1) - (borderSize * 2));
            barH = math.max(1, (y2 - y1) - (borderSize * 2));
            segmentW = math.max(1, (barW - (gap * 2)) / 3);
        end
    end

    for segment = 1, 3 do
        local segmentProgress = math.max(0, math.min(1, (progress / 100) - (segment - 1)));
        local segmentX = barX + ((segment - 1) * (segmentW + gap));
        local segmentColor = bar.color;

        if (segment == 2) then
            segmentColor = section2Color;
        elseif (segment == 3) then
            segmentColor = section3Color;
        end

        if (borderSize > 0) then
            DrawRect(
                device,
                segmentX - borderSize,
                barY - borderSize,
                segmentW + (borderSize * 2),
                barH + (borderSize * 2),
                ColorToD3D(bar.borderColor, { 0.0, 0.0, 0.0, 1.0 })
            );
        end

        DrawRect(device, segmentX, barY, segmentW, barH, ColorToD3D(bar.backgroundColor, { 0.05, 0.05, 0.05, 0.85 }));

        if (segmentProgress > 0) then
            if (bar.textureId ~= nil and tonumber(bar.textureId) ~= nil and tonumber(bar.textureId) ~= 0) then
                DrawTexture(device, bar.textureId, segmentX, barY, segmentW * segmentProgress, barH, ColorToD3D(segmentColor, defaultColor), segmentProgress, 1);
            else
                DrawRect(device, segmentX, barY, segmentW * segmentProgress, barH, ColorToD3D(segmentColor, defaultColor));
            end
        end
    end

    DrawBarLabel(device, barX, barY, barW, barH, bar);
end

local function AddRect(rects, x, y, w, h, padding, kind, layout, anchorOnly)
    local pad = tonumber(padding) or 0;

    if (((tonumber(w) or 0) <= 0 or (tonumber(h) or 0) <= 0) and anchorOnly ~= true) then
        return;
    end

    local drawX1 = tonumber(x) or 0;
    local drawY1 = tonumber(y) or 0;
    local drawX2 = drawX1 + (tonumber(w) or 0);
    local drawY2 = drawY1 + (tonumber(h) or 0);
    local x1 = drawX1 - pad;
    local y1 = drawY1 - pad;
    local x2 = drawX2 + pad;
    local y2 = drawY2 + pad;

    rects[#rects + 1] = {
        kind = kind,
        x1 = x1,
        y1 = y1,
        x2 = x2,
        y2 = y2,
        drawX1 = drawX1,
        drawY1 = drawY1,
        drawX2 = drawX2,
        drawY2 = drawY2,
        baseX1 = drawX1,
        baseY1 = drawY1,
        baseX2 = drawX2,
        baseY2 = drawY2,
        padding = pad,
        anchorLayout = layout,
        anchorOnly = anchorOnly == true,
    };
end

local function HasRectKind(rects, kind)
    local wanted = tostring(kind or '');

    if (wanted == '') then
        return false;
    end

    for _, rect in ipairs(rects or {}) do
        if (tostring(rect.kind or '') == wanted) then
            return true;
        end
    end

    return false;
end

local function RectToBounds(rect)
    if (rect == nil) then
        return nil;
    end

    return {
        x = tonumber(rect.drawX1) or tonumber(rect.x1) or 0,
        y = tonumber(rect.drawY1) or tonumber(rect.y1) or 0,
        width = (tonumber(rect.drawX2) or tonumber(rect.x2) or 0) - (tonumber(rect.drawX1) or tonumber(rect.x1) or 0),
        height = (tonumber(rect.drawY2) or tonumber(rect.y2) or 0) - (tonumber(rect.drawY1) or tonumber(rect.y1) or 0),
    };
end

local function BuildBoundsByKind(rects)
    local bounds = {};

    for _, rect in ipairs(rects or {}) do
        local key = tostring(rect.kind or '');

        if (key ~= '' and bounds[key] == nil) then
            bounds[key] = RectToBounds(rect);
        end
    end

    return bounds;
end

local function ResolveAnchorRects(rects, plate)
    local anchorMap = (plate ~= nil and plate.anchorMap) or {
        ['Background'] = 'background',
        ['Name'] = 'name',
        ['HP Bar'] = 'hp',
        ['MP Bar'] = 'mp',
        ['TP Bar'] = 'tp',
        ['Cast bar'] = 'cast',
        ['Job'] = 'job',
        ['Level'] = 'level',
        ['ID'] = 'id',
        ['Icon'] = 'icon',
        ['Game mode icon'] = 'gameModeIcon',
        ['Linkshell icon'] = 'linkshellIcon',
        ['Bazaar icon'] = 'bazaarIcon',
        ['Away icon'] = 'awayIcon',
        ['Disconnect icon'] = 'disconnectIcon',
        ['Anon icon'] = 'anonIcon',
        ['Follow icon'] = 'followIcon',
        ['Party leader icon'] = 'partyLeaderIcon',
        ['Alliance leader icon'] = 'allianceLeaderIcon',
        ['Stars icon'] = 'starsIcon',
        ['Level sync icon'] = 'levelSyncIcon',
        ['New adventurer icon'] = 'newAdventurerIcon',
        ['Buffs'] = 'buffs',
        ['Debuffs'] = 'debuffs',
        ['Type line'] = 'type',
        ['Distance'] = 'distance',
    };
    local hasFallbacks = plate ~= nil and type(plate.anchorFallbackRects) == 'table' and #plate.anchorFallbackRects > 0;
    local fallbackDefs = {};

    for _, fallbackRect in ipairs((plate ~= nil and plate.anchorFallbackRects) or {}) do
        local key = tostring(fallbackRect ~= nil and fallbackRect.kind or '');

        if (key ~= '' and fallbackDefs[key] == nil) then
            fallbackDefs[key] = {
                x = tonumber(fallbackRect.x) or 0,
                y = tonumber(fallbackRect.y) or 0,
                width = tonumber(fallbackRect.w) or 0,
                height = tonumber(fallbackRect.h) or 0,
                layout = fallbackRect.layout,
            };
        end
    end
    local fallbackResolvedCache = {};

    local function ResolveMissingAnchorSlot(anchorName, bounds, stack)
        anchorName = tostring(anchorName or '');

        if (anchorName == '') then
            return nil;
        end

        if (fallbackResolvedCache[anchorName] ~= nil) then
            return fallbackResolvedCache[anchorName];
        end

        local targetKey = anchorMap[anchorName];

        if (targetKey ~= nil and bounds[targetKey] ~= nil) then
            fallbackResolvedCache[anchorName] = bounds[targetKey];
            return bounds[targetKey];
        end

        local fallback = fallbackDefs[anchorName];

        if (fallback == nil) then
            return nil;
        end

        stack = stack or {};

        if (stack[anchorName] == true) then
            local result = {
                x = fallback.x,
                y = fallback.y,
                width = fallback.width,
                height = fallback.height,
            };
            fallbackResolvedCache[anchorName] = result;
            return result;
        end

        stack[anchorName] = true;

        local defaultRect = {
            x = fallback.x,
            y = fallback.y,
            width = fallback.width,
            height = fallback.height,
        };
        local layout = fallback.layout;

        if (layout == nil or tostring(layout.anchorTo or 'Plate') == 'Plate') then
            stack[anchorName] = nil;
            fallbackResolvedCache[anchorName] = defaultRect;
            return defaultRect;
        end

        local parentAnchorName = tostring(layout.anchorTo or 'Plate');
        local parentRect = ResolveMissingAnchorSlot(parentAnchorName, bounds, stack);

        if (parentRect == nil) then
            stack[anchorName] = nil;
            fallbackResolvedCache[anchorName] = defaultRect;
            return defaultRect;
        end

        local tempBounds = {};

        for key, value in pairs(bounds or {}) do
            tempBounds[key] = value;
        end

        local parentTargetKey = anchorMap[parentAnchorName];

        if (parentTargetKey ~= nil) then
            tempBounds[parentTargetKey] = parentRect;
        end

        local resolved = anchorGeometry.ResolveAnchoredRect(layout, anchorName, defaultRect, tempBounds, anchorMap);
        stack[anchorName] = nil;
        fallbackResolvedCache[anchorName] = resolved;
        return resolved;
    end

    for _ = 1, 12 do
        local bounds = BuildBoundsByKind(rects);
        local changed = false;
        fallbackResolvedCache = {};

        for _, rect in ipairs(rects or {}) do
            local layout = rect.anchorLayout;

            if (layout ~= nil and tostring(layout.anchorTo or 'Plate') ~= 'Plate') then
                local defaultRect = {
                    x = tonumber(rect.baseX1) or tonumber(rect.x1) or 0,
                    y = tonumber(rect.baseY1) or tonumber(rect.y1) or 0,
                    width = (tonumber(rect.baseX2) or tonumber(rect.x2) or 0) - (tonumber(rect.baseX1) or tonumber(rect.x1) or 0),
                    height = (tonumber(rect.baseY2) or tonumber(rect.y2) or 0) - (tonumber(rect.baseY1) or tonumber(rect.y1) or 0),
                };
                local anchorTo = tostring(layout.anchorTo or 'Plate');
                local targetKey = anchorMap[anchorTo];
                local fallbackTarget = (hasFallbacks == true and targetKey ~= nil and bounds[targetKey] == nil) and ResolveMissingAnchorSlot(anchorTo, bounds) or nil;
                local resolved = nil;

                if (fallbackTarget ~= nil) then
                    resolved = {
                        x = tonumber(fallbackTarget.x) or 0,
                        y = tonumber(fallbackTarget.y) or 0,
                        width = defaultRect.width,
                        height = defaultRect.height,
                    };
                else
                    resolved = anchorGeometry.ResolveAnchoredRect(layout, tostring(rect.kind or ''), defaultRect, bounds, anchorMap);
                end

                local pad = tonumber(rect.padding) or 0;
                local oldX1 = tonumber(rect.drawX1) or 0;
                local oldY1 = tonumber(rect.drawY1) or 0;
                local oldX2 = tonumber(rect.drawX2) or 0;
                local oldY2 = tonumber(rect.drawY2) or 0;

                rect.drawX1 = resolved.x;
                rect.drawY1 = resolved.y;
                rect.drawX2 = resolved.x + resolved.width;
                rect.drawY2 = resolved.y + resolved.height;
                rect.x1 = rect.drawX1 - pad;
                rect.y1 = rect.drawY1 - pad;
                rect.x2 = rect.drawX2 + pad;
                rect.y2 = rect.drawY2 + pad;

                if (
                    math.abs((tonumber(rect.drawX1) or 0) - oldX1) > 0.01 or
                    math.abs((tonumber(rect.drawY1) or 0) - oldY1) > 0.01 or
                    math.abs((tonumber(rect.drawX2) or 0) - oldX2) > 0.01 or
                    math.abs((tonumber(rect.drawY2) or 0) - oldY2) > 0.01
                ) then
                    changed = true;
                end
            end
        end

        if (changed ~= true) then
            break;
        end
    end
end

local function FindRect(rects, kind, occurrence)
    local wanted = tostring(kind or '');
    local index = 0;
    local target = math.max(1, tonumber(occurrence) or 1);

    for _, rect in ipairs(rects or {}) do
        if (tostring(rect.kind or '') == wanted) then
            index = index + 1;

            if (index == target) then
                return rect;
            end
        end
    end

    return nil;
end

local function AddBarRect(rects, centerX, centerY, bar, progress, kind)
    bar = bar or {};
    progress = math.max(0, math.min(100, tonumber(progress) or 100));

    local showAtPercent = math.max(1, math.min(100, tonumber(bar.showAtPercent) or 100));

    if (bar.enabled ~= true) then
        return;
    end

    local isRing = tostring(bar.displayMode or '') == 'Ring';
    local barW = isRing and math.max(8, tonumber(bar.ringSize) or tonumber(bar.width) or 88) or (tonumber(bar.width) or 180);
    local barH = isRing and barW or (tonumber(bar.height) or 12);
    local barX = centerX - (barW * 0.5) + (tonumber(bar.offsetX) or 0);
    local barY = centerY - (barH * 0.5) + (tonumber(bar.offsetY) or 0);
    local borderSize = math.max(0, tonumber(bar.borderSize) or 0);
    local hiddenByThreshold = progress > showAtPercent;

    AddRect(rects, barX - borderSize, barY - borderSize, barW + (borderSize * 2), barH + (borderSize * 2), 4, kind, bar, hiddenByThreshold);

    if (hiddenByThreshold == true) then
        return;
    end

    local barText = tostring(bar.text or '');
    local labelText = tostring(bar.labelText or '');

    if (barText == '' and labelText == '' and bar.iconTextureId == nil) then
        return;
    end

    local textOptions = {
        fontFamily = ResolveFontFamily(bar.fontFamily),
        fontFlags = tonumber(bar.fontFlags) or 0,
        fontSize = math.max(1, tonumber(bar.fontSize) or 12),
        color = bar.textColor or { 1.0, 1.0, 1.0, 1.0 },
        outlineEnabled = bar.textOutlineEnabled == true,
        outlineColor = bar.textOutlineColor or { 0.0, 0.0, 0.0, 1.0 },
        outlineSize = tonumber(bar.textOutlineSize) or 1,
    };
    local _, textW, textH = gdiTextTexture.GetTexture(barText, textOptions);
    local _, labelW, labelH = gdiTextTexture.GetTexture(labelText, textOptions);

    if (barText == '') then
        textW = 0;
        textH = 0;
    end

    if (labelText == '') then
        labelW = 0;
        labelH = 0;
    end

    local iconSize = (bar.iconTextureId ~= nil) and math.max(1, tonumber(bar.iconSize) or textH or barH) or 0;
    local iconGap = (iconSize > 0 and textW ~= nil and textW > 0) and math.max(0, tonumber(bar.iconGap) or 4) or 0;
    local contentW = (tonumber(textW) or 0) + iconSize + iconGap;
    local contentH = math.max(tonumber(textH) or 0, iconSize);
    local contentX = barX + ((barW - contentW) * 0.5);
    local contentY = barY + ((barH - contentH) * 0.5);
    local iconX = contentX;
    local iconY = contentY + ((contentH - iconSize) * 0.5);
    local textX = contentX + iconSize + iconGap;
    local textY = contentY + ((contentH - (tonumber(textH) or 0)) * 0.5);

    if (bar.separateLabelOffsets == true) then
        iconX = barX + ((barW - iconSize) * 0.5) + (tonumber(bar.iconOffsetX) or 0);
        iconY = barY + ((barH - iconSize) * 0.5) + (tonumber(bar.iconOffsetY) or 0);
        textX = barX + ((barW - (tonumber(textW) or 0)) * 0.5) + (tonumber(bar.textOffsetX) or 0);
        textY = barY + ((barH - (tonumber(textH) or 0)) * 0.5) + (tonumber(bar.textOffsetY) or 0);
    else
        local sharedOffsetX = tonumber(bar.textOffsetX) or 0;
        local sharedOffsetY = tonumber(bar.textOffsetY) or 0;
        iconX = iconX + sharedOffsetX;
        iconY = iconY + sharedOffsetY;
        textX = textX + sharedOffsetX;
        textY = textY + sharedOffsetY;
    end

    if (iconSize > 0) then
        AddRect(rects, iconX, iconY, iconSize, iconSize, 4, kind);
    elseif (bar.separateLabelOffsets == true and labelText ~= '' and labelW ~= nil and labelH ~= nil and labelW > 0 and labelH > 0) then
        AddRect(
            rects,
            barX + ((barW - labelW) * 0.5) + (tonumber(bar.iconOffsetX) or 0),
            barY + ((barH - labelH) * 0.5) + (tonumber(bar.iconOffsetY) or 0),
            labelW,
            labelH,
            4,
            kind
        );
    end

    if (barText ~= '' and textW ~= nil and textH ~= nil and textW > 0 and textH > 0) then
        AddRect(rects, textX, textY, textW, textH, 4, kind);
    end
end

local function GetBadgeRect(centerX, centerY, badge)
    badge = badge or {};

    local textValue = tostring(badge.text or '');
    local labelValue = tostring(badge.labelText or '');
    local hasIcon = badge.iconTextureId ~= nil;

    if (textValue == '' and labelValue == '' and hasIcon ~= true) then
        return nil;
    end

    local textW = 0;
    local textH = 0;

    if (textValue ~= '') then
        local _, measuredW, measuredH = gdiTextTexture.GetTexture(textValue, {
            fontFamily = ResolveFontFamily(badge.fontFamily),
            fontFlags = tonumber(badge.fontFlags) or 0,
            fontSize = math.max(8, tonumber(badge.fontSize) or 12),
            color = badge.textColor or { 1.0, 1.0, 1.0, 1.0 },
            outlineEnabled = badge.textOutlineEnabled == true,
            outlineColor = badge.textOutlineColor or { 0.0, 0.0, 0.0, 1.0 },
            outlineSize = tonumber(badge.textOutlineSize) or 0,
        });

        if (measuredW == nil or measuredH == nil or measuredW <= 0 or measuredH <= 0) then
            return nil;
        end

        textW = measuredW;
        textH = measuredH;
    end

    local iconSize = 0;
    local iconGap = 0;

    if (hasIcon == true) then
        iconSize = math.max(1, tonumber(badge.iconSize) or textH or 16);
        iconGap = math.max(0, tonumber(badge.iconGap) or 4);
    end

    local padX = math.max(0, tonumber(badge.paddingX) or 0);
    local padY = math.max(0, tonumber(badge.paddingY) or 0);
    local contentW = textW + iconSize + ((iconSize > 0 and textW > 0) and iconGap or 0);
    local contentH = math.max(textH, iconSize);
    local badgeW = math.max(tonumber(badge.minWidth) or 0, contentW + (padX * 2));
    local badgeH = math.max(tonumber(badge.minHeight) or 0, contentH + (padY * 2));
    local badgeX = centerX - (badgeW * 0.5) + (tonumber(badge.offsetX) or 0);
    local badgeY = centerY - (badgeH * 0.5) + (tonumber(badge.offsetY) or 0);

    return {
        x = badgeX,
        y = badgeY,
        w = badgeW,
        h = badgeH,
        textW = textW,
        textH = textH,
        iconSize = iconSize,
        iconGap = iconGap,
        contentW = contentW,
        contentH = contentH,
    };
end

local function DrawBadge(device, centerX, centerY, badge, resolvedRect)
    local rect = GetBadgeRect(centerX, centerY, badge);

    if (rect == nil) then
        return;
    end

    if (resolvedRect ~= nil) then
        local x = tonumber(resolvedRect.drawX1);
        local y = tonumber(resolvedRect.drawY1);

        if (x ~= nil and y ~= nil) then
            rect.x = x;
            rect.y = y;
        end
    end

    if (badge.backgroundEnabled == true) then
        DrawRoundedRectWithBorder(
            device,
            rect.x,
            rect.y,
            rect.w,
            rect.h,
            ColorToD3D(badge.backgroundColor, { 0.08, 0.08, 0.08, 0.70 }),
            ColorToD3D(badge.borderColor, { 1.0, 1.0, 1.0, 0.70 }),
            badge.borderSize,
            badge.cornerRadius
        );
    end

    if (badge.separateLabelOffsets == true) then
        local textOptions = {
            fontFamily = ResolveFontFamily(badge.fontFamily),
            fontFlags = tonumber(badge.fontFlags) or 0,
            fontSize = math.max(8, tonumber(badge.fontSize) or 12),
            color = badge.textColor or { 1.0, 1.0, 1.0, 1.0 },
            outlineEnabled = badge.textOutlineEnabled == true,
            outlineColor = badge.textOutlineColor or { 0.0, 0.0, 0.0, 1.0 },
            outlineSize = tonumber(badge.textOutlineSize) or 0,
        };

        if (badge.iconTextureId ~= nil and rect.iconSize > 0) then
            DrawTexture(
                device,
                badge.iconTextureId,
                centerX + (tonumber(badge.offsetX) or 0) + (tonumber(badge.labelOffsetX) or 0) - (rect.iconSize * 0.5),
                centerY + (tonumber(badge.offsetY) or 0) + (tonumber(badge.labelOffsetY) or 0) - (rect.iconSize * 0.5),
                rect.iconSize,
                rect.iconSize,
                0xFFFFFFFF
            );
        elseif (tostring(badge.labelText or '') ~= '') then
            local labelTextureId, labelW, labelH = gdiTextTexture.GetTexture(tostring(badge.labelText or ''), textOptions);

            if (labelTextureId ~= nil and labelW ~= nil and labelH ~= nil and labelW > 0 and labelH > 0) then
                DrawTexture(
                    device,
                    labelTextureId,
                    centerX + (tonumber(badge.offsetX) or 0) + (tonumber(badge.labelOffsetX) or 0) - (labelW * 0.5),
                    centerY + (tonumber(badge.offsetY) or 0) + (tonumber(badge.labelOffsetY) or 0) - (labelH * 0.5),
                    labelW,
                    labelH,
                    0xFFFFFFFF
                );
            end
        end

        if (tostring(badge.text or '') ~= '') then
            local textTextureId, textW, textH = gdiTextTexture.GetTexture(tostring(badge.text or ''), textOptions);

            if (textTextureId ~= nil and textW ~= nil and textH ~= nil and textW > 0 and textH > 0) then
                DrawTexture(
                    device,
                    textTextureId,
                    centerX + (tonumber(badge.offsetX) or 0) + (tonumber(badge.textOffsetX) or 0) - (textW * 0.5),
                    centerY + (tonumber(badge.offsetY) or 0) + (tonumber(badge.textOffsetY) or 0) - (textH * 0.5),
                    textW,
                    textH,
                    0xFFFFFFFF
                );
            end
        end

        return;
    end

    local contentX = rect.x + ((rect.w - rect.contentW) * 0.5);
    local contentY = rect.y + ((rect.h - rect.contentH) * 0.5);

    if (badge.iconTextureId ~= nil and rect.iconSize > 0) then
        DrawTexture(
            device,
            badge.iconTextureId,
            contentX,
            contentY + ((rect.contentH - rect.iconSize) * 0.5),
            rect.iconSize,
            rect.iconSize,
            0xFFFFFFFF
        );

        contentX = contentX + rect.iconSize + ((rect.textW > 0) and rect.iconGap or 0);
    end

    if (tostring(badge.text or '') ~= '') then
        local textTextureId, textW, textH = gdiTextTexture.GetTexture(tostring(badge.text or ''), {
            fontFamily = ResolveFontFamily(badge.fontFamily),
            fontFlags = tonumber(badge.fontFlags) or 0,
            fontSize = math.max(8, tonumber(badge.fontSize) or 12),
            color = badge.textColor or { 1.0, 1.0, 1.0, 1.0 },
            outlineEnabled = badge.textOutlineEnabled == true,
            outlineColor = badge.textOutlineColor or { 0.0, 0.0, 0.0, 1.0 },
            outlineSize = tonumber(badge.textOutlineSize) or 0,
        });

        if (textTextureId ~= nil and textW ~= nil and textH ~= nil and textW > 0 and textH > 0) then
            DrawTexture(
                device,
                textTextureId,
                contentX,
                contentY + ((rect.contentH - textH) * 0.5),
                textW,
                textH,
                0xFFFFFFFF
            );
        end
    end
end

function canvasTexture.GetElementRects(plate)
    local rects = {};

    if (plate == nil) then
        return rects;
    end

    local centerX = width * 0.5;
    local centerY = height * 0.5;
    local hp = math.max(0, math.min(100, tonumber(plate.hp) or 100));
    local mp = math.max(0, math.min(100, tonumber(plate.mp) or 100));

    if (plate.background ~= nil and plate.background.enabled == true) then
        local background = plate.background;
        local bgW = tonumber(background.width) or 220;
        local bgH = tonumber(background.height) or 74;
        local bgX = centerX - (bgW * 0.5) + (tonumber(background.offsetX) or 0);
        local bgY = centerY - (bgH * 0.5) + (tonumber(background.offsetY) or 0);

        AddRect(
            rects,
            bgX,
            bgY,
            bgW,
            bgH,
            0,
            'background',
            background
        );
    end

    AddBarRect(rects, centerX, centerY, plate.hpBar, hp, 'hp');
    AddBarRect(rects, centerX, centerY, plate.mpBar, mp, 'mp');
    AddBarRect(rects, centerX, centerY, plate.tpBar, math.max(0, math.min(100, tonumber(plate.tp) or 0)), 'tp');
    AddBarRect(rects, centerX, centerY, plate.castBar, math.max(0, math.min(100, tonumber(plate.cast) or 0)), 'cast');

    for _, extraBar in ipairs(plate.extraBars or {}) do
        AddBarRect(rects, centerX, centerY, extraBar, math.max(0, math.min(100, tonumber(extraBar.progress) or 0)), extraBar.kind or 'bar');
    end

    for _, badge in ipairs(plate.badges or {}) do
        local rect = GetBadgeRect(centerX, centerY, badge);

        if (rect ~= nil) then
            AddRect(rects, rect.x, rect.y, rect.w, rect.h, 4, badge.kind or 'badge', badge);
        end
    end

    for _, icon in ipairs(plate.icons or {}) do
        local iconSize = tonumber(icon.size) or 16;

        AddRect(
            rects,
            centerX - (iconSize * 0.5) + (tonumber(icon.offsetX) or 0),
            centerY - (iconSize * 0.5) + (tonumber(icon.offsetY) or 0),
            iconSize,
            iconSize,
            4,
            icon.kind or 'icon',
            icon
        );
    end

    local jobText = tostring(plate.jobText or '');

    if (jobText ~= '') then
        local _, jobW, jobH = gdiTextTexture.GetTexture(jobText, {
            fontFamily = ResolveFontFamily(plate.jobFontFamily or plate.nameFontFamily),
            fontFlags = tonumber(plate.jobFontFlags or plate.nameFontFlags) or 0,
            fontSize = math.max(8, tonumber(plate.jobFontSize) or 12),
            color = plate.jobColor or { 1.0, 1.0, 1.0, 1.0 },
            outlineEnabled = plate.jobOutlineEnabled == true,
            outlineColor = plate.jobOutlineColor or { 0.0, 0.0, 0.0, 1.0 },
            outlineSize = tonumber(plate.jobOutlineSize) or 0,
        });

        if (jobW ~= nil and jobH ~= nil and jobW > 0 and jobH > 0) then
            AddRect(
                rects,
                centerX - (jobW * 0.5) + (tonumber(plate.jobOffsetX) or 0),
                centerY - (jobH * 0.5) + (tonumber(plate.jobOffsetY) or -54),
                jobW,
                jobH,
                4,
                'job',
                {
                    anchorTo = plate.jobAnchorTo,
                    anchorPoint = plate.jobAnchorPoint,
                    offsetX = plate.jobOffsetX,
                    offsetY = plate.jobOffsetY,
                }
            );
        end
    end

    local plateName = nativeUiPolicy.ShouldDrawLibraNames() == true and tostring(plate.name or '') or '';

    if (plateName ~= '') then
        local manualOutlineRadius = GetManualNameOutlineRadius(plate.nameOutlineSize);
        local nameFontSize = GetNameFontSize(plate, plateName);
        local renderFontSize = GetNameRenderFontSize(nameFontSize);
        local renderScale = GetNameRenderScale(nameFontSize, renderFontSize);
        local _, nameW, nameH = gdiTextTexture.GetTexture(plateName, {
            fontFamily = ResolveFontFamily(plate.nameFontFamily),
            fontFlags = tonumber(plate.nameFontFlags) or 0,
            fontSize = renderFontSize,
            color = plate.nameColor or { 1.0, 1.0, 1.0, 1.0 },
            outlineEnabled = plate.nameOutlineEnabled == true and manualOutlineRadius <= 0,
            outlineColor = plate.nameOutlineColor or { 0.0, 0.0, 0.0, 1.0 },
            outlineSize = tonumber(plate.nameOutlineSize) or 0,
        });

        if (nameW ~= nil and nameH ~= nil and nameW > 0 and nameH > 0) then
            local drawW = nameW * renderScale;
            local drawH = nameH * renderScale;
            local outlineRadius = manualOutlineRadius * renderScale;

            AddRect(
                rects,
                centerX - (drawW * 0.5) + (tonumber(plate.nameOffsetX) or 0) - outlineRadius,
                centerY - (drawH * 0.5) + (tonumber(plate.nameOffsetY) or -54) - outlineRadius,
                drawW + (outlineRadius * 2),
                drawH + (outlineRadius * 2),
                4,
                'name',
                {
                    anchorTo = plate.nameAnchorTo,
                    anchorPoint = plate.nameAnchorPoint,
                    offsetX = plate.nameOffsetX,
                    offsetY = plate.nameOffsetY,
                }
            );
        end
    end

    for _, text in ipairs(plate.texts or {}) do
        local textValue = tostring(text.text or '');

        if (textValue ~= '') then
            local _, textW, textH = gdiTextTexture.GetTexture(textValue, {
                fontFamily = ResolveFontFamily(text.fontFamily or plate.nameFontFamily),
                fontFlags = tonumber(text.fontFlags or plate.nameFontFlags) or 0,
                fontSize = math.max(8, tonumber(text.fontSize) or 12),
                color = text.color or { 1.0, 1.0, 1.0, 1.0 },
                outlineEnabled = text.outlineEnabled ~= false,
                outlineColor = text.outlineColor or { 0.0, 0.0, 0.0, 1.0 },
                outlineSize = tonumber(text.outlineSize) or 1,
            });

            if (textW ~= nil and textH ~= nil and textW > 0 and textH > 0) then
                local rectX = centerX + (tonumber(text.offsetX) or 0);

                if (text.align == 'center') then
                    rectX = rectX - (textW * 0.5);
                end

                AddRect(
                    rects,
                    rectX,
                    centerY + (tonumber(text.offsetY) or 0),
                    textW,
                    textH,
                    4,
                    text.kind or 'text',
                    text
                );
            end
        end
    end

    ResolveAnchorRects(rects, plate);

    return rects;
end

local function GetElementAnchorRect(rects, kinds)
    local allowed = nil;

    if (kinds ~= nil) then
        allowed = {};

        for _, kind in ipairs(kinds) do
            allowed[tostring(kind)] = true;
        end
    end

    local anchorRect = nil;

    for _, rect in ipairs(rects or {}) do
        if (allowed == nil or allowed[tostring(rect.kind or '')] == true) then
            local x1 = tonumber(rect.x1);
            local y1 = tonumber(rect.y1);
            local x2 = tonumber(rect.x2);
            local y2 = tonumber(rect.y2);

            if (x1 ~= nil and y1 ~= nil and x2 ~= nil and y2 ~= nil and x2 > x1 and y2 > y1) then
                if (anchorRect == nil or (x2 - x1) > (anchorRect.x2 - anchorRect.x1)) then
                    anchorRect = { x1 = x1, y1 = y1, x2 = x2, y2 = y2 };
                end
            end
        end
    end

    return anchorRect;
end

local function AddTargetMarkerBackgroundRect(rects, centerX, centerY, marker)
    if (marker == nil or marker.enabled ~= true or marker.showBackground ~= true) then
        return;
    end

    local targetW = tonumber(marker.width) or 220;
    local targetH = tonumber(marker.height) or 74;
    local bgW = tonumber(marker.backgroundWidth) or targetW;
    local bgH = tonumber(marker.backgroundHeight) or targetH;
    local bgX = centerX - (bgW * 0.5) + (tonumber(marker.backgroundOffsetX) or 0);
    local bgY = centerY - (bgH * 0.5) + (tonumber(marker.backgroundOffsetY) or 0);
    local anchorRect = marker.backgroundAnchorRect or marker.anchorRect;

    if (
        marker.backgroundAnchorToPlate == true and
        anchorRect ~= nil and
        tonumber(anchorRect.x1) ~= nil and
        tonumber(anchorRect.y1) ~= nil and
        tonumber(anchorRect.x2) ~= nil and
        tonumber(anchorRect.y2) ~= nil and
        tonumber(anchorRect.x2) > tonumber(anchorRect.x1) and
        tonumber(anchorRect.y2) > tonumber(anchorRect.y1)
    ) then
        local spacing = math.max(0, tonumber(marker.backgroundSpacing) or 0);
        bgX = tonumber(anchorRect.x1) - spacing + (tonumber(marker.backgroundOffsetX) or 0);
        bgY = tonumber(anchorRect.y1) - spacing + (tonumber(marker.backgroundOffsetY) or 0);
        bgW = math.max(1, (tonumber(anchorRect.x2) - tonumber(anchorRect.x1)) + (spacing * 2));
        bgH = math.max(1, (tonumber(anchorRect.y2) - tonumber(anchorRect.y1)) + (spacing * 2));
    end

    AddRect(rects, bgX, bgY, bgW, bgH, 0, 'targetModuleBackground');
end

local function GetTargetMarkerDistanceScale(marker)
    local distance = tonumber(marker.distance);

    if (distance == nil or distance <= 0) then
        return 1.0;
    end

    local minScale = tonumber(marker.arrowMinScale) or 0.45;
    local farMinDistance = math.max(1.0, tonumber(marker.arrowFarMinDistance) or 10.0);
    local farMinScale = math.max(minScale, math.min(tonumber(marker.arrowFarMinScale) or 6.0, 6.0));
    local farFullDistance = math.max(farMinDistance, tonumber(marker.arrowFarFullDistance) or 50.0);
    local maxScale = math.max(tonumber(marker.arrowMaxScale) or 10.00, farMinScale);

    maxScale = math.max(minScale, math.min(maxScale, 64.0));

    if (marker.arrowLockFarMinSize ~= false) then
        local t = math.max(0.0, math.min(1.0, (distance - 1.0) / (farFullDistance - 1.0)));
        return math.min(maxScale, minScale + ((farMinScale - minScale) * t));
    end

    if (marker.arrowScaleWithDistance == true) then
        return math.max(minScale, math.min(maxScale, distance / farMinDistance));
    end

    return 1.0;
end

local function AddTargetMarkerForegroundRects(rects, centerX, centerY, marker)
    if (marker == nil or marker.enabled ~= true) then
        return;
    end

    local targetW = tonumber(marker.width) or 220;
    local targetH = tonumber(marker.height) or 74;
    local baseY = centerY - (targetH * 0.5) + (tonumber(marker.offsetY) or -20);

    if ((marker.showArrow == true and marker.arrowTextureId ~= nil) or (marker.showLock == true and marker.lockTextureId ~= nil)) then
        local distanceScale = GetTargetMarkerDistanceScale(marker);
        local arrowW = (tonumber(marker.arrowWidth) or 20) * distanceScale;
        local arrowH = (tonumber(marker.arrowHeight) or 20) * distanceScale;
        local lockW = tonumber(marker.lockWidth) or 18;
        local lockH = tonumber(marker.lockHeight) or 18;
        local arrowX = centerX + (tonumber(marker.arrowOffsetX) or 0);
        local arrowY = baseY - (tonumber(marker.arrowSpacing) or 10) + (tonumber(marker.arrowOffsetY) or 0);
        local arrowAnchorRect = marker.arrowAnchorRect;

        if (
            marker.arrowAnchorToName == true and
            arrowAnchorRect ~= nil and
            tonumber(arrowAnchorRect.x1) ~= nil and
            tonumber(arrowAnchorRect.y1) ~= nil and
            tonumber(arrowAnchorRect.x2) ~= nil and
            tonumber(arrowAnchorRect.x2) > tonumber(arrowAnchorRect.x1)
        ) then
            local spacing = math.max(0, tonumber(marker.arrowSpacing) or 0);

            arrowX = ((tonumber(arrowAnchorRect.x1) + tonumber(arrowAnchorRect.x2)) * 0.5) + (tonumber(marker.arrowOffsetX) or 0);
            arrowY = tonumber(arrowAnchorRect.y1) - spacing - (arrowH * 0.5) + (tonumber(marker.arrowOffsetY) or 0);
        end

        local canvasH = centerY * 2;
        local margin = 4;
        arrowY = math.max((arrowH * 0.5) + margin, math.min(canvasH - (arrowH * 0.5) - margin, arrowY));

        if (marker.showLock == true and marker.lockTextureId ~= nil) then
            local lockX = arrowX + (tonumber(marker.lockOffsetX) or 0);
            local lockY = math.max((lockH * 0.5) + margin, arrowY - (arrowH * 0.5) - (lockH * 0.5) + (tonumber(marker.lockOffsetY) or -24));
            AddRect(rects, lockX - (lockW * 0.5), lockY - (lockH * 0.5), lockW, lockH, 4, 'targetModuleLock');
        end

        if (marker.showArrow == true and marker.arrowTextureId ~= nil) then
            AddRect(rects, arrowX - (arrowW * 0.5), arrowY - (arrowH * 0.5), arrowW, arrowH, 4, 'targetModuleArrow');
        end
    end

    if (marker.showChevrons ~= false and marker.chevronTextureId ~= nil) then
        local chevW = tonumber(marker.chevronWidth) or 24;
        local chevH = tonumber(marker.chevronHeight) or 32;
        local chevY = centerY - (chevH * 0.5) + (tonumber(marker.chevronOffsetY) or 0);
        local spacing = tonumber(marker.chevronSpacing);
        local manualOffsetX = tonumber(marker.chevronOffsetX) or 0;
        local leftX = nil;
        local rightX = nil;
        local anchorRect = marker.chevronAnchorRect or marker.anchorRect;

        if (
            marker.chevronAnchorToPlate == true and
            anchorRect ~= nil and
            tonumber(anchorRect.y1) ~= nil and
            tonumber(anchorRect.y2) ~= nil and
            tonumber(anchorRect.y2) > tonumber(anchorRect.y1)
        ) then
            chevY = ((tonumber(anchorRect.y1) + tonumber(anchorRect.y2)) * 0.5) - (chevH * 0.5) + (tonumber(marker.chevronOffsetY) or 0);
        end

        if (spacing ~= nil) then
            spacing = math.max(0, spacing);

            if (marker.chevronAnchorToPlate == true) then
                local gap = spacing * 0.05;
                local leftEdge = anchorRect ~= nil and tonumber(anchorRect.x1) or nil;
                local rightEdge = anchorRect ~= nil and tonumber(anchorRect.x2) or nil;

                if (leftEdge == nil or rightEdge == nil or rightEdge <= leftEdge) then
                    leftEdge = centerX - (targetW * 0.5);
                    rightEdge = centerX + (targetW * 0.5);
                end

                leftX = leftEdge - gap - (chevW * 0.5) + manualOffsetX;
                rightX = rightEdge + gap + (chevW * 0.5) + manualOffsetX;
            else
                local gap = spacing * 0.05;
                local edgeSpacing = math.max(28, (targetW * 0.5) + gap + (chevW * 0.5));

                edgeSpacing = math.min(edgeSpacing, 280);
                leftX = centerX - edgeSpacing + manualOffsetX;
                rightX = centerX + edgeSpacing + manualOffsetX;
            end
        else
            leftX = centerX + (tonumber(marker.chevronLeftX) or -110) + manualOffsetX;
            rightX = centerX + (tonumber(marker.chevronRightX) or 110) + manualOffsetX;
        end

        AddRect(rects, leftX - (chevW * 0.5), chevY, chevW, chevH, 4, 'targetModuleChevron');
        AddRect(rects, rightX - (chevW * 0.5), chevY, chevW, chevH, 4, 'targetModuleChevron');
    end
end

function canvasTexture.Render(plate, key)
    perfMeter.CountCanvasRender(plate, key);

    local oldWidth = width;
    local oldHeight = height;
    width = math.max(1024, tonumber(plate ~= nil and plate.canvasWidth) or oldWidth);
    height = math.max(512, tonumber(plate ~= nil and plate.canvasHeight) or oldHeight);

    local function Finish(resultTexture, resultWidth, resultHeight)
        width = oldWidth;
        height = oldHeight;
        return resultTexture, resultWidth, resultHeight;
    end

    local device = d3d.get_device();

    if (device == nil or device.CreateTexture == nil or plate == nil) then
        return Finish(nil, width, height);
    end

    local targetTexture = EnsureTexture(device, key);

    if (targetTexture == nil or targetTexture.GetSurfaceLevel == nil) then
        return Finish(nil, width, height);
    end

    local okSurface, hrSurface, surface = pcall(function()
        return targetTexture:GetSurfaceLevel(0);
    end);

    if (okSurface ~= true or hrSurface ~= C.S_OK or surface == nil) then
        return Finish(nil, width, height);
    end

    local okTarget, hrTarget, oldTarget = pcall(function()
        return device:GetRenderTarget();
    end);

    if (okTarget ~= true or hrTarget ~= C.S_OK or oldTarget == nil) then
        d3d.gc_safe_release(surface);
        return Finish(nil, width, height);
    end

    local _, saveZ = device:GetRenderState(D3DRS_ZENABLE);
    local _, saveLight = device:GetRenderState(D3DRS_LIGHTING);
    local _, saveBlend = device:GetRenderState(D3DRS_ALPHABLENDENABLE);
    local _, saveSrc = device:GetRenderState(D3DRS_SRCBLEND);
    local _, saveDst = device:GetRenderState(D3DRS_DESTBLEND);
    local _, saveFvf = device:GetVertexShader();
    local _, saveTex = device:GetTexture(0);
    local _, savePixelShader = device:GetPixelShader();

    local setOk, setHr = pcall(function()
        return device:SetRenderTarget(surface);
    end);

    if (setOk == true and setHr == C.S_OK) then
        pcall(function()
            device:Clear(0, nil, 1, 0x00000000, 1.0, 0);
            device:SetPixelShader(0);
            device:SetRenderState(D3DRS_ZENABLE, 0);
            device:SetRenderState(D3DRS_LIGHTING, 0);
            device:SetRenderState(D3DRS_ALPHABLENDENABLE, 1);
            device:SetRenderState(D3DRS_SRCBLEND, 5);
            device:SetRenderState(D3DRS_DESTBLEND, 6);

            local centerX = width * 0.5;
            local centerY = height * 0.5;
            local hp = math.max(0, math.min(100, tonumber(plate.hp) or 100)) / 100;
            local mp = math.max(0, math.min(100, tonumber(plate.mp) or 100));
            local tp = math.max(0, math.min(300, tonumber(plate.tp) or 0));
            local elementRects = canvasTexture.GetElementRects(plate);

            plate._elementRects = elementRects;

            local function PrepareTargetMarker(marker)
                if (marker == nil) then
                    return;
                end

                marker.anchorRect = GetElementAnchorRect(elementRects, marker.anchorKinds);
                marker.backgroundAnchorRect = GetElementAnchorRect(elementRects, marker.backgroundAnchorKinds or marker.anchorKinds);
                marker.chevronAnchorRect = GetElementAnchorRect(elementRects, marker.chevronAnchorKinds or marker.anchorKinds);
                marker.arrowAnchorRect = GetElementAnchorRect(elementRects, marker.arrowAnchorKinds);
                AddTargetMarkerBackgroundRect(elementRects, centerX, centerY, marker);
                AddTargetMarkerForegroundRects(elementRects, centerX, centerY, marker);

                for _, stackedMarker in ipairs(marker.stackedMarkers or {}) do
                    PrepareTargetMarker(stackedMarker);
                end
            end

            local function DrawTargetMarkerStack(marker, pass)
                if (marker == nil) then
                    return;
                end

                for _, stackedMarker in ipairs(marker.stackedMarkers or {}) do
                    DrawTargetMarker(device, centerX, centerY, stackedMarker, pass);
                end

                DrawTargetMarker(device, centerX, centerY, marker, pass);
            end

            PrepareTargetMarker(plate.targetMarker);

            DrawPlateBackground(device, centerX, centerY, plate.background, FindRect(elementRects, 'background'));
            DrawTargetMarkerStack(plate.targetMarker, 'background');
            DrawTargetMarkerStack(plate.targetMarker, 'foreground');
            DrawBar(device, centerX, centerY, plate.hpBar, hp * 100, { 0.20, 0.95, 0.34, 0.95 }, FindRect(elementRects, 'hp'));
            DrawBar(device, centerX, centerY, plate.mpBar, mp, { 0.25, 0.45, 1.0, 0.95 }, FindRect(elementRects, 'mp'));
            DrawTpBar(device, centerX, centerY, plate.tpBar, tp, { 1.0, 0.70, 0.18, 0.95 }, FindRect(elementRects, 'tp'));
            DrawBar(device, centerX, centerY, plate.castBar, math.max(0, math.min(100, tonumber(plate.cast) or 0)), { 0.65, 0.35, 1.0, 0.95 }, FindRect(elementRects, 'cast'));

            local extraBarOccurrences = {};

            for _, extraBar in ipairs(plate.extraBars or {}) do
                local extraBarKind = tostring(extraBar.kind or 'bar');

                extraBarOccurrences[extraBarKind] = (extraBarOccurrences[extraBarKind] or 0) + 1;

                local extraBarRect = FindRect(elementRects, extraBarKind, extraBarOccurrences[extraBarKind]);

                if (tostring(extraBar.displayMode or '') == 'Ring') then
                    DrawRingProgress(device, centerX, centerY, extraBar, math.max(0, math.min(100, tonumber(extraBar.progress) or 0)), extraBar.color or { 0.90, 0.65, 0.25, 1.0 }, extraBarRect);
                elseif (extraBar.segmented == true) then
                    DrawTpBar(device, centerX, centerY, extraBar, math.max(0, math.min(300, tonumber(extraBar.progress) or 0)), extraBar.color or { 0.90, 0.65, 0.25, 1.0 }, extraBarRect);
                else
                    DrawBar(device, centerX, centerY, extraBar, math.max(0, math.min(100, tonumber(extraBar.progress) or 0)), extraBar.color or { 0.90, 0.65, 0.25, 1.0 }, extraBarRect);
                end
            end

            local badgeOccurrences = {};

            for _, badge in ipairs(plate.badges or {}) do
                local badgeKind = tostring(badge.kind or 'badge');

                badgeOccurrences[badgeKind] = (badgeOccurrences[badgeKind] or 0) + 1;
                DrawBadge(device, centerX, centerY, badge, FindRect(elementRects, badgeKind, badgeOccurrences[badgeKind]));
            end

            local iconOccurrences = {};

            for _, icon in ipairs(plate.icons or {}) do
                local iconSize = tonumber(icon.size) or 16;
                local iconX = centerX - (iconSize * 0.5) + (tonumber(icon.offsetX) or 0);
                local iconY = centerY - (iconSize * 0.5) + (tonumber(icon.offsetY) or 0);
                local iconKind = tostring(icon.kind or 'icon');

                iconOccurrences[iconKind] = (iconOccurrences[iconKind] or 0) + 1;

                local iconRect = FindRect(elementRects, iconKind, iconOccurrences[iconKind]);

                if (iconRect ~= nil) then
                    iconX = tonumber(iconRect.drawX1) or iconX;
                    iconY = tonumber(iconRect.drawY1) or iconY;
                    iconSize = math.max(1, (tonumber(iconRect.drawX2) or (iconX + iconSize)) - iconX);
                end

                local iconBackgroundWarningColor = GetTimerWarningColor(icon, 'iconBackground');
                local iconBorderWarningColor = GetTimerWarningColor(icon, 'iconBorder');
                local timerFontWarningColor = GetTimerWarningColor(icon, 'font');
                local timerBoxWarningColor = GetTimerWarningColor(icon, 'box');

                local iconWarningBackgroundActive = iconBackgroundWarningColor ~= nil and icon.timerWarningBackgroundEnabled == true;
                local iconWarningPad = iconWarningBackgroundActive and math.max(0, math.floor((tonumber(icon.timerWarningIconPadding) or 6) + 0.5)) or 0;
                local iconWarningX = iconX - iconWarningPad;
                local iconWarningY = iconY - iconWarningPad;
                local iconWarningSize = iconSize + (iconWarningPad * 2);

                if (iconWarningBackgroundActive == true) then

                    DrawRoundedRect(
                        device,
                        iconWarningX,
                        iconWarningY,
                        iconWarningSize,
                        iconWarningSize,
                        ColorToD3D(iconBackgroundWarningColor, { 1.0, 0.0, 0.0, 0.82 }),
                        math.max(3, math.floor(iconWarningPad * 0.55))
                    );
                end

                DrawTexture(
                    device,
                    icon.textureId,
                    iconX,
                    iconY,
                    iconSize,
                    iconSize,
                    0xFFFFFFFF
                );

                if (iconBorderWarningColor ~= nil and icon.timerWarningBorderEnabled == true) then
                    local borderX = iconWarningBackgroundActive and iconWarningX or (iconX - 1);
                    local borderY = iconWarningBackgroundActive and iconWarningY or (iconY - 1);
                    local borderSize = iconWarningBackgroundActive and iconWarningSize or (iconSize + 2);

                    DrawRectOutline(
                        device,
                        borderX,
                        borderY,
                        borderSize,
                        borderSize,
                        ColorToD3D(iconBorderWarningColor, { 1.0, 0.0, 0.0, 1.0 }),
                        2
                    );
                end

                local timerText = tostring(icon.timerText or '');

                if (timerText ~= '') then
                    local timerTextColor = icon.timerTextColor or { 1.0, 1.0, 1.0, 1.0 };

                    if (timerFontWarningColor ~= nil and icon.timerWarningTextColorEnabled == true) then
                        timerTextColor = timerFontWarningColor;
                    end

                    local timerFontOptions = {
                        fontFamily = ResolveFontFamily(icon.timerFontFamily or plate.nameFontFamily),
                        fontFlags = tonumber(icon.timerFontFlags or plate.nameFontFlags) or 0,
                        fontSize = math.max(4, tonumber(icon.timerFontSize) or 8),
                        color = timerTextColor,
                        outlineEnabled = (tonumber(icon.timerTextOutlineSize) or 0) > 0,
                        outlineColor = icon.timerTextOutlineColor or { 0.0, 0.0, 0.0, 1.0 },
                        outlineSize = tonumber(icon.timerTextOutlineSize) or 1,
                    };
                    local timerTextureId, timerW, timerH = gdiTextTexture.GetTexture(timerText, timerFontOptions);

                    if (timerTextureId ~= nil and timerW ~= nil and timerH ~= nil and timerW > 0 and timerH > 0) then
                        local timerBoxW = timerW;
                        local timerBoxH = timerH;
                        local timerBoxX = iconX + ((iconSize - timerBoxW) * 0.5);
                        local timerY = iconY + iconSize + 1 + (tonumber(icon.timerOffsetY) or 0);

                        if (icon.timerBackground == true) then
                            local sampleText = string.find(timerText, 'm', 1, true) ~= nil and '88m' or '88';
                            local _, sampleW = gdiTextTexture.GetTexture(sampleText, timerFontOptions);

                            timerBoxW = math.max(timerW, tonumber(sampleW) or 0);
                            timerBoxX = iconX + ((iconSize - timerBoxW) * 0.5);

                            local padX = tonumber(icon.timerBackgroundPaddingX) or 2;
                            local padY = tonumber(icon.timerBackgroundPaddingY) or 1;
                            local boxColor = ColorToD3D(
                                (timerBoxWarningColor ~= nil and icon.timerWarningBoxColorEnabled == true) and timerBoxWarningColor or GetTimerBackgroundColor(icon),
                                { 0.0, 0.0, 0.0, 0.80 }
                            );
                            local borderSize = math.max(0, tonumber(icon.timerBackgroundBorderSize) or 0);

                            DrawRoundedRectWithBorder(
                                device,
                                timerBoxX - padX,
                                timerY - padY,
                                timerBoxW + (padX * 2),
                                timerBoxH + (padY * 2),
                                boxColor,
                                ColorToD3D(icon.timerBackgroundBorderColor, { 0.0, 0.0, 0.0, 1.0 }),
                                borderSize,
                                tonumber(icon.timerCornerRadius) or 0
                            );
                        end

                        local timerX = timerBoxX + ((timerBoxW - timerW) * 0.5);
                        DrawTexture(device, timerTextureId, timerX, timerY, timerW, timerH, 0xFFFFFFFF);
                    end
                end
            end

            local textOccurrences = {};

            for _, text in ipairs(plate.texts or {}) do
                local textValue = tostring(text.text or '');

                if (textValue ~= '') then
                    local textTextureId, textW, textH = gdiTextTexture.GetTexture(textValue, {
                        fontFamily = ResolveFontFamily(text.fontFamily or plate.nameFontFamily),
                        fontFlags = tonumber(text.fontFlags or plate.nameFontFlags) or 0,
                        fontSize = math.max(8, tonumber(text.fontSize) or 12),
                        color = text.color or { 1.0, 1.0, 1.0, 1.0 },
                        outlineEnabled = text.outlineEnabled ~= false,
                        outlineColor = text.outlineColor or { 0.0, 0.0, 0.0, 1.0 },
                        outlineSize = tonumber(text.outlineSize) or 1,
                    });

                    if (textTextureId ~= nil and textW ~= nil and textH ~= nil and textW > 0 and textH > 0) then
                        local textX = centerX + (tonumber(text.offsetX) or 0);
                        local textY = centerY + (tonumber(text.offsetY) or 0);
                        local textKind = tostring(text.kind or 'text');

                        textOccurrences[textKind] = (textOccurrences[textKind] or 0) + 1;

                        if (text.align == 'center') then
                            textX = textX - (textW * 0.5);
                        end

                        local textRect = FindRect(elementRects, textKind, textOccurrences[textKind]);

                        if (textRect ~= nil) then
                            textX = tonumber(textRect.drawX1) or textX;
                            textY = tonumber(textRect.drawY1) or textY;
                        end

                        DrawTexture(
                            device,
                            textTextureId,
                            textX,
                            textY,
                            textW,
                            textH,
                            0xFFFFFFFF
                        );
                    end
                end
            end

            local plateName = nativeUiPolicy.ShouldDrawLibraNames() == true and tostring(plate.name or '') or '';
            local nameFontSize = GetNameFontSize(plate, plateName);
            local renderFontSize = GetNameRenderFontSize(nameFontSize);
            local renderScale = GetNameRenderScale(nameFontSize, renderFontSize);
            local nameTextureId, nameW, nameH = gdiTextTexture.GetTexture(plateName, {
                fontFamily = ResolveFontFamily(plate.nameFontFamily),
                fontFlags = tonumber(plate.nameFontFlags) or 0,
                fontSize = renderFontSize,
                color = plate.nameColor or { 1.0, 1.0, 1.0, 1.0 },
                outlineEnabled = plate.nameOutlineEnabled == true and GetManualNameOutlineRadius(plate.nameOutlineSize) <= 0,
                outlineColor = plate.nameOutlineColor or { 0.0, 0.0, 0.0, 1.0 },
                outlineSize = tonumber(plate.nameOutlineSize) or 0,
            });

            if (nameTextureId ~= nil and nameW ~= nil and nameH ~= nil and nameW > 0 and nameH > 0) then
                local manualOutlineRadius = GetManualNameOutlineRadius(plate.nameOutlineSize);
                local outlineRadius = manualOutlineRadius * renderScale;
                local drawW = nameW * renderScale;
                local drawH = nameH * renderScale;
                local nameX = centerX - (drawW * 0.5) + (tonumber(plate.nameOffsetX) or 0);
                local nameY = centerY - (drawH * 0.5) + (tonumber(plate.nameOffsetY) or -54);
                local nameRect = FindRect(elementRects, 'name');

                if (nameRect ~= nil) then
                    nameX = (tonumber(nameRect.drawX1) or nameX) + outlineRadius;
                    nameY = (tonumber(nameRect.drawY1) or nameY) + outlineRadius;
                end

                if (manualOutlineRadius > 0 and plate.nameOutlineEnabled == true) then
                    local outlineTextureId, outlineW, outlineH = gdiTextTexture.GetTexture(plateName, {
                        fontFamily = ResolveFontFamily(plate.nameFontFamily),
                        fontFlags = tonumber(plate.nameFontFlags) or 0,
                        fontSize = renderFontSize,
                        color = plate.nameOutlineColor or { 0.0, 0.0, 0.0, 1.0 },
                        outlineEnabled = false,
                        outlineColor = plate.nameOutlineColor or { 0.0, 0.0, 0.0, 1.0 },
                        outlineSize = 0,
                    });

                    if (outlineTextureId ~= nil and outlineW ~= nil and outlineH ~= nil and outlineW > 0 and outlineH > 0) then
                        for _, offset in ipairs(BuildOutlineOffsets(manualOutlineRadius)) do
                            DrawTexture(
                                device,
                                outlineTextureId,
                                nameX + (offset[1] * renderScale),
                                nameY + (offset[2] * renderScale),
                                outlineW * renderScale,
                                outlineH * renderScale,
                                0xFFFFFFFF
                            );
                        end
                    end
                end

                DrawTexture(
                    device,
                    nameTextureId,
                    nameX,
                    nameY,
                    drawW,
                    drawH,
                    0xFFFFFFFF
                );

            end

            local jobText = tostring(plate.jobText or '');

            if (jobText ~= '') then
                local jobTextureId, jobW, jobH = gdiTextTexture.GetTexture(jobText, {
                    fontFamily = ResolveFontFamily(plate.jobFontFamily or plate.nameFontFamily),
                    fontFlags = tonumber(plate.jobFontFlags or plate.nameFontFlags) or 0,
                    fontSize = math.max(8, tonumber(plate.jobFontSize) or 12),
                    color = plate.jobColor or { 1.0, 1.0, 1.0, 1.0 },
                    outlineEnabled = plate.jobOutlineEnabled == true,
                    outlineColor = plate.jobOutlineColor or { 0.0, 0.0, 0.0, 1.0 },
                    outlineSize = tonumber(plate.jobOutlineSize) or 0,
                });

                if (jobTextureId ~= nil and jobW ~= nil and jobH ~= nil and jobW > 0 and jobH > 0) then
                    local jobX = centerX - (jobW * 0.5) + (tonumber(plate.jobOffsetX) or 0);
                    local jobY = centerY - (jobH * 0.5) + (tonumber(plate.jobOffsetY) or -54);
                    local jobRect = FindRect(elementRects, 'job');

                    if (jobRect ~= nil) then
                        jobX = tonumber(jobRect.drawX1) or jobX;
                        jobY = tonumber(jobRect.drawY1) or jobY;
                    end

                    DrawTexture(
                        device,
                        jobTextureId,
                        jobX,
                        jobY,
                        jobW,
                        jobH,
                        0xFFFFFFFF
                    );
                end
            end

            if (plate.debugClickRects == true) then
                local debugColor = tonumber(plate.debugClickRectColor) or 0xDDFFD400;

                for _, rect in ipairs(plate._elementRects or {}) do
                    DrawRectOutline(
                        device,
                        rect.x1,
                        rect.y1,
                        rect.x2 - rect.x1,
                        rect.y2 - rect.y1,
                        debugColor,
                        2
                    );
                end
            end

        end);
    end

    pcall(function()
        device:SetRenderTarget(oldTarget);
    end);

    device:SetTexture(0, saveTex);
    device:SetRenderState(D3DRS_ZENABLE, saveZ);
    device:SetRenderState(D3DRS_LIGHTING, saveLight);
    device:SetRenderState(D3DRS_ALPHABLENDENABLE, saveBlend);
    device:SetRenderState(D3DRS_SRCBLEND, saveSrc);
    device:SetRenderState(D3DRS_DESTBLEND, saveDst);
    device:SetVertexShader(saveFvf);
    if (savePixelShader ~= nil) then
        device:SetPixelShader(savePixelShader);
    end

    d3d.gc_safe_release(oldTarget);
    d3d.gc_safe_release(surface);

    return Finish(targetTexture, width, height);
end

function canvasTexture.GetTextureId(value)
    local id = TextureId(value);

    if (id ~= nil and textureIdToKey[id] ~= nil) then
        TouchTextureKey(textureIdToKey[id]);
    end

    return id;
end

function canvasTexture.GetRenderPolicyKey()
    return 'libraNames=' .. tostring(nativeUiPolicy.ShouldDrawLibraNames() == true) ..
        '|libraTargeting=' .. tostring(nativeUiPolicy.ShouldDrawLibraTargetingSystem() == true) ..
        '|renderVersion=' .. tostring(renderVersion);
end

function canvasTexture.TouchKey(key)
    return TouchTextureKey(key);
end

function canvasTexture.ReleaseKey(key)
    return ReleaseTextureKey(key);
end

function canvasTexture.GetCacheStats()
    return {
        count = textureCount,
        max = maxTextures,
        evictions = textureEvictions,
    };
end

return canvasTexture;
