-- ==========================================================
-- = DEPENDENCIES =
-- ==========================================================

require('common');

local ffi = require('ffi');
local bit = require('bit');
local d3d8 = require('d3d8');
local defaultImgui = require('imgui');
local gdiTextTexture = require('ui.gdi_text_texture');
local targeting = require('core.targeting');

-- ==========================================================
-- = D3D CONSTANTS =
-- ==========================================================

ffi.cdef[[
    typedef struct {
        float x, y, z;
        unsigned int color;
    } lp_world_marker_vertex_t;

    typedef struct {
        float x, y, z;
        unsigned int color;
        float tu, tv;
    } lp_world_marker_text_vertex_t;

    typedef struct {
        float x, y, z, rhw;
        unsigned int color;
        float tu, tv;
    } lp_world_marker_screen_vertex_t;

    typedef struct {
        float x, y, z;
    } lp_d3dx_vector3_t;

    typedef void (__thiscall* lp_get_nameplate_offset_f)(void* pThis, int32_t idx, lp_d3dx_vector3_t* vec3);
    void* __stdcall GetForegroundWindow(void);
    void* __stdcall GetActiveWindow(void);
]];

local D3DPT_TRIANGLELIST = 4;
local D3DFVF_XYZ_DIFFUSE = 0x042;
local D3DFVF_XYZ_DIFFUSE_TEX1 = 0x142;
local D3DFVF_XYZRHW_DIFFUSE_TEX1 = 0x144;
local D3DRS_ZENABLE = 7;
local D3DRS_ZWRITEENABLE = 14;
local D3DRS_ALPHATESTENABLE = 15;
local D3DRS_SRCBLEND = 19;
local D3DRS_DESTBLEND = 20;
local D3DRS_CULLMODE = 22;
local D3DRS_ZFUNC = 23;
local D3DRS_ALPHAREF = 24;
local D3DRS_ALPHAFUNC = 25;
local D3DRS_ZBIAS = 47;
local D3DRS_ALPHABLENDENABLE = 27;
local D3DRS_LIGHTING = 137;
local D3DCMP_LESSEQUAL = 4;
local D3DCMP_GREATEREQUAL = 7;
local D3DCMP_ALWAYS = 8;
local D3DTS_WORLD = 256;

local D3DTSS_COLOROP = 1;
local D3DTSS_COLORARG1 = 2;
local D3DTSS_COLORARG2 = 3;
local D3DTSS_ALPHAOP = 4;
local D3DTSS_ALPHAARG1 = 5;
local D3DTSS_ADDRESSU = 13;
local D3DTSS_ADDRESSV = 14;
local D3DTSS_MAGFILTER = 16;
local D3DTSS_MINFILTER = 17;

local D3DTOP_DISABLE = 1;
local D3DTOP_SELECTARG1 = 2;
local D3DTA_DIFFUSE = 0;
local D3DTA_TEXTURE = 2;
local D3DTEXF_POINT = 1;
local D3DTEXF_LINEAR = 2;
local D3DTADDRESS_CLAMP = 3;

local DOT_SEGMENTS = 12;
local MAX_TEXT_CHARS = 32;
local VERTEX_SIZE = 16;
local TEXTURED_VERTEX_SIZE = 24;
local SCREEN_VERTEX_SIZE = 28;

-- ==========================================================
-- = STATE =
-- ==========================================================

local worldMarkerProbe = {};

local enabled = false;
local replacePlates = false;
local compareAnchors = false;
local showText = false;
local showDistance = false;
local showCanvasCenter = false;
local pass = 0;
local anchorMode = 'bone';
local anchorBone = 2;
local verticalOffset = 0.16;
local nameVerticalOffset = 0.54;
local queuedPlates = {};
local queuedPlateSet = {};
local selfClickRect = nil;
local selfClickRects = nil;
local clickRects = {};
local pendingClickRects = {};
local pendingSelfClickRect = nil;
local pendingSelfClickRects = nil;
local clickDebugEnabled = true;
local clickDebugVisible = false;
local lastQueuedCount = 0;
local lastDrawCount = 0;
local lastError = nil;
local lastClickStatus = 'none';
local clickVersion = 'projection-20260525-1';
local suppressNextLeftRelease = false;
local rightDownPlate = nil;
local lastSelfJobText = '';
local lastSelfJobEnabled = false;
local lastSelfJobMode = 0;
local clickSelectTarget = nil;
local clickSelectEnemyTarget = nil;
local clickAttackEnemyTarget = nil;
local helperPointer = nil;
local helperStatus = 'not-searched';
local fontAtlasTexture = nil;
local fontBaked = nil;
local fontStatus = 'not-ready';
local imguiApi = defaultImgui;
local user32 = nil;
local lastWindowFocused = nil;
local suppressFocusClickUntil = 0;
local suppressFocusRelease = false;
local verts = ffi.new('lp_world_marker_vertex_t[?]', DOT_SEGMENTS * 3);
local textVerts = ffi.new('lp_world_marker_text_vertex_t[?]', MAX_TEXT_CHARS * 6);
local identity = ffi.new('D3DMATRIX');
identity._11 = 1;
identity._22 = 1;
identity._33 = 1;
identity._44 = 1;
local ortho = ffi.new('D3DMATRIX');

local function SafeNumber(fn)
    local ok, value = pcall(fn);

    if (ok ~= true) then
        return nil;
    end

    return tonumber(value);
end

local function IsPlayerEngaged()
    local party = nil;

    pcall(function()
        party = AshitaCore:GetMemoryManager():GetParty();
    end);

    if (party == nil) then
        return false;
    end

    local status = SafeNumber(function()
        if (party.GetMemberStatus ~= nil) then
            return party:GetMemberStatus(0);
        end

        return nil;
    end);

    if (status == 1) then
        return true;
    end

    local targetIndex = SafeNumber(function()
        return party:GetMemberTargetIndex(0);
    end);

    if (targetIndex == nil or targetIndex == 0) then
        return false;
    end

    status = SafeNumber(function()
        local entityManager = AshitaCore:GetMemoryManager():GetEntity();

        if (entityManager ~= nil and entityManager.GetStatus ~= nil) then
            return entityManager:GetStatus(targetIndex);
        end

        return nil;
    end);

    return status == 1;
end

local function GetUser32()
    if (user32 ~= nil) then
        return user32;
    end

    local ok, loaded = pcall(function()
        return ffi.load('user32');
    end);

    if (ok == true and loaded ~= nil) then
        user32 = loaded;
    end

    return user32;
end

local function IsGameWindowFocused()
    local lib = GetUser32();

    if (lib == nil) then
        return nil;
    end

    local ok, foreground, active = pcall(function()
        return lib.GetForegroundWindow(), lib.GetActiveWindow();
    end);

    if (ok ~= true or foreground == nil or active == nil) then
        return nil;
    end

    return foreground == active and foreground ~= ffi.NULL;
end

function worldMarkerProbe.UpdateFocusState()
    local focused = IsGameWindowFocused();

    if (focused == nil) then
        return;
    end

    if (lastWindowFocused == false and focused == true) then
        suppressFocusClickUntil = os.clock() + 0.75;
        suppressFocusRelease = true;
        lastClickStatus = 'focus returned suppressing next plate click';
    end

    lastWindowFocused = focused == true;
end

-- ==========================================================
-- = HELPERS =
-- ==========================================================

local function CopyMatrix(m)
    if (m == nil) then
        return nil;
    end

    return {
        _11 = m._11, _12 = m._12, _13 = m._13, _14 = m._14,
        _21 = m._21, _22 = m._22, _23 = m._23, _24 = m._24,
        _31 = m._31, _32 = m._32, _33 = m._33, _34 = m._34,
        _41 = m._41, _42 = m._42, _43 = m._43, _44 = m._44,
    };
end

local function MatrixFromTable(t)
    if (t == nil) then
        return nil;
    end

    local m = ffi.new('D3DMATRIX');
    m._11 = t._11; m._12 = t._12; m._13 = t._13; m._14 = t._14;
    m._21 = t._21; m._22 = t._22; m._23 = t._23; m._24 = t._24;
    m._31 = t._31; m._32 = t._32; m._33 = t._33; m._34 = t._34;
    m._41 = t._41; m._42 = t._42; m._43 = t._43; m._44 = t._44;
    return m;
end

local function GetBillboardVectors(device)
    local _, view = device:GetTransform(2);

    if (view == nil) then
        return 1, 0, 0, 0, -1, 0;
    end

    local rx = tonumber(view._11) or 1;
    local ry = tonumber(view._21) or 0;
    local rz = tonumber(view._31) or 0;
    local ux = tonumber(view._12) or 0;
    local uy = tonumber(view._22) or -1;
    local uz = tonumber(view._32) or 0;

    local rlen = math.sqrt((rx * rx) + (ry * ry) + (rz * rz));
    local ulen = math.sqrt((ux * ux) + (uy * uy) + (uz * uz));

    if (rlen > 0.001) then
        rx = rx / rlen; ry = ry / rlen; rz = rz / rlen;
    end

    if (ulen > 0.001) then
        ux = ux / ulen; uy = uy / ulen; uz = uz / ulen;
    end

    return rx, ry, rz, ux, uy, uz;
end

local function EnsureFontAtlas()
    if (fontAtlasTexture ~= nil and fontBaked ~= nil) then
        return true;
    end

    if (imguiApi == nil or imguiApi.GetFont == nil) then
        fontStatus = 'imgui-missing';
        return false;
    end

    local ok, font = pcall(function () return imguiApi.GetFont(); end);

    if (ok ~= true or font == nil) then
        fontStatus = 'font-nil';
        return false;
    end

    local atlas = font.ContainerAtlas or font.Atlas;

    if (atlas == nil) then
        fontStatus = 'atlas-missing';
        return false;
    end

    local texRef = atlas.TexRef or atlas.TexID or atlas._TexID;

    if (texRef == nil) then
        fontStatus = 'texref-missing';
        return false;
    end

    local texId = nil;
    ok, texId = pcall(function ()
        if (type(texRef) == 'number') then
            return texRef;
        end

        if (texRef.GetTexID ~= nil) then
            return texRef:GetTexID();
        end

        return texRef._TexID;
    end);

    if (ok ~= true or texId == nil or texId == 0) then
        ok, texId = pcall(function () return texRef._TexID; end);
    end

    if (ok ~= true or texId == nil or texId == 0) then
        fontStatus = 'texid-missing';
        return false;
    end

    local baked = nil;
    ok, baked = pcall(function () return imguiApi.GetFontBaked(); end);

    if (ok ~= true or baked == nil) then
        ok, baked = pcall(function () return font.LastBaked; end);
    end

    if (ok ~= true or baked == nil) then
        fontStatus = 'bake-missing';
        return false;
    end

    local glyphOk, glyph = pcall(function () return baked:FindGlyph(65); end);

    if (glyphOk ~= true or glyph == nil) then
        fontStatus = 'glyph-missing';
        return false;
    end

    fontAtlasTexture = ffi.cast('IDirect3DBaseTexture8*', ffi.cast('uintptr_t', texId));
    fontBaked = baked;
    fontStatus = 'ok';
    return true;
end

local function ProjectWithZ(view, proj, vpWidth, vpHeight, wx, wy, wz)
    local vx = wx * view._11 + wy * view._21 + wz * view._31 + view._41;
    local vy = wx * view._12 + wy * view._22 + wz * view._32 + view._42;
    local vz = wx * view._13 + wy * view._23 + wz * view._33 + view._43;
    local vw = wx * view._14 + wy * view._24 + wz * view._34 + view._44;
    local cx = vx * proj._11 + vy * proj._21 + vz * proj._31 + vw * proj._41;
    local cy = vx * proj._12 + vy * proj._22 + vz * proj._32 + vw * proj._42;
    local cz = vx * proj._13 + vy * proj._23 + vz * proj._33 + vw * proj._43;
    local cw = vx * proj._14 + vy * proj._24 + vz * proj._34 + vw * proj._44;

    if (cw <= 0.001) then
        return nil;
    end

    return
        ((cx / cw) * 0.5 + 0.5) * vpWidth,
        (-(cy / cw) * 0.5 + 0.5) * vpHeight,
        cz / cw;
end

