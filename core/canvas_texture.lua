require('common');

local d3d = require('d3d8');
local ffi = require('ffi');
local C = ffi.C;
local gdiTextTexture = require('ui.gdi_text_texture');
local fonts = require('core.fonts');
local anchorGeometry = require('core.anchor_geometry');
local nativeUiPolicy = require('core.native_ui_policy');
local iconPack = require('core.icon_pack');

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
local textureAliases = {};
local textureCount = 0;
local textureEvictions = 0;
local evictionWindowStart = os.clock();
local evictionWindowCount = 0;
local evictionRatePerMinute = 0;
local lastEvictedKey = '';
local lastEvictedAt = 0;
local lastRenderBaseKey = '';
local lastRenderTextureKey = '';
local lastRenderSize = '';
local retiredTextureSequence = 0;
local retiredTextureKeys = {};
local lastIdlePruneAt = 0;
local renderSuspendedUntil = 0;
local maxTextures = 96;
-- Textures returned to ImGui/world-marker draw lists can remain referenced
-- after the Lua code that queued them has finished.  Never evict a texture
-- that was used recently; doing so can let D3D reuse its pointer while a
-- queued draw still references it, producing swapped/oversized plates or a
-- client crash.
local textureEvictionGraceSeconds = 2.0;
local width = 1024;
local height = 512;
local drawOffsetX = 0;
local drawOffsetY = 0;
local renderVersion = 8;

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
local DrawTexture = nil;

local function RequireD3dSuccess(result, label)
    if result ~= nil and result ~= C.S_OK then
        error(tostring(label or 'D3D call') .. ' failed with HRESULT ' .. tostring(result), 0);
    end

    return result;
end

local function ReleaseInterface(value)
    if (value == nil) then
        return;
    end

    pcall(function()
        value:Release();
    end);
end

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

local function BarBorderColorToD3D(color, fallback, borderSize)
    local source = color or fallback or { 0.0, 0.0, 0.0, 1.0 };

    -- Bar color controls edit RGB only. Some pet-bar defaults historically
    -- carried alpha 0, which made every positive border size remain invisible.
    if ((tonumber(borderSize) or 0) > 0 and type(source) == 'table'
        and (tonumber(source[4]) or 0) <= 0) then
        source = {
            tonumber(source[1]) or 0,
            tonumber(source[2]) or 0,
            tonumber(source[3]) or 0,
            1.0,
        };
    end

    return ColorToD3D(source, fallback);
end

local function BoostColor(color, boost, alpha)
    if (type(color) ~= 'table') then
        return color;
    end

    boost = tonumber(boost) or 1.0;

    return {
        math.min(1.0, (tonumber(color[1]) or 1.0) * boost),
        math.min(1.0, (tonumber(color[2]) or 1.0) * boost),
        math.min(1.0, (tonumber(color[3]) or 1.0) * boost),
        tonumber(alpha) or tonumber(color[4]) or 1.0,
    };
end

local function NormalizeTextureStrength(value)
    local strength = tonumber(value);

    if (strength == nil) then
        strength = 100;
    end

    return math.max(0, math.min(100, strength)) / 100;
end

local function ColorWithAlphaMultiplier(color, fallback, multiplier)
    local source = color or fallback or { 1.0, 1.0, 1.0, 1.0 };
    local alpha = 1.0;

    if (type(source) == 'table') then
        alpha = tonumber(source[4]) or 1.0;
    end

    local result = BoostColor(source, 1.0, alpha * (tonumber(multiplier) or 1.0));
    return ColorToD3D(result, fallback);
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
        end
    end
end

local function TouchTextureKey(key)
    key = tostring(key or '');

    if (key == '' or textures[key] == nil) then
        local aliases = textureAliases[key];

        if (type(aliases) == 'table') then
            local touched = false;

            for actualKey, _ in pairs(aliases) do
                if (textures[actualKey] ~= nil) then
                    TouchTextureKey(actualKey);
                    touched = true;
                end
            end

            return touched;
        end

        return false;
    end

    local info = textureInfo[key] or {};
    info.lastTouch = os.clock();
    textureInfo[key] = info;
    RemoveTextureOrderKey(key);
    textureOrder[#textureOrder + 1] = key;
    return true;
end

local function RemoveTextureAlias(actualKey)
    for alias, aliases in pairs(textureAliases) do
        if (type(aliases) == 'table') then
            aliases[actualKey] = nil;

            if (next(aliases) == nil) then
                textureAliases[alias] = nil;
            end
        end
    end
end

local function AddTextureAlias(alias, actualKey)
    alias = tostring(alias or '');
    actualKey = tostring(actualKey or '');

    if (alias == '' or actualKey == '' or alias == actualKey) then
        return;
    end

    textureAliases[alias] = textureAliases[alias] or {};
    textureAliases[alias][actualKey] = true;
end

local function ReleaseTextureKey(key, countEviction)
    key = tostring(key or '');

    if (key == '' or textures[key] == nil) then
        local aliases = textureAliases[key];

        if (type(aliases) == 'table') then
            local keys = {};

            for actualKey, _ in pairs(aliases) do
                keys[#keys + 1] = actualKey;
            end

            local released = false;

            for _, actualKey in ipairs(keys) do
                if (ReleaseTextureKey(actualKey, countEviction) == true) then
                    released = true;
                end
            end

            textureAliases[key] = nil;
            return released;
        end

        return false;
    end

    local id = TextureId(textures[key]);

    if (id ~= nil) then
        textureIdToKey[id] = nil;
    end

    textures[key] = nil;
    textureInfo[key] = nil;
    RemoveTextureAlias(key);
    RemoveTextureOrderKey(key);
    textureCount = math.max(0, textureCount - 1);

    if (countEviction == true) then
        lastEvictedKey = key;
        lastEvictedAt = os.clock();
        textureEvictions = textureEvictions + 1;
        evictionWindowCount = evictionWindowCount + 1;
        local now = os.clock();
        local elapsed = math.max(0.01, now - (tonumber(evictionWindowStart) or now));
        if (elapsed >= 10.0) then
            evictionRatePerMinute = (evictionWindowCount / elapsed) * 60.0;
            evictionWindowStart = now;
            evictionWindowCount = 0;
        elseif (evictionRatePerMinute <= 0 and evictionWindowCount > 0) then
            evictionRatePerMinute = (evictionWindowCount / elapsed) * 60.0;
        end
    end

    collectgarbage('step', 32);
    return true;
end

local function TrimTextureCache(protectedKey)
    while (textureCount > maxTextures and #textureOrder > 0) do
        local evictionIndex = nil;
        local now = os.clock();

        for i = 1, #textureOrder do
            local candidateKey = textureOrder[i];
            local candidateInfo = textureInfo[candidateKey] or {};
            local idleSeconds = now - (tonumber(candidateInfo.lastTouch) or 0);

            if (
                candidateKey ~= protectedKey and
                idleSeconds >= textureEvictionGraceSeconds
            ) then
                evictionIndex = i;
                break;
            end
        end

        if (evictionIndex == nil) then
            break;
        end

        ReleaseTextureKey(textureOrder[evictionIndex], true);
    end
end

local function PruneIdleTextures(protectedKey)
    local now = os.clock();

    if ((now - lastIdlePruneAt) < 1.0) then
        return;
    end

    lastIdlePruneAt = now;
    local staleKeys = {};

    for key, info in pairs(textureInfo) do
        local idleSeconds = now - (tonumber(info ~= nil and info.lastTouch) or 0);

        if (key ~= protectedKey and idleSeconds >= 15.0) then
            staleKeys[#staleKeys + 1] = key;
        end
    end

    for _, key in ipairs(staleKeys) do
        ReleaseTextureKey(key, false);
    end
end

local function ReleaseTextureKeyIfIdle(key)
    key = tostring(key or '');

    if (key == '') then
        return false;
    end

    if (textures[key] ~= nil) then
        local info = textureInfo[key] or {};
        local idleSeconds = os.clock() - (tonumber(info.lastTouch) or 0);

        if (idleSeconds < textureEvictionGraceSeconds) then
            return false;
        end

        return ReleaseTextureKey(key, false);
    end

    local aliases = textureAliases[key];

    if (type(aliases) ~= 'table') then
        return false;
    end

    local actualKeys = {};

    for actualKey, _ in pairs(aliases) do
        actualKeys[#actualKeys + 1] = actualKey;
    end

    local released = false;

    for _, actualKey in ipairs(actualKeys) do
        if (ReleaseTextureKeyIfIdle(actualKey) == true) then
            released = true;
        end
    end

    return released;
end

local function GetManualNameOutlineRadius(value)
    return 0;
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
    local cropInfo = type(plate._canvasCrop) == 'table' and plate._canvasCrop or nil;
    local sizingWidth = tonumber(cropInfo ~= nil and cropInfo.fullWidth)
        or tonumber(plate.canvasWidth)
        or width;
    local safeWidth = sizingWidth - 96;
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
    local x1 = (tonumber(x) or 0) - drawOffsetX;
    local y1 = (tonumber(y) or 0) - drawOffsetY;
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

    RequireD3dSuccess(device:SetTexture(0, nil), 'SetTexture');
    RequireD3dSuccess(device:SetVertexShader(D3DFVF_XYZRHW_DIFFUSE), 'SetVertexShader');
    RequireD3dSuccess(device:SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_SELECTARG1), 'Set COLOROP');
    RequireD3dSuccess(device:SetTextureStageState(0, D3DTSS_COLORARG1, D3DTA_DIFFUSE), 'Set COLORARG1');
    RequireD3dSuccess(device:SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_SELECTARG1), 'Set ALPHAOP');
    RequireD3dSuccess(device:SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_DIFFUSE), 'Set ALPHAARG1');
    RequireD3dSuccess(device:DrawPrimitiveUP(D3DPT_TRIANGLELIST, 2, vertices, ffi.sizeof('lp_canvas_color_vertex_t')), 'Draw rectangle');
end

local function DrawRingSegment(device, centerX, centerY, outerRadius, innerRadius, startAngle, endAngle, color, segmentCount)
    centerX = (tonumber(centerX) or 0) - drawOffsetX;
    centerY = (tonumber(centerY) or 0) - drawOffsetY;

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

    RequireD3dSuccess(device:SetTexture(0, nil), 'SetTexture');
    RequireD3dSuccess(device:SetVertexShader(D3DFVF_XYZRHW_DIFFUSE), 'SetVertexShader');
    RequireD3dSuccess(device:SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_SELECTARG1), 'Set COLOROP');
    RequireD3dSuccess(device:SetTextureStageState(0, D3DTSS_COLORARG1, D3DTA_DIFFUSE), 'Set COLORARG1');
    RequireD3dSuccess(device:SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_SELECTARG1), 'Set ALPHAOP');
    RequireD3dSuccess(device:SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_DIFFUSE), 'Set ALPHAARG1');
    RequireD3dSuccess(device:DrawPrimitiveUP(D3DPT_TRIANGLELIST, segments * 2, vertices, ffi.sizeof('lp_canvas_color_vertex_t')), 'Draw rounded rectangle');
end

local function DrawRectOutline(device, x, y, w, h, color, thickness)
    local line = math.max(1, tonumber(thickness) or 1);

    DrawRect(device, x, y, w, line, color);
    DrawRect(device, x, y + h - line, w, line, color);
    DrawRect(device, x, y, line, h, color);
    DrawRect(device, x + w - line, y, line, h, color);
end