local function AddPlateClickRects(targetIndex, targetType, rects, union, metadata)
    if (targetIndex == nil or targetIndex == 0 or rects == nil or #rects == 0 or union == nil) then
        return;
    end

    local entry = {
        targetIndex = targetIndex,
        targetType = tostring(targetType or 'self'),
        serverId = metadata ~= nil and metadata.serverId or nil,
        name = metadata ~= nil and metadata.name or nil,
        layoutStateName = metadata ~= nil and metadata.layoutStateName or nil,
        trustIsMine = metadata ~= nil and metadata.trustIsMine or nil,
        distance = metadata ~= nil and metadata.distance or nil,
        modelHitboxSize = metadata ~= nil and metadata.modelHitboxSize or nil,
        plateTextureId = metadata ~= nil and metadata.plateTextureId or nil,
        plateOverlayRect = metadata ~= nil and metadata.plateOverlayRect or nil,
        clickEnabled = metadata == nil or metadata.clickEnabled ~= false,
        rects = rects,
        union = union,
    };

    pendingClickRects[#pendingClickRects + 1] = entry;

    if (entry.targetType == 'self') then
        pendingSelfClickRects = rects;
        pendingSelfClickRect = {
            targetIndex = targetIndex,
            targetType = entry.targetType,
            serverId = entry.serverId,
            name = entry.name,
            layoutStateName = entry.layoutStateName,
            x1 = union.x1,
            y1 = union.y1,
            x2 = union.x2,
            y2 = union.y2,
        };
    end
end

local function SetSelfClickRectFromBillboard(device, targetIndex, wx, wy, wz, worldWidth, worldHeight)
    if (device == nil or targetIndex == nil or targetIndex == 0) then
        return;
    end

    local _, view = device:GetTransform(2);
    local _, proj = device:GetTransform(3);
    local _, viewport = device:GetViewport();

    if (view == nil or proj == nil or viewport == nil or viewport.Width == nil or viewport.Height == nil) then
        return;
    end

    local rx, ry, rz, ux, uy, uz = GetBillboardVectors(device);
    local halfWidth = (tonumber(worldWidth) or 0.84) * 0.5;
    local halfHeight = (tonumber(worldHeight) or 0.315) * 0.5;
    local points = {
        { wx, wy, wz },
        { wx - (rx * halfWidth), wy - (ry * halfWidth), wz - (rz * halfWidth) },
        { wx + (rx * halfWidth), wy + (ry * halfWidth), wz + (rz * halfWidth) },
        { wx - (ux * halfHeight), wy - (uy * halfHeight), wz - (uz * halfHeight) },
        { wx + (ux * halfHeight), wy + (uy * halfHeight), wz + (uz * halfHeight) },
    };
    local left = nil;
    local top = nil;
    local right = nil;
    local bottom = nil;

    for _, point in ipairs(points) do
        local sx, sy = ProjectWithZ(view, proj, viewport.Width, viewport.Height, point[1], point[2], point[3]);

        if (sx ~= nil and sy ~= nil) then
            left = (left == nil) and sx or math.min(left, sx);
            top = (top == nil) and sy or math.min(top, sy);
            right = (right == nil) and sx or math.max(right, sx);
            bottom = (bottom == nil) and sy or math.max(bottom, sy);
        end
    end

    if (left == nil or top == nil or right == nil or bottom == nil) then
        return;
    end

    local padding = 10;
    local rect = {
        targetIndex = targetIndex,
        targetType = 'self',
        x1 = left - padding,
        y1 = top - padding,
        x2 = right + padding,
        y2 = bottom + padding,
    };

    AddPlateClickRects(targetIndex, 'self', { rect }, rect);
end

local function ProjectBillboardPoint(view, proj, viewport, wx, wy, wz, rx, ry, rz, ux, uy, uz, offsetX, offsetY)
    return ProjectWithZ(
        view,
        proj,
        viewport.Width,
        viewport.Height,
        wx + (rx * offsetX) - (ux * offsetY),
        wy + (ry * offsetX) - (uy * offsetY),
        wz + (rz * offsetX) - (uz * offsetY)
    );
end

local function SetSelfClickRectsFromCanvas(device, targetIndex, wx, wy, wz, style, worldWidth, worldHeight)
    if (device == nil or targetIndex == nil or targetIndex == 0 or style == nil or style.plateClickRects == nil) then
        return false;
    end

    local _, view = device:GetTransform(2);
    local _, proj = device:GetTransform(3);
    local _, viewport = device:GetViewport();

    if (view == nil or proj == nil or viewport == nil or viewport.Width == nil or viewport.Height == nil) then
        return false;
    end

    local textureWidth = math.max(1, tonumber(style.plateTextureWidth) or 1024);
    local textureHeight = math.max(1, tonumber(style.plateTextureHeight) or 512);
    local rx, ry, rz, ux, uy, uz = GetBillboardVectors(device);
    local rects = {};
    local union = nil;
    local targetType = tostring(style.clickTargetType or 'self');
    local metadata = {
        serverId = style.serverId,
        name = style.clickName,
        layoutStateName = style.layoutStateName,
        trustIsMine = style.trustIsMine,
        distance = style.distance,
        modelHitboxSize = style.modelHitboxSize,
        plateTextureId = style.plateAlwaysOnTop == true and style.plateTextureId or nil,
        plateOverlayRect = nil,
        clickEnabled = style.plateClickTargetEnabled ~= false,
    };

    local function projectCanvasPixel(px, py)
        local localX = (((tonumber(px) or 0) / textureWidth) - 0.5) * worldWidth;
        local localY = (0.5 - ((tonumber(py) or 0) / textureHeight)) * worldHeight;

        return ProjectWithZ(
            view,
            proj,
            viewport.Width,
            viewport.Height,
            wx + (rx * localX) + (ux * localY),
            wy + (ry * localX) + (uy * localY),
            wz + (rz * localX) + (uz * localY)
        );
    end

    local function setOverlayRect()
        if (style.plateAlwaysOnTop ~= true) then
            return;
        end

        local points = {
            { 0, 0 },
            { textureWidth, 0 },
            { textureWidth, textureHeight },
            { 0, textureHeight },
        };
        local left = nil;
        local top = nil;
        local right = nil;
        local bottom = nil;

        for _, point in ipairs(points) do
            local sx, sy = projectCanvasPixel(point[1], point[2]);

            if (sx ~= nil and sy ~= nil) then
                left = (left == nil) and sx or math.min(left, sx);
                top = (top == nil) and sy or math.min(top, sy);
                right = (right == nil) and sx or math.max(right, sx);
                bottom = (bottom == nil) and sy or math.max(bottom, sy);
            end
        end

        if (left ~= nil and top ~= nil and right ~= nil and bottom ~= nil) then
            metadata.plateOverlayRect = { x1 = left, y1 = top, x2 = right, y2 = bottom };
        end
    end

    setOverlayRect();

    for _, rect in ipairs(style.plateClickRects) do
        if (rect.anchorOnly ~= true) then
            local points = {
                { rect.x1, rect.y1 },
                { rect.x2, rect.y1 },
                { rect.x2, rect.y2 },
                { rect.x1, rect.y2 },
            };
            local left = nil;
            local top = nil;
            local right = nil;
            local bottom = nil;

            for _, point in ipairs(points) do
                local sx, sy = projectCanvasPixel(point[1], point[2]);

                if (sx ~= nil and sy ~= nil) then
                    left = (left == nil) and sx or math.min(left, sx);
                    top = (top == nil) and sy or math.min(top, sy);
                    right = (right == nil) and sx or math.max(right, sx);
                    bottom = (bottom == nil) and sy or math.max(bottom, sy);
                end
            end

            if (left ~= nil and top ~= nil and right ~= nil and bottom ~= nil) then
                local padding = 3;
                local screenRect = {
                    kind = rect.kind,
                    targetIndex = targetIndex,
                    targetType = targetType,
                    x1 = left - padding,
                    y1 = top - padding,
                    x2 = right + padding,
                    y2 = bottom + padding,
                };

                rects[#rects + 1] = screenRect;

                if (union == nil) then
                    union = { x1 = screenRect.x1, y1 = screenRect.y1, x2 = screenRect.x2, y2 = screenRect.y2 };
                else
                    union.x1 = math.min(union.x1, screenRect.x1);
                    union.y1 = math.min(union.y1, screenRect.y1);
                    union.x2 = math.max(union.x2, screenRect.x2);
                    union.y2 = math.max(union.y2, screenRect.y2);
                end
            end
        end
    end

    if (#rects > 0 and union ~= nil) then
        AddPlateClickRects(targetIndex, targetType, rects, union, metadata);
        return true;
    end

    local fullPoints = {
        { worldWidth * -0.5, worldHeight * -0.5 },
        { worldWidth * 0.5, worldHeight * -0.5 },
        { worldWidth * 0.5, worldHeight * 0.5 },
        { worldWidth * -0.5, worldHeight * 0.5 },
    };
    local fullLeft = nil;
    local fullTop = nil;
    local fullRight = nil;
    local fullBottom = nil;

    for _, point in ipairs(fullPoints) do
        local sx, sy = ProjectBillboardPoint(view, proj, viewport, wx, wy, wz, rx, ry, rz, ux, uy, uz, point[1], point[2]);

        if (sx ~= nil and sy ~= nil) then
            fullLeft = (fullLeft == nil) and sx or math.min(fullLeft, sx);
            fullTop = (fullTop == nil) and sy or math.min(fullTop, sy);
            fullRight = (fullRight == nil) and sx or math.max(fullRight, sx);
            fullBottom = (fullBottom == nil) and sy or math.max(fullBottom, sy);
        end
    end

    if (fullLeft == nil or fullTop == nil or fullRight == nil or fullBottom == nil) then
        return false;
    end

    local fullWidth = math.max(1, fullRight - fullLeft);
    local fullHeight = math.max(1, fullBottom - fullTop);

    for _, rect in ipairs(style.plateClickRects) do
        local left = fullLeft + ((tonumber(rect.x1) or 0) / textureWidth) * fullWidth;
        local top = fullTop + ((tonumber(rect.y1) or 0) / textureHeight) * fullHeight;
        local right = fullLeft + ((tonumber(rect.x2) or 0) / textureWidth) * fullWidth;
        local bottom = fullTop + ((tonumber(rect.y2) or 0) / textureHeight) * fullHeight;
        local padding = 3;
        local screenRect = {
            kind = rect.kind,
            targetIndex = targetIndex,
            targetType = targetType,
            x1 = math.min(left, right) - padding,
            y1 = math.min(top, bottom) - padding,
            x2 = math.max(left, right) + padding,
            y2 = math.max(top, bottom) + padding,
        };

        rects[#rects + 1] = screenRect;

        if (union == nil) then
            union = { x1 = screenRect.x1, y1 = screenRect.y1, x2 = screenRect.x2, y2 = screenRect.y2 };
        else
            union.x1 = math.min(union.x1, screenRect.x1);
            union.y1 = math.min(union.y1, screenRect.y1);
            union.x2 = math.max(union.x2, screenRect.x2);
            union.y2 = math.max(union.y2, screenRect.y2);
        end
    end

    if (#rects == 0 or union == nil) then
        return false;
    end

    AddPlateClickRects(targetIndex, targetType, rects, union, metadata);
    return true;
end

local function GetWorldUnitsPerPixelAlongVector(device, wx, wy, wz, vx, vy, vz)
    local _, view = device:GetTransform(2);
    local _, proj = device:GetTransform(3);
    local _, viewport = device:GetViewport();

    if (view == nil or proj == nil or viewport == nil or viewport.Width == nil or viewport.Height == nil) then
        return nil;
    end

    local x1, y1 = ProjectWithZ(view, proj, viewport.Width, viewport.Height, wx, wy, wz);
    local x2, y2 = ProjectWithZ(view, proj, viewport.Width, viewport.Height, wx + vx, wy + vy, wz + vz);

    if (x1 == nil or y1 == nil or x2 == nil or y2 == nil) then
        return nil;
    end

    local pixelsPerWorldUnit = math.sqrt(((x2 - x1) * (x2 - x1)) + ((y2 - y1) * (y2 - y1)));

    if (pixelsPerWorldUnit == nil or pixelsPerWorldUnit <= 0.001) then
        return nil;
    end

    return 1 / pixelsPerWorldUnit;
end

local function MeasureText(text, scale)
    local width = 0;
    local len = math.min(#text, MAX_TEXT_CHARS);

    for i = 1, len do
        local glyph = fontBaked:FindGlyph(string.byte(text, i));

        if (glyph ~= nil) then
            width = width + (glyph.AdvanceX * scale);
        end
    end

    return width;
end

local function BuildText(text, color, sx, sy, z, scale)
    local vi = 0;
    local cursorX = 0;
    local len = math.min(#text, MAX_TEXT_CHARS);

    for i = 1, len do
        local glyph = fontBaked:FindGlyph(string.byte(text, i));

        if (glyph ~= nil) then
            if ((glyph.X1 - glyph.X0) > 0 and (glyph.Y1 - glyph.Y0) > 0) then
                local x0 = sx + cursorX + glyph.X0 * scale;
                local y0 = sy + glyph.Y0 * scale;
                local x1 = sx + cursorX + glyph.X1 * scale;
                local y1 = sy + glyph.Y1 * scale;

                textVerts[vi].x = x0; textVerts[vi].y = y0; textVerts[vi].z = z; textVerts[vi].color = color; textVerts[vi].tu = glyph.U0; textVerts[vi].tv = glyph.V0;
                textVerts[vi + 1].x = x1; textVerts[vi + 1].y = y0; textVerts[vi + 1].z = z; textVerts[vi + 1].color = color; textVerts[vi + 1].tu = glyph.U1; textVerts[vi + 1].tv = glyph.V0;
                textVerts[vi + 2].x = x0; textVerts[vi + 2].y = y1; textVerts[vi + 2].z = z; textVerts[vi + 2].color = color; textVerts[vi + 2].tu = glyph.U0; textVerts[vi + 2].tv = glyph.V1;
                textVerts[vi + 3].x = x1; textVerts[vi + 3].y = y0; textVerts[vi + 3].z = z; textVerts[vi + 3].color = color; textVerts[vi + 3].tu = glyph.U1; textVerts[vi + 3].tv = glyph.V0;
                textVerts[vi + 4].x = x1; textVerts[vi + 4].y = y1; textVerts[vi + 4].z = z; textVerts[vi + 4].color = color; textVerts[vi + 4].tu = glyph.U1; textVerts[vi + 4].tv = glyph.V1;
                textVerts[vi + 5].x = x0; textVerts[vi + 5].y = y1; textVerts[vi + 5].z = z; textVerts[vi + 5].color = color; textVerts[vi + 5].tu = glyph.U0; textVerts[vi + 5].tv = glyph.V1;
                vi = vi + 6;
            end

            cursorX = cursorX + (glyph.AdvanceX * scale);
        end
    end

    return vi;
end

local function BuildTextureQuad(x, y, z, width, height, color)
    textVerts[0].x = x; textVerts[0].y = y; textVerts[0].z = z; textVerts[0].color = color; textVerts[0].tu = 0; textVerts[0].tv = 0;
    textVerts[1].x = x + width; textVerts[1].y = y; textVerts[1].z = z; textVerts[1].color = color; textVerts[1].tu = 1; textVerts[1].tv = 0;
    textVerts[2].x = x; textVerts[2].y = y + height; textVerts[2].z = z; textVerts[2].color = color; textVerts[2].tu = 0; textVerts[2].tv = 1;
    textVerts[3].x = x + width; textVerts[3].y = y; textVerts[3].z = z; textVerts[3].color = color; textVerts[3].tu = 1; textVerts[3].tv = 0;
    textVerts[4].x = x + width; textVerts[4].y = y + height; textVerts[4].z = z; textVerts[4].color = color; textVerts[4].tu = 1; textVerts[4].tv = 1;
    textVerts[5].x = x; textVerts[5].y = y + height; textVerts[5].z = z; textVerts[5].color = color; textVerts[5].tu = 0; textVerts[5].tv = 1;
end

local function ColorTableToD3D(color, fallback)
    color = color or fallback or { 1.0, 1.0, 1.0, 1.0 };

    if (type(color) == 'number') then
        return color;
    end

    local r = tonumber(color[1]) or 1.0;
    local g = tonumber(color[2]) or 1.0;
    local b = tonumber(color[3]) or 1.0;
    local a = tonumber(color[4]) or 1.0;

    if (r <= 1) then r = r * 255; end
    if (g <= 1) then g = g * 255; end
    if (b <= 1) then b = b * 255; end
    if (a <= 1) then a = a * 255; end

    r = math.max(0, math.min(255, math.floor(r + 0.5)));
    g = math.max(0, math.min(255, math.floor(g + 0.5)));
    b = math.max(0, math.min(255, math.floor(b + 0.5)));
    a = math.max(0, math.min(255, math.floor(a + 0.5)));

    return (a * 0x1000000) + (r * 0x10000) + (g * 0x100) + b;
end

local function BuildTextureBillboardQuad(wx, wy, wz, rx, ry, rz, ux, uy, uz, width, height, color)
    local halfWidth = width * 0.5;
    local halfHeight = height * 0.5;
    local leftX = wx - (rx * halfWidth);
    local leftY = wy - (ry * halfWidth);
    local leftZ = wz - (rz * halfWidth);
    local rightX = wx + (rx * halfWidth);
    local rightY = wy + (ry * halfWidth);
    local rightZ = wz + (rz * halfWidth);
    local topLeftX = leftX + (ux * halfHeight);
    local topLeftY = leftY + (uy * halfHeight);
    local topLeftZ = leftZ + (uz * halfHeight);
    local topRightX = rightX + (ux * halfHeight);
    local topRightY = rightY + (uy * halfHeight);
    local topRightZ = rightZ + (uz * halfHeight);
    local bottomLeftX = leftX - (ux * halfHeight);
    local bottomLeftY = leftY - (uy * halfHeight);
    local bottomLeftZ = leftZ - (uz * halfHeight);
    local bottomRightX = rightX - (ux * halfHeight);
    local bottomRightY = rightY - (uy * halfHeight);
    local bottomRightZ = rightZ - (uz * halfHeight);

    textVerts[0].x = topLeftX; textVerts[0].y = topLeftY; textVerts[0].z = topLeftZ; textVerts[0].color = color; textVerts[0].tu = 0; textVerts[0].tv = 0;
    textVerts[1].x = topRightX; textVerts[1].y = topRightY; textVerts[1].z = topRightZ; textVerts[1].color = color; textVerts[1].tu = 1; textVerts[1].tv = 0;
    textVerts[2].x = bottomLeftX; textVerts[2].y = bottomLeftY; textVerts[2].z = bottomLeftZ; textVerts[2].color = color; textVerts[2].tu = 0; textVerts[2].tv = 1;
    textVerts[3].x = topRightX; textVerts[3].y = topRightY; textVerts[3].z = topRightZ; textVerts[3].color = color; textVerts[3].tu = 1; textVerts[3].tv = 0;
    textVerts[4].x = bottomRightX; textVerts[4].y = bottomRightY; textVerts[4].z = bottomRightZ; textVerts[4].color = color; textVerts[4].tu = 1; textVerts[4].tv = 1;
    textVerts[5].x = bottomLeftX; textVerts[5].y = bottomLeftY; textVerts[5].z = bottomLeftZ; textVerts[5].color = color; textVerts[5].tu = 0; textVerts[5].tv = 1;
end

local DrawQuad = nil;

local function DrawDot(device, wx, wy, wz, size)
    local rx, ry, rz, ux, uy, uz = GetBillboardVectors(device);
    local core = 0xFFFF2A2A;
    local edge = 0x99FFCC00;
    local step = (2 * math.pi) / DOT_SEGMENTS;
    local vi = 0;

    for i = 0, DOT_SEGMENTS - 1 do
        local a1 = i * step;
        local a2 = (i + 1) * step;
        local c1 = math.cos(a1);
        local s1 = math.sin(a1);
        local c2 = math.cos(a2);
        local s2 = math.sin(a2);

        verts[vi].x = wx;
        verts[vi].y = wy;
        verts[vi].z = wz;
        verts[vi].color = core;
        vi = vi + 1;

        verts[vi].x = wx + ((rx * c1) + (ux * s1)) * size;
        verts[vi].y = wy + ((ry * c1) + (uy * s1)) * size;
        verts[vi].z = wz + ((rz * c1) + (uz * s1)) * size;
        verts[vi].color = edge;
        vi = vi + 1;

        verts[vi].x = wx + ((rx * c2) + (ux * s2)) * size;
        verts[vi].y = wy + ((ry * c2) + (uy * s2)) * size;
        verts[vi].z = wz + ((rz * c2) + (uz * s2)) * size;
        verts[vi].color = edge;
        vi = vi + 1;
    end

    device:DrawPrimitiveUP(D3DPT_TRIANGLELIST, DOT_SEGMENTS, verts, VERTEX_SIZE);
end

local function DrawCanvasDebugWithState(device, wx, wy, wz, width, height, dotSize)
    if (device == nil or wx == nil or wy == nil or wz == nil) then
        return;
    end

    width = math.max(0.05, tonumber(width) or 0.84);
    height = math.max(0.05, tonumber(height) or 0.315);

    local _, saveLight = device:GetRenderState(D3DRS_LIGHTING);
    local _, saveZ = device:GetRenderState(D3DRS_ZENABLE);
    local _, saveZWrite = device:GetRenderState(D3DRS_ZWRITEENABLE);
    local _, saveZFunc = device:GetRenderState(D3DRS_ZFUNC);
    local _, saveZBias = device:GetRenderState(D3DRS_ZBIAS);
    local _, saveBlend = device:GetRenderState(D3DRS_ALPHABLENDENABLE);
    local _, saveSrc = device:GetRenderState(D3DRS_SRCBLEND);
    local _, saveDst = device:GetRenderState(D3DRS_DESTBLEND);
    local _, saveCull = device:GetRenderState(D3DRS_CULLMODE);
    local _, saveAlphaTest = device:GetRenderState(D3DRS_ALPHATESTENABLE);
    local _, saveFvf = device:GetVertexShader();
    local _, saveTex = device:GetTexture(0);
    local _, savePixelShader = device:GetPixelShader();
    local _, rawWorld = device:GetTransform(D3DTS_WORLD);
    local saveWorld = CopyMatrix(rawWorld);
    local _, saveColorOp = device:GetTextureStageState(0, D3DTSS_COLOROP);
    local _, saveColorArg1 = device:GetTextureStageState(0, D3DTSS_COLORARG1);
    local _, saveColorArg2 = device:GetTextureStageState(0, D3DTSS_COLORARG2);
    local _, saveAlphaOp = device:GetTextureStageState(0, D3DTSS_ALPHAOP);
    local _, saveAlphaArg1 = device:GetTextureStageState(0, D3DTSS_ALPHAARG1);

    device:SetTexture(0, nil);
    device:SetVertexShader(D3DFVF_XYZ_DIFFUSE);
    device:SetPixelShader(0);
    device:SetRenderState(D3DRS_LIGHTING, 0);
    device:SetRenderState(D3DRS_CULLMODE, 1);
    device:SetRenderState(D3DRS_ALPHABLENDENABLE, 1);
    device:SetRenderState(D3DRS_SRCBLEND, 5);
    device:SetRenderState(D3DRS_DESTBLEND, 6);
    device:SetRenderState(D3DRS_ZENABLE, 0);
    device:SetRenderState(D3DRS_ZWRITEENABLE, 0);
    device:SetRenderState(D3DRS_ZFUNC, D3DCMP_ALWAYS);
    device:SetRenderState(D3DRS_ZBIAS, 0);
    device:SetRenderState(D3DRS_ALPHATESTENABLE, 0);
    device:SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_SELECTARG1);
    device:SetTextureStageState(0, D3DTSS_COLORARG1, D3DTA_DIFFUSE);
    device:SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_SELECTARG1);
    device:SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_DIFFUSE);
    device:SetTransform(D3DTS_WORLD, identity);

    pcall(function ()
        local rx, ry, rz, ux, uy, uz = GetBillboardVectors(device);
        DrawQuad(device, wx, wy, wz, rx, ry, rz, ux, uy, uz, width * 0.5, height * 0.5, 0xAA00FFFF);
        DrawDot(device, wx, wy, wz, tonumber(dotSize) or 0.075);
    end);

    if (saveWorld ~= nil) then device:SetTransform(D3DTS_WORLD, MatrixFromTable(saveWorld)); end
    device:SetTexture(0, saveTex);
    device:SetRenderState(D3DRS_LIGHTING, saveLight);
    device:SetRenderState(D3DRS_ZENABLE, saveZ);
    device:SetRenderState(D3DRS_ZWRITEENABLE, saveZWrite);
    device:SetRenderState(D3DRS_ZFUNC, saveZFunc);
    device:SetRenderState(D3DRS_ZBIAS, saveZBias);
    device:SetRenderState(D3DRS_ALPHABLENDENABLE, saveBlend);
    device:SetRenderState(D3DRS_SRCBLEND, saveSrc);
    device:SetRenderState(D3DRS_DESTBLEND, saveDst);
    device:SetRenderState(D3DRS_CULLMODE, saveCull);
    device:SetRenderState(D3DRS_ALPHATESTENABLE, saveAlphaTest);
    device:SetTextureStageState(0, D3DTSS_COLOROP, saveColorOp);
    device:SetTextureStageState(0, D3DTSS_COLORARG1, saveColorArg1);
    device:SetTextureStageState(0, D3DTSS_COLORARG2, saveColorArg2);
    device:SetTextureStageState(0, D3DTSS_ALPHAOP, saveAlphaOp);
    device:SetTextureStageState(0, D3DTSS_ALPHAARG1, saveAlphaArg1);
    device:SetVertexShader(saveFvf);
    if (savePixelShader ~= nil) then device:SetPixelShader(savePixelShader); end
end

DrawQuad = function(device, wx, wy, wz, rx, ry, rz, ux, uy, uz, halfWidth, halfHeight, color)
    local leftX = wx - (rx * halfWidth);
    local leftY = wy - (ry * halfWidth);
    local leftZ = wz - (rz * halfWidth);
    local rightX = wx + (rx * halfWidth);
    local rightY = wy + (ry * halfWidth);
    local rightZ = wz + (rz * halfWidth);
    local topLeftX = leftX + (ux * halfHeight);
    local topLeftY = leftY + (uy * halfHeight);
    local topLeftZ = leftZ + (uz * halfHeight);
    local topRightX = rightX + (ux * halfHeight);
    local topRightY = rightY + (uy * halfHeight);
    local topRightZ = rightZ + (uz * halfHeight);
    local bottomLeftX = leftX - (ux * halfHeight);
    local bottomLeftY = leftY - (uy * halfHeight);
    local bottomLeftZ = leftZ - (uz * halfHeight);
    local bottomRightX = rightX - (ux * halfHeight);
    local bottomRightY = rightY - (uy * halfHeight);
    local bottomRightZ = rightZ - (uz * halfHeight);

    verts[0].x = topLeftX; verts[0].y = topLeftY; verts[0].z = topLeftZ; verts[0].color = color;
    verts[1].x = topRightX; verts[1].y = topRightY; verts[1].z = topRightZ; verts[1].color = color;
    verts[2].x = bottomLeftX; verts[2].y = bottomLeftY; verts[2].z = bottomLeftZ; verts[2].color = color;
    verts[3].x = topRightX; verts[3].y = topRightY; verts[3].z = topRightZ; verts[3].color = color;
    verts[4].x = bottomRightX; verts[4].y = bottomRightY; verts[4].z = bottomRightZ; verts[4].color = color;
    verts[5].x = bottomLeftX; verts[5].y = bottomLeftY; verts[5].z = bottomLeftZ; verts[5].color = color;

    device:DrawPrimitiveUP(D3DPT_TRIANGLELIST, 2, verts, VERTEX_SIZE);
end

local function Clamp01(value)
    value = tonumber(value) or 0;

    if (value < 0) then return 0; end
    if (value > 1) then return 1; end

    return value;
end

local function GetCurrentDistance(targetIndex, fallback)
    local ent = GetEntity(targetIndex);
    local distanceSq = ent ~= nil and tonumber(ent.Distance) or nil;

    if (distanceSq ~= nil and distanceSq >= 0) then
        return math.sqrt(distanceSq);
    end

    return tonumber(fallback);
end

local function GetPlateDistanceScale(style, targetIndex, fallbackDistance)
    style = style or {};

    local maxScale = tonumber(style.plateDistanceScaleMax) or 1.0;

    if (maxScale <= 1.0) then
        return 1.0;
    end

    local distance = GetCurrentDistance(targetIndex, fallbackDistance);

    if (distance == nil) then
        return 1.0;
    end

    local scaleStart = tonumber(style.plateDistanceScaleStart) or 2.0;
    local scaleEnd = tonumber(style.plateDistanceScaleEnd) or 8.0;
    local span = math.max(0.1, scaleEnd - scaleStart);
    local progress = math.max(0.0, math.min(1.0, (distance - scaleStart) / span));

    return 1.0 + ((maxScale - 1.0) * progress);
end

local function DrawWorldResourceBar(device, wx, wy, wz, rx, ry, rz, ux, uy, uz, progress, barStyle)
    barStyle = barStyle or {};

    if (barStyle.enabled ~= true) then
        return;
    end

    local width = tonumber(barStyle.worldWidth) or 0.42;
    local height = tonumber(barStyle.worldHeight) or 0.045;
    local offsetX = tonumber(barStyle.worldOffsetX) or 0;
    local offsetY = tonumber(barStyle.worldOffsetY) or 0;
    local centerX = wx + (rx * offsetX) - (ux * offsetY);
    local centerY = wy + (ry * offsetX) - (uy * offsetY);
    local centerZ = wz + (rz * offsetX) - (uz * offsetY);
    local fillColor = ColorTableToD3D(barStyle.color, { 0.22, 0.95, 0.38, 0.93 });
    local fillProgress = Clamp01(progress);
    local fillWidth = width * fillProgress;

    if (fillWidth > 0.001) then
        local fillCenterOffset = ((fillWidth - width) * 0.5);

        DrawQuad(
            device,
            centerX + (rx * fillCenterOffset),
            centerY + (ry * fillCenterOffset),
            centerZ + (rz * fillCenterOffset),
            rx, ry, rz,
            ux, uy, uz,
            fillWidth * 0.5,
            height * 0.5,
            fillColor
        );
    end
end

local function CopyBarStyleWithOffset(barStyle, worldOffsetY)
    if (barStyle == nil) then
        return nil;
    end

    local copy = {};

    for key, value in pairs(barStyle) do
        copy[key] = value;
    end

    copy.worldOffsetY = worldOffsetY;

    return copy;
end

local function DrawMiniPlate(device, wx, wy, wz, hpPercent, style, color)
    local rx, ry, rz, ux, uy, uz = GetBillboardVectors(device);
    local hp = math.max(0, math.min(100, tonumber(hpPercent) or 100)) / 100;
    style = style or {};

    if (color ~= nil) then
        local temporaryStyle = {
            enabled = true,
            worldWidth = tonumber(style.hpBarWorldWidth) or 0.42,
            worldHeight = tonumber(style.hpBarWorldHeight) or 0.045,
            worldOffsetX = 0,
            worldOffsetY = 0,
            color = color,
            backgroundColor = { 0.0, 0.0, 0.0, 0.0 },
        };
        DrawWorldResourceBar(device, wx, wy, wz, rx, ry, rz, ux, uy, uz, hp, temporaryStyle);
        return;
    end

    DrawWorldResourceBar(device, wx, wy, wz, rx, ry, rz, ux, uy, uz, hp, style.hpBar or {
        enabled = true,
        worldWidth = tonumber(style.hpBarWorldWidth) or 0.42,
        worldHeight = tonumber(style.hpBarWorldHeight) or 0.045,
        worldOffsetX = 0,
        worldOffsetY = 0,
        color = style.hpBarColor,
        backgroundColor = { 0.0, 0.0, 0.0, 0.0 },
    });
end

local function DrawSelfResourceBars(device, wx, wy, wz, plate)
    local style = plate.worldMarker or {};
    local rx, ry, rz, ux, uy, uz = GetBillboardVectors(device);
    local _, view = device:GetTransform(2);
    local fx = 0;
    local fy = 0;
    local fz = 0;
    local hpPercent = math.max(0, math.min(100, tonumber(plate.hp) or 0));
    local mpPercent = math.max(0, math.min(100, tonumber(plate.mp) or 0));
    local tpValue = tonumber(plate.tp);

    if (tpValue == nil and plate.vitals ~= nil) then
        tpValue = tonumber(plate.vitals.tp);
    end

    if (view ~= nil) then
        fx = -(tonumber(view._13) or 0);
        fy = -(tonumber(view._23) or 0);
        fz = -(tonumber(view._33) or 0);

        local flen = math.sqrt((fx * fx) + (fy * fy) + (fz * fz));

        if (flen > 0.001) then
            fx = fx / flen;
            fy = fy / flen;
            fz = fz / flen;
        else
            fx = 0;
            fy = 0;
            fz = 0;
        end
    end

    local modelDepthLift = tonumber(style.selfBarModelDepthLift) or 0.18;
    wx = wx + (fx * modelDepthLift);
    wy = wy + (fy * modelDepthLift);
    wz = wz + (fz * modelDepthLift);

    local hpOffsetY = tonumber(style.hpBar ~= nil and style.hpBar.worldOffsetY) or 0.24;
    local mpOffsetY = tonumber(style.mpBar ~= nil and style.mpBar.worldOffsetY) or hpOffsetY;
    local tpOffsetY = tonumber(style.tpBar ~= nil and style.tpBar.worldOffsetY) or mpOffsetY;
    local sharedOffsetX = tonumber(style.hpBar ~= nil and style.hpBar.worldOffsetX) or 0;
    local rowGap = math.max(
        0.030,
        (tonumber(style.hpBar ~= nil and style.hpBar.worldHeight) or 0.045) + 0.010,
        (tonumber(style.mpBar ~= nil and style.mpBar.worldHeight) or 0.045) + 0.010,
        (tonumber(style.tpBar ~= nil and style.tpBar.worldHeight) or 0.020) + 0.010
    );
    local offsetsOverlap = (
        math.abs(mpOffsetY - hpOffsetY) < (rowGap * 0.5) and
        math.abs(tpOffsetY - mpOffsetY) < (rowGap * 0.5)
    );

    if (offsetsOverlap == true) then
        mpOffsetY = hpOffsetY + rowGap;
        tpOffsetY = mpOffsetY + rowGap;
    end

    local hpBar = CopyBarStyleWithOffset(style.hpBar, hpOffsetY);
    local mpBar = CopyBarStyleWithOffset(style.mpBar, mpOffsetY);
    local tpBar = CopyBarStyleWithOffset(style.tpBar, tpOffsetY);

    if (hpBar ~= nil) then hpBar.worldOffsetX = sharedOffsetX; end
    if (mpBar ~= nil) then mpBar.worldOffsetX = sharedOffsetX; end
    if (tpBar ~= nil) then tpBar.worldOffsetX = sharedOffsetX; end

    DrawWorldResourceBar(device, wx, wy, wz, rx, ry, rz, ux, uy, uz, hpPercent / 100, hpBar);

    if (plate.mp ~= nil) then
        DrawWorldResourceBar(device, wx, wy, wz, rx, ry, rz, ux, uy, uz, mpPercent / 100, mpBar);
    end

    if (tpValue ~= nil) then
        DrawWorldResourceBar(device, wx, wy, wz, rx, ry, rz, ux, uy, uz, tpValue / 3000, tpBar);
    end
end

local function DrawWithState(device, wx, wy, wz, hpPercent, style, color, plate)
    local _, saveLight = device:GetRenderState(D3DRS_LIGHTING);
    local _, saveZ = device:GetRenderState(D3DRS_ZENABLE);
    local _, saveZWrite = device:GetRenderState(D3DRS_ZWRITEENABLE);
    local _, saveZFunc = device:GetRenderState(D3DRS_ZFUNC);
    local _, saveZBias = device:GetRenderState(D3DRS_ZBIAS);
    local _, saveBlend = device:GetRenderState(D3DRS_ALPHABLENDENABLE);
    local _, saveSrc = device:GetRenderState(D3DRS_SRCBLEND);
    local _, saveDst = device:GetRenderState(D3DRS_DESTBLEND);
    local _, saveCull = device:GetRenderState(D3DRS_CULLMODE);
    local _, saveAlphaTest = device:GetRenderState(D3DRS_ALPHATESTENABLE);
    local _, saveFvf = device:GetVertexShader();
    local _, saveTex = device:GetTexture(0);
    local _, savePixelShader = device:GetPixelShader();
    local _, rawWorld = device:GetTransform(D3DTS_WORLD);
    local saveWorld = CopyMatrix(rawWorld);
    local _, saveColorOp = device:GetTextureStageState(0, D3DTSS_COLOROP);
    local _, saveColorArg1 = device:GetTextureStageState(0, D3DTSS_COLORARG1);
    local _, saveAlphaOp = device:GetTextureStageState(0, D3DTSS_ALPHAOP);
    local _, saveAlphaArg1 = device:GetTextureStageState(0, D3DTSS_ALPHAARG1);

    device:SetTexture(0, nil);
    device:SetVertexShader(D3DFVF_XYZ_DIFFUSE);
    device:SetPixelShader(0);
    device:SetRenderState(D3DRS_LIGHTING, 0);
    device:SetRenderState(D3DRS_CULLMODE, 1);
    device:SetRenderState(D3DRS_ALPHABLENDENABLE, 1);
    device:SetRenderState(D3DRS_SRCBLEND, 5);
    device:SetRenderState(D3DRS_DESTBLEND, 6);
    device:SetRenderState(D3DRS_ZENABLE, (alwaysOnTop == true) and 0 or 1);
    device:SetRenderState(D3DRS_ZWRITEENABLE, (alwaysOnTop == true) and 0 or 1);
    device:SetRenderState(D3DRS_ZFUNC, D3DCMP_LESSEQUAL);
    device:SetRenderState(D3DRS_ZBIAS, 8);
    device:SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_SELECTARG1);
    device:SetTextureStageState(0, D3DTSS_COLORARG1, D3DTA_DIFFUSE);
    device:SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_SELECTARG1);
    device:SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_DIFFUSE);
    device:SetTransform(D3DTS_WORLD, identity);

    local ok, err = pcall(function ()
        if (plate ~= nil and plate.isSelf == true) then
            DrawSelfResourceBars(device, wx, wy, wz, plate);
        else
            DrawMiniPlate(device, wx, wy, wz, hpPercent, style, color);
        end
    end);

    if (saveWorld ~= nil) then
        device:SetTransform(D3DTS_WORLD, MatrixFromTable(saveWorld));
    end

    device:SetTexture(0, saveTex);
    device:SetRenderState(D3DRS_LIGHTING, saveLight);
    device:SetRenderState(D3DRS_ZENABLE, saveZ);
    device:SetRenderState(D3DRS_ZWRITEENABLE, saveZWrite);
    device:SetRenderState(D3DRS_ZFUNC, saveZFunc);
    device:SetRenderState(D3DRS_ZBIAS, saveZBias);
    device:SetRenderState(D3DRS_ALPHABLENDENABLE, saveBlend);
    device:SetRenderState(D3DRS_SRCBLEND, saveSrc);
    device:SetRenderState(D3DRS_DESTBLEND, saveDst);
    device:SetRenderState(D3DRS_CULLMODE, saveCull);
    device:SetRenderState(D3DRS_ALPHATESTENABLE, saveAlphaTest);
    device:SetVertexShader(saveFvf);
    if (savePixelShader ~= nil) then
        device:SetPixelShader(savePixelShader);
    end
    device:SetTextureStageState(0, D3DTSS_COLOROP, saveColorOp);
    device:SetTextureStageState(0, D3DTSS_COLORARG1, saveColorArg1);
    device:SetTextureStageState(0, D3DTSS_ALPHAOP, saveAlphaOp);
    device:SetTextureStageState(0, D3DTSS_ALPHAARG1, saveAlphaArg1);

    if (ok ~= true) then
        print('[LibraPlates] World marker probe draw failed: ' .. tostring(err));
    end
end

local function DrawTextWithState(device, text, wx, wy, wz, style, mode)
    text = tostring(text or '');
    style = style or {};
    mode = tostring(mode or 'name');

    if (text == '') then
        return;
    end

    local isSmall = (mode == 'small');
    local isJob = (mode == 'job');
    local maxLetters = (isSmall or isJob) and 0 or (tonumber(style.nameMaxLetters) or 0);

    if (maxLetters > 0 and string.len(text) > maxLetters) then
        text = string.sub(text, 1, maxLetters);
    end

    local fontScale = isSmall and (tonumber(style.smallTextFontScale) or 4.0) or (tonumber(style.nameFontScale) or 3.4);
    local worldScale = isSmall and (tonumber(style.smallTextWorldTextureScale) or 0.00105) or (tonumber(style.nameWorldTextureScale) or 0.00175);
    local color = isSmall and (style.distanceColor or style.nameColor) or style.nameColor;
    local fontFamily = style.nameFontFamily or 'Arial';
    local fontSize = tonumber(style.nameFontSize) or 24;
    local outlineEnabled = style.nameOutlineEnabled ~= false;
    local outlineColor = style.nameOutlineColor or { 0.0, 0.0, 0.0, 1.0 };
    local userOutlineSize = isSmall and (tonumber(style.smallTextOutlineSize) or tonumber(style.nameOutlineSize) or 0) or (tonumber(style.nameOutlineSize) or 0);
    local outlineBase = tonumber(style.nameWorldOutlineBase) or 0;
    local offsetX = tonumber(style.nameOffsetX) or 0;
    local offsetWorldScale = worldScale;
    local billboardOffsetY = tonumber(style.nameBillboardOffsetY) or 0;
    local usePixelOffsets = (isSmall ~= true and isJob ~= true and style.nameUsePixelOffsets == true);

    if (isJob == true) then
        fontScale = tonumber(style.jobFontScale) or fontScale;
        worldScale = tonumber(style.jobWorldTextureScale) or worldScale;
        color = style.jobColor or color;
        fontFamily = style.jobFontFamily or fontFamily;
        fontSize = tonumber(style.jobFontSize) or fontSize;
        outlineEnabled = style.jobOutlineEnabled == true;
        outlineColor = style.jobOutlineColor or outlineColor;
        userOutlineSize = tonumber(style.jobOutlineSize) or 0;
        outlineBase = tonumber(style.jobWorldOutlineBase) or 0;
        offsetX = tonumber(style.jobOffsetX) or 0;
        offsetWorldScale = tonumber(style.jobOffsetWorldScale) or worldScale;
        billboardOffsetY = tonumber(style.jobBillboardOffsetY) or 0;
    end

    local outlineSize = userOutlineSize;

    if (isSmall ~= true and outlineEnabled == true) then
        outlineSize = outlineBase + userOutlineSize;
    end

    local textureId, textureWidth, textureHeight = gdiTextTexture.GetTexture(text, {
        fontFamily = fontFamily,
        fontSize = math.max(10, math.floor(fontSize * fontScale)),
        color = color or { 0.22, 0.95, 0.38, 1.0 },
        outlineEnabled = outlineEnabled,
        outlineColor = outlineColor,
        outlineSize = outlineSize,
    });

    if (textureId == nil or textureWidth == nil or textureHeight == nil or textureWidth <= 0 or textureHeight <= 0) then
        fontStatus = 'gdi-text-missing';
        return;
    end

    local texture = ffi.cast('IDirect3DBaseTexture8*', ffi.cast('uintptr_t', textureId));
    local textureScale = tonumber(style.nameTextureScale) or 1.0;
    local width = math.max(0.08, textureWidth * textureScale * worldScale);
    local height = math.max(0.025, textureHeight * textureScale * worldScale);
    local rx, ry, rz, ux, uy, uz = GetBillboardVectors(device);

    if (isJob == true and style.jobUsePixelOffsets == true) then
        offsetWorldScale = GetWorldUnitsPerPixelAlongVector(device, wx, wy, wz, rx, ry, rz) or offsetWorldScale;
    end

    if (usePixelOffsets == true) then
        offsetWorldScale = GetWorldUnitsPerPixelAlongVector(device, wx, wy, wz, rx, ry, rz) or offsetWorldScale;
        worldScale = offsetWorldScale;
    end

    wx = wx + (rx * (offsetX * offsetWorldScale));
    wy = wy - (uy * (billboardOffsetY * worldScale));
    wz = wz - (uz * (billboardOffsetY * worldScale));
    local _, saveLight = device:GetRenderState(D3DRS_LIGHTING);
    local _, saveZ = device:GetRenderState(D3DRS_ZENABLE);
    local _, saveZWrite = device:GetRenderState(D3DRS_ZWRITEENABLE);
    local _, saveZFunc = device:GetRenderState(D3DRS_ZFUNC);
    local _, saveZBias = device:GetRenderState(D3DRS_ZBIAS);
    local _, saveBlend = device:GetRenderState(D3DRS_ALPHABLENDENABLE);
    local _, saveSrc = device:GetRenderState(D3DRS_SRCBLEND);
    local _, saveDst = device:GetRenderState(D3DRS_DESTBLEND);
    local _, saveCull = device:GetRenderState(D3DRS_CULLMODE);
    local _, saveAlphaTest = device:GetRenderState(D3DRS_ALPHATESTENABLE);
    local _, saveAlphaRef = device:GetRenderState(D3DRS_ALPHAREF);
    local _, saveAlphaFunc = device:GetRenderState(D3DRS_ALPHAFUNC);
    local _, saveFvf = device:GetVertexShader();
    local _, saveTex = device:GetTexture(0);
    local _, savePixelShader = device:GetPixelShader();
    local _, rawWorld = device:GetTransform(D3DTS_WORLD);
    local saveWorld = CopyMatrix(rawWorld);
    local _, saveColorOp = device:GetTextureStageState(0, D3DTSS_COLOROP);
    local _, saveColorArg1 = device:GetTextureStageState(0, D3DTSS_COLORARG1);
    local _, saveColorArg2 = device:GetTextureStageState(0, D3DTSS_COLORARG2);
    local _, saveAlphaOp = device:GetTextureStageState(0, D3DTSS_ALPHAOP);
    local _, saveAlphaArg1 = device:GetTextureStageState(0, D3DTSS_ALPHAARG1);
    local _, saveMagFilter = device:GetTextureStageState(0, D3DTSS_MAGFILTER);
    local _, saveMinFilter = device:GetTextureStageState(0, D3DTSS_MINFILTER);
    local _, saveAddressU = device:GetTextureStageState(0, D3DTSS_ADDRESSU);
    local _, saveAddressV = device:GetTextureStageState(0, D3DTSS_ADDRESSV);

    device:SetTexture(0, texture);
    device:SetVertexShader(D3DFVF_XYZ_DIFFUSE_TEX1);
    device:SetPixelShader(0);
    device:SetRenderState(D3DRS_LIGHTING, 0);
    device:SetRenderState(D3DRS_CULLMODE, 1);
    device:SetRenderState(D3DRS_ALPHABLENDENABLE, 1);
    device:SetRenderState(D3DRS_SRCBLEND, 5);
    device:SetRenderState(D3DRS_DESTBLEND, 6);
    device:SetRenderState(D3DRS_ZENABLE, (alwaysOnTop == true) and 0 or 1);
    device:SetRenderState(D3DRS_ZWRITEENABLE, (alwaysOnTop == true) and 0 or 1);
    device:SetRenderState(D3DRS_ZFUNC, D3DCMP_LESSEQUAL);
    device:SetRenderState(D3DRS_ZBIAS, 8);
    device:SetRenderState(D3DRS_ALPHATESTENABLE, 1);
    device:SetRenderState(D3DRS_ALPHAREF, 0x20);
    device:SetRenderState(D3DRS_ALPHAFUNC, D3DCMP_GREATEREQUAL);
    device:SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_SELECTARG1);
    device:SetTextureStageState(0, D3DTSS_COLORARG1, D3DTA_TEXTURE);
    device:SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_SELECTARG1);
    device:SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_TEXTURE);
    device:SetTextureStageState(0, D3DTSS_MAGFILTER, D3DTEXF_LINEAR);
    device:SetTextureStageState(0, D3DTSS_MINFILTER, D3DTEXF_LINEAR);
    device:SetTextureStageState(0, D3DTSS_ADDRESSU, D3DTADDRESS_CLAMP);
    device:SetTextureStageState(0, D3DTSS_ADDRESSV, D3DTADDRESS_CLAMP);
    device:SetTransform(D3DTS_WORLD, identity);

    local ok, err = pcall(function ()
        BuildTextureBillboardQuad(wx, wy, wz, rx, ry, rz, ux, uy, uz, width, height, 0xFFFFFFFF);
        device:DrawPrimitiveUP(D3DPT_TRIANGLELIST, 2, textVerts, TEXTURED_VERTEX_SIZE);
    end);

    if (saveWorld ~= nil) then device:SetTransform(D3DTS_WORLD, MatrixFromTable(saveWorld)); end
    device:SetTexture(0, saveTex);
    device:SetRenderState(D3DRS_LIGHTING, saveLight);
    device:SetRenderState(D3DRS_ZENABLE, saveZ);
    device:SetRenderState(D3DRS_ZWRITEENABLE, saveZWrite);
    device:SetRenderState(D3DRS_ZFUNC, saveZFunc);
    device:SetRenderState(D3DRS_ZBIAS, saveZBias);
    device:SetRenderState(D3DRS_ALPHABLENDENABLE, saveBlend);
    device:SetRenderState(D3DRS_SRCBLEND, saveSrc);
    device:SetRenderState(D3DRS_DESTBLEND, saveDst);
    device:SetRenderState(D3DRS_CULLMODE, saveCull);
    device:SetRenderState(D3DRS_ALPHATESTENABLE, saveAlphaTest);
    device:SetRenderState(D3DRS_ALPHAREF, saveAlphaRef);
    device:SetRenderState(D3DRS_ALPHAFUNC, saveAlphaFunc);
    device:SetVertexShader(saveFvf);
    if (savePixelShader ~= nil) then device:SetPixelShader(savePixelShader); end
    device:SetTextureStageState(0, D3DTSS_COLOROP, saveColorOp);
    device:SetTextureStageState(0, D3DTSS_COLORARG1, saveColorArg1);
    device:SetTextureStageState(0, D3DTSS_COLORARG2, saveColorArg2);
    device:SetTextureStageState(0, D3DTSS_ALPHAOP, saveAlphaOp);
    device:SetTextureStageState(0, D3DTSS_ALPHAARG1, saveAlphaArg1);
    device:SetTextureStageState(0, D3DTSS_MAGFILTER, saveMagFilter);
    device:SetTextureStageState(0, D3DTSS_MINFILTER, saveMinFilter);
    device:SetTextureStageState(0, D3DTSS_ADDRESSU, saveAddressU);
    device:SetTextureStageState(0, D3DTSS_ADDRESSV, saveAddressV);

    if (ok ~= true) then
        fontStatus = tostring(err);
        lastError = fontStatus;
    else
        fontStatus = 'gdi-ok';
    end
end

local function DrawNameWithState(device, name, distance, wx, wy, wz, style)
    DrawTextWithState(device, name, wx, wy, wz, style, 'name');
end

local DrawTextureWithState = nil;

local function DrawScreenTextureWithDepth(device, textureId, wx, wy, wz, offsetX, offsetY, size, height, alwaysOnTop)
    textureId = tonumber(textureId);

    if (textureId == nil or textureId == 0) then
        return false;
    end

    local _, view = device:GetTransform(2);
    local _, proj = device:GetTransform(3);
    local _, viewport = device:GetViewport();

    if (view == nil or proj == nil or viewport == nil or viewport.Width == nil or viewport.Height == nil) then
        return false;
    end

    local sx, sy, sz = ProjectWithZ(view, proj, viewport.Width, viewport.Height, wx, wy, wz);

    if (sx == nil or sy == nil or sz == nil or sz < 0 or sz > 1) then
        return false;
    end

    local drawSize = math.max(1, tonumber(size) or 16);
    local drawHeight = math.max(1, tonumber(height) or drawSize);
    local centerX = sx + (tonumber(offsetX) or 0);
    local centerY = sy + (tonumber(offsetY) or 0);
    local left = centerX - (drawSize * 0.5);
    local top = centerY - (drawHeight * 0.5);
    local right = left + drawSize;
    local bottom = top + drawHeight;
    local texture = ffi.cast('IDirect3DBaseTexture8*', ffi.cast('uintptr_t', textureId));

    local _, saveLight = device:GetRenderState(D3DRS_LIGHTING);
    local _, saveZ = device:GetRenderState(D3DRS_ZENABLE);
    local _, saveZWrite = device:GetRenderState(D3DRS_ZWRITEENABLE);
    local _, saveZFunc = device:GetRenderState(D3DRS_ZFUNC);
    local _, saveZBias = device:GetRenderState(D3DRS_ZBIAS);
    local _, saveBlend = device:GetRenderState(D3DRS_ALPHABLENDENABLE);
    local _, saveSrc = device:GetRenderState(D3DRS_SRCBLEND);
    local _, saveDst = device:GetRenderState(D3DRS_DESTBLEND);
    local _, saveCull = device:GetRenderState(D3DRS_CULLMODE);
    local _, saveAlphaTest = device:GetRenderState(D3DRS_ALPHATESTENABLE);
    local _, saveAlphaRef = device:GetRenderState(D3DRS_ALPHAREF);
    local _, saveAlphaFunc = device:GetRenderState(D3DRS_ALPHAFUNC);
    local _, saveFvf = device:GetVertexShader();
    local _, saveTex = device:GetTexture(0);
    local _, savePixelShader = device:GetPixelShader();
    local _, saveColorOp = device:GetTextureStageState(0, D3DTSS_COLOROP);
    local _, saveColorArg1 = device:GetTextureStageState(0, D3DTSS_COLORARG1);
    local _, saveColorArg2 = device:GetTextureStageState(0, D3DTSS_COLORARG2);
    local _, saveAlphaOp = device:GetTextureStageState(0, D3DTSS_ALPHAOP);
    local _, saveAlphaArg1 = device:GetTextureStageState(0, D3DTSS_ALPHAARG1);
    local _, saveMagFilter = device:GetTextureStageState(0, D3DTSS_MAGFILTER);
    local _, saveMinFilter = device:GetTextureStageState(0, D3DTSS_MINFILTER);
    local _, saveAddressU = device:GetTextureStageState(0, D3DTSS_ADDRESSU);
    local _, saveAddressV = device:GetTextureStageState(0, D3DTSS_ADDRESSV);

    device:SetTexture(0, texture);
    device:SetVertexShader(D3DFVF_XYZRHW_DIFFUSE_TEX1);
    device:SetPixelShader(0);
    device:SetRenderState(D3DRS_LIGHTING, 0);
    device:SetRenderState(D3DRS_CULLMODE, 1);
    device:SetRenderState(D3DRS_ALPHABLENDENABLE, 1);
    device:SetRenderState(D3DRS_SRCBLEND, 5);
    device:SetRenderState(D3DRS_DESTBLEND, 6);
    device:SetRenderState(D3DRS_ZENABLE, (alwaysOnTop == true) and 0 or 1);
    device:SetRenderState(D3DRS_ZWRITEENABLE, 0);
    device:SetRenderState(D3DRS_ZFUNC, (alwaysOnTop == true) and D3DCMP_ALWAYS or D3DCMP_LESSEQUAL);
    device:SetRenderState(D3DRS_ZBIAS, 0);
    device:SetRenderState(D3DRS_ALPHATESTENABLE, 1);
    device:SetRenderState(D3DRS_ALPHAREF, 0x40);
    device:SetRenderState(D3DRS_ALPHAFUNC, D3DCMP_GREATEREQUAL);
    device:SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_SELECTARG1);
    device:SetTextureStageState(0, D3DTSS_COLORARG1, D3DTA_TEXTURE);
    device:SetTextureStageState(0, D3DTSS_COLORARG2, D3DTA_DIFFUSE);
    device:SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_SELECTARG1);
    device:SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_TEXTURE);
    device:SetTextureStageState(0, D3DTSS_MAGFILTER, D3DTEXF_LINEAR);
    device:SetTextureStageState(0, D3DTSS_MINFILTER, D3DTEXF_LINEAR);
    device:SetTextureStageState(0, D3DTSS_ADDRESSU, D3DTADDRESS_CLAMP);
    device:SetTextureStageState(0, D3DTSS_ADDRESSV, D3DTADDRESS_CLAMP);

    local color = 0xFFFFFFFF;
    local vertices = ffi.new('lp_world_marker_screen_vertex_t[6]', {
        { left,  top,    sz, 1, color, 0, 0 },
        { right, top,    sz, 1, color, 1, 0 },
        { right, bottom, sz, 1, color, 1, 1 },
        { left,  top,    sz, 1, color, 0, 0 },
        { right, bottom, sz, 1, color, 1, 1 },
        { left,  bottom, sz, 1, color, 0, 1 },
    });

    local ok = pcall(function()
        device:DrawPrimitiveUP(D3DPT_TRIANGLELIST, 2, vertices, SCREEN_VERTEX_SIZE);
    end);

    device:SetTexture(0, saveTex);
    device:SetRenderState(D3DRS_LIGHTING, saveLight);
    device:SetRenderState(D3DRS_ZENABLE, saveZ);
    device:SetRenderState(D3DRS_ZWRITEENABLE, saveZWrite);
    device:SetRenderState(D3DRS_ZFUNC, saveZFunc);
    device:SetRenderState(D3DRS_ZBIAS, saveZBias);
    device:SetRenderState(D3DRS_ALPHABLENDENABLE, saveBlend);
    device:SetRenderState(D3DRS_SRCBLEND, saveSrc);
    device:SetRenderState(D3DRS_DESTBLEND, saveDst);
    device:SetRenderState(D3DRS_CULLMODE, saveCull);
    device:SetRenderState(D3DRS_ALPHATESTENABLE, saveAlphaTest);
    device:SetRenderState(D3DRS_ALPHAREF, saveAlphaRef);
    device:SetRenderState(D3DRS_ALPHAFUNC, saveAlphaFunc);
    device:SetVertexShader(saveFvf);
    if (savePixelShader ~= nil) then device:SetPixelShader(savePixelShader); end
    device:SetTextureStageState(0, D3DTSS_COLOROP, saveColorOp);
    device:SetTextureStageState(0, D3DTSS_COLORARG1, saveColorArg1);
    device:SetTextureStageState(0, D3DTSS_COLORARG2, saveColorArg2);
    device:SetTextureStageState(0, D3DTSS_ALPHAOP, saveAlphaOp);
    device:SetTextureStageState(0, D3DTSS_ALPHAARG1, saveAlphaArg1);
    device:SetTextureStageState(0, D3DTSS_MAGFILTER, saveMagFilter);
    device:SetTextureStageState(0, D3DTSS_MINFILTER, saveMinFilter);
    device:SetTextureStageState(0, D3DTSS_ADDRESSU, saveAddressU);
    device:SetTextureStageState(0, D3DTSS_ADDRESSV, saveAddressV);

    return ok == true;