-- Draw a textured rounded rectangle in one primitive call.  The shape is
-- generated only when a plate canvas is rebuilt, never during the regular
-- world-position pass.
local function DrawRoundedTexture(device, textureId, x, y, w, h, color, radius, u1, v1, u2, v2)
    local rectW = math.max(0, tonumber(w) or 0);
    local rectH = math.max(0, tonumber(h) or 0);
    local r = math.max(0, math.min(tonumber(radius) or 0, math.floor(math.min(rectW, rectH) * 0.5)));

    if (rectW <= 0 or rectH <= 0) then
        return;
    end

    if (r <= 0) then
        DrawTexture(device, textureId, x, y, rectW, rectH, color, u2, v2);
        return;
    end

    local px = (tonumber(x) or 0) - drawOffsetX;
    local py = (tonumber(y) or 0) - drawOffsetY;
    local startU = tonumber(u1) or 0;
    local startV = tonumber(v1) or 0;
    local endU = tonumber(u2) or 1;
    local endV = tonumber(v2) or 1;
    local segments = 4;
    local points = {};

    local function AddPoint(pointX, pointY)
        points[#points + 1] = { pointX, pointY };
    end

    AddPoint(px + r, py);
    AddPoint(px + rectW - r, py);

    local corners = {
        { px + rectW - r, py + r, -math.pi * 0.5, 0 },
        { px + rectW - r, py + rectH - r, 0, math.pi * 0.5 },
        { px + r, py + rectH - r, math.pi * 0.5, math.pi },
        { px + r, py + r, math.pi, math.pi * 1.5 },
    };

    for _, corner in ipairs(corners) do
        local cx, cy, from, to = corner[1], corner[2], corner[3], corner[4];
        for step = 1, segments do
            local angle = from + ((to - from) * (step / segments));
            AddPoint(cx + (math.cos(angle) * r), cy + (math.sin(angle) * r));
        end
    end

    local centerX = px + (rectW * 0.5);
    local centerY = py + (rectH * 0.5);
    local vertexCount = #points * 3;
    local vertices = ffi.new('lp_canvas_texture_vertex_t[?]', vertexCount);
    local index = 0;

    local function AddVertex(vertexX, vertexY)
        local normalizedX = math.max(0, math.min(1, (vertexX - px) / rectW));
        local normalizedY = math.max(0, math.min(1, (vertexY - py) / rectH));
        vertices[index] = {
            vertexX,
            vertexY,
            0,
            1,
            color,
            startU + ((endU - startU) * normalizedX),
            startV + ((endV - startV) * normalizedY),
        };
        index = index + 1;
    end

    for pointIndex = 1, #points do
        local nextIndex = (pointIndex % #points) + 1;
        AddVertex(centerX, centerY);
        AddVertex(points[pointIndex][1], points[pointIndex][2]);
        AddVertex(points[nextIndex][1], points[nextIndex][2]);
    end

    RequireD3dSuccess(device:SetTexture(0, ffi.cast('IDirect3DBaseTexture8*', ffi.cast('uintptr_t', textureId))), 'SetTexture');
    RequireD3dSuccess(device:SetVertexShader(D3DFVF_XYZRHW_DIFFUSE_TEX1), 'SetVertexShader');
    RequireD3dSuccess(device:SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_MODULATE), 'Set COLOROP');
    RequireD3dSuccess(device:SetTextureStageState(0, D3DTSS_COLORARG1, D3DTA_TEXTURE), 'Set COLORARG1');
    RequireD3dSuccess(device:SetTextureStageState(0, D3DTSS_COLORARG2, D3DTA_DIFFUSE), 'Set COLORARG2');
    RequireD3dSuccess(device:SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_MODULATE), 'Set ALPHAOP');
    RequireD3dSuccess(device:SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_TEXTURE), 'Set ALPHAARG1');
    RequireD3dSuccess(device:SetTextureStageState(0, D3DTSS_ALPHAARG2, D3DTA_DIFFUSE), 'Set ALPHAARG2');
    RequireD3dSuccess(device:DrawPrimitiveUP(D3DPT_TRIANGLELIST, #points, vertices, ffi.sizeof('lp_canvas_texture_vertex_t')), 'Draw texture polygon');
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
        -- Pre-transformed D3D8 rectangles cover their trailing raster row and
        -- column. Reserve those pixels so the inner background does not paint
        -- over the bottom and right sides of the border.
        DrawRoundedRect(device, x + border, y + border, w - (border * 2) - 1, h - (border * 2) - 1, backgroundColor, math.max(0, (tonumber(radius) or 0) - border));
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

    if (icon.timerBackgroundColor ~= nil) then
        return icon.timerBackgroundColor;
    end

    if (seconds > normalSeconds) then
        return icon.timerNormalBackgroundColor;
    end

    if (seconds > soonSeconds) then
        return icon.timerSoonBackgroundColor;
    end

    return icon.timerUrgentBackgroundColor;
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

    if (target == 'outline') then
        if (stage == 3) then return icon.timerWarningOutlineStage3Color or icon.timerTextOutlineColor or { 0.0, 0.0, 0.0, 1.0 }; end
        if (stage == 2) then return icon.timerWarningOutlineStage2Color or icon.timerTextOutlineColor or { 0.0, 0.0, 0.0, 1.0 }; end
        return icon.timerWarningOutlineStage1Color or icon.timerTextOutlineColor or { 0.0, 0.0, 0.0, 1.0 };
    end

    if (target == 'box') then
        if (stage == 3) then return icon.timerWarningBoxStage3Color or icon.timerWarningStage3Color or { 1.0, 0.15, 0.15, 1.0 }; end
        if (stage == 2) then return icon.timerWarningBoxStage2Color or icon.timerWarningStage2Color or { 1.0, 0.50, 0.05, 1.0 }; end
        return icon.timerWarningBoxStage1Color or icon.timerWarningStage1Color or { 1.0, 0.90, 0.20, 1.0 };
    end

    if (target == 'boxBorder') then
        if (stage == 3) then return icon.timerWarningBoxBorderStage3Color or icon.timerWarningStage3Color or { 1.0, 0.15, 0.15, 1.0 }; end
        if (stage == 2) then return icon.timerWarningBoxBorderStage2Color or icon.timerWarningStage2Color or { 1.0, 0.50, 0.05, 1.0 }; end
        return icon.timerWarningBoxBorderStage1Color or icon.timerWarningStage1Color or { 1.0, 0.90, 0.20, 1.0 };
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

DrawTexture = nil;

local function ResolveTargetMarkerBackgroundBounds(centerX, centerY, marker)
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

    return bgX, bgY, bgW, bgH;
end

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
    local distanceScale = 1.0;

    if (pass ~= 'foreground' and marker.showBackground == true) then
        local bgX, bgY, bgW, bgH = ResolveTargetMarkerBackgroundBounds(centerX, centerY, marker);

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

        if (
            marker.showLock == true and
            marker.lockTextureId ~= nil and
            marker.suppressAnimatedLockDraw ~= true
        ) then
            local lockX = arrowX + (tonumber(marker.lockOffsetX) or 0);
            local lockY = math.max((lockH * 0.5) + margin, arrowY - (arrowH * 0.5) - (lockH * 0.5) + (tonumber(marker.lockOffsetY) or -24));
            DrawTexture(device, marker.lockTextureId, lockX - (lockW * 0.5), lockY - (lockH * 0.5), lockW, lockH, lockColor);
        end

        if (
            marker.showArrow == true and
            marker.arrowTextureId ~= nil and
            marker.suppressAnimatedArrowDraw ~= true
        ) then
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

    local x1 = (tonumber(x) or 0) - drawOffsetX;
    local y1 = (tonumber(y) or 0) - drawOffsetY;
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

    RequireD3dSuccess(device:SetTexture(0, ffi.cast('IDirect3DBaseTexture8*', ffi.cast('uintptr_t', textureId))), 'SetTexture');
    RequireD3dSuccess(device:SetVertexShader(D3DFVF_XYZRHW_DIFFUSE_TEX1), 'SetVertexShader');
    RequireD3dSuccess(device:SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_MODULATE), 'Set COLOROP');
    RequireD3dSuccess(device:SetTextureStageState(0, D3DTSS_COLORARG1, D3DTA_TEXTURE), 'Set COLORARG1');
    RequireD3dSuccess(device:SetTextureStageState(0, D3DTSS_COLORARG2, D3DTA_DIFFUSE), 'Set COLORARG2');
    RequireD3dSuccess(device:SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_MODULATE), 'Set ALPHAOP');
    RequireD3dSuccess(device:SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_TEXTURE), 'Set ALPHAARG1');
    RequireD3dSuccess(device:SetTextureStageState(0, D3DTSS_ALPHAARG2, D3DTA_DIFFUSE), 'Set ALPHAARG2');
    RequireD3dSuccess(device:DrawPrimitiveUP(D3DPT_TRIANGLELIST, 2, vertices, ffi.sizeof('lp_canvas_texture_vertex_t')), 'Draw texture');
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
    if (textureId == -1) then
        local speed = tonumber(bar.animationSpeed) or 40;
        local rate = math.max(0.2, speed / 40);
        local pulse = 0.10 + (0.30 * ((math.sin(os.clock() * rate * math.pi * 2) + 1) * 0.5));
        DrawRect(device, barX, barY, fillW, barH, ColorToD3D({ 1.0, 1.0, 1.0, pulse }, { 1.0, 1.0, 1.0, 0.25 }));
        return;
    end

    local tileW = math.max(barH, barH * 3.64);
    local speed = tonumber(bar.animationSpeed) or 40;
    local offset = (os.clock() * speed) % tileW;
    local x = barX - offset;
    local sourceColor = bar.animationColor or { 1.0, 1.0, 1.0, 0.35 };
    local overlayColor = {
        tonumber(sourceColor[1]) or 1.0,
        tonumber(sourceColor[2]) or 1.0,
        tonumber(sourceColor[3]) or 1.0,
        math.min(0.35, tonumber(sourceColor[4]) or 0.35),
    };
    local color = ColorToD3D(overlayColor, { 1.0, 1.0, 1.0, 0.35 });

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