end

local function DrawCanvasIconWithState(device, wx, wy, wz, style)
    if (style == nil or style.canvasIcons == nil) then
        return;
    end

    for _, icon in ipairs(style.canvasIcons) do
        if (icon ~= nil and icon.enabled == true) then
            local textureId = tonumber(icon.textureId);

            if (textureId ~= nil and textureId ~= 0) then
                local iconSize = tonumber(icon.size) or 16;
                local offsetX = tonumber(icon.offsetX) or 0;
                local offsetY = tonumber(icon.offsetY) or 0;
                DrawScreenTextureWithDepth(device, textureId, wx, wy, wz, offsetX, offsetY, iconSize);
            end
        end
    end
end

local function DrawPlateOverlayScreen(device, textureId, wx, wy, wz, worldWidth, worldHeight, alwaysOnTop)
    local _, view = device:GetTransform(2);
    local _, proj = device:GetTransform(3);
    local _, viewport = device:GetViewport();

    if (view == nil or proj == nil or viewport == nil or viewport.Width == nil or viewport.Height == nil) then
        return false;
    end

    local rx, ry, rz, ux, uy, uz = GetBillboardVectors(device);
    local halfWidth = (tonumber(worldWidth) or 0.84) * 0.5;
    local halfHeight = (tonumber(worldHeight) or 0.315) * 0.5;
    local points = {
        { -halfWidth, -halfHeight },
        { halfWidth, -halfHeight },
        { halfWidth, halfHeight },
        { -halfWidth, halfHeight },
    };
    local left = nil;
    local top = nil;
    local right = nil;
    local bottom = nil;

    for _, point in ipairs(points) do
        local sx, sy = ProjectBillboardPoint(view, proj, viewport, wx, wy, wz, rx, ry, rz, ux, uy, uz, point[1], point[2]);

        if (sx ~= nil and sy ~= nil) then
            left = (left == nil) and sx or math.min(left, sx);
            top = (top == nil) and sy or math.min(top, sy);
            right = (right == nil) and sx or math.max(right, sx);
            bottom = (bottom == nil) and sy or math.max(bottom, sy);
        end
    end

    if (left == nil or top == nil or right == nil or bottom == nil) then
        return false;
    end

    return DrawScreenTextureWithDepth(
        device,
        textureId,
        wx,
        wy,
        wz,
        0,
        0,
        math.max(1, right - left),
        math.max(1, bottom - top),
        alwaysOnTop == true
    );
end

DrawTextureWithState = function(device, textureId, wx, wy, wz, worldSize, offsetX, offsetY, offsetWorldScale, usePixelOffsets, worldHeight, alwaysOnTop)
    textureId = tonumber(textureId);

    if (textureId == nil or textureId == 0) then
        return false;
    end

    local texture = ffi.cast('IDirect3DBaseTexture8*', ffi.cast('uintptr_t', textureId));
    local size = math.max(0.03, tonumber(worldSize) or 0.10);
    local height = math.max(0.03, tonumber(worldHeight) or size);
    local rx, ry, rz, ux, uy, uz = GetBillboardVectors(device);
    local worldScale = tonumber(offsetWorldScale) or 0.00175;

    if (usePixelOffsets == true) then
        worldScale = GetWorldUnitsPerPixelAlongVector(device, wx, wy, wz, rx, ry, rz) or worldScale;
    end

    wx = wx + (rx * ((tonumber(offsetX) or 0) * worldScale));
    wy = wy - (uy * ((tonumber(offsetY) or 0) * worldScale));
    wz = wz - (uz * ((tonumber(offsetY) or 0) * worldScale));

    local _, saveLight = device:GetRenderState(D3DRS_LIGHTING);
    local _, saveZ = device:GetRenderState(D3DRS_ZENABLE);
    local _, saveZWrite = device:GetRenderState(D3DRS_ZWRITEENABLE);
    local _, saveZFunc = device:GetRenderState(D3DRS_ZFUNC);
    local _, saveZBias = device:GetRenderState(D3DRS_ZBIAS);
    local _, saveBlend = device:GetRenderState(D3DRS_ALPHABLENDENABLE);
    local _, saveSrc = device:GetRenderState(D3DRS_SRCBLEND);
    local _, saveDst = device:GetRenderState(D3DRS_DESTBLEND);
    local _, saveCull = device:GetRenderState(D3DRS_CULLMODE);
    local _, saveAlphaTest = device:GetRenderState(D3DRS_ALPHATESTENABLE);
    local _, saveAlphaRef = device:GetRenderState(D3DRS_ALPHAREF);
    local _, saveAlphaFunc = device:GetRenderState(D3DRS_ALPHAFUNC);
    local _, saveFvf = device:GetVertexShader();
    local _, saveTex = device:GetTexture(0);
    local _, savePixelShader = device:GetPixelShader();
    local _, rawWorld = device:GetTransform(D3DTS_WORLD);
    local saveWorld = CopyMatrix(rawWorld);
    local _, saveColorOp = device:GetTextureStageState(0, D3DTSS_COLOROP);
    local _, saveColorArg1 = device:GetTextureStageState(0, D3DTSS_COLORARG1);
    local _, saveColorArg2 = device:GetTextureStageState(0, D3DTSS_COLORARG2);
    local _, saveAlphaOp = device:GetTextureStageState(0, D3DTSS_ALPHAOP);
    local _, saveAlphaArg1 = device:GetTextureStageState(0, D3DTSS_ALPHAARG1);
    local _, saveMagFilter = device:GetTextureStageState(0, D3DTSS_MAGFILTER);
    local _, saveMinFilter = device:GetTextureStageState(0, D3DTSS_MINFILTER);
    local _, saveAddressU = device:GetTextureStageState(0, D3DTSS_ADDRESSU);
    local _, saveAddressV = device:GetTextureStageState(0, D3DTSS_ADDRESSV);

    device:SetTexture(0, texture);
    device:SetVertexShader(D3DFVF_XYZ_DIFFUSE_TEX1);
    device:SetPixelShader(0);
    device:SetRenderState(D3DRS_LIGHTING, 0);
    device:SetRenderState(D3DRS_CULLMODE, 1);
    device:SetRenderState(D3DRS_ALPHABLENDENABLE, 1);
    device:SetRenderState(D3DRS_SRCBLEND, 5);
    device:SetRenderState(D3DRS_DESTBLEND, 6);
    device:SetRenderState(D3DRS_ZENABLE, 1);
    device:SetRenderState(D3DRS_ZWRITEENABLE, 1);
    device:SetRenderState(D3DRS_ZFUNC, (alwaysOnTop == true) and D3DCMP_ALWAYS or D3DCMP_LESSEQUAL);
    device:SetRenderState(D3DRS_ZBIAS, 8);
    device:SetRenderState(D3DRS_ALPHATESTENABLE, 1);
    device:SetRenderState(D3DRS_ALPHAREF, 0x20);
    device:SetRenderState(D3DRS_ALPHAFUNC, D3DCMP_GREATEREQUAL);
    device:SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_SELECTARG1);
    device:SetTextureStageState(0, D3DTSS_COLORARG1, D3DTA_TEXTURE);
    device:SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_SELECTARG1);
    device:SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_TEXTURE);
    device:SetTextureStageState(0, D3DTSS_MAGFILTER, D3DTEXF_LINEAR);
    device:SetTextureStageState(0, D3DTSS_MINFILTER, D3DTEXF_LINEAR);
    device:SetTextureStageState(0, D3DTSS_ADDRESSU, D3DTADDRESS_CLAMP);
    device:SetTextureStageState(0, D3DTSS_ADDRESSV, D3DTADDRESS_CLAMP);
    device:SetTransform(D3DTS_WORLD, identity);

    local ok, err = pcall(function ()
        BuildTextureBillboardQuad(wx, wy, wz, rx, ry, rz, ux, uy, uz, size, height, 0xFFFFFFFF);
        device:DrawPrimitiveUP(D3DPT_TRIANGLELIST, 2, textVerts, TEXTURED_VERTEX_SIZE);
    end);

    if (saveWorld ~= nil) then device:SetTransform(D3DTS_WORLD, MatrixFromTable(saveWorld)); end
    device:SetTexture(0, saveTex);
    device:SetRenderState(D3DRS_LIGHTING, saveLight);
    device:SetRenderState(D3DRS_ZENABLE, saveZ);
    device:SetRenderState(D3DRS_ZWRITEENABLE, saveZWrite);
    device:SetRenderState(D3DRS_ZFUNC, saveZFunc);
    device:SetRenderState(D3DRS_ZBIAS, saveZBias);
    device:SetRenderState(D3DRS_ALPHABLENDENABLE, saveBlend);
    device:SetRenderState(D3DRS_SRCBLEND, saveSrc);
    device:SetRenderState(D3DRS_DESTBLEND, saveDst);
    device:SetRenderState(D3DRS_CULLMODE, saveCull);
    device:SetRenderState(D3DRS_ALPHATESTENABLE, saveAlphaTest);
    device:SetRenderState(D3DRS_ALPHAREF, saveAlphaRef);
    device:SetRenderState(D3DRS_ALPHAFUNC, saveAlphaFunc);
    device:SetVertexShader(saveFvf);
    if (savePixelShader ~= nil) then device:SetPixelShader(savePixelShader); end
    device:SetTextureStageState(0, D3DTSS_COLOROP, saveColorOp);
    device:SetTextureStageState(0, D3DTSS_COLORARG1, saveColorArg1);
    device:SetTextureStageState(0, D3DTSS_COLORARG2, saveColorArg2);
    device:SetTextureStageState(0, D3DTSS_ALPHAOP, saveAlphaOp);
    device:SetTextureStageState(0, D3DTSS_ALPHAARG1, saveAlphaArg1);
    device:SetTextureStageState(0, D3DTSS_MAGFILTER, saveMagFilter);
    device:SetTextureStageState(0, D3DTSS_MINFILTER, saveMinFilter);
    device:SetTextureStageState(0, D3DTSS_ADDRESSU, saveAddressU);
    device:SetTextureStageState(0, D3DTSS_ADDRESSV, saveAddressV);

    if (ok ~= true) then
        lastError = tostring(err);
        return false;
    end

    return true;
end

local function DrawJobWithState(device, plate, wx, wy, wz, style)
    if (style == nil or style.jobEnabled ~= true) then
        return;
    end

    if (tonumber(style.jobDisplayModeIndex) == 2) then
        local iconSize = tonumber(style.jobIconSize) or 16;

        local iconOffsetX = tonumber(style.jobOffsetX) or 0;
        local iconOffsetY = tonumber(style.jobBillboardOffsetY) or tonumber(style.jobOffsetY) or 0;

        if (DrawTextureWithState(device, plate.jobIconTextureId, wx, wy, wz, iconSize / 430, iconOffsetX, iconOffsetY, tonumber(style.jobOffsetWorldScale) or 0.00175, style.jobUsePixelOffsets == true) == true) then
            return;
        end
    end

    DrawTextWithState(device, plate.jobText, wx, wy, wz, style, 'job');
end

local function DrawDistanceWithState(device, distance, wx, wy, wz, style)
    local value = tonumber(distance);

    if (value == nil) then
        return;
    end

    DrawTextWithState(device, string.format('%.1fm', value), wx, wy, wz, style, 'small');
end

local function FindNameplateHelper()
    if (helperPointer ~= nil) then
        return helperPointer;
    end

    helperPointer = 0;
    helperStatus = 'missing';

    local ok, ptr = pcall(function ()
        return ashita.memory.find(
            'FFXiMain.dll',
            0,
            '83EC40568BF18D4C2404E8????????8B4424488D4E0850E8????????85C05E74',
            0,
            0
        );
    end);

    if (ok == true and ptr ~= nil and ptr ~= 0) then
        helperPointer = ptr;
        helperStatus = 'found';
    end

    return helperPointer;
end

local function NormalizeAnchorBone(value)
    local bone = math.floor(tonumber(value) or anchorBone);

    if (bone < 0) then
        return 0;
    elseif (bone > 32) then
        return 32;
    end

    return bone;
end