local function TakeReusableStagingTexture(key)
    key = tostring(key or '');
    local queue = retiredTextureKeys[key];

    -- Keep the two most recently published textures alive because ImGui can
    -- still reference them from queued draw data. Reuse only an older third
    -- buffer. This turns continuously updating pet timers into a bounded
    -- three-texture rotation instead of allocating a new render target every
    -- frame and retaining hundreds of them during the grace window.
    while (type(queue) == 'table' and #queue >= 2) do
        local retiredKey = table.remove(queue, 1);
        local texture = textures[retiredKey];

        if (texture ~= nil) then
            local id = TextureId(texture);
            if (id ~= nil) then
                textureIdToKey[id] = nil;
            end

            textures[retiredKey] = nil;
            textureInfo[retiredKey] = nil;
            RemoveTextureAlias(retiredKey);
            RemoveTextureOrderKey(retiredKey);
            textureCount = math.max(0, textureCount - 1);
            return texture;
        end
    end

    return nil;
end

local function CreateStagingTexture(device, key)
    local reusable = TakeReusableStagingTexture(key);
    if (reusable ~= nil) then
        return reusable;
    end

    local ok, hr, created = pcall(function()
        return device:CreateTexture(width, height, 1, 1, C.D3DFMT_A8R8G8B8, C.D3DPOOL_DEFAULT);
    end);

    if (ok ~= true or hr ~= C.S_OK or created == nil) then
        return nil;
    end

    return d3d.gc_safe_release(created);
end

local function PublishTexture(key, alias, texture, crop, renderSignature)
    key = tostring(key or 'world');
    alias = tostring(alias or '');

    local previous = textures[key];
    local previousInfo = textureInfo[key];

    if (previous ~= nil) then
        -- A previously returned texture can still be referenced by a queued
        -- ImGui/world draw. Move it to a retired cache key so the normal grace
        -- period and LRU eviction own its lifetime instead of releasing it
        -- while the current frame may still use its pointer.
        retiredTextureSequence = retiredTextureSequence + 1;
        local retiredKey = key .. '|retired=' .. tostring(retiredTextureSequence);
        local previousId = TextureId(previous);

        textures[retiredKey] = previous;
        textureInfo[retiredKey] = previousInfo or {
            createdAt = os.clock(),
            lastTouch = os.clock(),
            width = width,
            height = height,
        };

        if (previousId ~= nil) then
            textureIdToKey[previousId] = retiredKey;
        end

        RemoveTextureAlias(key);
        RemoveTextureOrderKey(key);
        textureOrder[#textureOrder + 1] = retiredKey;
        AddTextureAlias(alias, retiredKey);
        retiredTextureKeys[key] = retiredTextureKeys[key] or {};
        retiredTextureKeys[key][#retiredTextureKeys[key] + 1] = retiredKey;
    end

    textureCount = textureCount + 1;
    textures[key] = texture;
    textureInfo[key] = {
        createdAt = os.clock(),
        lastTouch = os.clock(),
        width = width,
        height = height,
        crop = crop,
        renderSignature = renderSignature,
    };
    AddTextureAlias(alias, key);

    local id = TextureId(texture);

    if (id ~= nil) then
        textureIdToKey[id] = key;
    end

    TouchTextureKey(key);
    PruneIdleTextures(key);
    -- Never evict the render target being returned to this frame's caller.
    -- A stale duplicate in the LRU list previously allowed a newly-created
    -- canvas to be released here and then drawn as black or unrelated content.
    TrimTextureCache(key);
    return texture;
end

local function DrawBarLabel(device, barX, barY, barW, barH, bar)
    local barText = tostring(bar.text or '');
    local secondaryText = tostring(bar.secondaryText or '');
    local labelText = tostring(bar.labelText or '');

    if (barText == '' and secondaryText == '' and labelText == '' and bar.iconTextureId == nil) then
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
    local secondaryTextureId, secondaryW, secondaryH = gdiTextTexture.GetTexture(secondaryText, textOptions);
    local labelTextureId, labelW, labelH = gdiTextTexture.GetTexture(labelText, textOptions);

    if (barText == '') then
        textW = 0;
        textH = 0;
    end

    if (labelText == '') then
        labelW = 0;
        labelH = 0;
    end
    if (secondaryText == '') then
        secondaryW = 0;
        secondaryH = 0;
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

    if (
        secondaryText ~= '' and
        secondaryTextureId ~= nil and
        secondaryW ~= nil and secondaryH ~= nil and
        secondaryW > 0 and secondaryH > 0
    ) then
        DrawTexture(
            device,
            secondaryTextureId,
            barX + ((barW - secondaryW) * 0.5) + (tonumber(bar.secondaryTextOffsetX) or 0),
            barY + ((barH - secondaryH) * 0.5) + (tonumber(bar.secondaryTextOffsetY) or 0),
            secondaryW,
            secondaryH,
            0xFFFFFFFF
        );
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
    local cornerRadius = math.max(0, tonumber(bar.cornerRadius) or 0);
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

    DrawRoundedRectWithBorder(
        device,
        barX - borderSize,
        barY - borderSize,
        barW + (borderSize * 2),
        barH + (borderSize * 2),
        ColorToD3D(bar.backgroundColor, { 0.05, 0.05, 0.05, 0.85 }),
        BarBorderColorToD3D(bar.borderColor, { 0.0, 0.0, 0.0, 1.0 }, borderSize),
        borderSize,
        cornerRadius + borderSize
    );

    local direction = tostring(bar.fillDirection or 'Left to right');
    local fillX = barX;
    local fillY = barY;
    local innerW = math.max(0, barW - ((borderSize > 0) and 1 or 0));
    local innerH = math.max(0, barH - ((borderSize > 0) and 1 or 0));
    local fillW = innerW * progress;
    local fillH = innerH;
    local u1, v1, u2, v2 = 0, 0, progress, 1;

    if (direction == 'Right to left') then
        fillX = barX + innerW - fillW;
        u1, u2 = 1 - progress, 1;
    elseif (direction == 'Bottom to top') then
        fillW = innerW;
        fillH = innerH * progress;
        fillY = barY + innerH - fillH;
        v1, v2 = 1 - progress, 1;
    elseif (direction == 'Top to bottom') then
        fillW = innerW;
        fillH = innerH * progress;
        v1, v2 = 0, progress;
    end

    local textureStrength = NormalizeTextureStrength(bar.textureStrength);

    if (bar.textureId ~= nil and tonumber(bar.textureId) ~= nil and tonumber(bar.textureId) ~= 0 and textureStrength > 0) then
        if (textureStrength < 1) then
            DrawRoundedRect(device, fillX, fillY, fillW, fillH, ColorToD3D(bar.color, defaultColor), cornerRadius);
        end

        DrawRoundedTexture(device, bar.textureId, fillX, fillY, fillW, fillH, ColorWithAlphaMultiplier(bar.color, defaultColor, textureStrength), cornerRadius, u1, v1, u2, v2);
    else
        DrawRoundedRect(device, fillX, fillY, fillW, fillH, ColorToD3D(bar.color, defaultColor), cornerRadius);
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
            BarBorderColorToD3D(ring.borderColor, { 0.0, 0.0, 0.0, 1.0 }, borderSize),
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
    local border = math.min(borderSize, math.floor(math.min(bgW, bgH) * 0.5));

    if (resolvedRect ~= nil) then
        local x1 = tonumber(resolvedRect.drawX1);
        local y1 = tonumber(resolvedRect.drawY1);
        local x2 = tonumber(resolvedRect.drawX2);
        local y2 = tonumber(resolvedRect.drawY2);

        if (x1 ~= nil and y1 ~= nil and x2 ~= nil and y2 ~= nil and x2 > x1 and y2 > y1) then
            local outerW = math.max(1, x2 - x1);
            local outerH = math.max(1, y2 - y1);
            border = math.min(borderSize, math.floor(math.min(outerW, outerH) * 0.5));
            bgX = x1 + border;
            bgY = y1 + border;
            bgW = math.max(1, outerW - (border * 2));
            bgH = math.max(1, outerH - (border * 2));
        end
    end

    DrawRect(device, bgX, bgY, bgW, bgH, ColorToD3D(background.color, { 0.0, 0.0, 0.0, 0.45 }));

    if (background.textureId ~= nil) then
        local textureAlpha = tonumber(background.imageOpacity);
        if (textureAlpha ~= nil and textureAlpha > 1) then
            textureAlpha = textureAlpha / 100;
        end
        if (textureAlpha == nil) then
            textureAlpha = tonumber(background.color ~= nil and background.color[4] or nil);
        end
        DrawTexture(device, background.textureId, bgX, bgY, bgW, bgH, ColorToD3D({ 1.0, 1.0, 1.0, textureAlpha }, { 1.0, 1.0, 1.0, 0.45 }));
    end

    if (border > 0) then
        local borderColor = ColorToD3D(background.borderColor, { 0.0, 0.0, 0.0, 0.80 });
        local outerX = bgX - border;
        local outerY = bgY - border;
        local outerW = bgW + (border * 2);
        local outerH = bgH + (border * 2);

        DrawRect(device, outerX, outerY, outerW, border, borderColor);
        DrawRect(device, outerX, outerY + outerH - border, outerW, border, borderColor);
        DrawRect(device, outerX, outerY + border, border, outerH - (border * 2), borderColor);
        DrawRect(device, outerX + outerW - border, outerY + border, border, outerH - (border * 2), borderColor);
    end
end

local function DrawTpBar(device, centerX, centerY, bar, progress, defaultColor, resolvedRect)
    bar = bar or {};
    progress = math.max(0, math.min(300, tonumber(progress) or 0));
    local showAtPercent = math.max(0, math.min(300, tonumber(bar.showAtPercent) or 300));

    if (bar.enabled ~= true or progress < showAtPercent) then
        return;
    end

    if (bar.segmented ~= true) then
        local renderBar = {};
        for key, value in pairs(bar) do
            renderBar[key] = value;
        end
        renderBar.showAtPercent = 100;
        DrawBar(device, centerX, centerY, renderBar, progress / 3, defaultColor, resolvedRect);
        return;
    end

    local barW = tonumber(bar.width) or 180;
    local barH = tonumber(bar.height) or 6;
    local barX = centerX - (barW * 0.5) + (tonumber(bar.offsetX) or 0);
    local barY = centerY - (barH * 0.5) + (tonumber(bar.offsetY) or 0);
    local borderSize = math.max(0, tonumber(bar.borderSize) or 0);
    local cornerRadius = math.max(0, tonumber(bar.cornerRadius) or 0);
    local rows = tostring(bar.segmentLayout or '') == 'Rows';
    local gap = rows
        and math.max(0, tonumber(bar.segmentGap) or 0)
        or math.max(6, tonumber(bar.segmentGap) or 6);
    local segmentW = rows and barW or math.max(1, (barW - (gap * 2)) / 3);
    local segmentH = rows and math.max(1, (barH - (gap * 2)) / 3) or barH;
    local section2Color = bar.color2 or { 0.80, 0.45, 1.0, 0.95 };
    local section3Color = bar.color3 or { 0.35, 0.75, 1.0, 0.95 };

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
            segmentW = rows and barW or math.max(1, (barW - (gap * 2)) / 3);
            segmentH = rows and math.max(1, (barH - (gap * 2)) / 3) or barH;
        end
    end

    for segment = 1, 3 do
        local segmentProgress = math.max(0, math.min(1, (progress / 100) - (segment - 1)));
        local segmentX = rows and barX or (barX + ((segment - 1) * (segmentW + gap)));
        -- Stacked charge rows fill from the bottom upward:
        -- charge 1 = bottom, charge 2 = middle, charge 3 = top.
        local segmentY = rows and (barY + ((3 - segment) * (segmentH + gap))) or barY;
        local segmentColor = bar.color;

        if (segment == 2) then
            segmentColor = section2Color;
        elseif (segment == 3) then
            segmentColor = section3Color;
        end

        DrawRoundedRectWithBorder(
            device,
            segmentX - borderSize,
            segmentY - borderSize,
            segmentW + (borderSize * 2),
            segmentH + (borderSize * 2),
            ColorToD3D(bar.backgroundColor, { 0.05, 0.05, 0.05, 0.85 }),
            BarBorderColorToD3D(bar.borderColor, { 0.0, 0.0, 0.0, 1.0 }, borderSize),
            borderSize,
            cornerRadius + borderSize
        );

        if (segmentProgress > 0) then
            local textureStrength = NormalizeTextureStrength(bar.textureStrength);
            local segmentInnerW = math.max(0, segmentW - ((borderSize > 0) and 1 or 0));
            local segmentInnerH = math.max(0, segmentH - ((borderSize > 0) and 1 or 0));
            local segmentFillW = segmentInnerW * segmentProgress;

            if (bar.textureId ~= nil and tonumber(bar.textureId) ~= nil and tonumber(bar.textureId) ~= 0 and textureStrength > 0) then
                if (textureStrength < 1) then
                    DrawRoundedRect(device, segmentX, segmentY, segmentFillW, segmentInnerH, ColorToD3D(segmentColor, defaultColor), cornerRadius);
                end

                DrawRoundedTexture(device, bar.textureId, segmentX, segmentY, segmentFillW, segmentInnerH, ColorWithAlphaMultiplier(segmentColor, defaultColor, textureStrength), cornerRadius, 0, 0, segmentProgress, 1);
            else
                DrawRoundedRect(device, segmentX, segmentY, segmentFillW, segmentInnerH, ColorToD3D(segmentColor, defaultColor), cornerRadius);
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

local function NextPowerOfTwo(value)
    local result = 1;
    local wanted = math.max(1, math.ceil(tonumber(value) or 1));

    while (result < wanted) do
        result = result * 2;
    end

    return result;
end

local function NextTextureBucket(value)
    local wanted = math.max(1, math.ceil(tonumber(value) or 1));
    local bucket = 16;

    return math.ceil(wanted / bucket) * bucket;
end

local function BuildContentCrop(rects, fullWidth, fullHeight, plate)
    fullWidth = math.max(1, tonumber(fullWidth) or 1024);
    fullHeight = math.max(1, tonumber(fullHeight) or 512);

    local minX = fullWidth;
    local maxX = 0;
    local minY = fullHeight;
    local maxY = 0;
    local found = false;

    for _, rect in ipairs(rects or {}) do
        local x1 = tonumber(rect.x1) or tonumber(rect.drawX1);
        local y1 = tonumber(rect.y1) or tonumber(rect.drawY1);
        local x2 = tonumber(rect.x2) or tonumber(rect.drawX2);
        local y2 = tonumber(rect.y2) or tonumber(rect.drawY2);

        if (x1 ~= nil and y1 ~= nil and x2 ~= nil and y2 ~= nil and x2 >= x1 and y2 >= y1) then
            minX = math.min(minX, x1);
            maxX = math.max(maxX, x2);
            minY = math.min(minY, y1);
            maxY = math.max(maxY, y2);
            found = true;
        end
    end

    if (found ~= true) then
        return {
            x = 0,
            y = 0,
            width = fullWidth,
            height = fullHeight,
            fullWidth = fullWidth,
            fullHeight = fullHeight,
        };
    end

    local padding = math.max(0, tonumber(plate ~= nil and plate.cropPadding) or 28);
    minX = math.max(0, math.floor(minX - padding));
    minY = math.max(0, math.floor(minY - padding));
    maxX = math.min(fullWidth, math.ceil(maxX + padding));
    maxY = math.min(fullHeight, math.ceil(maxY + padding));

    local contentWidth = math.max(1, maxX - minX);
    local contentHeight = math.max(1, maxY - minY);
    local cropWidth = math.min(fullWidth, math.max(64, NextTextureBucket(contentWidth)));
    local cropHeight = math.min(fullHeight, math.max(64, NextTextureBucket(contentHeight)));
    local contentCenterX = (minX + maxX) * 0.5;
    local contentCenterY = (minY + maxY) * 0.5;
    local cropX = math.floor(contentCenterX - (cropWidth * 0.5) + 0.5);
    local cropY = math.floor(contentCenterY - (cropHeight * 0.5) + 0.5);

    cropX = math.max(0, math.min(fullWidth - cropWidth, cropX));
    cropY = math.max(0, math.min(fullHeight - cropHeight, cropY));

    return {
        x = cropX,
        y = cropY,
        width = cropWidth,
        height = cropHeight,
        fullWidth = fullWidth,
        fullHeight = fullHeight,
    };
end

local function ShiftRect(rect, dx, dy)
    local shifted = {};

    for key, value in pairs(rect or {}) do
        shifted[key] = value;
    end

    for _, key in ipairs({ 'x1', 'y1', 'x2', 'y2', 'drawX1', 'drawY1', 'drawX2', 'drawY2', 'baseX1', 'baseY1', 'baseX2', 'baseY2' }) do
        if (type(shifted[key]) == 'number') then
            if (string.find(key, 'Y', 1, true) ~= nil or key == 'y1' or key == 'y2') then
                shifted[key] = shifted[key] + dy;
            else
                shifted[key] = shifted[key] + dx;
            end
        end
    end

    return shifted;
end

local function ShiftRects(rects, dx, dy)
    local shifted = {};

    for _, rect in ipairs(rects or {}) do
        shifted[#shifted + 1] = ShiftRect(rect, dx, dy);
    end

    return shifted;
end

function canvasTexture.GetWorldSize(baseWidth, baseHeight, textureWidth, textureHeight)
    local tw = math.max(1, tonumber(textureWidth) or 1024);
    local th = math.max(1, tonumber(textureHeight) or 512);

    return
        (tonumber(baseWidth) or 2.35) * (tw / 1024),
        (tonumber(baseHeight) or 1.18) * (th / 512);
end

function canvasTexture.GetTextureCrop(value)
    local id = TextureId(value) or tonumber(value);
    local key = id ~= nil and textureIdToKey[id] or nil;
    local info = key ~= nil and textureInfo[key] or nil;

    return info ~= nil and info.crop or nil;
end

function canvasTexture.GetWorldBatchInfo(value)
    local id = TextureId(value) or tonumber(value);
    local key = id ~= nil and textureIdToKey[id] or nil;
    local info = key ~= nil and textureInfo[key] or nil;

    if (info == nil) then
        return nil;
    end

    local crop = info.crop;

    return {
        key = key,
        width = tonumber(info.width),
        height = tonumber(info.height),
        -- BUGFIX: the atlas batching path was previously always copying
        -- from (0,0) of each source texture, ignoring the crop offset
        -- that the normal (unbatched) draw path already applies. Since
        -- plates share/reuse a pooled staging texture and only their own
        -- cropped sub-rectangle is meaningful, that caused the atlas to
        -- be populated from the wrong region of the source texture --
        -- visible as a grey rectangle behind each batched nameplate.
        cropX = crop ~= nil and tonumber(crop.x) or 0,
        cropY = crop ~= nil and tonumber(crop.y) or 0,
        revision = tonumber(info.createdAt),
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
        ['Pet timer'] = 'petTimer',
        ['Pet state'] = 'petState',
        ['Sic'] = 'sic',
        ['Ready bar'] = 'ready',
        ['Reward'] = 'reward',
        ['Ward timer'] = 'ward',
        ['Rage timer'] = 'rage',
        ["Avatar's Favor"] = 'favor',
    };
    local hasFallbacks = plate ~= nil and type(plate.anchorFallbackRects) == 'table' and #plate.anchorFallbackRects > 0;
    local fallbackDefs = {};
    local fallbackNames = {};
    local anchorNameByKind = {};

    for anchorName, kind in pairs(anchorMap) do
        if (kind ~= nil and anchorNameByKind[tostring(kind)] == nil) then
            anchorNameByKind[tostring(kind)] = tostring(anchorName);
        end
    end

    for _, fallbackRect in ipairs((plate ~= nil and plate.anchorFallbackRects) or {}) do
        local rectKind = tostring(fallbackRect ~= nil and fallbackRect.kind or '');
        local key = tostring(fallbackRect ~= nil and (fallbackRect.anchorName or anchorNameByKind[rectKind] or rectKind) or '');

        if (key ~= '' and fallbackDefs[key] == nil) then
            fallbackDefs[key] = {
                kind = rectKind,
                x = tonumber(fallbackRect.x) or 0,
                y = tonumber(fallbackRect.y) or 0,
                width = tonumber(fallbackRect.w) or 0,
                height = tonumber(fallbackRect.h) or 0,
                padding = tonumber(fallbackRect.padding) or 0,
                layout = fallbackRect.layout,
            };
            fallbackNames[#fallbackNames + 1] = key;
        end
    end
    local fallbackResolvedCache = {};

    local function CollapseToSlot(defaultRect, slot)
        if (slot == nil) then
            return nil;
        end

        return {
            x = tonumber(slot.x) or 0,
            y = tonumber(slot.y) or 0,
            width = tonumber(defaultRect ~= nil and defaultRect.width) or tonumber(slot.width) or 0,
            height = tonumber(defaultRect ~= nil and defaultRect.height) or tonumber(slot.height) or 0,
        };
    end

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

        local parentTargetKey = anchorMap[parentAnchorName];

        if (parentTargetKey ~= nil and bounds[parentTargetKey] == nil and layout.anchorCollapse ~= false) then
            local resolved = CollapseToSlot(defaultRect, parentRect);
            stack[anchorName] = nil;
            fallbackResolvedCache[anchorName] = resolved;
            return resolved;
        end

        local tempBounds = {};

        for key, value in pairs(bounds or {}) do
            tempBounds[key] = value;
        end

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
                -- Fallback rects are for preserving hidden auto-stack sibling slots.
                -- A visible child anchored to a disabled/missing parent should fall back
                -- to its own plate-relative default rect instead of chasing an invisible parent.
                local fallbackTarget = nil;
                local resolved = nil;

                if (fallbackTarget ~= nil) then
                    if (layout.anchorCollapse ~= false) then
                        resolved = CollapseToSlot(defaultRect, fallbackTarget);
                    else
                        local tempBounds = {};

                        for key, value in pairs(bounds or {}) do
                            tempBounds[key] = value;
                        end

                        tempBounds[targetKey] = fallbackTarget;
                        resolved = anchorGeometry.ResolveAnchoredRect(layout, tostring(rect.kind or ''), defaultRect, tempBounds, anchorMap);
                    end
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

    local bounds = BuildBoundsByKind(rects);
    local groups = {};
    local present = {};

    for _, rect in ipairs(rects or {}) do
        local kind = tostring(rect.kind or '');
        if (kind ~= '') then
            present[kind] = true;
        end

        local layout = rect.anchorLayout;
        local anchorTo = tostring(layout ~= nil and layout.anchorTo or 'Plate');
        local targetKey = anchorMap[anchorTo];
        local anchorExists = targetKey ~= nil and bounds[targetKey] ~= nil;
        if (layout ~= nil and anchorTo ~= 'Plate' and layout.anchorCollapse ~= false and anchorExists == true) then
            local anchorPoint = tostring(layout.anchorPoint or 'Center');
            local groupKey = anchorTo .. '\30' .. anchorPoint;
            groups[groupKey] = groups[groupKey] or {
                anchorTo = anchorTo,
                anchorPoint = anchorPoint,
                entries = {},
                entriesByKind = {},
            };
            local entry = groups[groupKey].entriesByKind[kind];
            if (entry == nil) then
                entry = {
                    rect = rect,
                    rects = { rect },
                    visible = true,
                    slot = RectToBounds(rect),
                    padding = tonumber(rect.padding) or 0,
                    sourceOrder = #groups[groupKey].entries + 1,
                    anchorOrder = tonumber(layout.anchorOrder),
                };
                groups[groupKey].entries[#groups[groupKey].entries + 1] = entry;
                groups[groupKey].entriesByKind[kind] = entry;
            else
                entry.rects[#entry.rects + 1] = rect;
            end
        end
    end

    -- Fallback rects are allowed to help children resolve where a missing
    -- parent would have been, but they must never become auto-stack members.
    -- Auto-stack is a compact chain of visible/present widgets only; adding
    -- invisible fallback entries here reserved empty slots when optional
    -- widgets such as New Adventurer were absent.

    local groupingChanged = false;

    local function ApplyShift(rect, dx, dy)
        if (math.abs(tonumber(dx) or 0) > 0.01 or math.abs(tonumber(dy) or 0) > 0.01) then
            groupingChanged = true;
        end

        local pad = tonumber(rect.padding) or 0;
        rect.drawX1 = (tonumber(rect.drawX1) or 0) + dx;
        rect.drawY1 = (tonumber(rect.drawY1) or 0) + dy;
        rect.drawX2 = (tonumber(rect.drawX2) or 0) + dx;
        rect.drawY2 = (tonumber(rect.drawY2) or 0) + dy;
        rect.x1 = rect.drawX1 - pad;
        rect.y1 = rect.drawY1 - pad;
        rect.x2 = rect.drawX2 + pad;
        rect.y2 = rect.drawY2 + pad;
    end

    local function GetEntrySpacing(entry)
        local layout = (entry ~= nil and entry.rect ~= nil and entry.rect.anchorLayout) or (entry ~= nil and entry.layout);
        local spacing = tonumber(layout ~= nil and layout.anchorSpacing or nil);

        if (spacing == nil) then
            return 6;
        end

        return math.max(0, math.min(64, spacing));
    end

    local function GetEntryBounds(entry)
        if (entry ~= nil and entry.rects ~= nil and #entry.rects > 1) then
            local minX = nil;
            local minY = nil;
            local maxX = nil;
            local maxY = nil;

            for _, rect in ipairs(entry.rects) do
                minX = math.min(minX or rect.x1, tonumber(rect.x1) or 0);
                minY = math.min(minY or rect.y1, tonumber(rect.y1) or 0);
                maxX = math.max(maxX or rect.x2, tonumber(rect.x2) or 0);
                maxY = math.max(maxY or rect.y2, tonumber(rect.y2) or 0);
            end

            return {
                x = minX or 0,
                y = minY or 0,
                width = math.max(0, (maxX or 0) - (minX or 0)),
                height = math.max(0, (maxY or 0) - (minY or 0)),
                padding = 0,
            };
        end

        if (entry ~= nil and entry.rect ~= nil) then
            local rect = entry.rect;
            return {
                x = tonumber(rect.x1) or tonumber(rect.drawX1) or 0,
                y = tonumber(rect.y1) or tonumber(rect.drawY1) or 0,
                width = math.max(0, (tonumber(rect.x2) or tonumber(rect.drawX2) or 0) - (tonumber(rect.x1) or tonumber(rect.drawX1) or 0)),
                height = math.max(0, (tonumber(rect.y2) or tonumber(rect.drawY2) or 0) - (tonumber(rect.y1) or tonumber(rect.drawY1) or 0)),
                padding = tonumber(rect.padding) or 0,
            };
        end

        local slot = (entry ~= nil and entry.slot) or {};
        local padding = tonumber(entry ~= nil and entry.padding) or 0;
        return {
            x = (tonumber(slot.x) or 0) - padding,
            y = (tonumber(slot.y) or 0) - padding,
            width = math.max(0, (tonumber(slot.width) or 0) + (padding * 2)),
            height = math.max(0, (tonumber(slot.height) or 0) + (padding * 2)),
            padding = padding,
        };
    end

    -- An anchored element may itself be the parent of another anchored
    -- element (for example HP Bar -> MP Bar -> TP Bar).  Group placement
    -- changes the final parent bounds, so resolve repeatedly with fresh
    -- bounds until the complete chain settles.
    for _ = 1, 12 do
        bounds = BuildBoundsByKind(rects);
        groupingChanged = false;

        for _, group in pairs(groups) do
            local entries = group.entries or {};
            if (#entries > 0) then
                local anchorPoint = tostring(group.anchorPoint or 'Center');
                local axis = (anchorPoint == 'Top' or anchorPoint == 'Top Left' or anchorPoint == 'Top Right' or anchorPoint == 'Bottom' or anchorPoint == 'Bottom Left' or anchorPoint == 'Bottom Right') and 'y' or 'x';
                local nearHigh = axis == 'y'
                    and (anchorPoint == 'Top' or anchorPoint == 'Top Left' or anchorPoint == 'Top Right')
                    or (anchorPoint == 'Left');

                table.sort(entries, function(left, right)
                    local leftOrder = tonumber(left.anchorOrder);
                    local rightOrder = tonumber(right.anchorOrder);
                    if leftOrder ~= nil or rightOrder ~= nil then
                        leftOrder = leftOrder or 1000000;
                        rightOrder = rightOrder or 1000000;
                        if leftOrder ~= rightOrder then
                            return leftOrder < rightOrder;
                        end
                    end
                    return (tonumber(left.sourceOrder) or 0) < (tonumber(right.sourceOrder) or 0);
                end);

                local parentKey = anchorMap[tostring(group.anchorTo or '')];
                local startSlot = parentKey ~= nil and bounds[parentKey] or nil;

                if (startSlot == nil) then
                    startSlot = entries[1] ~= nil and GetEntryBounds(entries[1]) or nil;
                end

                if (startSlot ~= nil) then
                    local cursor = nil;
                    if (axis == 'x') then
                        cursor = nearHigh == true
                            and (tonumber(startSlot.x) or 0)
                            or ((tonumber(startSlot.x) or 0) + (tonumber(startSlot.width) or 0));
                    else
                        cursor = nearHigh == true
                            and (tonumber(startSlot.y) or 0)
                            or ((tonumber(startSlot.y) or 0) + (tonumber(startSlot.height) or 0));
                    end

                    for _, entry in ipairs(entries) do
                        local rect = entry.rect;
                        local entryBounds = GetEntryBounds(entry);
                        local groupedRects = entry.rects ~= nil and #entry.rects > 1;
                        local currentX = groupedRects == true and (tonumber(entryBounds.x) or 0) or (rect ~= nil and tonumber(rect.drawX1) or tonumber(entryBounds.x) or 0);
                        local currentY = groupedRects == true and (tonumber(entryBounds.y) or 0) or (rect ~= nil and tonumber(rect.drawY1) or tonumber(entryBounds.y) or 0);
                        local padding = tonumber(entryBounds.padding) or 0;
                        local itemW = math.max(0, tonumber(entryBounds.width) or 0);
                        local itemH = math.max(0, tonumber(entryBounds.height) or 0);
                        local targetX = currentX;
                        local targetY = currentY;
                        local gap = GetEntrySpacing(entry);

                        if (axis == 'x') then
                            if (nearHigh == true) then
                                local baseX = cursor - gap - itemW + padding;
                                targetX = baseX;
                                cursor = baseX - padding;
                            else
                                local baseX = cursor + gap + padding;
                                targetX = baseX;
                                cursor = baseX - padding + itemW;
                            end
                        else
                            if (nearHigh == true) then
                                local baseY = cursor - gap - itemH + padding;
                                targetY = baseY;
                                cursor = baseY - padding;
                            else
                                local baseY = cursor + gap + padding;
                                targetY = baseY;
                                cursor = baseY - padding + itemH;
                            end
                        end

                        if (entry.visible == true and rect ~= nil) then
                            local shiftX = targetX - currentX;
                            local shiftY = targetY - currentY;
                            if groupedRects == true then
                                for _, groupedRect in ipairs(entry.rects) do
                                    ApplyShift(groupedRect, shiftX, shiftY);
                                end
                            else
                                ApplyShift(rect, shiftX, shiftY);
                            end
                        end
                    end
                end
            end
        end

        if (groupingChanged ~= true) then
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
    local isTp = tostring(kind or '') == 'tp';
    local usesSegmentedProgress = isTp == true or bar.segmented == true;
    local maxProgress = usesSegmentedProgress == true and 300 or 100;
    progress = math.max(0, math.min(maxProgress, tonumber(progress) or maxProgress));

    local showAtPercent = usesSegmentedProgress == true
        and math.max(0, math.min(300, tonumber(bar.showAtPercent) or 300))
        or math.max(1, math.min(100, tonumber(bar.showAtPercent) or 100));

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
    if (usesSegmentedProgress == true) then
        hiddenByThreshold = progress < showAtPercent;
    end

    AddRect(rects, barX - borderSize, barY - borderSize, barW + (borderSize * 2), barH + (borderSize * 2), 4, kind, bar, hiddenByThreshold);

    if (hiddenByThreshold == true) then
        return;
    end

    local barText = tostring(bar.text or '');
    local secondaryText = tostring(bar.secondaryText or '');
    local labelText = tostring(bar.labelText or '');

    if (barText == '' and secondaryText == '' and labelText == '' and bar.iconTextureId == nil) then
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
    local _, secondaryW, secondaryH = gdiTextTexture.GetTexture(secondaryText, textOptions);
    local _, labelW, labelH = gdiTextTexture.GetTexture(labelText, textOptions);

    if (barText == '') then
        textW = 0;
        textH = 0;
    end

    if (labelText == '') then
        labelW = 0;
        labelH = 0;
    end
    if (secondaryText == '') then
        secondaryW = 0;
        secondaryH = 0;
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

    local labelKind = bar.labelKind or kind;

    if (iconSize > 0) then
        AddRect(rects, iconX, iconY, iconSize, iconSize, 4, labelKind);
    elseif (bar.separateLabelOffsets == true and labelText ~= '' and labelW ~= nil and labelH ~= nil and labelW > 0 and labelH > 0) then
        AddRect(
            rects,
            barX + ((barW - labelW) * 0.5) + (tonumber(bar.iconOffsetX) or 0),
            barY + ((barH - labelH) * 0.5) + (tonumber(bar.iconOffsetY) or 0),
            labelW,
            labelH,
            4,
            labelKind
        );
    end

    if (barText ~= '' and textW ~= nil and textH ~= nil and textW > 0 and textH > 0) then
        AddRect(rects, textX, textY, textW, textH, 4, bar.textKind or labelKind);
    end

    if (
        secondaryText ~= '' and
        secondaryW ~= nil and secondaryH ~= nil and
        secondaryW > 0 and secondaryH > 0
    ) then
        AddRect(
            rects,
            barX + ((barW - secondaryW) * 0.5) + (tonumber(bar.secondaryTextOffsetX) or 0),
            barY + ((barH - secondaryH) * 0.5) + (tonumber(bar.secondaryTextOffsetY) or 0),
            secondaryW,
            secondaryH,
            4,
            bar.secondaryTextKind or labelKind
        );
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
    local labelW = 0;
    local labelH = 0;

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

    if (labelValue ~= '') then
        local _, measuredW, measuredH = gdiTextTexture.GetTexture(labelValue, {
            fontFamily = ResolveFontFamily(badge.fontFamily),
            fontFlags = tonumber(badge.fontFlags) or 0,
            fontSize = math.max(8, tonumber(badge.fontSize) or 12),
            color = badge.textColor or { 1.0, 1.0, 1.0, 1.0 },
            outlineEnabled = badge.textOutlineEnabled == true,
            outlineColor = badge.textOutlineColor or { 0.0, 0.0, 0.0, 1.0 },
            outlineSize = tonumber(badge.textOutlineSize) or 0,
        });

        if (measuredW ~= nil and measuredH ~= nil and measuredW > 0 and measuredH > 0) then
            labelW = measuredW;
            labelH = measuredH;
        end
    end

    local iconSize = 0;
    local iconGap = 0;

    if (hasIcon == true) then
        local defaultIconSize = ((textH > 0) and textH) or ((labelH > 0) and labelH) or 16;
        iconSize = math.max(1, tonumber(badge.iconSize) or defaultIconSize);
        iconGap = math.max(0, tonumber(badge.iconGap) or 4);
    end

    local padX = math.max(0, tonumber(badge.paddingX) or 0);
    local padY = math.max(0, tonumber(badge.paddingY) or 0);
    local measuredTextW = (textW > 0) and textW or labelW;
    local measuredTextH = (textH > 0) and textH or labelH;
    local contentW = measuredTextW + iconSize + ((iconSize > 0 and measuredTextW > 0) and iconGap or 0);
    local contentH = math.max(measuredTextH, iconSize);

    if (badge.separateLabelOffsets == true) then
        local offsetX = tonumber(badge.offsetX) or 0;
        local offsetY = tonumber(badge.offsetY) or 0;
        local minX = nil;
        local minY = nil;
        local maxX = nil;
        local maxY = nil;

        local function includeRect(x, y, w, h)
            if (x == nil or y == nil or w == nil or h == nil or w <= 0 or h <= 0) then
                return;
            end

            minX = (minX == nil) and x or math.min(minX, x);
            minY = (minY == nil) and y or math.min(minY, y);
            maxX = (maxX == nil) and (x + w) or math.max(maxX, x + w);
            maxY = (maxY == nil) and (y + h) or math.max(maxY, y + h);
        end

        if (iconSize > 0) then
            includeRect(
                centerX + offsetX + (tonumber(badge.labelOffsetX) or 0) - (iconSize * 0.5),
                centerY + offsetY + (tonumber(badge.labelOffsetY) or 0) - (iconSize * 0.5),
                iconSize,
                iconSize
            );
        elseif (labelW > 0 and labelH > 0) then
            includeRect(
                centerX + offsetX + (tonumber(badge.labelOffsetX) or 0) - (labelW * 0.5),
                centerY + offsetY + (tonumber(badge.labelOffsetY) or 0) - (labelH * 0.5),
                labelW,
                labelH
            );
        end

        if (textW > 0 and textH > 0) then
            includeRect(
                centerX + offsetX + (tonumber(badge.textOffsetX) or 0) - (textW * 0.5),
                centerY + offsetY + (tonumber(badge.textOffsetY) or 0) - (textH * 0.5),
                textW,
                textH
            );
        end

        if (minX ~= nil and minY ~= nil and maxX ~= nil and maxY ~= nil) then
            local visibleW = maxX - minX;
            local visibleH = maxY - minY;
            local badgeW = math.max(tonumber(badge.minWidth) or 0, visibleW + (padX * 2));
            local badgeH = math.max(tonumber(badge.minHeight) or 0, visibleH + (padY * 2));
            local badgeX = minX + (visibleW * 0.5) - (badgeW * 0.5);
            local badgeY = minY + (visibleH * 0.5) - (badgeH * 0.5);

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
    end

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
    local resolvedOffsetX = 0;
    local resolvedOffsetY = 0;

    if (rect == nil) then
        return;
    end

    if (resolvedRect ~= nil) then
        local x = tonumber(resolvedRect.drawX1);
        local y = tonumber(resolvedRect.drawY1);

        if (x ~= nil and y ~= nil) then
            resolvedOffsetX = x - rect.x;
            resolvedOffsetY = y - rect.y;
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
        local resolvedCenterX = centerX + resolvedOffsetX;
        local resolvedCenterY = centerY + resolvedOffsetY;
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
                resolvedCenterX + (tonumber(badge.offsetX) or 0) + (tonumber(badge.labelOffsetX) or 0) - (rect.iconSize * 0.5),
                resolvedCenterY + (tonumber(badge.offsetY) or 0) + (tonumber(badge.labelOffsetY) or 0) - (rect.iconSize * 0.5),
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
                    resolvedCenterX + (tonumber(badge.offsetX) or 0) + (tonumber(badge.labelOffsetX) or 0) - (labelW * 0.5),
                    resolvedCenterY + (tonumber(badge.offsetY) or 0) + (tonumber(badge.labelOffsetY) or 0) - (labelH * 0.5),
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
                    resolvedCenterX + (tonumber(badge.offsetX) or 0) + (tonumber(badge.textOffsetX) or 0) - (textW * 0.5),
                    resolvedCenterY + (tonumber(badge.offsetY) or 0) + (tonumber(badge.textOffsetY) or 0) - (textH * 0.5),
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
        local borderSize = math.max(0, tonumber(background.borderSize) or 0);
        local border = math.min(borderSize, math.floor(math.min(bgW, bgH) * 0.5));

        AddRect(
            rects,
            bgX - border,
            bgY - border,
            bgW + (border * 2),
            bgH + (border * 2),
            0,
            'background',
            background
        );
    end

    AddBarRect(rects, centerX, centerY, plate.hpBar, hp, 'hp');
    AddBarRect(rects, centerX, centerY, plate.mpBar, mp, 'mp');
    AddBarRect(rects, centerX, centerY, plate.tpBar, math.max(0, math.min(300, tonumber(plate.tp) or 0)), 'tp');
    AddBarRect(rects, centerX, centerY, plate.castBar, math.max(0, math.min(100, tonumber(plate.cast) or 0)), 'cast');

    for _, extraBar in ipairs(plate.extraBars or {}) do
        local extraMaxProgress = extraBar.segmented == true and 300 or 100;
        AddBarRect(
            rects,
            centerX,
            centerY,
            extraBar,
            math.max(0, math.min(extraMaxProgress, tonumber(extraBar.progress) or 0)),
            extraBar.kind or 'bar'
        );
    end

    for _, badge in ipairs(plate.badges or {}) do
        local rect = GetBadgeRect(centerX, centerY, badge);

        if (rect ~= nil) then
            AddRect(rects, rect.x, rect.y, rect.w, rect.h, 4, badge.kind or 'badge', badge);
        end
    end

    for _, icon in ipairs(plate.icons or {}) do
        local iconSize = tonumber(icon.size) or 16;
        local iconW = tonumber(icon.width) or iconSize;
        local iconH = tonumber(icon.height) or iconSize;
        local iconX = centerX - (iconW * 0.5) + (tonumber(icon.offsetX) or 0);
        local iconY = centerY - (iconH * 0.5) + (tonumber(icon.offsetY) or 0);
        local iconKind = icon.kind or 'icon';

        AddRect(
            rects,
            iconX,
            iconY,
            iconW,
            iconH,
            4,
            iconKind,
            icon
        );

        -- Maneuver timers are drawn below their icons. Include that separate
        -- text area in content bounds without changing the icon's own layout rect.
        if (tostring(iconKind) == 'maneuvers' and tostring(icon.timerText or '') ~= '') then
            local timerOutline = math.max(0, tonumber(icon.timerTextOutlineSize) or 0);
            local timerHeight = math.max(
                8,
                ((tonumber(icon.timerFontSize) or 8) * 2) + (timerOutline * 2)
            );
            AddRect(
                rects,
                iconX,
                iconY + iconSize + 1 + (tonumber(icon.timerOffsetY) or 0),
                iconW,
                timerHeight,
                2,
                'maneuver_timer_bounds',
                nil
            );
        end
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
                    anchorCollapse = plate.jobAnchorCollapse,
                    anchorSpacing = plate.jobAnchorSpacing,
                    anchorOrder = plate.jobAnchorOrder,
                    offsetX = plate.jobOffsetX,
                    offsetY = plate.jobOffsetY,
                }
            );
        end
    end

    local plateName = (nativeUiPolicy.ShouldDrawLibraNames() == true or plate.forceName == true) and tostring(plate.name or '') or '';

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
                    anchorCollapse = plate.nameAnchorCollapse,
                    anchorSpacing = plate.nameAnchorSpacing,
                    anchorOrder = plate.nameAnchorOrder,
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

    local bgX, bgY, bgW, bgH = ResolveTargetMarkerBackgroundBounds(centerX, centerY, marker);

    AddRect(
        rects,
        bgX,
        bgY,
        bgW,
        bgH,
        0,
        'targetModuleBackground',
        nil,
        marker.backgroundClickable == false
    );
end

local function GetTargetMarkerDistanceScale(marker)
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
            AddRect(rects, lockX - (lockW * 0.5), lockY - (lockH * 0.5), lockW, lockH, 4, 'targetModuleLock', nil, true);
        end

        if (marker.showArrow == true and marker.arrowTextureId ~= nil) then
            AddRect(rects, arrowX - (arrowW * 0.5), arrowY - (arrowH * 0.5), arrowW, arrowH, 4, 'targetModuleArrow', nil, true);
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

        AddRect(rects, leftX - (chevW * 0.5), chevY, chevW, chevH, 4, 'targetModuleChevron', nil, true);
        AddRect(rects, rightX - (chevW * 0.5), chevY, chevW, chevH, 4, 'targetModuleChevron', nil, true);
    end
end

local function GetSignedCachedTexture(textureKey, renderSignature)
    if (renderSignature == nil) then
        return nil;
    end

    local cachedTexture = textures[textureKey];
    local cachedInfo = textureInfo[textureKey];
    if (
        cachedTexture == nil or
        cachedInfo == nil or
        cachedInfo.renderSignature ~= renderSignature
    ) then
        return nil;
    end

    TouchTextureKey(textureKey);
    return cachedTexture;
end

function canvasTexture.Render(plate, key, renderSignature)
    if (os.clock() < renderSuspendedUntil) then
        return nil, nil, nil;
    end

    local oldWidth = width;
    local oldHeight = height;
    local oldDrawOffsetX = drawOffsetX;
    local oldDrawOffsetY = drawOffsetY;
    local fullWidth = math.max(1024, tonumber(plate ~= nil and plate.canvasWidth) or oldWidth);
    local fullHeight = math.max(512, tonumber(plate ~= nil and plate.canvasHeight) or oldHeight);
    width = fullWidth;
    height = fullHeight;
    drawOffsetX = 0;
    drawOffsetY = 0;

    local function Finish(resultTexture, resultWidth, resultHeight)
        width = oldWidth;
        height = oldHeight;
        drawOffsetX = oldDrawOffsetX;
        drawOffsetY = oldDrawOffsetY;
        return resultTexture, resultWidth, resultHeight;
    end

    local device = d3d.get_device();

    if (device == nil or device.CreateTexture == nil or plate == nil) then
        return Finish(nil, width, height);
    end

    local centerX = fullWidth * 0.5;
    local centerY = fullHeight * 0.5;
    local elementRects = canvasTexture.GetElementRects(plate);
    local aoeHighlightRect = nil;

    if (plate.aoeHighlight ~= nil and plate.aoeHighlight.textureId ~= nil) then
        local highlight = plate.aoeHighlight;
        local highlightW = tonumber(highlight.width) or 220;
        local highlightH = tonumber(highlight.height) or 74;
        local highlightX = centerX - (highlightW * 0.5) + (tonumber(highlight.offsetX) or 0);
        local highlightY = centerY - (highlightH * 0.5) + (tonumber(highlight.offsetY) or 0);

        if (highlight.autoPlace ~= false) then
            local anchorRect = GetElementAnchorRect(elementRects, highlight.anchorKinds);
            if (anchorRect ~= nil) then
                local spacing = math.max(0, tonumber(highlight.spacing) or 0);
                highlightX = anchorRect.x1 - spacing + (tonumber(highlight.offsetX) or 0);
                highlightY = anchorRect.y1 - spacing + (tonumber(highlight.offsetY) or 0);
                highlightW = (anchorRect.x2 - anchorRect.x1) + (spacing * 2);
                highlightH = (anchorRect.y2 - anchorRect.y1) + (spacing * 2);
            end
        end

        aoeHighlightRect = { x = highlightX, y = highlightY, w = highlightW, h = highlightH };
        if (highlight.clickable ~= false) then
            AddRect(elementRects, highlightX, highlightY, highlightW, highlightH, 0, 'aoeHighlight');
        end
    end

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

    PrepareTargetMarker(plate.targetMarker);

    local baseKey = tostring(key or 'world');
    local crop = nil;
    if (baseKey == 'settings-preview') then
        crop = {
            x = 0,
            y = 0,
            width = fullWidth,
            height = fullHeight,
            fullWidth = fullWidth,
            fullHeight = fullHeight,
        };
    else
        crop = BuildContentCrop(elementRects, fullWidth, fullHeight, plate);
    end
    width = crop.width;
    height = crop.height;
    drawOffsetX = crop.x;
    drawOffsetY = crop.y;
    plate._elementRects = ShiftRects(elementRects, -drawOffsetX, -drawOffsetY);
    plate._canvasCrop = crop;

    local textureKey = baseKey .. '|crop=' .. tostring(crop.x) .. ',' .. tostring(crop.y) .. ',' .. tostring(width) .. 'x' .. tostring(height);
    local effectiveRenderSignature = renderSignature ~= nil
        and (tostring(renderVersion) .. '|' .. tostring(renderSignature))
        or nil;
    lastRenderBaseKey = baseKey;
    lastRenderTextureKey = textureKey;
    lastRenderSize = tostring(width) .. 'x' .. tostring(height);

    -- Detached pet frames and other explicitly signed canvases can retain the
    -- completed render target until something visible changes. Layout bounds
    -- are still rebuilt above, so dragging and hit testing remain current
    -- without spending another off-screen D3D render every frame.
    local cachedTexture = GetSignedCachedTexture(textureKey, effectiveRenderSignature);
    if (cachedTexture ~= nil) then
        return Finish(cachedTexture, width, height);
    end

    perfMeter.CountCanvasRender(plate, key);

    -- Always draw into a private staging texture. The live cache entry is
    -- replaced only after the entire draw and D3D restoration both succeed.
    -- A failed redraw therefore cannot overwrite or publish a black/partial
    -- plate.
    local targetTexture = CreateStagingTexture(device, textureKey);

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
        ReleaseInterface(surface);
        return Finish(nil, width, height);
    end

    local saved = {};
    local captureOk, captureErr = pcall(function()
        local function Capture(getter, label)
            local hr, value = getter();

            if hr ~= C.S_OK then
                error('Get ' .. tostring(label) .. ' failed with HRESULT ' .. tostring(hr));
            end

            return value;
        end

        saved.z = Capture(function() return device:GetRenderState(D3DRS_ZENABLE); end, 'ZENABLE');
        saved.light = Capture(function() return device:GetRenderState(D3DRS_LIGHTING); end, 'LIGHTING');
        saved.blend = Capture(function() return device:GetRenderState(D3DRS_ALPHABLENDENABLE); end, 'ALPHABLENDENABLE');
        saved.src = Capture(function() return device:GetRenderState(D3DRS_SRCBLEND); end, 'SRCBLEND');
        saved.dst = Capture(function() return device:GetRenderState(D3DRS_DESTBLEND); end, 'DESTBLEND');
        saved.fvf = Capture(function() return device:GetVertexShader(); end, 'VERTEXSHADER');
        saved.texture = Capture(function() return device:GetTexture(0); end, 'TEXTURE0');
        saved.pixelShader = Capture(function() return device:GetPixelShader(); end, 'PIXELSHADER');
        saved.colorOp = Capture(function() return device:GetTextureStageState(0, D3DTSS_COLOROP); end, 'COLOROP');
        saved.colorArg1 = Capture(function() return device:GetTextureStageState(0, D3DTSS_COLORARG1); end, 'COLORARG1');
        saved.colorArg2 = Capture(function() return device:GetTextureStageState(0, D3DTSS_COLORARG2); end, 'COLORARG2');
        saved.alphaOp = Capture(function() return device:GetTextureStageState(0, D3DTSS_ALPHAOP); end, 'ALPHAOP');
        saved.alphaArg1 = Capture(function() return device:GetTextureStageState(0, D3DTSS_ALPHAARG1); end, 'ALPHAARG1');
        saved.alphaArg2 = Capture(function() return device:GetTextureStageState(0, D3DTSS_ALPHAARG2); end, 'ALPHAARG2');
        saved.viewport = Capture(function() return device:GetViewport(); end, 'VIEWPORT');
    end);

    if (captureOk ~= true) then
        ReleaseInterface(saved.texture);
        ReleaseInterface(oldTarget);
        ReleaseInterface(surface);
        Finish(nil, width, height);
        error('Canvas state capture failed for ' .. textureKey .. ': ' .. tostring(captureErr), 0);
    end

    local setOk, setHr = pcall(function()
        return device:SetRenderTarget(surface);
    end);

    local drawOk = false;
    local drawErr = nil;

    if (setOk == true and setHr == C.S_OK) then
        drawOk, drawErr = pcall(function()
            RequireD3dSuccess(device:Clear(0, nil, 1, 0x00000000, 1.0, 0), 'Clear canvas');
            RequireD3dSuccess(device:SetPixelShader(0), 'SetPixelShader');
            RequireD3dSuccess(device:SetRenderState(D3DRS_ZENABLE, 0), 'Set ZENABLE');
            RequireD3dSuccess(device:SetRenderState(D3DRS_LIGHTING, 0), 'Set LIGHTING');
            RequireD3dSuccess(device:SetRenderState(D3DRS_ALPHABLENDENABLE, 1), 'Set ALPHABLENDENABLE');
            RequireD3dSuccess(device:SetRenderState(D3DRS_SRCBLEND, 5), 'Set SRCBLEND');
            RequireD3dSuccess(device:SetRenderState(D3DRS_DESTBLEND, 6), 'Set DESTBLEND');

            local hp = math.max(0, math.min(100, tonumber(plate.hp) or 100)) / 100;
            local mp = math.max(0, math.min(100, tonumber(plate.mp) or 100));
            local tp = math.max(0, math.min(300, tonumber(plate.tp) or 0));

            local function DrawTargetMarkerStack(marker, pass)
                if (marker == nil) then
                    return;
                end

                for _, stackedMarker in ipairs(marker.stackedMarkers or {}) do
                    DrawTargetMarker(device, centerX, centerY, stackedMarker, pass);
                end

                DrawTargetMarker(device, centerX, centerY, marker, pass);
            end

            local function DrawExtraBars(behindBackground)
                local extraBarOccurrences = {};

                for _, extraBar in ipairs(plate.extraBars or {}) do
                    local extraBarKind = tostring(extraBar.kind or 'bar');
                    extraBarOccurrences[extraBarKind] = (extraBarOccurrences[extraBarKind] or 0) + 1;

                    if ((extraBar.behindBackground == true) == behindBackground) then
                        local extraBarRect = FindRect(
                            elementRects,
                            extraBarKind,
                            extraBarOccurrences[extraBarKind]
                        );
                        local renderBar = extraBar;

                        if (
                            behindBackground == true and
                            (
                                extraBar.foregroundLabel == true or
                                extraBarKind == 'ready' or
                                extraBarKind == 'sic' or
                                extraBarKind == 'reward'
                            )
                        ) then
                            renderBar = {};
                            for key, value in pairs(extraBar) do
                                renderBar[key] = value;
                            end
                            renderBar.text = '';
                            renderBar.secondaryText = '';
                            renderBar.labelText = '';
                            renderBar.iconTextureId = nil;
                        end

                        if (tostring(renderBar.displayMode or '') == 'Ring') then
                            DrawRingProgress(device, centerX, centerY, renderBar, math.max(0, math.min(100, tonumber(renderBar.progress) or 0)), renderBar.color or { 0.90, 0.65, 0.25, 1.0 }, extraBarRect);
                        elseif (renderBar.segmented == true) then
                            DrawTpBar(device, centerX, centerY, renderBar, math.max(0, math.min(300, tonumber(renderBar.progress) or 0)), renderBar.color or { 0.90, 0.65, 0.25, 1.0 }, extraBarRect);
                        else
                            DrawBar(device, centerX, centerY, renderBar, math.max(0, math.min(100, tonumber(renderBar.progress) or 0)), renderBar.color or { 0.90, 0.65, 0.25, 1.0 }, extraBarRect);
                        end
                    end
                end
            end

            local function DrawForegroundExtraBarLabels()
                local extraBarOccurrences = {};

                for _, extraBar in ipairs(plate.extraBars or {}) do
                    local extraBarKind = tostring(extraBar.kind or 'bar');
                    extraBarOccurrences[extraBarKind] = (extraBarOccurrences[extraBarKind] or 0) + 1;

                    if (
                        extraBar.behindBackground == true and
                        (
                            extraBar.foregroundLabel == true or
                            extraBarKind == 'ready' or
                            extraBarKind == 'sic' or
                            extraBarKind == 'reward'
                        )
                    ) then
                        local extraBarRect = FindRect(
                            elementRects,
                            extraBarKind,
                            extraBarOccurrences[extraBarKind]
                        );

                        if (extraBarRect ~= nil and extraBarRect.anchorOnly ~= true) then
                            local borderSize = math.max(0, tonumber(extraBar.borderSize) or 0);
                            local barX = (tonumber(extraBarRect.drawX1) or tonumber(extraBarRect.x1) or 0) + borderSize;
                            local barY = (tonumber(extraBarRect.drawY1) or tonumber(extraBarRect.y1) or 0) + borderSize;
                            local barW = math.max(
                                1,
                                (tonumber(extraBarRect.drawX2) or tonumber(extraBarRect.x2) or barX)
                                    - barX
                                    - borderSize
                            );
                            local barH = math.max(
                                1,
                                (tonumber(extraBarRect.drawY2) or tonumber(extraBarRect.y2) or barY)
                                    - barY
                                    - borderSize
                            );
                            DrawBarLabel(device, barX, barY, barW, barH, extraBar);
                        end
                    end
                end
            end

            DrawExtraBars(true);
            DrawPlateBackground(device, centerX, centerY, plate.background, FindRect(elementRects, 'background'));
            if (aoeHighlightRect ~= nil) then
                DrawTexture(
                    device,
                    plate.aoeHighlight.textureId,
                    aoeHighlightRect.x,
                    aoeHighlightRect.y,
                    aoeHighlightRect.w,
                    aoeHighlightRect.h,
                    ColorToD3D(plate.aoeHighlight.color, { 1.0, 0.82, 0.10, 0.95 })
                );
            end
            DrawTargetMarkerStack(plate.targetMarker, 'background');
            DrawTargetMarkerStack(plate.targetMarker, 'foreground');
            DrawBar(device, centerX, centerY, plate.mpBar, mp, { 0.25, 0.45, 1.0, 0.95 }, FindRect(elementRects, 'mp'));
            DrawBar(device, centerX, centerY, plate.hpBar, hp * 100, { 0.20, 0.95, 0.34, 0.95 }, FindRect(elementRects, 'hp'));
            DrawTpBar(device, centerX, centerY, plate.tpBar, tp, { 1.0, 0.70, 0.18, 0.95 }, FindRect(elementRects, 'tp'));
            DrawBar(device, centerX, centerY, plate.castBar, math.max(0, math.min(100, tonumber(plate.cast) or 0)), { 0.65, 0.35, 1.0, 0.95 }, FindRect(elementRects, 'cast'));

            DrawExtraBars(false);
            DrawForegroundExtraBarLabels();

            local function DrawForegroundBarLabel(kind, bar)
                local textRect = FindRect(elementRects, kind);
                if (bar == nil or textRect == nil or textRect.anchorOnly == true or tostring(bar.text or '') == '') then
                    return;
                end

                local borderSize = math.max(0, tonumber(bar.borderSize) or 0);
                local textX = (tonumber(textRect.drawX1) or tonumber(textRect.x1) or 0) + borderSize;
                local textY = (tonumber(textRect.drawY1) or tonumber(textRect.y1) or 0) + borderSize;
                local textW = math.max(1, (tonumber(textRect.drawX2) or tonumber(textRect.x2) or textX) - textX - borderSize);
                local textH = math.max(1, (tonumber(textRect.drawY2) or tonumber(textRect.y2) or textY) - textY - borderSize);
                DrawBarLabel(device, textX, textY, textW, textH, bar);
            end

            DrawForegroundBarLabel('hp', plate.hpBar);
            DrawForegroundBarLabel('mp', plate.mpBar);
            DrawForegroundBarLabel('tp', plate.tpBar);

            local badgeOccurrences = {};

            for _, badge in ipairs(plate.badges or {}) do
                local badgeKind = tostring(badge.kind or 'badge');

                badgeOccurrences[badgeKind] = (badgeOccurrences[badgeKind] or 0) + 1;
                DrawBadge(device, centerX, centerY, badge, FindRect(elementRects, badgeKind, badgeOccurrences[badgeKind]));
            end

            local iconOccurrences = {};

            for _, icon in ipairs(plate.icons or {}) do
                local iconSize = tonumber(icon.size) or 16;
                local iconW = tonumber(icon.width) or iconSize;
                local iconH = tonumber(icon.height) or iconSize;
                local iconX = centerX - (iconW * 0.5) + (tonumber(icon.offsetX) or 0);
                local iconY = centerY - (iconH * 0.5) + (tonumber(icon.offsetY) or 0);
                local iconKind = tostring(icon.kind or 'icon');

                iconOccurrences[iconKind] = (iconOccurrences[iconKind] or 0) + 1;

                local iconRect = FindRect(elementRects, iconKind, iconOccurrences[iconKind]);

                if (iconRect ~= nil) then
                    iconX = tonumber(iconRect.drawX1) or iconX;
                    iconY = tonumber(iconRect.drawY1) or iconY;
                    iconW = math.max(1, (tonumber(iconRect.drawX2) or (iconX + iconW)) - iconX);
                    iconH = math.max(1, (tonumber(iconRect.drawY2) or (iconY + iconH)) - iconY);
                    iconSize = math.max(iconW, iconH);
                end

                local iconBackgroundWarningColor = GetTimerWarningColor(icon, 'iconBackground');
                local iconBorderWarningColor = GetTimerWarningColor(icon, 'iconBorder');
                local timerFontWarningColor = GetTimerWarningColor(icon, 'font');
                local timerOutlineWarningColor = GetTimerWarningColor(icon, 'outline');
                local timerBoxWarningColor = GetTimerWarningColor(icon, 'box');
                local timerBoxBorderWarningColor = GetTimerWarningColor(icon, 'boxBorder');

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

                local iconTint = icon.tint;

                if (iconKind == 'linkshellIcon') then
                    iconTint = BoostColor(icon.tint, 1.65, 1.0);
                end

                DrawTexture(
                    device,
                    icon.textureId,
                    iconX,
                    iconY,
                    iconW,
                    iconH,
                    ColorToD3D(iconTint, { 1.0, 1.0, 1.0, 1.0 })
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
                        outlineColor = (timerOutlineWarningColor ~= nil and icon.timerWarningOutlineColorEnabled == true) and timerOutlineWarningColor or icon.timerTextOutlineColor or { 0.0, 0.0, 0.0, 1.0 },
                        outlineSize = tonumber(icon.timerTextOutlineSize) or 1,
                    };
                    local timerTextureId, timerW, timerH = gdiTextTexture.GetTexture(timerText, timerFontOptions);

                    if (timerTextureId ~= nil and timerW ~= nil and timerH ~= nil and timerW > 0 and timerH > 0) then
                        local timerBoxW = timerW;
                        local timerBoxH = timerH;
                        local timerBoxX = iconX + ((iconSize - timerBoxW) * 0.5) + (tonumber(icon.timerOffsetX) or 0);
                        local timerY = iconY + iconSize + 1 + (tonumber(icon.timerOffsetY) or 0);

                        if (icon.timerBackground == true) then
                            local sampleText = string.find(timerText, 'm', 1, true) ~= nil and '88m' or '88s';
                            local _, sampleW = gdiTextTexture.GetTexture(sampleText, timerFontOptions);

                            timerBoxW = math.max(timerW, tonumber(sampleW) or 0);
                            timerBoxX = iconX + ((iconSize - timerBoxW) * 0.5) + (tonumber(icon.timerOffsetX) or 0);

                            local padX = tonumber(icon.timerBackgroundPaddingX) or 2;
                            local padY = tonumber(icon.timerBackgroundPaddingY) or 1;
                            -- GDI text textures reserve ascender space above the visible glyphs.
                            -- Move the box down slightly so the visible timer text, rather than
                            -- the texture's transparent bounds, is vertically centered.
                            local visualCenterOffsetY = math.max(0, math.floor((timerH * 0.15) + 0.5));
                            local boxColor = ColorToD3D(
                                (timerBoxWarningColor ~= nil and icon.timerWarningBoxColorEnabled == true) and timerBoxWarningColor or GetTimerBackgroundColor(icon),
                                { 0.0, 0.0, 0.0, 0.80 }
                            );
                            local borderSize = math.max(0, tonumber(icon.timerBackgroundBorderSize) or 0);

                            DrawRoundedRectWithBorder(
                                device,
                                timerBoxX - padX,
                                timerY - padY + visualCenterOffsetY,
                                timerBoxW + (padX * 2),
                                timerBoxH + (padY * 2),
                                boxColor,
                                ColorToD3D(
                                    (timerBoxBorderWarningColor ~= nil and icon.timerWarningBoxBorderEnabled == true) and timerBoxBorderWarningColor or icon.timerBackgroundBorderColor,
                                    { 0.0, 0.0, 0.0, 1.0 }
                                ),
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

            local plateName = (nativeUiPolicy.ShouldDrawLibraNames() == true or plate.forceName == true) and tostring(plate.name or '') or '';
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

                for _, rect in ipairs(elementRects or {}) do
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
    else
        drawErr = setOk == true
            and ('SetRenderTarget failed with HRESULT ' .. tostring(setHr))
            or tostring(setHr);
    end

    local restoreErrors = {};
    local function Restore(label, callback)
        local ok, result = pcall(callback);

        if (ok ~= true) then
            restoreErrors[#restoreErrors + 1] = tostring(label) .. ': ' .. tostring(result);
        elseif result ~= nil and result ~= C.S_OK then
            restoreErrors[#restoreErrors + 1] = tostring(label) .. ': HRESULT ' .. tostring(result);
        end
    end

    -- Attempt every restoration even if an earlier one fails. This prevents a
    -- single bad Set call from skipping the remaining D3D cleanup.
    Restore('render target', function() device:SetRenderTarget(oldTarget); end);
    Restore('viewport', function() device:SetViewport(saved.viewport); end);
    Restore('texture 0', function() device:SetTexture(0, saved.texture); end);
    Restore('ZENABLE', function() device:SetRenderState(D3DRS_ZENABLE, saved.z); end);
    Restore('LIGHTING', function() device:SetRenderState(D3DRS_LIGHTING, saved.light); end);
    Restore('ALPHABLENDENABLE', function() device:SetRenderState(D3DRS_ALPHABLENDENABLE, saved.blend); end);
    Restore('SRCBLEND', function() device:SetRenderState(D3DRS_SRCBLEND, saved.src); end);
    Restore('DESTBLEND', function() device:SetRenderState(D3DRS_DESTBLEND, saved.dst); end);
    Restore('VERTEXSHADER', function() device:SetVertexShader(saved.fvf); end);
    Restore('PIXELSHADER', function() device:SetPixelShader(saved.pixelShader or 0); end);
    Restore('COLOROP', function() device:SetTextureStageState(0, D3DTSS_COLOROP, saved.colorOp); end);
    Restore('COLORARG1', function() device:SetTextureStageState(0, D3DTSS_COLORARG1, saved.colorArg1); end);
    Restore('COLORARG2', function() device:SetTextureStageState(0, D3DTSS_COLORARG2, saved.colorArg2); end);
    Restore('ALPHAOP', function() device:SetTextureStageState(0, D3DTSS_ALPHAOP, saved.alphaOp); end);
    Restore('ALPHAARG1', function() device:SetTextureStageState(0, D3DTSS_ALPHAARG1, saved.alphaArg1); end);
    Restore('ALPHAARG2', function() device:SetTextureStageState(0, D3DTSS_ALPHAARG2, saved.alphaArg2); end);

    ReleaseInterface(saved.texture);
    ReleaseInterface(oldTarget);
    ReleaseInterface(surface);

    if (drawOk ~= true or #restoreErrors > 0) then
        local parts = {};

        if (drawOk ~= true) then
            parts[#parts + 1] = 'draw: ' .. tostring(drawErr);
        end

        if (#restoreErrors > 0) then
            parts[#parts + 1] = 'restore: ' .. table.concat(restoreErrors, '; ');
        end

        Finish(nil, width, height);
        error('Canvas render failed for ' .. textureKey .. ': ' .. table.concat(parts, ' | '), 0);
    end

    local publishOk, publishedTexture = pcall(
        PublishTexture,
        textureKey,
        baseKey,
        targetTexture,
        crop,
        effectiveRenderSignature
    );

    if (publishOk ~= true) then
        Finish(nil, width, height);
        error('Canvas cache publish failed for ' .. textureKey .. ': ' .. tostring(publishedTexture), 0);
    end

    return Finish(publishedTexture, width, height);
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
        '|assetIconPack=' .. tostring(iconPack.GetName()) ..
        '|renderVersion=' .. tostring(renderVersion);
end

function canvasTexture.TouchKey(key)
    return TouchTextureKey(key);
end

function canvasTexture.TouchTextureForKey(key, texture)
    key = tostring(key or '');

    local id = TextureId(texture);
    local actualKey = id ~= nil and textureIdToKey[id] or nil;

    if (key == '' or actualKey == nil) then
        return false;
    end

    if (actualKey ~= key) then
        local aliases = textureAliases[key];

        if (type(aliases) ~= 'table' or aliases[actualKey] ~= true) then
            return false;
        end
    end

    return TouchTextureKey(actualKey);
end

function canvasTexture.ReleaseKey(key)
    -- Plate caches are cleared from render/update callbacks.  Their previous
    -- textures can still be referenced by a queued draw, so treat an explicit
    -- release as a request and retain anything touched during the grace
    -- window.  The global LRU will reclaim it once it is safely idle.
    return ReleaseTextureKeyIfIdle(key);
end

function canvasTexture.Invalidate()
    -- Cache signatures include renderVersion, so bumping it forces every
    -- owner to redraw its canvas.  Do not release render targets immediately:
    -- settings callbacks run during a render frame and queued world/ImGui
    -- draws may still reference those textures until the frame is submitted.
    renderVersion = renderVersion + 1;
end

function canvasTexture.GetRenderVersion()
    return renderVersion;
end

function canvasTexture.SuspendForZone(seconds)
    renderSuspendedUntil = math.max(
        renderSuspendedUntil,
        os.clock() + math.max(1.0, tonumber(seconds) or 3.0)
    );
    canvasTexture.Invalidate();
end

function canvasTexture.HandlePacketIn(e)
    if (e ~= nil and tonumber(e.id) == 0x000A) then
        canvasTexture.SuspendForZone(3.0);
    end
end

function canvasTexture.HandleLogin()
    canvasTexture.SuspendForZone(3.0);
end

function canvasTexture.Clear()
    textures = {};
    textureInfo = {};
    textureOrder = {};
    textureIdToKey = {};
    textureAliases = {};
    textureCount = 0;
    textureEvictions = 0;
    evictionWindowStart = os.clock();
    evictionWindowCount = 0;
    evictionRatePerMinute = 0;
    lastEvictedKey = '';
    lastEvictedAt = 0;
    lastRenderBaseKey = '';
    lastRenderTextureKey = '';
    lastRenderSize = '';
    retiredTextureSequence = 0;
    retiredTextureKeys = {};
    lastIdlePruneAt = 0;
end

function canvasTexture.GetCacheStats()
    local now = os.clock();
    local elapsed = math.max(0.01, now - (tonumber(evictionWindowStart) or now));
    local currentRate = evictionWindowCount > 0 and ((evictionWindowCount / elapsed) * 60.0) or evictionRatePerMinute;

    return {
        count = textureCount,
        max = maxTextures,
        evictions = textureEvictions,
        evictionsPerMinute = currentRate,
        lastEvictedKey = lastEvictedKey,
        lastEvictedAgo = (lastEvictedAt > 0) and (now - lastEvictedAt) or nil,
        lastRenderKey = lastRenderBaseKey,
        lastRenderTextureKey = lastRenderTextureKey,
        lastRenderSize = lastRenderSize,
    };
end

function canvasTexture.SetCacheLimit(value)
    maxTextures = math.max(32, math.min(256, math.floor((tonumber(value) or maxTextures) + 0.5)));
    TrimTextureCache();

    return maxTextures;
end

return canvasTexture;