local function GetExactNameplateAnchor(actorPointer, bone)
    local baseX = ashita.memory.read_float(actorPointer + 0x678);
    local baseY = ashita.memory.read_float(actorPointer + 0x680);
    local baseZ = ashita.memory.read_float(actorPointer + 0x67C);
    local helper = FindNameplateHelper();

    if (helper == nil or helper == 0) then
        return nil;
    end

    local objectPointer = ashita.memory.read_uint32(actorPointer + 0x674 + 0x44);

    if (objectPointer == nil or objectPointer == 0) then
        helperStatus = 'object-missing';
        return nil;
    end

    local offset = ffi.new('lp_d3dx_vector3_t', { 0, 0, 0 });
    local func = ffi.cast('lp_get_nameplate_offset_f', helper);
    func(ffi.cast('void*', objectPointer), NormalizeAnchorBone(bone), offset);
    helperStatus = 'ok';

    return baseX + offset.x, baseY + offset.z, baseZ + offset.y;
end

local function GetAnchor(actorPointer, getBone, style)
    local bone = NormalizeAnchorBone(style ~= nil and style.anchorBone or anchorBone);

    if (anchorMode == 'exact') then
        local ok, x, y, z = pcall(function ()
            return GetExactNameplateAnchor(actorPointer, bone);
        end);

        if (ok == true and x ~= nil and y ~= nil and z ~= nil) then
            return x, y, z;
        end

        if (ok ~= true) then
            helperStatus = tostring(x);
            lastError = helperStatus;
        end
    end

    return getBone(actorPointer, bone);
end

local function GetBoneBounds(actorPointer)
    if (actorPointer == nil or actorPointer == 0) then
        return nil;
    end

    local skeletonBaseAddress = ashita.memory.read_uint32(actorPointer + 0x6B8);

    if (skeletonBaseAddress == nil or skeletonBaseAddress == 0) then
        return nil;
    end

    local skeletonOffsetAddress = ashita.memory.read_uint32(skeletonBaseAddress + 0x0C);

    if (skeletonOffsetAddress == nil or skeletonOffsetAddress == 0) then
        return nil;
    end

    local skeletonAddress = ashita.memory.read_uint32(skeletonOffsetAddress);

    if (skeletonAddress == nil or skeletonAddress == 0) then
        return nil;
    end

    local baseX = ashita.memory.read_float(actorPointer + 0x678);
    local baseY = ashita.memory.read_float(actorPointer + 0x680);
    local baseZ = ashita.memory.read_float(actorPointer + 0x67C);
    local boneCount = tonumber(ashita.memory.read_uint16(skeletonAddress + 0x32)) or 0;
    local bufferPointer = skeletonAddress + 0x30;
    local skeletonSize = 0x04;
    local boneSize = 0x1E;
    local generatorsAddress = bufferPointer + skeletonSize + boneSize * boneCount + 4;
    local minX = nil;
    local maxX = nil;
    local minY = nil;
    local maxY = nil;
    local minZ = nil;
    local maxZ = nil;

    for bone = 0, math.min(tonumber(boneCount) or 0, 96) - 1 do
        local bx = baseX + ashita.memory.read_float(generatorsAddress + (bone * 0x1A) + 0x0E + 0x0);
        local by = baseY + ashita.memory.read_float(generatorsAddress + (bone * 0x1A) + 0x0E + 0x8);
        local bz = baseZ + ashita.memory.read_float(generatorsAddress + (bone * 0x1A) + 0x0E + 0x4);

        minX = (minX == nil) and bx or math.min(minX, bx);
        maxX = (maxX == nil) and bx or math.max(maxX, bx);
        minY = (minY == nil) and by or math.min(minY, by);
        maxY = (maxY == nil) and by or math.max(maxY, by);
        minZ = (minZ == nil) and bz or math.min(minZ, bz);
        maxZ = (maxZ == nil) and bz or math.max(maxZ, bz);
    end

    if (minZ == nil or maxZ == nil) then
        return nil;
    end

    return {
        count = boneCount,
        minX = minX,
        maxX = maxX,
        minY = minY,
        maxY = maxY,
        minZ = minZ,
        maxZ = maxZ,
        spanX = maxX - minX,
        spanY = maxY - minY,
        spanZ = maxZ - minZ,
        baseX = baseX,
        baseY = baseY,
        baseZ = baseZ,
    };
end

local function ReadFloatList(pointer, offsets)
    if (pointer == nil or pointer == 0) then
        return nil;
    end

    local parts = {};

    for _, offset in ipairs(offsets) do
        local ok, value = pcall(function()
            return ashita.memory.read_float(pointer + offset);
        end);

        parts[#parts + 1] = string.format('%X=%s', offset, ok == true and tostring(value) or 'err');
    end

    return table.concat(parts, ',');
end

local function ReadIntList(pointer, offsets)
    if (pointer == nil or pointer == 0) then
        return nil;
    end

    local parts = {};

    for _, offset in ipairs(offsets) do
        local ok, value = pcall(function()
            return ashita.memory.read_uint32(pointer + offset);
        end);

        parts[#parts + 1] = string.format('%X=0x%X', offset, ok == true and (tonumber(value) or 0) or 0);
    end

    return table.concat(parts, ',');
end

local function GetSelfVerticalPosition(entityManager)
    if (entityManager == nil) then
        return nil;
    end

    local selfIndex = nil;

    pcall(function()
        selfIndex = AshitaCore:GetMemoryManager():GetParty():GetMemberTargetIndex(0);
    end);

    if (selfIndex == nil or selfIndex == 0) then
        return nil;
    end

    return SafeNumber(function()
        return entityManager:GetLocalPositionZ(selfIndex);
    end);
end

local function ShouldHideProjectedBelowViewportPlate(device, entityManager, style, wx, wy, wz)
    if (device == nil or style == nil or style.hideWhenProjectedBelowViewport ~= true) then
        return false;
    end

    if (style.plateTacticalOverlayOnly == true) then
        return false;
    end

    local selfZ = GetSelfVerticalPosition(entityManager);
    local belowPlayerDelta = tonumber(style.belowPlayerViewHideDelta);

    if (selfZ ~= nil and belowPlayerDelta ~= nil and wy < (selfZ - belowPlayerDelta)) then
        return true;
    end

    local _, view = device:GetTransform(2);
    local _, proj = device:GetTransform(3);
    local _, viewport = device:GetViewport();

    if (view == nil or proj == nil or viewport == nil or viewport.Width == nil or viewport.Height == nil) then
        return false;
    end

    local screenX, screenY = ProjectWithZ(view, proj, viewport.Width, viewport.Height, wx, wy, wz);
    local margin = tonumber(style.belowViewportHideMargin) or 96;

    if (screenX ~= nil and screenY ~= nil and screenY > (tonumber(viewport.Height) + margin)) then
        return true;
    end

    return false;
end

-- ==========================================================
-- = PUBLIC API =
-- ==========================================================

function worldMarkerProbe.SetEnabled(value)
    enabled = (value == true);
end

function worldMarkerProbe.GetEnabled()
    return enabled;
end

function worldMarkerProbe.SetImgui(value)
    imguiApi = value;
    fontAtlasTexture = nil;
    fontBaked = nil;
    fontStatus = 'not-ready';
end

function worldMarkerProbe.SetReplacePlates(value)
    replacePlates = (value == true);
end

function worldMarkerProbe.GetReplacePlates()
    return replacePlates;
end

function worldMarkerProbe.SetCompareAnchors(value)
    compareAnchors = (value == true);
end

function worldMarkerProbe.GetCompareAnchors()
    return compareAnchors;
end

function worldMarkerProbe.SetShowText(value)
    showText = (value == true);
end

function worldMarkerProbe.GetShowText()
    return showText;
end

function worldMarkerProbe.SetShowDistance(value)
    showDistance = (value == true);
end

function worldMarkerProbe.GetShowDistance()
    return showDistance;
end

function worldMarkerProbe.SetCanvasCenterDebug(value)
    showCanvasCenter = (value == true);
end

function worldMarkerProbe.GetCanvasCenterDebug()
    return showCanvasCenter;
end

function worldMarkerProbe.SetAnchorMode(value)
    local mode = tostring(value or ''):lower();

    if (mode == 'exact' or mode == 'nameplate') then
        anchorMode = 'exact';
    else
        anchorMode = 'bone';
    end
end

function worldMarkerProbe.GetAnchorMode()
    return anchorMode;
end

function worldMarkerProbe.SetAnchorBone(value)
    anchorBone = NormalizeAnchorBone(value);
end

function worldMarkerProbe.GetAnchorBone()
    return anchorBone;
end

function worldMarkerProbe.SetVerticalOffset(value)
    local offset = tonumber(value) or verticalOffset;

    if (offset < -5) then
        offset = -5;
    elseif (offset > 5) then
        offset = 5;
    end

    verticalOffset = offset;
end

function worldMarkerProbe.GetVerticalOffset()
    return verticalOffset;
end

function worldMarkerProbe.SetNameVerticalOffset(value)
    local offset = tonumber(value) or nameVerticalOffset;

    if (offset < -5) then
        offset = -5;
    elseif (offset > 5) then
        offset = 5;
    end

    nameVerticalOffset = offset;
end

function worldMarkerProbe.GetNameVerticalOffset()
    return nameVerticalOffset;
end

function worldMarkerProbe.GetAnchorDebug(targetIndex, getEntityManager, getBone)
    targetIndex = tonumber(targetIndex);

    if (targetIndex == nil or targetIndex == 0 or getEntityManager == nil or getBone == nil) then
        return nil, 'missing-args';
    end

    local entityManager = getEntityManager();
    local device = d3d8.get_device();

    if (entityManager == nil or device == nil) then
        return nil, 'missing-device';
    end

    local actorPointer = entityManager:GetActorPointer(targetIndex);

    if (actorPointer == nil or actorPointer == 0) then
        return nil, 'missing-actor';
    end

    local _, view = device:GetTransform(2);
    local _, proj = device:GetTransform(3);
    local _, viewport = device:GetViewport();

    if (view == nil or proj == nil or viewport == nil or viewport.Width == nil or viewport.Height == nil) then
        return nil, 'missing-transform';
    end

    local bx, by, bz = getBone(actorPointer, anchorBone);
    local exactOk, ex, ey, ez = pcall(function()
        return GetExactNameplateAnchor(actorPointer);
    end);
    local boneScreenX, boneScreenY, boneScreenZ = nil, nil, nil;
    local exactScreenX, exactScreenY, exactScreenZ = nil, nil, nil;

    if (bx ~= nil and by ~= nil and bz ~= nil) then
        boneScreenX, boneScreenY, boneScreenZ = ProjectWithZ(view, proj, viewport.Width, viewport.Height, bx, bz, by);
    end

    if (exactOk == true and ex ~= nil and ey ~= nil and ez ~= nil) then
        exactScreenX, exactScreenY, exactScreenZ = ProjectWithZ(view, proj, viewport.Width, viewport.Height, ex, ez, ey);
    elseif (exactOk ~= true) then
        helperStatus = tostring(ex);
        lastError = helperStatus;
    end

    return {
        targetIndex = targetIndex,
        boneWorldX = bx,
        boneWorldY = by,
        boneWorldZ = bz,
        boneScreenX = boneScreenX,
        boneScreenY = boneScreenY,
        boneScreenZ = boneScreenZ,
        exactOk = exactOk == true and ex ~= nil and ey ~= nil and ez ~= nil,
        exactWorldX = ex,
        exactWorldY = ey,
        exactWorldZ = ez,
        exactScreenX = exactScreenX,
        exactScreenY = exactScreenY,
        exactScreenZ = exactScreenZ,
        deltaScreenX = (boneScreenX ~= nil and exactScreenX ~= nil) and (exactScreenX - boneScreenX) or nil,
        deltaScreenY = (boneScreenY ~= nil and exactScreenY ~= nil) and (exactScreenY - boneScreenY) or nil,
        helperStatus = helperStatus,
    };
end

function worldMarkerProbe.GetVisibilityDebug(targetIndex, getEntityManager, getBone)
    targetIndex = tonumber(targetIndex);

    if (targetIndex == nil or targetIndex == 0 or getEntityManager == nil or getBone == nil) then
        return nil, 'missing-args';
    end

    local entityManager = getEntityManager();
    local device = d3d8.get_device();

    if (entityManager == nil or device == nil) then
        return nil, 'missing-device';
    end

    local ent = GetEntity(targetIndex);
    local actorPointer = entityManager:GetActorPointer(targetIndex);
    local objectPointer = nil;
    local _, view = device:GetTransform(2);
    local _, proj = device:GetTransform(3);
    local _, viewport = device:GetViewport();

    if (actorPointer == nil or actorPointer == 0) then
        return nil, 'missing-actor';
    end

    if (view == nil or proj == nil or viewport == nil or viewport.Width == nil or viewport.Height == nil) then
        return nil, 'missing-transform';
    end

    pcall(function()
        objectPointer = ashita.memory.read_uint32(actorPointer + 0x674 + 0x44);
    end);

    local function safeNumber(fn)
        local ok, value = pcall(fn);

        if (ok ~= true) then
            return nil;
        end

        return tonumber(value);
    end

    local function projectBone(bone)
        local ok, bx, by, bz = pcall(function()
            return getBone(actorPointer, bone);
        end);

        if (ok ~= true or bx == nil or by == nil or bz == nil) then
            return nil;
        end

        local sx, sy, sz = ProjectWithZ(view, proj, viewport.Width, viewport.Height, bx, bz, by);

        return {
            worldX = bx,
            worldY = by,
            worldZ = bz,
            screenX = sx,
            screenY = sy,
            screenZ = sz,
            projected = sx ~= nil and sy ~= nil and sz ~= nil,
        };
    end

    local function projectEnemyPlate(bone, plateWorldOffsetY)
        local ok, bx, by, bz = pcall(function()
            return getBone(actorPointer, bone);
        end);

        if (ok ~= true or bx == nil or by == nil or bz == nil) then
            return nil;
        end

        local plateY = bz + verticalOffset + (tonumber(plateWorldOffsetY) or 0.50) - nameVerticalOffset;
        local sx, sy, sz = ProjectWithZ(view, proj, viewport.Width, viewport.Height, bx, plateY, by);

        return {
            worldX = bx,
            worldY = by,
            worldZ = bz,
            plateWorldY = plateY,
            screenX = sx,
            screenY = sy,
            screenZ = sz,
            projected = sx ~= nil and sy ~= nil and sz ~= nil,
        };
    end

    local zoneId = nil;
    local selfZ = nil;

    pcall(function()
        zoneId = AshitaCore:GetMemoryManager():GetParty():GetMemberZone(0);
    end);

    selfZ = GetSelfVerticalPosition(entityManager);

    local bounds = GetBoneBounds(actorPointer);

    return {
        targetIndex = targetIndex,
        zoneId = tonumber(zoneId),
        name = ent ~= nil and ent.Name or nil,
        status = ent ~= nil and ent.Status or nil,
        hpPercent = ent ~= nil and ent.HPPercent or nil,
        distance = ent ~= nil and ent.Distance or nil,
        type = safeNumber(function() return entityManager:GetType(targetIndex); end),
        spawnFlags = safeNumber(function() return entityManager:GetSpawnFlags(targetIndex); end),
        renderFlags0 = safeNumber(function() return entityManager:GetRenderFlags0(targetIndex); end),
        renderFlags1 = safeNumber(function() return entityManager:GetRenderFlags1(targetIndex); end),
        localX = safeNumber(function() return entityManager:GetLocalPositionX(targetIndex); end),
        localY = safeNumber(function() return entityManager:GetLocalPositionY(targetIndex); end),
        localZ = safeNumber(function() return entityManager:GetLocalPositionZ(targetIndex); end),
        lastX = safeNumber(function() return entityManager:GetLastPositionX(targetIndex); end),
        lastY = safeNumber(function() return entityManager:GetLastPositionY(targetIndex); end),
        lastZ = safeNumber(function() return entityManager:GetLastPositionZ(targetIndex); end),
        bone2 = projectBone(2),
        bone12 = projectBone(12),
        enemyPlate2 = projectEnemyPlate(2, 0.50),
        selfZ = selfZ,
        viewportHeight = tonumber(viewport.Height),
        boneCount = bounds ~= nil and bounds.count or nil,
        boneMinZ = bounds ~= nil and bounds.minZ or nil,
        boneMaxZ = bounds ~= nil and bounds.maxZ or nil,
        boneSpanZ = bounds ~= nil and bounds.spanZ or nil,
        boneMinY = bounds ~= nil and bounds.minY or nil,
        boneMaxY = bounds ~= nil and bounds.maxY or nil,
        boneSpanY = bounds ~= nil and bounds.spanY or nil,
        baseZ = bounds ~= nil and bounds.baseZ or nil,
        actorScalars = ReadFloatList(actorPointer, { 0x30, 0x34, 0x38, 0x44, 0x48, 0x4C, 0x58, 0x5C, 0x60, 0x6C, 0x70, 0x74, 0x6A0, 0x6A4, 0x6A8, 0x6AC }),
        actorInts = ReadIntList(actorPointer, { 0x20, 0x24, 0x28, 0x674, 0x6B8, 0x6C0 }),
        objectPointer = objectPointer,
        objectScalars = ReadFloatList(objectPointer, { 0x10, 0x14, 0x18, 0x20, 0x24, 0x28, 0x30, 0x34, 0x38, 0x40, 0x44, 0x48, 0x50, 0x54, 0x58, 0x60, 0x64, 0x68 }),
        objectInts = ReadIntList(objectPointer, { 0x00, 0x04, 0x08, 0x0C, 0x10, 0x20, 0x30, 0x40, 0x50 }),
    };
end

function worldMarkerProbe.PrepareFontAtlas()
    EnsureFontAtlas();
end

function worldMarkerProbe.BeginPlateFrame()
end

function worldMarkerProbe.QueuePlate(plate)
    if (enabled ~= true or plate == nil or plate.targetIndex == nil) then
        return;
    end

    if (queuedPlateSet[plate.targetIndex] == true) then
        return;
    end

    queuedPlateSet[plate.targetIndex] = true;
    queuedPlates[#queuedPlates + 1] = {
        targetIndex = plate.targetIndex,
        serverId = plate.serverId,
        hp = plate.hp or 100,
        mp = plate.mp,
        tp = (plate.vitals ~= nil and plate.vitals.tp or plate.petTp),
        vitals = plate.vitals,
        name = plate.name or '',
        trustIsMine = plate.trustIsMine,
        jobText = plate.jobText or '',
        jobIconTextureId = plate.jobIconTextureId,
        distance = plate.distance,
        isSelf = plate.isSelf == true,
        worldMarker = plate.worldMarker,
        clickTargetType = plate.clickTargetType or (plate.isSelf == true and 'self' or 'enemy'),
    };

    if (plate.isSelf == true) then
        lastSelfJobText = tostring(plate.jobText or '');
        lastSelfJobEnabled = plate.worldMarker ~= nil and plate.worldMarker.jobEnabled == true;
        lastSelfJobMode = tonumber(plate.worldMarker ~= nil and plate.worldMarker.jobDisplayModeIndex) or 0;
    end

    lastQueuedCount = #queuedPlates;
end

function worldMarkerProbe.ResetPass()
    pass = 0;
    queuedPlates = {};
    queuedPlateSet = {};
end

local function DrawOne(plate, entityManager, getBone, device, updateClickOnly)
    local targetIndex = plate.targetIndex;
    local hpPercent = plate.hp;

    if (targetIndex == nil or targetIndex == 0 or entityManager == nil or getBone == nil or device == nil) then
        return;
    end

    local actorPointer = entityManager:GetActorPointer(targetIndex);

    if (actorPointer == nil or actorPointer == 0) then
        return;
    end

    local style = plate.worldMarker or {};
    local plateAnchorBone = NormalizeAnchorBone(style.anchorBone or anchorBone);

    if (compareAnchors == true) then
        local bx, by, bz = getBone(actorPointer, plateAnchorBone);
        local ok, ex, ey, ez = pcall(function ()
            return GetExactNameplateAnchor(actorPointer, plateAnchorBone);
        end);

        if (bx ~= nil and by ~= nil and bz ~= nil) then
            DrawWithState(device, bx, bz + verticalOffset + 0.04, by, hpPercent, plate.worldMarker, 0xEE39F060);
        end

        if (ok == true and ex ~= nil and ey ~= nil and ez ~= nil) then
            DrawWithState(device, ex, ez + verticalOffset - 0.04, ey, hpPercent, plate.worldMarker, 0xEE31A8FF);
        elseif (ok ~= true) then
            lastError = tostring(ex);
        end

        return;
    end

    local wx, wy, wz = GetAnchor(actorPointer, getBone, style);

    if (wx == nil or wy == nil or wz == nil) then
        return;
    end

    -- FFXI actor memory uses x/y/z; D3D world uses x/z/y.
    if (style.plateTextureId ~= nil) then
        local plateScale = GetPlateDistanceScale(style, targetIndex, plate.distance or style.distance);
        local plateWorldOffsetX = tonumber(style.plateWorldOffsetX) or 0;
        local plateWorldOffsetY =
            (tonumber(style.plateWorldOffsetY) or tonumber(style.nameWorldOffsetY) or 0.78) +
            ((plateScale - 1.0) * (tonumber(style.plateDistanceScaleOffsetY) or 0));
        local plateWorldOffsetZ = tonumber(style.plateWorldOffsetZ) or 0;
        local plateX = wx + plateWorldOffsetX;
        local plateY = wz + verticalOffset + plateWorldOffsetY - nameVerticalOffset;
        local plateZ = wy + plateWorldOffsetZ;

        if (ShouldHideProjectedBelowViewportPlate(device, entityManager, style, plateX, plateY, plateZ) == true) then
            return;
        end

        local _, savePlateZFunc = device:GetRenderState(D3DRS_ZFUNC);
        local plateWorldWidth = (tonumber(style.plateWorldWidth) or 0.84) * plateScale;
        local plateWorldHeight = (tonumber(style.plateWorldHeight) or 0.315) * plateScale;

        style.clickTargetType = plate.clickTargetType or style.clickTargetType or (plate.isSelf == true and 'self' or 'enemy');
        style.serverId = plate.serverId or style.serverId;
        style.distance = plate.distance or style.distance;
        style.modelHitboxSize = plate.modelHitboxSize or style.modelHitboxSize;
        if (plate.trustIsMine ~= nil) then
            style.trustIsMine = plate.trustIsMine == true;
        end

        if (updateClickOnly == true) then
            if (SetSelfClickRectsFromCanvas(device, targetIndex, plateX, plateY, plateZ, style, plateWorldWidth, plateWorldHeight) ~= true) then
                if (plate.isSelf == true) then
                    SetSelfClickRectFromBillboard(device, targetIndex, plateX, plateY, plateZ, plateWorldWidth, plateWorldHeight);
                end
            end

            return;
        end

        if (showCanvasCenter == true) then
            DrawCanvasDebugWithState(device, plateX, plateY, plateZ, plateWorldWidth, plateWorldHeight, 0.035);
        end

        if (style.plateTacticalOverlayOnly == true) then
            return;
        end

        device:SetRenderState(D3DRS_ZFUNC, D3DCMP_LESSEQUAL);

        DrawTextureWithState(
            device,
            style.plateTextureId,
            plateX,
            plateY,
            plateZ,
            plateWorldWidth,
            0,
            0,
            0.00175,
            false,
            plateWorldHeight,
            false
        );

        device:SetRenderState(D3DRS_ZFUNC, savePlateZFunc);

        return;
    end

    if (plate.isSelf == true) then
        local _, view = device:GetTransform(2);
        local _, proj = device:GetTransform(3);
        local _, viewport = device:GetViewport();

        if (view ~= nil and proj ~= nil and viewport ~= nil and viewport.Width ~= nil and viewport.Height ~= nil) then
            local nameY = wz + verticalOffset + (tonumber(style.nameWorldOffsetY) or 0.78) - nameVerticalOffset;
            local sx, sy = ProjectWithZ(view, proj, viewport.Width, viewport.Height, wx, nameY, wy);

            if (sx ~= nil and sy ~= nil) then
                local width = math.max(110, math.min(220, (tonumber(style.hpBarWorldWidth) or 0.42) * 360));
                local height = 74;
                selfClickRect = {
                    targetIndex = targetIndex,
                    x1 = sx - (width * 0.5),
                    y1 = sy - 34,
                    x2 = sx + (width * 0.5),
                    y2 = sy + height - 34,
                };
            end
        end
    end

    local barY = wz + verticalOffset;

    if (plate.isSelf ~= true) then
        barY = barY + (tonumber(style.hpBarWorldOffsetY) or 0);
    end

    DrawWithState(device, wx, barY, wy, hpPercent, style, nil, plate);
    if (showText == true) then
        local nameY = wz + verticalOffset + (tonumber(style.nameWorldOffsetY) or 0.78) - nameVerticalOffset;
        DrawCanvasIconWithState(device, wx, nameY, wy, style);
        DrawNameWithState(device, plate.name, plate.distance, wx, nameY, wy, style);
        if (plate.isSelf == true and plate.jobText ~= nil and tostring(plate.jobText or '') ~= '') then
            local jobY = wz + verticalOffset + (tonumber(style.jobWorldOffsetY) or 0.54) - nameVerticalOffset;
            DrawJobWithState(device, plate, wx, jobY, wy, style);
        end

        if (showDistance == true and plate.isSelf ~= true) then
            DrawDistanceWithState(device, plate.distance, wx, nameY - 0.12, wy, style);
        end
    end
end

local function GetDrawableQueuedPlates()
    local settings = targeting.GetSettings();
    local maxCount = math.floor((tonumber(settings.maxWorldPlateCount) or 0) + 0.5);

    if (maxCount <= 0 or #queuedPlates <= maxCount) then
        return queuedPlates;
    end

    local targetIndex, subTargetIndex = targeting.GetCurrentTargetAndSubTargetIndexes();
    local list = {};

    for _, plate in ipairs(queuedPlates) do
        local index = tonumber(plate.targetIndex) or 0;
        local marker = plate.worldMarker ~= nil and plate.worldMarker.targetMarker or nil;
        local priority = 3;

        if (plate.isSelf == true) then
            priority = 0;
        elseif (index ~= 0 and (index == tonumber(targetIndex) or index == tonumber(subTargetIndex))) then
            priority = 1;
        elseif (marker ~= nil and marker.enabled == true) then
            priority = 2;
        end

        list[#list + 1] = {
            plate = plate,
            priority = priority,
            distance = tonumber(plate.distance) or 9999,
        };
    end

    table.sort(list, function(left, right)
        if (left.priority ~= right.priority) then
            return left.priority < right.priority;
        end

        return left.distance < right.distance;
    end);

    local out = {};
    for index = 1, math.min(maxCount, #list) do
        out[#out + 1] = list[index].plate;
    end

    return out;
end

function worldMarkerProbe.DrawQueued(getEntityManager, getBone)
    pass = pass + 1;

    if (enabled ~= true or getEntityManager == nil or getBone == nil) then
        return;
    end

    if (#queuedPlates == 0) then
        return;
    end

    local entityManager = getEntityManager();
    local device = d3d8.get_device();

    if (entityManager == nil or device == nil) then
        return;
    end

    if (pass == 1) then
        pendingSelfClickRect = nil;
        pendingSelfClickRects = nil;
        pendingClickRects = {};

        for _, plate in ipairs(GetDrawableQueuedPlates()) do
            if (plate.worldMarker ~= nil and plate.worldMarker.plateTextureId ~= nil) then
                pcall(function ()
                    DrawOne(plate, entityManager, getBone, device, true);
                end);
            end
        end

        clickRects = pendingClickRects;
        selfClickRect = pendingSelfClickRect;
        selfClickRects = pendingSelfClickRects;

        return;
    end

    if (pass ~= 2) then
        return;
    end

    lastDrawCount = 0;

    local drawablePlates = GetDrawableQueuedPlates();

    for _, plate in ipairs(drawablePlates) do
        local ok, err = pcall(function ()
            DrawOne(plate, entityManager, getBone, device, false);
        end);

        if (ok == true) then
            lastDrawCount = lastDrawCount + 1;
        else
            lastError = tostring(err);
        end
    end

    queuedPlates = {};
    queuedPlateSet = {};
end

function worldMarkerProbe.HandleSelfClick(selectTarget)
    if (enabled ~= true or replacePlates ~= true or selfClickRect == nil or selectTarget == nil) then
        return false;
    end

    local io = nil;
    local ok = pcall(function ()
        io = imguiApi.GetIO();
    end);

    if (ok ~= true or io == nil or io.MousePos == nil) then
        return false;
    end

    local mouseX = tonumber(io.MousePos.x or io.MousePos.X or io.MousePos[1]);
    local mouseY = tonumber(io.MousePos.y or io.MousePos.Y or io.MousePos[2]);

    if (mouseX == nil or mouseY == nil) then
        return false;
    end

    local flags = bit.bor(
        ImGuiWindowFlags_NoDecoration or 0,
        ImGuiWindowFlags_NoFocusOnAppearing or 0,
        ImGuiWindowFlags_NoNav or 0,
        ImGuiWindowFlags_NoResize or 0,
        ImGuiWindowFlags_NoSavedSettings or 0,
        ImGuiWindowFlags_NoScrollbar or 0,
        ImGuiWindowFlags_NoBackground or 0
    );
    local clicked = false;
    local rects = selfClickRects or { selfClickRect };

    for index, rect in ipairs(rects) do
        local width = math.max(1, rect.x2 - rect.x1);
        local height = math.max(1, rect.y2 - rect.y1);

        imguiApi.SetNextWindowBgAlpha(0.0);
        imguiApi.SetNextWindowPos({ rect.x1, rect.y1 }, ImGuiCond_Always or 1);
        imguiApi.SetNextWindowSize({ width, height }, ImGuiCond_Always or 1);

        if (imguiApi.Begin('LibraPlates Self Click##' .. tostring(index), true, flags)) then
            if (imguiApi.SetCursorScreenPos ~= nil) then
                imguiApi.SetCursorScreenPos({ rect.x1, rect.y1 });
            end

            if (imguiApi.InvisibleButton ~= nil) then
                imguiApi.InvisibleButton('##hit', { width, height });

                if (imguiApi.IsItemClicked ~= nil and imguiApi.IsItemClicked(0) == true) then
                    clicked = true;
                elseif (imguiApi.IsItemHovered ~= nil and imguiApi.IsMouseClicked ~= nil) then
                    clicked = (imguiApi.IsItemHovered() == true and imguiApi.IsMouseClicked(0) == true);
                end
            elseif (
                mouseX >= rect.x1 and
                mouseX <= rect.x2 and
                mouseY >= rect.y1 and
                mouseY <= rect.y2 and
                imguiApi.IsMouseClicked ~= nil and
                imguiApi.IsMouseClicked(0) == true
            ) then
                clicked = true;
            end
        end

        imguiApi.End();

        if (clicked == true) then
            pcall(function ()
                selectTarget(selfClickRect.targetIndex, false);
            end);

            return true;
        end
    end

    return false;
end

local function IsPointInSelfClickRect(x, y)
    if (selfClickRect == nil) then
        return false;
    end

    local mouseX = tonumber(x);
    local mouseY = tonumber(y);

    if (mouseX == nil or mouseY == nil) then
        return false;
    end

    local rects = selfClickRects or { selfClickRect };

    for _, rect in ipairs(rects) do
        if (
            mouseX >= rect.x1 and
            mouseX <= rect.x2 and
            mouseY >= rect.y1 and
            mouseY <= rect.y2
        ) then
            return true;
        end
    end

    if (selfClickRects ~= nil) then
        return false;
    end

    return (
        mouseX >= selfClickRect.x1 and
        mouseX <= selfClickRect.x2 and
        mouseY >= selfClickRect.y1 and
        mouseY <= selfClickRect.y2
    );
end

local function FindClickRectAt(x, y)
    local mouseX = tonumber(x);
    local mouseY = tonumber(y);

    if (mouseX == nil or mouseY == nil) then
        return nil;
    end

    for i = #clickRects, 1, -1 do
        local entry = clickRects[i];

        if (entry.clickEnabled ~= false) then
            for _, rect in ipairs(entry.rects or {}) do
                if (
                    mouseX >= rect.x1 and
                    mouseX <= rect.x2 and
                    mouseY >= rect.y1 and
                    mouseY <= rect.y2
                ) then
                    return entry, rect;
                end
            end
        end
    end

    return nil;
end

local function IsImguiCapturingMouse()
    if (imguiApi == nil or imguiApi.GetIO == nil) then
        return false;
    end

    local ok, io = pcall(function()
        return imguiApi.GetIO();
    end);

    if (ok ~= true or io == nil) then
        return false;
    end

    return io.WantCaptureMouse == true;
end

local function IsPointInNoGoZone(x, y, settings)
    if (settings == nil or settings.plateClickNoGoZonesEnabled ~= true) then
        return false, nil;
    end

    local mouseX = tonumber(x);
    local mouseY = tonumber(y);

    if (mouseX == nil or mouseY == nil) then
        return false, nil;
    end

    for index, zone in ipairs(settings.plateClickNoGoZones or {}) do
        if (type(zone) == 'table' and zone.enabled == true) then
            local left = tonumber(zone.x) or 0;
            local top = tonumber(zone.y) or 0;
            local width = math.max(1, tonumber(zone.width) or 1);
            local height = math.max(1, tonumber(zone.height) or 1);

            if (
                mouseX >= left and
                mouseX <= (left + width) and
                mouseY >= top and
                mouseY <= (top + height)
            ) then
                return true, zone.name or ('Zone ' .. tostring(index));
            end
        end
    end

    return false, nil;
end

local function ShouldIgnorePlateClickForUi(x, y)
    local settings = targeting.GetSettings();

    if (
        settings.blockPlateClicksWhenImguiCapturesMouse == true and
        IsImguiCapturingMouse() == true
    ) then
        return true, 'imgui';
    end

    local blocked, zoneName = IsPointInNoGoZone(x, y, settings);

    if (blocked == true) then
        return true, 'zone=' .. tostring(zoneName);
    end

    return false, nil;
end

local function GetMousePosition()
    if (imguiApi == nil or imguiApi.GetIO == nil) then
        return nil, nil;
    end

    local ok, io = pcall(function()
        return imguiApi.GetIO();
    end);

    if (ok ~= true or io == nil or io.MousePos == nil) then
        return nil, nil;
    end

    return
        tonumber(io.MousePos.x or io.MousePos.X or io.MousePos[1]),
        tonumber(io.MousePos.y or io.MousePos.Y or io.MousePos[2]);
end

function worldMarkerProbe.IsPlateHovered(targetIndex, targetType)
    local mouseX, mouseY = GetMousePosition();

    if (mouseX == nil or mouseY == nil) then
        return false;
    end

    local entry = FindClickRectAt(mouseX, mouseY);

    if (entry == nil) then
        return false;
    end

    if (tonumber(entry.targetIndex) ~= tonumber(targetIndex)) then
        return false;
    end

    if (targetType ~= nil and tostring(entry.targetType or '') ~= tostring(targetType)) then
        return false;
    end

    return true;
end

function worldMarkerProbe.GetHoveredPlate(targetType)
    local mouseX, mouseY = GetMousePosition();

    if (mouseX == nil or mouseY == nil) then
        return nil;
    end

    local entry, rect = FindClickRectAt(mouseX, mouseY);

    if (entry == nil) then
        return nil;
    end

    if (targetType ~= nil and tostring(entry.targetType or '') ~= tostring(targetType)) then
        return nil;
    end

    return entry, rect;
end

function worldMarkerProbe.GetWidestPlateRect(targetIndex, targetType, kinds)
    targetIndex = tonumber(targetIndex);

    if (targetIndex == nil or clickRects == nil) then
        return nil;
    end

    local allowed = {};

    for _, kind in ipairs(kinds or { 'name', 'hp', 'mp', 'tp' }) do
        allowed[tostring(kind)] = true;
    end

    local bestRect = nil;

    for _, entry in ipairs(clickRects) do
        if (
            tonumber(entry.targetIndex) == targetIndex and
            (targetType == nil or tostring(entry.targetType or '') == tostring(targetType))
        ) then
            for _, rect in ipairs(entry.rects or {}) do
                if (rect.anchorOnly ~= true and allowed[tostring(rect.kind or '')] == true) then
                    local x1 = tonumber(rect.x1);
                    local y1 = tonumber(rect.y1);
                    local x2 = tonumber(rect.x2);
                    local y2 = tonumber(rect.y2);

                    if (x1 ~= nil and y1 ~= nil and x2 ~= nil and y2 ~= nil and x2 > x1 and y2 > y1) then
                        if (bestRect == nil or (x2 - x1) > (bestRect.x2 - bestRect.x1)) then
                            bestRect = { x1 = x1, y1 = y1, x2 = x2, y2 = y2 };
                        end
                    end
                end
            end
        end
    end

    return bestRect;
end

function worldMarkerProbe.GetAlwaysVisiblePlates()
    local results = {};

    for _, entry in ipairs(clickRects or {}) do
        if (entry.plateTextureId ~= nil and entry.plateOverlayRect ~= nil) then
            results[#results + 1] = {
                targetIndex = entry.targetIndex,
                targetType = entry.targetType,
                clickName = entry.name,
                textureId = entry.plateTextureId,
                rect = entry.plateOverlayRect,
            };
        end
    end

    return results;
end

function worldMarkerProbe.HandleMouse(e, selectTarget, selectEnemyTarget, attackEnemyTarget, interactTarget, openQuickMenu)
    if (
        enabled ~= true or
        replacePlates ~= true or
        e == nil or
        selectTarget == nil
    ) then
        return false;
    end

    local message = tonumber(e.message);

    if (message ~= 513 and message ~= 514 and message ~= 516 and message ~= 517) then
        return false;
    end

    if (message == 513 and os.clock() < (tonumber(suppressFocusClickUntil) or 0)) then
        suppressFocusClickUntil = 0;
        suppressFocusRelease = true;
        e.blocked = true;
        lastClickStatus = 'suppressed focus left down message=' .. tostring(message) .. ' x=' .. tostring(e.x) .. ' y=' .. tostring(e.y);
        return true;
    end

    if (message == 514 and suppressFocusRelease == true) then
        suppressFocusRelease = false;
        e.blocked = true;
        lastClickStatus = 'suppressed focus left release message=' .. tostring(message) .. ' x=' .. tostring(e.x) .. ' y=' .. tostring(e.y);
        return true;
    end

    if (message == 514 and suppressNextLeftRelease == true) then
        suppressNextLeftRelease = false;
        e.blocked = true;
        lastClickStatus = 'suppressed left release message=' .. tostring(message) .. ' x=' .. tostring(e.x) .. ' y=' .. tostring(e.y);
        return true;
    end

    local ignoreForUi, ignoreReason = ShouldIgnorePlateClickForUi(e.x, e.y);

    if (ignoreForUi == true) then
        lastClickStatus = 'ignored ui ' .. tostring(ignoreReason) .. ' message=' .. tostring(message) .. ' x=' .. tostring(e.x) .. ' y=' .. tostring(e.y);
        return false;
    end

    local entry = FindClickRectAt(e.x, e.y);

    if (entry == nil and IsPointInSelfClickRect(e.x, e.y) == true) then
        entry = {
            targetIndex = selfClickRect.targetIndex,
            targetType = 'self',
            serverId = selfClickRect.serverId,
            name = selfClickRect.name,
            layoutStateName = selfClickRect.layoutStateName,
        };
    end

    if (message == 516) then
        rightDownPlate = entry ~= nil and {
            targetIndex = entry.targetIndex,
            targetType = entry.targetType,
        } or nil;
    elseif (message == 517) then
        local startedOnPlate = rightDownPlate ~= nil;
        local startedTargetIndex = startedOnPlate == true and tonumber(rightDownPlate.targetIndex) or nil;
        local startedTargetType = startedOnPlate == true and tostring(rightDownPlate.targetType or '') or '';
        rightDownPlate = nil;

        if (
            startedOnPlate ~= true or
            entry == nil or
            tonumber(entry.targetIndex) ~= startedTargetIndex or
            tostring(entry.targetType or '') ~= startedTargetType
        ) then
            lastClickStatus = 'right release native pass message=' .. tostring(message) .. ' x=' .. tostring(e.x) .. ' y=' .. tostring(e.y);
            e.blocked = startedOnPlate == true;
            return startedOnPlate == true;
        end
    end

    if (entry == nil) then
        if (message == 513) then
            lastClickStatus = 'miss message=' .. tostring(message) .. ' x=' .. tostring(e.x) .. ' y=' .. tostring(e.y);
        elseif (lastClickStatus == 'none') then
            lastClickStatus = 'mouse message=' .. tostring(message) .. ' x=' .. tostring(e.x) .. ' y=' .. tostring(e.y) .. ' plates=' .. tostring(clickRects ~= nil and #clickRects or 0);
        end

        return false;
    end

    local isSubTargetMode = targeting.IsSubTargetModeActive() == true;

    if (message == 513 and IsPlayerEngaged() == true and isSubTargetMode ~= true) then
        suppressNextLeftRelease = true;
        e.blocked = true;
        lastClickStatus = 'engaged left blocked message=' .. tostring(message) .. ' x=' .. tostring(e.x) .. ' y=' .. tostring(e.y) .. ' target=' .. tostring(entry.targetIndex);
        return true;
    end

    if (
        entry.targetType == 'object' and
        (message == 513 or message == 514)
    ) then
        lastClickStatus = 'object left native pass message=' .. tostring(message) .. ' x=' .. tostring(e.x) .. ' y=' .. tostring(e.y) .. ' target=' .. tostring(entry.targetIndex);
        return false;
    end

    if (message == 514) then
        lastClickStatus = 'left release native pass message=' .. tostring(message) .. ' x=' .. tostring(e.x) .. ' y=' .. tostring(e.y) .. ' target=' .. tostring(entry.targetIndex);
        return false;
    end

    e.blocked = true;
    lastClickStatus = 'detected ' .. tostring(entry.targetType) .. ' blocked message=' .. tostring(message) .. ' x=' .. tostring(e.x) .. ' y=' .. tostring(e.y) .. ' target=' .. tostring(entry.targetIndex);

    if (message == 513) then
        local ok = false;
        suppressNextLeftRelease = true;

        pcall(function ()
            if (entry.targetType == 'enemy' and selectEnemyTarget ~= nil) then
                ok = selectEnemyTarget(entry.targetIndex);
            else
                ok = selectTarget(entry.targetIndex, false);
            end
        end);

        lastClickStatus = 'left select ' .. tostring(ok) .. ' ' .. tostring(entry.targetType) .. ' message=' .. tostring(message) .. ' target=' .. tostring(entry.targetIndex);

        if (
            ok ~= true and
            (entry.targetType == 'npc' or entry.targetType == 'object')
        ) then
            suppressNextLeftRelease = false;
            e.blocked = false;
            return false;
        end
    elseif (message == 516 and isSubTargetMode == true) then
        local ok = false;

        pcall(function ()
            if (entry.targetType == 'enemy' and selectEnemyTarget ~= nil) then
                ok = selectEnemyTarget(entry.targetIndex);
            else
                ok = selectTarget(entry.targetIndex, false);
            end
        end);

        lastClickStatus = 'right subtarget select ' .. tostring(ok) .. ' ' .. tostring(entry.targetType) .. ' message=' .. tostring(message) .. ' target=' .. tostring(entry.targetIndex);

        if (ok ~= true) then
            e.blocked = false;
            return false;
        end
    elseif (message == 517 and entry.targetType == 'enemy' and attackEnemyTarget ~= nil) then
        local ok = false;

        pcall(function ()
            ok = attackEnemyTarget(entry.targetIndex, entry.serverId, entry.distance, entry.modelHitboxSize);
        end);

        lastClickStatus = 'right attack ' .. tostring(ok) .. ' message=' .. tostring(message) .. ' target=' .. tostring(entry.targetIndex) .. ' server=' .. tostring(entry.serverId) .. ' distance=' .. tostring(entry.distance);
        return true;
    elseif (
        message == 516 and
        interactTarget ~= nil and
        entry.targetType == 'object'
    ) then
        local ok = false;

        pcall(function ()
            ok = interactTarget(entry.targetIndex, entry.targetType, entry.distance);
        end);

        lastClickStatus = 'right interact ' .. tostring(ok) .. ' ' .. tostring(entry.targetType) .. ' message=' .. tostring(message) .. ' target=' .. tostring(entry.targetIndex) .. ' distance=' .. tostring(entry.distance);

        if (ok == true) then
            return true;
        end

        if (openQuickMenu ~= nil) then
            pcall(function ()
                ok = openQuickMenu(entry, e.x, e.y);
            end);

            if (ok == true) then
                lastClickStatus = 'right quickmenu true ' .. tostring(entry.targetType) .. ' message=' .. tostring(message) .. ' target=' .. tostring(entry.targetIndex);
                return true;
            end
        end
    elseif (message == 516 and openQuickMenu ~= nil) then
        local ok = false;

        pcall(function ()
            ok = openQuickMenu(entry, e.x, e.y);
        end);

        if (ok == true) then
            lastClickStatus = 'right quickmenu true ' .. tostring(entry.targetType) .. ' message=' .. tostring(message) .. ' target=' .. tostring(entry.targetIndex);
            return true;
        end
    elseif (message == 516 and interactTarget ~= nil) then
        local ok = false;

        pcall(function ()
            ok = interactTarget(entry.targetIndex, entry.targetType, entry.distance);
        end);

        lastClickStatus = 'right interact ' .. tostring(ok) .. ' ' .. tostring(entry.targetType) .. ' message=' .. tostring(message) .. ' target=' .. tostring(entry.targetIndex) .. ' distance=' .. tostring(entry.distance);

        if (ok ~= true) then
            e.blocked = false;
            return false;
        end
    end

    return true;
end

function worldMarkerProbe.SetClickHandlers(selectTarget, selectEnemyTarget, attackEnemyTarget)
    clickSelectTarget = selectTarget;
    clickSelectEnemyTarget = selectEnemyTarget;
    clickAttackEnemyTarget = attackEnemyTarget;
end

function worldMarkerProbe.SetClickDebug(value)
    clickDebugEnabled = true;
    clickDebugVisible = (value == true);
    lastClickStatus = 'debugpath=true visible=' .. tostring(clickDebugVisible) .. ' plates=' .. tostring(clickRects ~= nil and #clickRects or 0);
end

function worldMarkerProbe.GetClickDebug()
    return clickDebugEnabled == true;
end

function worldMarkerProbe.GetClickBordersVisible()
    return clickDebugVisible == true;
end

function worldMarkerProbe.DrawRawClickDebug()
    if (clickDebugEnabled ~= true or imguiApi == nil) then
        return;
    end

    local drawList = nil;
    pcall(function ()
        drawList = (imguiApi.GetForegroundDrawList ~= nil) and imguiApi.GetForegroundDrawList() or nil;
    end);

    if (drawList == nil) then
        return;
    end

    for _, entry in ipairs(clickRects) do
        local alpha = 0.01;
        local color = (entry.targetType == 'enemy') and { 1.0, 0.35, 0.0, alpha } or { 1.0, 0.0, 1.0, alpha };

        for _, rect in ipairs(entry.rects or {}) do
            drawList:AddRect(
                { rect.x1, rect.y1 },
                { rect.x2, rect.y2 },
                imguiApi.GetColorU32(color),
                0,
                0,
                1
            );
        end
    end
end

function worldMarkerProbe.GetStatusText()
    return 'enabled=' .. tostring(enabled) ..
        ' replace=' .. tostring(replacePlates) ..
        ' compare=' .. tostring(compareAnchors) ..
        ' text=' .. tostring(showText) ..
        ' distance=' .. tostring(showDistance) ..
        ' canvasdebug=' .. tostring(showCanvasCenter) ..
        ' queued=' .. tostring(lastQueuedCount) ..
        ' drawn=' .. tostring(lastDrawCount) ..
        ' anchor=' .. tostring(anchorMode) ..
        ' bone=' .. tostring(anchorBone) ..
        ' height=' .. tostring(verticalOffset) ..
        ' nameheight=' .. tostring(nameVerticalOffset) ..
        ' helper=' .. tostring(helperStatus) ..
        ' font=' .. tostring(fontStatus) ..
        ' selfjob=' .. tostring(lastSelfJobText) ..
        ' jobon=' .. tostring(lastSelfJobEnabled) ..
        ' jobmode=' .. tostring(lastSelfJobMode) ..
        ' clickactive=true' ..
        ' clickrect=' .. tostring(selfClickRect ~= nil) ..
        ' clickrects=' .. tostring(selfClickRects ~= nil and #selfClickRects or 0) ..
        ' clickplates=' .. tostring(clickRects ~= nil and #clickRects or 0) ..
        ' clickdebug=' .. tostring(clickDebugEnabled) ..
        ' clickvisible=' .. tostring(clickDebugVisible) ..
        ' clickver=' .. tostring(clickVersion) ..
        ' click=' .. tostring(lastClickStatus) ..
        ' error=' .. tostring(lastError);
end

function worldMarkerProbe.GetPerfStats()
    return {
        queued = tonumber(lastQueuedCount) or 0,
        drawn = tonumber(lastDrawCount) or 0,
        clickRects = clickRects ~= nil and #clickRects or 0,
    };
end

function worldMarkerProbe.Draw(targetIndex, getEntityManager, getEntity, getBone)
    if (getEntity == nil) then
        return;
    end

    local ent = getEntity(targetIndex);
    local hpPercent = (ent ~= nil and ent.HPPercent or 100);
    queuedPlates = { { targetIndex = targetIndex, hp = hpPercent, name = (ent ~= nil and ent.Name or ''), distance = (ent ~= nil and ent.Distance ~= nil and math.sqrt(ent.Distance) or nil) } };
    worldMarkerProbe.DrawQueued(getEntityManager, getBone);
end

return worldMarkerProbe;
