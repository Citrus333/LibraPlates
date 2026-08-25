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
local entities = require('core.entities');
local perfMeter = require('core.perf_meter');

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
        long x1, y1, x2, y2;
    } lp_d3d_rect_t;

    typedef struct {
        float x, y, z;
    } lp_d3dx_vector3_t;

    typedef struct {
        long x, y;
    } lp_mouse_snap_point_t;

    typedef void (__thiscall* lp_get_nameplate_offset_f)(void* pThis, int32_t idx, lp_d3dx_vector3_t* vec3);
    void* __stdcall GetForegroundWindow(void);
    void* __stdcall GetActiveWindow(void);
    int __stdcall SetForegroundWindow(void* hWnd);
    int __stdcall BringWindowToTop(void* hWnd);
    void* __stdcall SetFocus(void* hWnd);
    int __stdcall ClientToScreen(void* hWnd, lp_mouse_snap_point_t* point);
    int __stdcall SetCursorPos(int x, int y);
    short __stdcall GetAsyncKeyState(int key);
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
local D3DRS_COLORWRITEENABLE = 168;
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
local D3DCOLORWRITEENABLE_RED = 1;
local D3DCOLORWRITEENABLE_GREEN = 2;
local D3DCOLORWRITEENABLE_BLUE = 4;
local D3DCOLORWRITEENABLE_ALPHA = 8;
local D3DBLEND_ZERO = 1;
local D3DBLEND_ONE = 2;
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
worldMarkerProbe._plateBatch = require('core.world_plate_batch');
worldMarkerProbe._deferredLiveResourceBars = {};
worldMarkerProbe._atlasDrawSuppressed = false;
worldMarkerProbe._projectionCache = nil;

local enabled = false;
local replacePlates = false;
local drawSuppressed = false;
local compareAnchors = false;
-- ============================================================
-- Tier 1.5 perf fix: idle NPC anchor throttling
-- ============================================================
-- GetAnchor() does a real native memory read (skeleton/bone lookup) to
-- find where to hang a plate above an entity's head. That is necessary
-- for anything that moves, but idle town NPCs (Norg, Bastok, etc.) are
-- effectively stationary. Without this cache, every idle NPC plate pays
-- that native read every single frame, in addition to combat mobs and
-- players who actually need it. This cache lets idle NPC plates reuse
-- their last resolved position for a short window instead, the same way
-- GetDistanceRefreshBucket() already throttles distance-text redraws
-- elsewhere in the addon. (Helper functions that call GetAnchor() live
-- just below its own definition further down this file, since GetAnchor
-- is a local function and isn't in scope up here yet.)
worldMarkerProbe._idleNpcAnchor = { cache = {}, refreshSeconds = 0.025 };
-- EXPERIMENTAL: set to false to instantly revert plate drawing to the
-- original unbatched path (one SetTexture+DrawPrimitive call per plate)
-- if enabling batching causes any visual issues.
-- DISABLED (2026-08-23): two attempts at fixing the crop-offset atlas
-- copy each failed differently -- first with an outright CopyRects
-- error, then (after adding a GetDesc() probe to query/clamp against
-- the real source dimensions) with CopyRects reporting success while
-- silently copying wrong content. The visual artifact's behavior
-- (color/gradient varies with font size and text content; disappears
-- for the currently-targeted plate specifically) suggests the wrongly
-- copied region is picking up rendered text/GDI content rather than a
-- static background panel, but this isn't confirmed. Given two
-- increasingly-risky failed attempts, batching is turned off here
-- rather than attempting a third fix -- the individual (non-batched)
-- draw path is proven-correct and this flag is the single toggle to
-- revisit batching later if desired.
worldMarkerProbe._experimentalPlateBatchingEnabled = false;
-- Perf: how far outside the viewport (in pixels, in any direction) a
-- plate's projected screen position has to be before it's treated as
-- "clearly not visible" and skipped entirely. Deliberately generous --
-- lower it (e.g. 200) for a more aggressive cull if profiling shows
-- this is still conservative for your setup; raise it if anything near
-- screen edges seems to flicker or vanish too early.
worldMarkerProbe._offScreenCullMargin = 350;
-- DISABLED (2026-08-24): both left-click targeting and the Quick Menu
-- (right-click) stopped working, but only when the settings window is
-- closed. Both features depend on the same underlying click-rect
-- detection in this file. This cull is the newest change touching the
-- code path directly upstream of click-rect construction (everything
-- from style.clickTargetType onward, including click-rect building,
-- only runs AFTER this check passes) -- so it's the prime suspect,
-- though not yet confirmed with live diagnostic data. Disabled here to
-- immediately restore known-working click behavior; re-enable once the
-- actual interaction is found and fixed, rather than guessing further.
worldMarkerProbe._offScreenCullEnabled = false;
local showText = false;
local showDistance = false;
local showCanvasCenter = false;
local pass = 0;
local anchorMode = 'bone';
local anchorBone = 2;
local verticalOffset = 0.16;
local nameVerticalOffset = 0.54;
local queuedPlates = {};
local queuedStaticPlates = {};
local queuedPlateSet = {};
local selfClickRect = nil;
local selfClickRects = nil;
local clickRects = {};
local pendingClickRects = {};
local pendingSelfClickRect = nil;
local pendingSelfClickRects = nil;
local clickDebugEnabled = false;
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
worldMarkerProbe._stackScreenOffsetState = {};
worldMarkerProbe._lastStackSmoothingClock = nil;
worldMarkerProbe._clickHitMode = 'legacy';
worldMarkerProbe._lastClickPlates = {};
worldMarkerProbe._lastClickGetEntityManager = nil;
worldMarkerProbe._lastClickGetBone = nil;
worldMarkerProbe._pendingStackRects = {};
worldMarkerProbe._collectFrameClickRects = true;
worldMarkerProbe._pcModelBaselineCache = {};
function worldMarkerProbe._HasStackScreenOffset(plate)
    return
        (tonumber(plate ~= nil and plate._stackScreenOffsetX) or 0) ~= 0 or
        (tonumber(plate ~= nil and plate._stackScreenOffsetY) or 0) ~= 0 or
        (tonumber(plate ~= nil and plate._plateScreenOffsetX) or 0) ~= 0 or
        (tonumber(plate ~= nil and plate._plateScreenOffsetY) or 0) ~= 0;
end
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
local lastGameWindow = nil;
local suppressFocusClickUntil = 0;
local suppressFocusRelease = false;
local verts = ffi.new('lp_world_marker_vertex_t[?]', DOT_SEGMENTS * 3);
local textVerts = ffi.new('lp_world_marker_text_vertex_t[?]', MAX_TEXT_CHARS * 6);
-- Exact anchors are resolved for every visible PC each frame.  Keep the
-- immutable FFI call wrapper and its sequential scratch vector instead of
-- allocating both for every plate; the returned world position is still
-- resolved live, so animation and movement remain exact.
worldMarkerProbe._exactAnchorOffset = ffi.new('lp_d3dx_vector3_t');
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

function worldMarkerProbe._ReleaseInterface(value)
    if (value ~= nil) then
        pcall(function()
            value:Release();
        end);
    end
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

    if (active ~= nil and active ~= ffi.NULL) then
        lastGameWindow = active;
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

function worldMarkerProbe.IsGameWindowFocused()
    return IsGameWindowFocused();
end

function worldMarkerProbe.FocusGameWindow()
    local lib = GetUser32();

    if (lib == nil) then
        return false;
    end

    local window = lastGameWindow;

    if (window == nil or window == ffi.NULL) then
        pcall(function()
            window = lib.GetActiveWindow();
        end);
    end

    if (window == nil or window == ffi.NULL) then
        return false;
    end

    pcall(function()
        lib.BringWindowToTop(window);
    end);

    pcall(function()
        lib.SetForegroundWindow(window);
    end);

    pcall(function()
        lib.SetFocus(window);
    end);

    return true;
end

function worldMarkerProbe.ConsumeFocusPassthrough(e)
    if (e == nil) then
        return false;
    end

    local message = tonumber(e.message);

    if (message == 513 and os.clock() < (tonumber(suppressFocusClickUntil) or 0)) then
        suppressFocusClickUntil = 0;
        suppressFocusRelease = true;
        lastClickStatus = 'ignored focus left down message=' .. tostring(message) .. ' x=' .. tostring(e.x) .. ' y=' .. tostring(e.y);
        return true;
    end

    if (message == 514 and suppressFocusRelease == true) then
        suppressFocusRelease = false;
        lastClickStatus = 'ignored focus left release message=' .. tostring(message) .. ' x=' .. tostring(e.x) .. ' y=' .. tostring(e.y);
        return true;
    end

    return false;
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

function worldMarkerProbe._RefreshProjectionCache(device)
    if (device == nil) then
        worldMarkerProbe._projectionCache = nil;
        return nil;
    end

    local _, view = device:GetTransform(2);
    local _, projection = device:GetTransform(3);
    local _, viewport = device:GetViewport();
    local cache = {
        device = device,
        view = view,
        projection = projection,
        viewport = viewport,
    };

    if (view ~= nil) then
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

        cache.rx = rx; cache.ry = ry; cache.rz = rz;
        cache.ux = ux; cache.uy = uy; cache.uz = uz;
    end

    worldMarkerProbe._projectionCache = cache;
    return cache;
end

function worldMarkerProbe._GetProjectionState(device)
    local cache = worldMarkerProbe._projectionCache;
    if (cache == nil or cache.device ~= device) then
        cache = worldMarkerProbe._RefreshProjectionCache(device);
    end

    return
        cache ~= nil and cache.view or nil,
        cache ~= nil and cache.projection or nil,
        cache ~= nil and cache.viewport or nil;
end

local function GetBillboardVectors(device)
    local cache = worldMarkerProbe._projectionCache;
    if (cache ~= nil and cache.device == device and cache.rx ~= nil) then
        return cache.rx, cache.ry, cache.rz, cache.ux, cache.uy, cache.uz;
    end

    local view = worldMarkerProbe._GetProjectionState(device);

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

function worldMarkerProbe._ApplyStackScreenOffset(device, wx, wy, wz, plate)
    local plateOffsetX = 0;
    local plateOffsetY = 0;

    if (tostring(plate ~= nil and plate.stateName or 'Idle') == 'Idle') then
        plateOffsetX = tonumber(plate ~= nil and plate._plateScreenOffsetX) or 0;
        plateOffsetY = tonumber(plate ~= nil and plate._plateScreenOffsetY) or 0;
    end

    local offsetX = (tonumber(plate ~= nil and plate._stackScreenOffsetX) or 0) + plateOffsetX;
    local offsetY = (tonumber(plate ~= nil and plate._stackScreenOffsetY) or 0) + plateOffsetY;

    if (device == nil or (offsetX == 0 and offsetY == 0)) then
        return wx, wy, wz;
    end

    local view, proj, viewport = worldMarkerProbe._GetProjectionState(device);

    if (view == nil or proj == nil or viewport == nil or viewport.Width == nil or viewport.Height == nil) then
        return wx, wy, wz;
    end

    local centerX, centerY = ProjectWithZ(view, proj, viewport.Width, viewport.Height, wx, wy, wz);

    if (centerX == nil or centerY == nil) then
        return wx, wy, wz;
    end

    local rx, ry, rz, ux, uy, uz = GetBillboardVectors(device);
    local rightX = nil;
    local rightY = nil;
    local upX = nil;
    local upY = nil;

    rightX, rightY = ProjectWithZ(view, proj, viewport.Width, viewport.Height, wx + (rx * 0.10), wy + (ry * 0.10), wz + (rz * 0.10));
    upX, upY = ProjectWithZ(view, proj, viewport.Width, viewport.Height, wx + (ux * 0.10), wy + (uy * 0.10), wz + (uz * 0.10));

    if (offsetX ~= 0 and rightX ~= nil and rightX ~= centerX) then
        local amount = offsetX / ((rightX - centerX) / 0.10);
        wx = wx + (rx * amount);
        wy = wy + (ry * amount);
        wz = wz + (rz * amount);
    end

    if (offsetY ~= 0 and upY ~= nil and upY ~= centerY) then
        local amount = offsetY / ((upY - centerY) / 0.10);
        wx = wx + (ux * amount);
        wy = wy + (uy * amount);
        wz = wz + (uz * amount);
    end

    return wx, wy, wz;
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
        rawName = metadata ~= nil and metadata.rawName or nil,
        layoutStateName = metadata ~= nil and metadata.layoutStateName or nil,
        trustIsMine = metadata ~= nil and metadata.trustIsMine or nil,
        distance = metadata ~= nil and metadata.distance or nil,
        modelHitboxSize = metadata ~= nil and metadata.modelHitboxSize or nil,
        plateTextureId = metadata ~= nil and metadata.plateTextureId or nil,
        plateTextureWidth = metadata ~= nil and metadata.plateTextureWidth or nil,
        plateTextureHeight = metadata ~= nil and metadata.plateTextureHeight or nil,
        plateWorldWidth = metadata ~= nil and metadata.plateWorldWidth or nil,
        plateWorldHeight = metadata ~= nil and metadata.plateWorldHeight or nil,
        plateOverlayOnly = metadata ~= nil and metadata.plateOverlayOnly == true,
        plateOverlayRect = metadata ~= nil and metadata.plateOverlayRect or nil,
        plateOverlayOffsetX = metadata ~= nil and metadata.plateOverlayOffsetX or nil,
        plateOverlayOffsetY = metadata ~= nil and metadata.plateOverlayOffsetY or nil,
        animatedTargetMarker = metadata ~= nil and metadata.animatedTargetMarker or nil,
        clickEnabled = metadata == nil or metadata.clickEnabled ~= false,
        rects = rects,
        union = union,
    };

    worldMarkerProbe._pendingStackRects[#worldMarkerProbe._pendingStackRects + 1] = entry;

    if (worldMarkerProbe._collectFrameClickRects ~= true) then
        if (entry.targetType == 'object') then
            pendingClickRects[#pendingClickRects + 1] = entry;
        end

        return;
    end

    pendingClickRects[#pendingClickRects + 1] = entry;

    if (entry.targetType == 'self') then
        pendingSelfClickRects = rects;
        pendingSelfClickRect = {
            targetIndex = targetIndex,
            targetType = entry.targetType,
            serverId = entry.serverId,
            name = entry.name,
            rawName = entry.rawName,
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

    local view, proj, viewport = worldMarkerProbe._GetProjectionState(device);

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

local function SetPlateClickRectFromBillboard(device, targetIndex, targetType, wx, wy, wz, worldWidth, worldHeight, metadata)
    if (device == nil or targetIndex == nil or targetIndex == 0) then
        return;
    end

    local view, proj, viewport = worldMarkerProbe._GetProjectionState(device);

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
        targetType = tostring(targetType or 'pc'),
        serverId = metadata ~= nil and metadata.serverId or nil,
        name = metadata ~= nil and metadata.name or nil,
        layoutStateName = metadata ~= nil and metadata.layoutStateName or nil,
        x1 = left - padding,
        y1 = top - padding,
        x2 = right + padding,
        y2 = bottom + padding,
    };

    AddPlateClickRects(targetIndex, tostring(targetType or 'pc'), { rect }, rect, metadata);
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

local function SetSelfClickRectsFromCanvas(device, targetIndex, wx, wy, wz, style, worldWidth, worldHeight, boundsOnly)
    if (device == nil or targetIndex == nil or targetIndex == 0 or style == nil or style.plateClickRects == nil) then
        return false;
    end

    local view, proj, viewport = worldMarkerProbe._GetProjectionState(device);

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
        rawName = style.rawName,
        layoutStateName = style.layoutStateName,
        trustIsMine = style.trustIsMine,
        distance = style.distance,
        modelHitboxSize = style.modelHitboxSize,
        plateTextureId = style.plateAlwaysOnTop == true and style.plateTextureId or nil,
        plateTextureWidth = textureWidth,
        plateTextureHeight = textureHeight,
        plateWorldWidth = worldWidth,
        plateWorldHeight = worldHeight,
        plateOverlayOnly = style.plateTacticalOverlayOnly == true or (style.plateAlwaysOnTop == true and style.plateSuppressWorldWhenAlwaysOnTop == true),
        plateOverlayRect = nil,
        plateOverlayOffsetX = tonumber(style.plateOverlayOffsetX) or 0,
        plateOverlayOffsetY = tonumber(style.plateOverlayOffsetY) or 0,
        animatedTargetMarker = style.animatedTargetMarker,
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

    local canvasPoints = {
        { 0, 0 },
        { textureWidth, 0 },
        { textureWidth, textureHeight },
        { 0, textureHeight },
    };
    local fullLeft = nil;
    local fullTop = nil;
    local fullRight = nil;
    local fullBottom = nil;

    for _, point in ipairs(canvasPoints) do
        local sx, sy = projectCanvasPixel(point[1], point[2]);

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

    local function setOverlayRect()
        if (style.plateAlwaysOnTop ~= true) then
            return;
        end

        local overlayOffsetX = tonumber(metadata.plateOverlayOffsetX) or 0;
        local overlayOffsetY = tonumber(metadata.plateOverlayOffsetY) or 0;
        metadata.plateOverlayRect = {
            x1 = fullLeft + overlayOffsetX,
            y1 = fullTop + overlayOffsetY,
            x2 = fullRight + overlayOffsetX,
            y2 = fullBottom + overlayOffsetY,
        };
    end

    setOverlayRect();

    -- Stacking and no-go-zone masking only need the outside bounds of a
    -- plate.  Projecting every individual widget rect here for idle PCs
    -- turns the frame prepass into a full click-hitbox build every frame.
    -- Keep exact widget rects for an actual click (and for features that
    -- explicitly require live rects), but use one inexpensive union for the
    -- ordinary stacking prepass.
    if (boundsOnly == true) then
        local bounds = {
            kind = 'bounds',
            anchorOnly = true,
            targetIndex = targetIndex,
            targetType = targetType,
            x1 = fullLeft,
            y1 = fullTop,
            x2 = fullRight,
            y2 = fullBottom,
        };
        local union = { x1 = fullLeft, y1 = fullTop, x2 = fullRight, y2 = fullBottom };
        AddPlateClickRects(targetIndex, targetType, { bounds }, union, metadata);
        return true;
    end

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
    local view, proj, viewport = worldMarkerProbe._GetProjectionState(device);

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
    worldMarkerProbe._ReleaseInterface(saveTex);
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

local DrawTextureWithState = nil;

local function DrawWorldResourceBarText(device, centerX, centerY, centerZ, rx, ry, rz, ux, uy, uz, barStyle)
    local text = tostring(barStyle ~= nil and barStyle.text or '');

    if (text == '' or DrawTextureWithState == nil) then
        return;
    end

    local textureId, textureWidth, textureHeight = gdiTextTexture.GetTexture(text, {
        fontFamily = barStyle.fontFamily or 'Arial',
        fontSize = math.max(10, tonumber(barStyle.fontSize) or 16),
        color = barStyle.textColor or { 1.0, 1.0, 1.0, 1.0 },
        outlineEnabled = barStyle.textOutlineEnabled == true,
        outlineColor = barStyle.textOutlineColor or { 0.0, 0.0, 0.0, 1.0 },
        outlineSize = tonumber(barStyle.textOutlineSize) or 0,
    });

    if (textureId == nil or tonumber(textureWidth) == nil or tonumber(textureHeight) == nil or textureWidth <= 0 or textureHeight <= 0) then
        return;
    end

    local textOffsetX = tonumber(barStyle.textWorldOffsetX) or 0;
    local textOffsetY = tonumber(barStyle.textWorldOffsetY) or 0;
    local textX = centerX + (rx * textOffsetX) - (ux * textOffsetY);
    local textY = centerY + (ry * textOffsetX) - (uy * textOffsetY);
    local textZ = centerZ + (rz * textOffsetX) - (uz * textOffsetY);
    local worldHeight = math.max(0.028, (tonumber(textureHeight) or 16) * (tonumber(barStyle.textWorldScale) or 0.0011));
    local worldWidth = math.max(0.04, worldHeight * ((tonumber(textureWidth) or 1) / math.max(1, tonumber(textureHeight) or 1)));

    DrawTextureWithState(device, textureId, textX, textY, textZ, worldWidth, 0, 0, 0.00175, false, worldHeight, barStyle.alwaysOnTop == true);
end

local function DrawWorldResourceBar(device, wx, wy, wz, rx, ry, rz, ux, uy, uz, progress, barStyle)
    barStyle = barStyle or {};

    if (barStyle.enabled ~= true) then
        return;
    end

    local percent = Clamp01(progress) * 100;
    local showAtPercent = tonumber(barStyle.showAtPercent);

    if (showAtPercent ~= nil and percent > math.max(0, math.min(300, showAtPercent))) then
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
    local backgroundColor = ColorTableToD3D(barStyle.backgroundColor, { 0.0, 0.0, 0.0, 0.0 });
    local borderSize = math.max(0, tonumber(barStyle.borderWorldSize) or 0);
    local borderColor = ColorTableToD3D(barStyle.borderColor, { 0.0, 0.0, 0.0, 1.0 });
    local fillProgress = Clamp01(progress);
    local fillWidth = width * fillProgress;

    if (borderSize > 0) then
        DrawQuad(
            device,
            centerX,
            centerY,
            centerZ,
            rx, ry, rz,
            ux, uy, uz,
            (width * 0.5) + borderSize,
            (height * 0.5) + borderSize,
            borderColor
        );
    end

    if (barStyle.backgroundColor ~= nil) then
        DrawQuad(
            device,
            centerX,
            centerY,
            centerZ,
            rx, ry, rz,
            ux, uy, uz,
            width * 0.5,
            height * 0.5,
            backgroundColor
        );
    end

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

    DrawWorldResourceBarText(device, centerX, centerY, centerZ, rx, ry, rz, ux, uy, uz, barStyle);
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
    local view = worldMarkerProbe._GetProjectionState(device);
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
    local _, saveColorWrite = device:GetRenderState(D3DRS_COLORWRITEENABLE);
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
    device:SetRenderState(D3DRS_ZENABLE, 1);
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
    worldMarkerProbe._ReleaseInterface(saveTex);

    if (ok ~= true) then
        print('[LibraPlates] World marker probe draw failed: ' .. tostring(err));
    end
end

local DrawScreenTextureWithDepth = nil;
local GetPlateMaskZones = nil;
local ScreenRectIntersectsPlateMask = nil;
local DrawPlateOverlayScreen = nil;
local DrawFixedScreenTexture = nil;

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
    device:SetRenderState(D3DRS_ZENABLE, 1);
    device:SetRenderState(D3DRS_ZWRITEENABLE, 1);
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
    worldMarkerProbe._ReleaseInterface(saveTex);

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

function worldMarkerProbe._SetNameStackRect(device, targetIndex, targetType, name, wx, wy, wz, style, metadata)
    local text = tostring(name or '');

    if (device == nil or targetIndex == nil or targetIndex == 0 or text == '') then
        return false;
    end

    style = style or {};

    local maxLetters = tonumber(style.nameMaxLetters) or 0;
    if (maxLetters > 0 and string.len(text) > maxLetters) then
        text = string.sub(text, 1, maxLetters);
    end

    local fontScale = tonumber(style.nameFontScale) or 3.4;
    local worldScale = tonumber(style.nameWorldTextureScale) or 0.00175;
    local outlineEnabled = style.nameOutlineEnabled ~= false;
    local outlineColor = style.nameOutlineColor or { 0.0, 0.0, 0.0, 1.0 };
    local outlineSize = (tonumber(style.nameWorldOutlineBase) or 0) + (tonumber(style.nameOutlineSize) or 0);
    local textureId, textureWidth, textureHeight = gdiTextTexture.GetTexture(text, {
        fontFamily = style.nameFontFamily or 'Arial',
        fontSize = math.max(10, math.floor((tonumber(style.nameFontSize) or 24) * fontScale)),
        color = style.nameColor or { 0.22, 0.95, 0.38, 1.0 },
        outlineEnabled = outlineEnabled,
        outlineColor = outlineColor,
        outlineSize = outlineSize,
    });

    textureWidth = tonumber(textureWidth) or math.max(48, string.len(text) * 18);
    textureHeight = tonumber(textureHeight) or 28;

    local rx, ry, rz, ux, uy, uz = GetBillboardVectors(device);
    local offsetWorldScale = worldScale;

    if (style.nameUsePixelOffsets == true) then
        offsetWorldScale = GetWorldUnitsPerPixelAlongVector(device, wx, wy, wz, rx, ry, rz) or offsetWorldScale;
        worldScale = offsetWorldScale;
    end

    wx = wx + (rx * ((tonumber(style.nameOffsetX) or 0) * offsetWorldScale));
    wy = wy - (uy * ((tonumber(style.nameBillboardOffsetY) or 0) * worldScale));
    wz = wz - (uz * ((tonumber(style.nameBillboardOffsetY) or 0) * worldScale));

    local textureScale = tonumber(style.nameTextureScale) or 1.0;
    local width = math.max(0.08, textureWidth * textureScale * worldScale);
    local height = math.max(0.025, textureHeight * textureScale * worldScale);
    local view, proj, viewport = worldMarkerProbe._GetProjectionState(device);

    if (view == nil or proj == nil or viewport == nil or viewport.Width == nil or viewport.Height == nil) then
        return false;
    end

    local halfWidth = width * 0.5;
    local halfHeight = height * 0.5;
    local left = nil;
    local top = nil;
    local right = nil;
    local bottom = nil;
    local points = {
        { -halfWidth, -halfHeight },
        { halfWidth, -halfHeight },
        { halfWidth, halfHeight },
        { -halfWidth, halfHeight },
    };

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

    local padding = 4;
    local rect = {
        kind = 'name',
        targetIndex = targetIndex,
        targetType = tostring(targetType or 'pc'),
        x1 = left - padding,
        y1 = top - padding,
        x2 = right + padding,
        y2 = bottom + padding,
    };

    AddPlateClickRects(targetIndex, tostring(targetType or 'pc'), { rect }, rect, metadata);
    return true;
end

GetPlateMaskZones = function(viewport)
    local settings = targeting.GetSettings();

    if (
        settings == nil or
        settings.plateClickNoGoZonesEnabled ~= true or
        settings.plateClickNoGoZonesMask ~= true
    ) then
        return nil;
    end

    local zones = {};

    for _, zone in ipairs(settings.plateClickNoGoZones or {}) do
        if (type(zone) == 'table' and zone.enabled == true) then
            local left = tonumber(zone.x) or 0;
            local top = tonumber(zone.y) or 0;
            local width = math.max(1, tonumber(zone.width) or 1);
            local height = math.max(1, tonumber(zone.height) or 1);

            zones[#zones + 1] = {
                left = left,
                top = top,
                right = left + width,
                bottom = top + height,
            };
        end
    end

    return (#zones > 0) and zones or nil;
end

local function SubtractMaskZone(rects, zone)
    local out = {};

    for _, rect in ipairs(rects or {}) do
        local overlapLeft = math.max(rect.left, zone.left);
        local overlapTop = math.max(rect.top, zone.top);
        local overlapRight = math.min(rect.right, zone.right);
        local overlapBottom = math.min(rect.bottom, zone.bottom);

        if (overlapLeft >= overlapRight or overlapTop >= overlapBottom) then
            out[#out + 1] = rect;
        else
            if (rect.top < overlapTop) then
                out[#out + 1] = { left = rect.left, top = rect.top, right = rect.right, bottom = overlapTop };
            end

            if (overlapBottom < rect.bottom) then
                out[#out + 1] = { left = rect.left, top = overlapBottom, right = rect.right, bottom = rect.bottom };
            end

            if (rect.left < overlapLeft) then
                out[#out + 1] = { left = rect.left, top = overlapTop, right = overlapLeft, bottom = overlapBottom };
            end

            if (overlapRight < rect.right) then
                out[#out + 1] = { left = overlapRight, top = overlapTop, right = rect.right, bottom = overlapBottom };
            end
        end
    end

    return out;
end

local function GetVisibleScreenTextureRects(left, top, right, bottom, viewport)
    local rects = { { left = left, top = top, right = right, bottom = bottom } };
    local zones = GetPlateMaskZones(viewport);

    if (zones == nil) then
        return rects;
    end

    for _, zone in ipairs(zones) do
        rects = SubtractMaskZone(rects, zone);

        if (#rects == 0) then
            break;
        end
    end

    return rects;
end

ScreenRectIntersectsPlateMask = function(left, top, right, bottom, viewport)
    local zones = GetPlateMaskZones(viewport);

    if (zones == nil) then
        return false;
    end

    for _, zone in ipairs(zones) do
        if (
            math.max(left, zone.left) < math.min(right, zone.right) and
            math.max(top, zone.top) < math.min(bottom, zone.bottom)
        ) then
            return true;
        end
    end

    return false;
end

local function ScreenPointInPlateMask(x, y, viewport)
    local zones = GetPlateMaskZones(viewport);

    if (zones == nil) then
        return false;
    end

    x = tonumber(x);
    y = tonumber(y);

    if (x == nil or y == nil) then
        return false;
    end

    for _, zone in ipairs(zones) do
        if (x >= zone.left and x <= zone.right and y >= zone.top and y <= zone.bottom) then
            return true;
        end
    end

    return false;
end

local function RectIntersectsNoGoZone(left, top, right, bottom, settings)
    if (
        settings == nil or
        settings.plateClickNoGoZonesEnabled ~= true or
        settings.plateClickNoGoZonesMask ~= true
    ) then
        return false;
    end

    left = tonumber(left);
    top = tonumber(top);
    right = tonumber(right);
    bottom = tonumber(bottom);

    if (left == nil or top == nil or right == nil or bottom == nil or right <= left or bottom <= top) then
        return false;
    end

    for _, zone in ipairs(settings.plateClickNoGoZones or {}) do
        if (type(zone) == 'table' and zone.enabled == true) then
            local zoneLeft = tonumber(zone.x) or 0;
            local zoneTop = tonumber(zone.y) or 0;
            local zoneRight = zoneLeft + math.max(1, tonumber(zone.width) or 1);
            local zoneBottom = zoneTop + math.max(1, tonumber(zone.height) or 1);

            if (math.max(left, zoneLeft) < math.min(right, zoneRight) and math.max(top, zoneTop) < math.min(bottom, zoneBottom)) then
                return true;
            end
        end
    end

    return false;
end

local function ShouldHardHidePlateByNoGoZone(targetIndex)
    local settings = targeting.GetSettings();
    local index = tonumber(targetIndex);

    if (index == nil or settings == nil) then
        return false;
    end

    for _, entry in ipairs(worldMarkerProbe._pendingStackRects or {}) do
        if (tonumber(entry.targetIndex) == index and entry.union ~= nil) then
            return RectIntersectsNoGoZone(entry.union.x1, entry.union.y1, entry.union.x2, entry.union.y2, settings);
        end
    end

    return false;
end

function worldMarkerProbe._ShouldKeepFrameClickRects()
    if (worldMarkerProbe._clickHitMode ~= 'ondemand') then
        worldMarkerProbe._clickFrameRectsReason = 'legacy';
        return true;
    end

    local settings = targeting.GetSettings();

    if (settings == nil) then
        worldMarkerProbe._clickFrameRectsReason = 'no-settings';
        return true;
    end

    -- Mouse snap moves the cursor before a click exists, so it is the one
    -- feature that genuinely needs detailed live rectangles for all eligible
    -- plates.  Ordinary clicks build those detailed rectangles on demand.
    local getSnapKinds = worldMarkerProbe._MouseSnapKinds;
    local pcSnap = getSnapKinds ~= nil and getSnapKinds(settings.pcMouseSnapMode) or nil;
    local enemySnap = getSnapKinds ~= nil and getSnapKinds(settings.enemyMouseSnapMode) or nil;

    if (pcSnap ~= nil or enemySnap ~= nil) then
        worldMarkerProbe._clickFrameRectsReason = 'mouse-snap';
        return true;
    end

    worldMarkerProbe._clickFrameRectsReason = 'ondemand';
    return false;
end

local function DrawScreenTextureRect(device, left, top, right, bottom, rect, z)
    if (rect == nil or rect.left >= rect.right or rect.top >= rect.bottom) then
        return;
    end

    local width = math.max(1, right - left);
    local height = math.max(1, bottom - top);
    local u1 = (rect.left - left) / width;
    local v1 = (rect.top - top) / height;
    local u2 = (rect.right - left) / width;
    local v2 = (rect.bottom - top) / height;
    local color = 0xFFFFFFFF;
    local vertices = ffi.new('lp_world_marker_screen_vertex_t[6]', {
        { rect.left,  rect.top,    z, 1, color, u1, v1 },
        { rect.right, rect.top,    z, 1, color, u2, v1 },
        { rect.right, rect.bottom, z, 1, color, u2, v2 },
        { rect.left,  rect.top,    z, 1, color, u1, v1 },
        { rect.right, rect.bottom, z, 1, color, u2, v2 },
        { rect.left,  rect.bottom, z, 1, color, u1, v2 },
    });

    device:DrawPrimitiveUP(D3DPT_TRIANGLELIST, 2, vertices, SCREEN_VERTEX_SIZE);
end

DrawScreenTextureWithDepth = function(device, textureId, wx, wy, wz, offsetX, offsetY, size, height, alwaysOnTop, rectLeft, rectTop, rectRight, rectBottom)
    textureId = tonumber(textureId);

    if (textureId == nil or textureId == 0) then
        return false;
    end

    local view, proj, viewport = worldMarkerProbe._GetProjectionState(device);

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

    if (rectLeft ~= nil and rectTop ~= nil and rectRight ~= nil and rectBottom ~= nil) then
        left = tonumber(rectLeft) or left;
        top = tonumber(rectTop) or top;
        right = tonumber(rectRight) or right;
        bottom = tonumber(rectBottom) or bottom;
    end

    local screenOverlayDraw = alwaysOnTop == true or (rectLeft ~= nil and rectTop ~= nil and rectRight ~= nil and rectBottom ~= nil);
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
    device:SetRenderState(D3DRS_ZENABLE, screenOverlayDraw == true and 0 or 1);
    device:SetRenderState(D3DRS_ZWRITEENABLE, 0);
    device:SetRenderState(D3DRS_ZFUNC, screenOverlayDraw == true and D3DCMP_ALWAYS or D3DCMP_LESSEQUAL);
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

    local ok = pcall(function()
        local color = 0xFFFFFFFF;
        local vertices = ffi.new('lp_world_marker_screen_vertex_t[6]', {
            { left,  top,    sz, 1, color, 0, 0 },
            { right, top,    sz, 1, color, 1, 0 },
            { right, bottom, sz, 1, color, 1, 1 },
            { left,  top,    sz, 1, color, 0, 0 },
            { right, bottom, sz, 1, color, 1, 1 },
            { left,  bottom, sz, 1, color, 0, 1 },
        });

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
    worldMarkerProbe._ReleaseInterface(saveTex);

    return ok == true;
end

DrawFixedScreenTexture = function(device, textureId, centerX, centerY, width, height)
    textureId = tonumber(textureId);

    if (textureId == nil or textureId == 0) then
        return false;
    end

    local drawW = math.max(1, tonumber(width) or 1);
    local drawH = math.max(1, tonumber(height) or 1);
    local left = (tonumber(centerX) or 0) - (drawW * 0.5);
    local top = (tonumber(centerY) or 0) - (drawH * 0.5);
    local right = left + drawW;
    local bottom = top + drawH;
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
    device:SetRenderState(D3DRS_ZENABLE, 0);
    device:SetRenderState(D3DRS_ZWRITEENABLE, 0);
    device:SetRenderState(D3DRS_ZFUNC, D3DCMP_ALWAYS);
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

    local ok = pcall(function()
        local color = 0xFFFFFFFF;
        local vertices = ffi.new('lp_world_marker_screen_vertex_t[6]', {
            { left,  top,    0, 1, color, 0, 0 },
            { right, top,    0, 1, color, 1, 0 },
            { right, bottom, 0, 1, color, 1, 1 },
            { left,  top,    0, 1, color, 0, 0 },
            { right, bottom, 0, 1, color, 1, 1 },
            { left,  bottom, 0, 1, color, 0, 1 },
        });

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
    worldMarkerProbe._ReleaseInterface(saveTex);

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

DrawPlateOverlayScreen = function(device, textureId, wx, wy, wz, worldWidth, worldHeight, alwaysOnTop, offsetX, offsetY, requireMaskOverlap)
    local view, proj, viewport = worldMarkerProbe._GetProjectionState(device);

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

    local screenOffsetX = tonumber(offsetX) or 0;
    local screenOffsetY = tonumber(offsetY) or 0;
    local drawLeft = left + screenOffsetX;
    local drawTop = top + screenOffsetY;
    local drawRight = right + screenOffsetX;
    local drawBottom = bottom + screenOffsetY;

    if (requireMaskOverlap == true) then
        if (ScreenRectIntersectsPlateMask(drawLeft, drawTop, drawRight, drawBottom, viewport) ~= true) then
            return false;
        end

        return true;
    end

    return DrawScreenTextureWithDepth(
        device,
        textureId,
        wx,
        wy,
        wz,
        screenOffsetX,
        screenOffsetY,
        math.max(1, right - left),
        math.max(1, bottom - top),
        alwaysOnTop == true,
        drawLeft,
        drawTop,
        drawRight,
        drawBottom
    );
end

function worldMarkerProbe._ApplyCanvasCropWorldOffset(device, textureId, wx, wy, wz, worldWidth, worldHeight)
    local textureModule = package.loaded['core.canvas_texture'];
    local crop = textureModule ~= nil and textureModule.GetTextureCrop ~= nil and textureModule.GetTextureCrop(textureId) or nil;

    if (
        crop == nil or
        tonumber(crop.fullWidth) == nil or
        tonumber(crop.fullHeight) == nil or
        tonumber(crop.width) == nil or
        tonumber(crop.height) == nil or
        tonumber(crop.x) == nil or
        tonumber(crop.y) == nil
    ) then
        return wx, wy, wz;
    end

    local fullWidth = math.max(1, tonumber(crop.fullWidth) or 1024);
    local fullHeight = math.max(1, tonumber(crop.fullHeight) or 512);
    local cropWidth = math.max(1, tonumber(crop.width) or fullWidth);
    local cropHeight = math.max(1, tonumber(crop.height) or fullHeight);
    local deltaX = ((tonumber(crop.x) or 0) + (cropWidth * 0.5)) - (fullWidth * 0.5);
    local deltaY = ((tonumber(crop.y) or 0) + (cropHeight * 0.5)) - (fullHeight * 0.5);

    if (math.abs(deltaX) < 0.01 and math.abs(deltaY) < 0.01) then
        return wx, wy, wz;
    end

    local rx, ry, rz, ux, uy, uz = GetBillboardVectors(device);
    local worldDx = deltaX * ((tonumber(worldWidth) or 0) / cropWidth);
    local worldDy = deltaY * ((tonumber(worldHeight) or 0) / cropHeight);

    wx = wx + (rx * worldDx) - (ux * worldDy);
    wy = wy + (ry * worldDx) - (uy * worldDy);
    wz = wz + (rz * worldDx) - (uz * worldDy);

    return wx, wy, wz;
end

DrawTextureWithState = function(device, textureId, wx, wy, wz, worldSize, offsetX, offsetY, offsetWorldScale, usePixelOffsets, worldHeight, alwaysOnTop, batchEligible)
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

    if (
        batchEligible == true and
        worldMarkerProbe._plateBatch ~= nil and
        worldMarkerProbe._plateBatch.Queue ~= nil
    ) then
        local textureModule = package.loaded['core.canvas_texture'];
        local batchInfo =
            textureModule ~= nil and
            textureModule.GetWorldBatchInfo ~= nil and
            textureModule.GetWorldBatchInfo(textureId) or nil;

        if (
            batchInfo ~= nil and
            worldMarkerProbe._plateBatch.Queue(textureId, batchInfo, {
                wx = wx,
                wy = wy,
                wz = wz,
                rx = rx,
                ry = ry,
                rz = rz,
                ux = ux,
                uy = uy,
                uz = uz,
                width = size,
                height = height,
                alwaysOnTop = alwaysOnTop == true,
            }) == true
        ) then
            return true, true;
        end
    end

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
    worldMarkerProbe._ReleaseInterface(saveTex);

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

    DrawTextWithState(device, string.format('%.1fm', value):gsub(',', '.'), wx, wy, wz, style, 'small');
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

    if (worldMarkerProbe._helperFunction == nil) then
        worldMarkerProbe._helperFunction = ffi.cast('lp_get_nameplate_offset_f', helper);
    end

    local offset = worldMarkerProbe._exactAnchorOffset;
    offset.x = 0;
    offset.y = 0;
    offset.z = 0;
    worldMarkerProbe._helperFunction(ffi.cast('void*', objectPointer), NormalizeAnchorBone(bone), offset);
    helperStatus = 'ok';

    return baseX + offset.x, baseY + offset.z, baseZ + offset.y;
end

local function GetAnchor(actorPointer, getBone, style)
    local bone = NormalizeAnchorBone(style ~= nil and style.anchorBone or anchorBone);

    if (anchorMode == 'exact' or (style ~= nil and style.useExactNameplateAnchor == true)) then
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

worldMarkerProbe._idleNpcAnchor.IsEligible = function(plate, isObjectPlate)
    -- Objects are deliberately excluded: FFXI can return a stale object
    -- offset on the first read, and the existing code already relies on
    -- re-resolving them every pass to work around that. Only ordinary
    -- NPCs, and only while genuinely idle (not targeted/subtargeted),
    -- are safe to throttle here.
    if (isObjectPlate == true) then
        return false;
    end

    if (tostring(plate.clickTargetType or ''):lower() ~= 'npc') then
        return false;
    end

    local stateName = plate.stateName or (plate.worldMarker ~= nil and plate.worldMarker.layoutStateName) or nil;

    return stateName == 'Idle' or stateName == nil;
end

worldMarkerProbe._idleNpcAnchor.Resolve = function(targetIndex, actorPointer, getBone, style)
    local now = os.clock();
    local cache = worldMarkerProbe._idleNpcAnchor.cache;
    local cached = cache[targetIndex];

    if (
        cached ~= nil and
        cached.actorPointer == actorPointer and
        (now - (tonumber(cached.at) or 0)) < worldMarkerProbe._idleNpcAnchor.refreshSeconds
    ) then
        if (perfMeter ~= nil and perfMeter.Count ~= nil) then
            perfMeter.Count('world.anchor.idleNpcReuse', 1);
        end

        return cached.x, cached.y, cached.z;
    end

    local x, y, z = GetAnchor(actorPointer, getBone, style);

    if (x ~= nil and y ~= nil and z ~= nil) then
        cache[targetIndex] = {
            actorPointer = actorPointer,
            x = x,
            y = y,
            z = z,
            at = now,
        };
    end

    if (perfMeter ~= nil and perfMeter.Count ~= nil) then
        perfMeter.Count('world.anchor.resolve', 1);
    end

    return x, y, z;
end

function worldMarkerProbe._IsObjectWorldPointInFrontOfCamera(device, plate, wx, wy, wz)
    if (tostring(plate ~= nil and plate.clickTargetType or ''):lower() ~= 'object') then
        return true;
    end

    local view, proj, viewport = worldMarkerProbe._GetProjectionState(device);

    if (view == nil or proj == nil or viewport == nil or viewport.Width == nil or viewport.Height == nil) then
        -- Failure to inspect the camera is not evidence that the object is
        -- behind it.  Keep the plate rather than hiding it for a transient
        -- D3D transform read failure.
        return true;
    end

    local screenX, screenY = ProjectWithZ(
        view,
        proj,
        viewport.Width,
        viewport.Height,
        wx,
        wy,
        wz
    );

    return screenX ~= nil and screenY ~= nil;
end

local function GetObjectEntityAnchor(entityManager, targetIndex)
    if (entityManager == nil or targetIndex == nil or targetIndex == 0) then
        return nil;
    end

    local x = SafeNumber(function() return entityManager:GetLocalPositionX(targetIndex); end);
    local y = SafeNumber(function() return entityManager:GetLocalPositionY(targetIndex); end);
    local z = SafeNumber(function() return entityManager:GetLocalPositionZ(targetIndex); end);

    if (x == nil or y == nil or z == nil) then
        x = SafeNumber(function() return entityManager:GetLastPositionX(targetIndex); end);
        y = SafeNumber(function() return entityManager:GetLastPositionY(targetIndex); end);
        z = SafeNumber(function() return entityManager:GetLastPositionZ(targetIndex); end);
    end

    return x, y, z;
end

function worldMarkerProbe._IsPlausibleObjectAnchor(plate, x, y, z, entityX, entityY, entityZ)
    if (
        x == nil or y == nil or z == nil or
        entityX == nil or entityY == nil or entityZ == nil or
        x ~= x or y ~= y or z ~= z
    ) then
        return false;
    end

    local rawName = tostring(
        (plate ~= nil and plate.rawName) or
        (plate ~= nil and plate.worldMarker ~= nil and plate.worldMarker.rawName) or
        ''
    );
    local isDoor = rawName:match('^Door:') ~= nil;
    local horizontalLimit = isDoor and 3.0 or 8.0;
    local verticalLimit = isDoor and 6.0 or 16.0;
    local dx = x - entityX;
    local dy = y - entityY;

    return
        ((dx * dx) + (dy * dy)) <= (horizontalLimit * horizontalLimit) and
        math.abs(z - entityZ) <= verticalLimit;
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

local function NearlyEqual(value, target, tolerance)
    value = tonumber(value);
    target = tonumber(target);
    tolerance = tonumber(tolerance) or 0.05;

    if (value == nil or target == nil) then
        return false;
    end

    return math.abs(value - target) <= tolerance;
end

local function GetPcBodyFamilyFromBounds(bounds)
    if (bounds == nil) then
        return nil;
    end

    local bones = tonumber(bounds.count);
    local zSpan = tonumber(bounds.spanZ);
    local ySpan = tonumber(bounds.spanY);

    if (bones == 93 and NearlyEqual(zSpan, 2.10, 0.06) and NearlyEqual(ySpan, 1.90, 0.08)) then
        return 'Tarutaru';
    elseif (bones == 108 and NearlyEqual(zSpan, 2.00, 0.08) and NearlyEqual(ySpan, 2.50, 0.08)) then
        return 'Mithra';
    elseif ((bones == 97 or bones == 94 or bones == 93) and zSpan >= 2.10 and zSpan <= 2.70 and NearlyEqual(ySpan, 2.50, 0.08)) then
        return 'Hume';
    elseif (bones == 99 and (NearlyEqual(zSpan, 3.40, 0.10) or NearlyEqual(zSpan, 2.84, 0.10)) and NearlyEqual(ySpan, 2.50, 0.08)) then
        return 'Elvaan';
    elseif (bones == 107 and NearlyEqual(zSpan, 3.04, 0.10) and NearlyEqual(ySpan, 2.65, 0.08)) then
        return 'Galka';
    end

    return nil;
end

local function ReadPcRaceId(entityManager, targetIndex)
    local ent = GetEntity(targetIndex);
    local direct = tonumber(ent ~= nil and ent.Race or nil);

    if (direct ~= nil and direct >= 1 and direct <= 8) then
        return direct;
    end

    if (entityManager ~= nil and entityManager.GetRace ~= nil) then
        local ok, value = pcall(function()
            return entityManager:GetRace(targetIndex);
        end);

        value = tonumber(ok == true and value or nil);

        if (value ~= nil and value >= 1 and value <= 8) then
            return value;
        end
    end

    return nil;
end

local function GetPcRaceFamilyKeyAndSex(raceId, fallbackFamily)
    raceId = tonumber(raceId);

    if (raceId == 1) then return 'hume', 'male'; end
    if (raceId == 2) then return 'hume', 'female'; end
    if (raceId == 3) then return 'elvaan', 'male'; end
    if (raceId == 4) then return 'elvaan', 'female'; end
    if (raceId == 5) then return 'tarutaru', 'male'; end
    if (raceId == 6) then return 'tarutaru', 'female'; end
    if (raceId == 7) then return 'mithra', 'female'; end
    if (raceId == 8) then return 'galka', 'male'; end

    local key = tostring(fallbackFamily or ''):lower();

    if (key == 'tarutaru' or key == 'mithra' or key == 'hume' or key == 'elvaan' or key == 'galka') then
        return key, key == 'mithra' and 'female' or key == 'galka' and 'male' or 'unknown';
    end

    return nil, nil;
end

local function ReadPcSizeScale(actorPointer)
    if (actorPointer == nil or actorPointer == 0) then
        return nil;
    end

    local ok, value = pcall(function()
        return ashita.memory.read_float(actorPointer + 0x6A0);
    end);

    if (ok ~= true) then
        return nil;
    end

    return tonumber(value);
end

local function GetPcSizeBucket(sizeScale, familyKey)
    local scale = tonumber(sizeScale);

    if (scale == nil) then
        return 'medium';
    end

    if (tostring(familyKey or '') == 'tarutaru') then
        if (scale < 0.845) then return 'small'; end
        if (scale < 0.895) then return 'medium'; end
        return 'large';
    end

    if (tostring(familyKey or '') == 'mithra') then
        if (scale < 0.91) then return 'small'; end
        if (scale < 0.95) then return 'medium'; end
        return 'large';
    end

    if (scale < 0.985) then return 'small'; end
    if (scale > 1.015) then return 'large'; end
    return 'medium';
end

local function GetPcBucketBaselineY(familyKey, sexKey, sizeKey)
    local baselines = {
        tarutaru = {
            male = { small = 64, medium = 55, large = 56 },
            female = { small = 63, medium = 64, large = 64 },
        },
        mithra = {
            female = { small = 62, medium = 53, large = 55 },
        },
        hume = {
            male = { small = 30, medium = 28, large = 14 },
            female = { small = 53, medium = 44, large = 29 },
        },
        elvaan = {
            male = { small = 53, medium = 43, large = 25 },
            female = { small = 48, medium = 38, large = 36 },
        },
        galka = {
            male = { small = 34, medium = 31, large = 28 },
        },
    };

    local family = baselines[tostring(familyKey or '')];
    local sex = family ~= nil and (family[tostring(sexKey or '')] or family.male or family.female) or nil;

    if (sex ~= nil) then
        return tonumber(sex[tostring(sizeKey or '')]) or tonumber(sex.medium) or 0;
    end

    local fallback = {
        tarutaru = 64,
        mithra = 44,
        hume = 43,
        elvaan = 37,
        galka = 31,
    };

    return fallback[tostring(familyKey or '')] or 0;
end

local function GetPcBodyPlateOffset(actorPointer, targetIndex, entityManager)
    local cacheKey = tonumber(targetIndex) or 0;
    local modelCache = worldMarkerProbe._pcModelBaselineCache;
    local cached = modelCache[cacheKey];
    local familyKey = nil;
    local sexKey = nil;
    local sizeKey = nil;
    local baselineY = 0;

    if (cached ~= nil and cached.actorPointer == actorPointer) then
        familyKey = cached.familyKey;
        sexKey = cached.sexKey;
        -- A model can report its temporary default scale while it is still
        -- loading.  Cache the expensive family/race work, but refresh this
        -- single float so Small/Medium/Large corrections never get stuck on
        -- the first observed bucket.
        sizeKey = GetPcSizeBucket(ReadPcSizeScale(actorPointer), familyKey);
        if (sizeKey ~= cached.sizeKey) then
            cached.sizeKey = sizeKey;
            cached.baselineY = GetPcBucketBaselineY(familyKey, sexKey, sizeKey);
        end
        baselineY = tonumber(cached.baselineY) or 0;
    else
        local bounds = GetBoneBounds(actorPointer);
        local family = GetPcBodyFamilyFromBounds(bounds);
        familyKey, sexKey = GetPcRaceFamilyKeyAndSex(ReadPcRaceId(entityManager, targetIndex), family);

        if (familyKey == nil) then
            return 0;
        end

        sizeKey = GetPcSizeBucket(ReadPcSizeScale(actorPointer), familyKey);
        baselineY = GetPcBucketBaselineY(familyKey, sexKey, sizeKey);
        modelCache[cacheKey] = {
            actorPointer = actorPointer,
            familyKey = familyKey,
            sexKey = sexKey,
            sizeKey = sizeKey,
            baselineY = baselineY,
        };
    end

    return baselineY * 0.01;
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

local function BuildOffsetRange(first, last, step)
    local offsets = {};

    for offset = first, last, step or 1 do
        offsets[#offsets + 1] = offset;
    end

    return offsets;
end

local function ReadByteList(pointer, offsets)
    if (pointer == nil or pointer == 0) then
        return nil;
    end

    local parts = {};

    for _, offset in ipairs(offsets) do
        local ok, value = pcall(function()
            return ashita.memory.read_uint8(pointer + offset);
        end);

        parts[#parts + 1] = string.format('%X=0x%02X', offset, ok == true and (tonumber(value) or 0) or 0);
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

    local view, proj, viewport = worldMarkerProbe._GetProjectionState(device);

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

-- ============================================================
-- Perf: general off-screen cull
-- ============================================================
-- ShouldHideProjectedBelowViewportPlate() above only ever fires for
-- plates that explicitly opt in (style.hideWhenProjectedBelowViewport)
-- and only catches the "below the bottom edge" case. Every other plate
-- -- including ones directly behind the camera, or off to the far left
-- or right, which is common for anyone standing in a crowd -- still pays
-- the full remaining cost of DrawOne(): click-rect construction, D3D
-- render-state save/restore, and either an individual draw call or a
-- batch-queue append. None of that is skippable once you know the plate
-- has zero chance of being visible this frame.
--
-- This is deliberately generous (large margin, and it treats a failed
-- projection as "can't prove it's off-screen" rather than culling it) so
-- it only ever removes work for plates that are unambiguously not going
-- to be seen, never for anything genuinely near an edge.
worldMarkerProbe._IsClearlyOffScreen = function(device, wx, wy, wz)
    local view, proj, viewport = worldMarkerProbe._GetProjectionState(device);

    if (view == nil or proj == nil or viewport == nil or viewport.Width == nil or viewport.Height == nil) then
        -- Can't determine screen position; don't risk hiding something
        -- that might actually be visible.
        return false;
    end

    local screenX, screenY = ProjectWithZ(view, proj, viewport.Width, viewport.Height, wx, wy, wz);

    if (screenX == nil or screenY == nil) then
        -- ProjectWithZ returns nil specifically when the point is behind
        -- (or essentially at) the camera -- unambiguously not visible.
        return true;
    end

    local margin = worldMarkerProbe._offScreenCullMargin;

    return
        screenX < -margin or
        screenX > (tonumber(viewport.Width) + margin) or
        screenY < -margin or
        screenY > (tonumber(viewport.Height) + margin);
end

-- ============================================================
-- Quick Menu without a visible plate
-- ============================================================
-- The Quick Menu previously only opened for entities that currently
-- have a LibraPlates click-rect -- which only exist for plates that are
-- actually visible (not off-screen-culled, not trimmed by a max-plates
-- cap, not a disabled type). Right-clicking a character whose nameplate
-- isn't showing did nothing, even though the character itself is
-- clearly visible on screen.
--
-- ATTEMPT 1 (removed): scanned nearby entities and matched whichever one
-- projected closest to the click position on screen. This didn't work --
-- confirmed by live testing showing errors of 500-1800+ pixels even for
-- a click immediately next to the intended target. The coordinate
-- conversion itself was correct (verified against this file's own
-- pre-existing, proven usage of the same conversion), but the
-- UNDERLYING POSITION DATA (GetObjectEntityAnchor, backed by
-- GetLocalPositionX/Y/Z) isn't precise enough for pixel-level screen
-- matching -- everywhere else in this file, it's only ever used for
-- coarse plausibility checks (an 8-16 YALM tolerance, not a pixel
-- tolerance) or as a last-resort fallback when the precise method
-- (getBone/GetExactNameplateAnchor) fails. That precise method isn't
-- reachable from a mouse-click handler at all -- it's only available
-- during the normal per-frame render loop.
--
-- ATTEMPT 2 (current): sidesteps position math entirely. If you
-- currently have a target selected -- via native click, tab-target, or
-- however you normally target, all of which already work regardless of
-- LibraPlates nameplate visibility -- open the Quick Menu for that
-- target instead of trying to figure out what's under the cursor. Only
-- called as a fallback when the normal click-rect lookup finds nothing,
-- and only ever wired into right-click handling (see HandleMouse) --
-- left-click targeting is untouched by this entirely.
worldMarkerProbe._BuildEntryForCurrentTarget = function(entityManager)
    if (entityManager == nil) then
        return nil;
    end

    local targetIndex = targeting.GetCurrentTargetIndex();
    targetIndex = tonumber(targetIndex);

    if (targetIndex == nil or targetIndex == 0) then
        return nil;
    end

    local okName, name = pcall(function()
        return entityManager:GetName(targetIndex);
    end);
    name = (okName == true and name ~= nil) and name or '';

    -- Self: party slot 0 is always your own character.
    local okSelf, selfIndex = pcall(function()
        return AshitaCore:GetMemoryManager():GetParty():GetMemberTargetIndex(0);
    end);

    if (okSelf == true and tonumber(selfIndex) == targetIndex) then
        return { targetIndex = targetIndex, targetType = 'self', name = name };
    end

    -- Same classification rules used by the entity scan this replaces:
    -- SpawnFlags bit 0x10 = enemy/mob; player-index-range (1024-1791)
    -- with Type 0 or 2 = PC; Type 2 or 3 = object; otherwise NPC.
    local inPlayerRange = targetIndex >= 1024 and targetIndex <= 1791;

    local okFlags, spawnFlags = pcall(function()
        return entityManager:GetSpawnFlags(targetIndex);
    end);
    local isMob =
        okFlags == true and spawnFlags ~= nil and
        bit.band(tonumber(spawnFlags) or 0, 0x10) ~= 0;

    if (isMob == true) then
        return { targetIndex = targetIndex, targetType = 'enemy', name = name };
    end

    local okType, entType = pcall(function()
        return entityManager:GetType(targetIndex);
    end);
    entType = (okType == true) and tonumber(entType) or nil;

    if (inPlayerRange == true and (entType == 0 or entType == 2)) then
        return { targetIndex = targetIndex, targetType = 'pc', name = name };
    end

    -- Trust: occupies one of your own party slots (1-5; slot 0 is self,
    -- already handled above) but isn't in the player index range --
    -- real player party members would be.
    if (inPlayerRange ~= true) then
        local okParty, party = pcall(function()
            return AshitaCore:GetMemoryManager():GetParty();
        end);

        if (okParty == true and party ~= nil) then
            for slot = 1, 5 do
                local okSlot, slotIndex = pcall(function()
                    return party:GetMemberTargetIndex(slot);
                end);

                if (okSlot == true and tonumber(slotIndex) == targetIndex) then
                    return { targetIndex = targetIndex, targetType = 'trust', name = name };
                end
            end
        end
    end

    if (entType == 2 or entType == 3) then
        return { targetIndex = targetIndex, targetType = 'object', name = name };
    end

    return { targetIndex = targetIndex, targetType = 'npc', name = name };
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

function worldMarkerProbe.SetDrawSuppressed(value)
    drawSuppressed = value == true;
end

function worldMarkerProbe.GetDrawSuppressed()
    return drawSuppressed == true;
end

function worldMarkerProbe.SetAtlasDrawSuppressed(value)
    worldMarkerProbe._atlasDrawSuppressed = value == true;
end

function worldMarkerProbe.GetAtlasDrawSuppressed()
    return worldMarkerProbe._atlasDrawSuppressed == true;
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

    local view, proj, viewport = worldMarkerProbe._GetProjectionState(device);

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

-- Safe exact-anchor capture for actors whose skeleton pointer is unavailable or
-- unsafe to inspect.  This intentionally uses only the same actor/object reads
-- and native nameplate helper that the normal exact-anchor render path uses.
function worldMarkerProbe.GetSafeAnchorDebug(targetIndex, getEntityManager)
    targetIndex = tonumber(targetIndex);

    if (targetIndex == nil or targetIndex == 0 or getEntityManager == nil) then
        return nil, 'missing-args';
    end

    local entityManager = getEntityManager();

    if (entityManager == nil) then
        return nil, 'missing-entity-manager';
    end

    local actorPointer = nil;
    local actorOk = pcall(function()
        actorPointer = entityManager:GetActorPointer(targetIndex);
    end);

    if (actorOk ~= true or actorPointer == nil or actorPointer == 0) then
        return nil, 'missing-actor';
    end

    local function safeNumber(fn)
        local ok, value = pcall(fn);

        if (ok ~= true) then
            return nil;
        end

        return tonumber(value);
    end

    local baseX = safeNumber(function() return ashita.memory.read_float(actorPointer + 0x678); end);
    local baseY = safeNumber(function() return ashita.memory.read_float(actorPointer + 0x680); end);
    local baseZ = safeNumber(function() return ashita.memory.read_float(actorPointer + 0x67C); end);
    local objectPointer = safeNumber(function()
        return ashita.memory.read_uint32(actorPointer + 0x674 + 0x44);
    end);

    if (
        baseX == nil or baseY == nil or baseZ == nil or
        objectPointer == nil or objectPointer == 0
    ) then
        return nil, 'missing-anchor-data';
    end

    local helper = FindNameplateHelper();

    if (helper == nil or helper == 0) then
        return nil, 'missing-helper';
    end

    if (worldMarkerProbe._helperFunction == nil) then
        worldMarkerProbe._helperFunction = ffi.cast('lp_get_nameplate_offset_f', helper);
    end

    local offset = worldMarkerProbe._exactAnchorOffset;
    offset.x = 0;
    offset.y = 0;
    offset.z = 0;

    local helperOk, helperError = pcall(function()
        worldMarkerProbe._helperFunction(
            ffi.cast('void*', objectPointer),
            NormalizeAnchorBone(anchorBone),
            offset
        );
    end);

    if (helperOk ~= true) then
        return nil, 'helper-failed:' .. tostring(helperError);
    end

    local offsetX = tonumber(offset.x);
    local offsetY = tonumber(offset.y);
    local offsetZ = tonumber(offset.z);
    local heading = safeNumber(function() return entityManager:GetHeading(targetIndex); end);
    local rotatedX = nil;
    local rotatedY = nil;
    local rotatedInverseX = nil;
    local rotatedInverseY = nil;

    if (heading ~= nil) then
        local cosHeading = math.cos(heading);
        local sinHeading = math.sin(heading);
        rotatedX = baseX + (offsetX * cosHeading) - (offsetZ * sinHeading);
        rotatedY = baseY + (offsetX * sinHeading) + (offsetZ * cosHeading);
        rotatedInverseX = baseX + (offsetX * cosHeading) + (offsetZ * sinHeading);
        rotatedInverseY = baseY - (offsetX * sinHeading) + (offsetZ * cosHeading);
    end

    return {
        targetIndex = targetIndex,
        baseX = baseX,
        baseY = baseY,
        baseZ = baseZ,
        offsetX = offsetX,
        offsetY = offsetY,
        offsetZ = offsetZ,
        exactX = baseX + offsetX,
        exactY = baseY + offsetZ,
        exactZ = baseZ + offsetY,
        heading = heading,
        rotatedX = rotatedX,
        rotatedY = rotatedY,
        rotatedInverseX = rotatedInverseX,
        rotatedInverseY = rotatedInverseY,
        entityX = safeNumber(function() return entityManager:GetLocalPositionX(targetIndex); end),
        entityY = safeNumber(function() return entityManager:GetLocalPositionY(targetIndex); end),
        entityZ = safeNumber(function() return entityManager:GetLocalPositionZ(targetIndex); end),
        lastX = safeNumber(function() return entityManager:GetLastPositionX(targetIndex); end),
        lastY = safeNumber(function() return entityManager:GetLastPositionY(targetIndex); end),
        lastZ = safeNumber(function() return entityManager:GetLastPositionZ(targetIndex); end),
        entityType = safeNumber(function() return entityManager:GetType(targetIndex); end),
        spawnFlags = safeNumber(function() return entityManager:GetSpawnFlags(targetIndex); end),
        renderFlags0 = safeNumber(function() return entityManager:GetRenderFlags0(targetIndex); end),
        renderFlags1 = safeNumber(function() return entityManager:GetRenderFlags1(targetIndex); end),
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
    local view, proj, viewport = worldMarkerProbe._GetProjectionState(device);

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
        actorBytes = ReadByteList(actorPointer, BuildOffsetRange(0x00, 0xC0, 1)),
        actorExtendedBytes = ReadByteList(actorPointer, BuildOffsetRange(0x660, 0x6D0, 1)),
        objectPointer = objectPointer,
        objectScalars = ReadFloatList(objectPointer, { 0x10, 0x14, 0x18, 0x20, 0x24, 0x28, 0x30, 0x34, 0x38, 0x40, 0x44, 0x48, 0x50, 0x54, 0x58, 0x60, 0x64, 0x68 }),
        objectInts = ReadIntList(objectPointer, { 0x00, 0x04, 0x08, 0x0C, 0x10, 0x20, 0x30, 0x40, 0x50 }),
        objectBytes = ReadByteList(objectPointer, BuildOffsetRange(0x00, 0xA0, 1)),
    };
end

function worldMarkerProbe.PrepareFontAtlas()
    EnsureFontAtlas();
end

function worldMarkerProbe.QueuePlate(plate)
    if (enabled ~= true or plate == nil or plate.targetIndex == nil) then
        return;
    end

    if (queuedPlateSet[plate.targetIndex] == true) then
        return;
    end

    queuedPlateSet[plate.targetIndex] = true;
    -- Plate modules already create a frame-owned queue record. Keep that
    -- record instead of cloning it into another table for every visible
    -- entity on every frame. Large battles previously created two queue
    -- tables per plate and forced multi-megabyte garbage collections.
    plate.hp = plate.hp or 100;
    plate.tp = plate.vitals ~= nil and plate.vitals.tp or plate.petTp;
    plate.name = plate.name or '';
    plate.jobText = plate.jobText or '';
    plate.isSelf = plate.isSelf == true;
    plate.isProtectedPlate = plate.isProtectedPlate == true;
    plate.isPartyPlayer = plate.isPartyPlayer == true;
    plate._plateScreenOffsetX = tonumber(plate.screenOffsetX) or 0;
    plate._plateScreenOffsetY = tonumber(plate.screenOffsetY) or 0;
    plate.clickTargetType = plate.clickTargetType or (plate.isSelf == true and 'self' or 'enemy');
    queuedPlates[#queuedPlates + 1] = plate;

    if (plate.isSelf == true) then
        lastSelfJobText = tostring(plate.jobText or '');
        lastSelfJobEnabled = plate.worldMarker ~= nil and plate.worldMarker.jobEnabled == true;
        lastSelfJobMode = tonumber(plate.worldMarker ~= nil and plate.worldMarker.jobDisplayModeIndex) or 0;
    end

    lastQueuedCount = #queuedPlates;
end

function worldMarkerProbe.GetQueuedPlateCount()
    return #queuedPlates;
end

function worldMarkerProbe.QueueStaticPlate(plate)
    if (enabled ~= true or plate == nil or plate.textureId == nil) then
        return;
    end

    queuedStaticPlates[#queuedStaticPlates + 1] = {
        textureId = plate.textureId,
        x = tonumber(plate.x) or 0,
        y = tonumber(plate.y) or 0,
        width = tonumber(plate.width) or 1,
        height = tonumber(plate.height) or 1,
    };
end

function worldMarkerProbe.ResetPass()
    pass = 0;
    queuedPlates = {};
    queuedStaticPlates = {};
    queuedPlateSet = {};
end

function worldMarkerProbe.Shutdown()
    enabled = false;
    worldMarkerProbe.ResetPass();
    selfClickRect = nil;
    selfClickRects = nil;
    clickRects = {};
    pendingClickRects = {};
    pendingSelfClickRect = nil;
    pendingSelfClickRects = nil;
    rightDownPlate = nil;
    suppressNextLeftRelease = false;
    fontAtlasTexture = nil;
    fontBaked = nil;
    fontStatus = 'not-ready';
    helperPointer = nil;
    helperStatus = 'not-searched';
    worldMarkerProbe._stackScreenOffsetState = {};
    worldMarkerProbe._lastStackSmoothingClock = nil;
    worldMarkerProbe._lastClickPlates = {};
    worldMarkerProbe._lastClickGetEntityManager = nil;
    worldMarkerProbe._lastClickGetBone = nil;
    worldMarkerProbe._pendingStackRects = {};
    worldMarkerProbe._deferredLiveResourceBars = {};
    worldMarkerProbe._projectionCache = nil;
    worldMarkerProbe._idleNpcAnchor.cache = {};
    lastQueuedCount = 0;
    lastDrawCount = 0;
    lastError = nil;
    if (worldMarkerProbe._plateBatch ~= nil and worldMarkerProbe._plateBatch.Shutdown ~= nil) then
        worldMarkerProbe._plateBatch.Shutdown();
    end
end

local function GetStackType(plate)
    local targetType = tostring(plate ~= nil and plate.clickTargetType or ''):lower();

    if (
        targetType == 'pc' or
        targetType == 'enemy' or
        targetType == 'trust' or
        targetType == 'pet' or
        targetType == 'npc' or
        targetType == 'object'
    ) then
        return targetType;
    end

    return nil;
end

local function GetStackPriority(settings, stackType)
    local priority = settings ~= nil and settings.plateStackingPriority or nil;

    if (type(priority) == 'table') then
        for index, key in ipairs(priority) do
            if (tostring(key or ''):lower() == stackType) then
                return index;
            end
        end
    end

    if (stackType == 'pc') then return 1; end
    if (stackType == 'enemy') then return 2; end
    if (stackType == 'trust') then return 3; end
    if (stackType == 'pet') then return 4; end
    if (stackType == 'npc') then return 5; end
    if (stackType == 'object') then return 6; end

    return 99;
end

local function IsFixedStackAnchor(plate, targetIndex, subTargetIndex)
    local index = tonumber(plate ~= nil and plate.targetIndex) or 0;
    local marker = plate ~= nil and plate.worldMarker ~= nil and plate.worldMarker.targetMarker or nil;

    if (plate ~= nil and plate.isSelf == true) then
        return true;
    end

    if (index ~= 0 and (index == tonumber(targetIndex) or index == tonumber(subTargetIndex))) then
        return true;
    end

    return marker ~= nil and marker.enabled == true;
end

local function StackRectsOverlap(left, right, horizontalAllowance, verticalAllowance)
    return
        math.min(left.drawX + left.width, right.drawX + right.width) - math.max(left.drawX, right.drawX) > horizontalAllowance and
        math.min(left.drawY + left.height, right.drawY + right.height) - math.max(left.drawY, right.drawY) > verticalAllowance;
end

local stackIgnoredRectKinds = {
    background = true,
    targetModuleBackground = true,
};

worldMarkerProbe._stackPrimaryRectKinds = {
    name = true,
    hp = true,
    mp = true,
    tp = true,
    cast = true,
    type = true,
    job = true,
    level = true,
    id = true,
    peerId = true,
    peerJob = true,
    petState = true,
    petTimer = true,
};

function worldMarkerProbe._NormalizeStackRect(rect)
    local x1 = tonumber(rect ~= nil and rect.x1);
    local y1 = tonumber(rect ~= nil and rect.y1);
    local x2 = tonumber(rect ~= nil and rect.x2);
    local y2 = tonumber(rect ~= nil and rect.y2);

    if (x1 == nil or y1 == nil or x2 == nil or y2 == nil or x2 <= x1 or y2 <= y1) then
        return nil;
    end

    return {
        x1 = x1,
        y1 = y1,
        x2 = x2,
        y2 = y2,
    };
end

function worldMarkerProbe._GetStackPrimaryRect(entry)
    local union = nil;

    for _, rect in ipairs(entry ~= nil and entry.rects or {}) do
        local kind = tostring(rect ~= nil and rect.kind or '');

        if (worldMarkerProbe._stackPrimaryRectKinds[kind] == true) then
            local normalized = worldMarkerProbe._NormalizeStackRect(rect);

            if (normalized ~= nil) then
                if (union == nil) then
                    union = normalized;
                else
                    union.x1 = math.min(union.x1, normalized.x1);
                    union.y1 = math.min(union.y1, normalized.y1);
                    union.x2 = math.max(union.x2, normalized.x2);
                    union.y2 = math.max(union.y2, normalized.y2);
                end
            end
        end
    end

    return union;
end

local function GetStackCollisionUnion(entry)
    local primaryRect = worldMarkerProbe._GetStackPrimaryRect(entry);

    if (primaryRect ~= nil) then
        return primaryRect;
    end

    local overlayRect = worldMarkerProbe._NormalizeStackRect(entry ~= nil and entry.plateOverlayRect or nil);

    if (overlayRect ~= nil) then
        return overlayRect;
    end

    local union = nil;

    for _, rect in ipairs(entry ~= nil and entry.rects or {}) do
        local kind = tostring(rect ~= nil and rect.kind or '');

        if (stackIgnoredRectKinds[kind] ~= true) then
            local normalized = worldMarkerProbe._NormalizeStackRect(rect);

            if (normalized ~= nil) then
                if (union == nil) then
                    union = normalized;
                else
                    union.x1 = math.min(union.x1, normalized.x1);
                    union.y1 = math.min(union.y1, normalized.y1);
                    union.x2 = math.max(union.x2, normalized.x2);
                    union.y2 = math.max(union.y2, normalized.y2);
                end
            end
        end
    end

    return union;
end

function worldMarkerProbe._FindNearestFreeStackAxis(base, intervals, maxDistance, negativeOnly)
    if (#(intervals or {}) == 0) then
        return base, 0;
    end

    table.sort(intervals, function(left, right)
        return left.first < right.first;
    end);

    local merged = {};
    for _, interval in ipairs(intervals) do
        local current = merged[#merged];

        if (current == nil or interval.first > current.last) then
            merged[#merged + 1] = {
                first = interval.first,
                last = interval.last,
            };
        else
            current.last = math.max(current.last, interval.last);
        end
    end

    for _, interval in ipairs(merged) do
        if (base > interval.first and base < interval.last) then
            local candidate = interval.first;

            if (negativeOnly ~= true and math.abs(interval.last - base) < math.abs(candidate - base)) then
                candidate = interval.last;
            end

            local score = math.abs(candidate - base);
            if (maxDistance ~= nil and score > maxDistance) then
                return nil, nil;
            end

            return candidate, score;
        end
    end

    return base, 0;
end

local function FindBestHorizontalStackX(entry, placed, gap, horizontalAllowance, verticalAllowance, maxSpread)
    local intervals = {};
    for _, other in ipairs(placed) do
        local verticalOverlap =
            math.min(entry.drawY + entry.height, other.drawY + other.height) -
            math.max(entry.drawY, other.drawY);

        if (verticalOverlap > verticalAllowance) then
            intervals[#intervals + 1] = {
                first = other.drawX - entry.width - gap + horizontalAllowance,
                last = other.drawX + other.width + gap - horizontalAllowance,
            };
        end
    end

    return worldMarkerProbe._FindNearestFreeStackAxis(entry.baseX, intervals, maxSpread, false);
end

function worldMarkerProbe._FindBestVerticalStackY(entry, placed, gap, horizontalAllowance, verticalAllowance)
    local intervals = {};
    for _, other in ipairs(placed) do
        local horizontalOverlap =
            math.min(entry.baseX + entry.width, other.drawX + other.width) -
            math.max(entry.baseX, other.drawX);

        if (horizontalOverlap > horizontalAllowance) then
            intervals[#intervals + 1] = {
                first = other.drawY - entry.height - gap + verticalAllowance,
                last = other.drawY + other.height + gap - verticalAllowance,
            };
        end
    end

    return worldMarkerProbe._FindNearestFreeStackAxis(
        entry.baseY,
        intervals,
        nil,
        entry.stackType ~= 'enemy'
    );
end

local function ShiftStackRect(rect, dx, dy)
    if (rect == nil) then
        return;
    end

    rect.x1 = (tonumber(rect.x1) or 0) + dx;
    rect.x2 = (tonumber(rect.x2) or 0) + dx;
    rect.y1 = (tonumber(rect.y1) or 0) + dy;
    rect.y2 = (tonumber(rect.y2) or 0) + dy;
end

local function ShiftStackClickEntry(entry, dx, dy)
    if (entry == nil or (dx == 0 and dy == 0)) then
        return;
    end

    ShiftStackRect(entry.union, dx, dy);
    ShiftStackRect(entry.plateOverlayRect, dx, dy);

    for _, rect in ipairs(entry.rects or {}) do
        ShiftStackRect(rect, dx, dy);
    end
end

local function ApplySubtargetTargetSeparation(stackEntries, targetIndex, subTargetIndex, gap, liftOffset, horizontalAllowance, verticalAllowance)
    local targetEntry = nil;
    local subTargetEntry = nil;
    local targetId = tonumber(targetIndex) or 0;
    local subTargetId = tonumber(subTargetIndex) or 0;

    if (targetId == 0 or subTargetId == 0 or targetId == subTargetId) then
        return;
    end

    for _, entry in ipairs(stackEntries or {}) do
        local index = tonumber(entry ~= nil and entry.plate ~= nil and entry.plate.targetIndex) or 0;

        if (index == targetId) then
            targetEntry = entry;
        elseif (index == subTargetId) then
            subTargetEntry = entry;
        end
    end

    if (targetEntry == nil or subTargetEntry == nil) then
        return;
    end

    if (StackRectsOverlap(subTargetEntry, targetEntry, horizontalAllowance, verticalAllowance) ~= true) then
        return;
    end

    local overlapY =
        math.min(subTargetEntry.drawY + subTargetEntry.height, targetEntry.drawY + targetEntry.height) -
        math.max(subTargetEntry.drawY, targetEntry.drawY);

    if (overlapY <= verticalAllowance) then
        return;
    end

    subTargetEntry.drawY = subTargetEntry.drawY - overlapY - gap - liftOffset;
end

local function GetImguiDisplaySize()
    if (imguiApi == nil or imguiApi.GetIO == nil) then
        return nil, nil;
    end

    local ok, io = pcall(function()
        return imguiApi.GetIO();
    end);

    if (ok ~= true or io == nil or io.DisplaySize == nil) then
        return nil, nil;
    end

    return
        tonumber(io.DisplaySize.x or io.DisplaySize.X or io.DisplaySize[1]),
        tonumber(io.DisplaySize.y or io.DisplaySize.Y or io.DisplaySize[2]);
end

local function GetScreenClampPadding(settings)
    return {
        top = math.max(0, tonumber(settings ~= nil and settings.tacticalScreenClampTopPadding) or 24),
        bottom = math.max(0, tonumber(settings ~= nil and settings.tacticalScreenClampBottomPadding) or 24),
        left = math.max(0, tonumber(settings ~= nil and settings.tacticalScreenClampLeftPadding) or 0),
        right = math.max(0, tonumber(settings ~= nil and settings.tacticalScreenClampRightPadding) or 0),
    };
end

function worldMarkerProbe._GetStackScreenOffsetKey(plate)
    local index = tonumber(plate ~= nil and plate.targetIndex) or 0;

    if (index == 0) then
        return nil;
    end

    return tostring(index) .. ':' .. tostring(plate.clickTargetType or '');
end

function worldMarkerProbe._GetStackSmoothingDelta()
    local now = os.clock();
    local dt = 1 / 60;

    if (worldMarkerProbe._lastStackSmoothingClock ~= nil) then
        dt = now - worldMarkerProbe._lastStackSmoothingClock;

        if (dt < (1 / 240) or dt > (1 / 15)) then
            dt = 1 / 60;
        end
    end

    worldMarkerProbe._lastStackSmoothingClock = now;
    return dt;
end

function worldMarkerProbe._SmoothStackOffsetValue(current, target, dt, speed)
    local diff = target - current;
    local distance = math.abs(diff);
    local travelSpeed = math.max(1.0, math.min(40.0, tonumber(speed) or 14.0));

    if (distance <= 0.35) then
        return target;
    end

    local ease = 1.0 - math.exp(-math.max(0.0, dt) * travelSpeed);
    local nextValue = current + (diff * ease);
    local maxStep = math.max(1.0, (travelSpeed * 52.0) * math.max(0.0, dt));
    local moved = nextValue - current;

    if (math.abs(moved) > maxStep) then
        nextValue = current + ((moved < 0) and -maxStep or maxStep);
    end

    if (math.abs(target - nextValue) <= 0.35) then
        return target;
    end

    return nextValue;
end

function worldMarkerProbe._ApplySmoothedStackOffset(plate, targetX, targetY, dt, activeKeys, speed)
    local key = worldMarkerProbe._GetStackScreenOffsetKey(plate);

    if (key == nil) then
        plate._stackScreenOffsetX = targetX;
        plate._stackScreenOffsetY = targetY;
        return targetX, targetY;
    end

    activeKeys[key] = true;

    local state = worldMarkerProbe._stackScreenOffsetState[key];
    if (state == nil) then
        state = { x = 0, y = 0 };
        worldMarkerProbe._stackScreenOffsetState[key] = state;
    end

    state.x = worldMarkerProbe._SmoothStackOffsetValue(tonumber(state.x) or 0, tonumber(targetX) or 0, dt, speed);
    state.y = worldMarkerProbe._SmoothStackOffsetValue(tonumber(state.y) or 0, tonumber(targetY) or 0, dt, speed);

    plate._stackScreenOffsetX = state.x;
    plate._stackScreenOffsetY = state.y;

    return state.x, state.y;
end

local function ApplyScreenPlateStacking(drawablePlates)
    local settings = targeting.GetSettings();
    local dt = worldMarkerProbe._GetStackSmoothingDelta();
    local activeStackKeys = {};
    local travelSpeed = math.max(1, math.min(40, tonumber(settings.plateStackTravelSpeed) or 14));

    for _, plate in ipairs(drawablePlates or {}) do
        plate._stackScreenOffsetX = 0;
        plate._stackScreenOffsetY = 0;
    end

    if (settings.plateStackingEnabled ~= true or #worldMarkerProbe._pendingStackRects <= 1) then
        if (settings.plateStackingEnabled ~= true) then
            worldMarkerProbe._stackScreenOffsetState = {};
        end

        return;
    end

    local entriesByIndex = {};
    for _, entry in ipairs(worldMarkerProbe._pendingStackRects) do
        local targetIndex = tonumber(entry.targetIndex);
        local union = GetStackCollisionUnion(entry);

        if (
            targetIndex ~= nil and
            union ~= nil and
            tonumber(union.x1) ~= nil and
            tonumber(union.y1) ~= nil and
            tonumber(union.x2) ~= nil and
            tonumber(union.y2) ~= nil and
            tonumber(union.x2) > tonumber(union.x1) and
            tonumber(union.y2) > tonumber(union.y1)
        ) then
            entriesByIndex[targetIndex] = {
                clickEntry = entry,
                stackUnion = union,
            };
        end
    end

    local targetIndex, subTargetIndex = targeting.GetCurrentTargetAndSubTargetIndexes();
    local stackTypes = type(settings.plateStackingTypes) == 'table' and settings.plateStackingTypes or {};
    local stackPadding = math.max(0, math.min(20, math.floor((tonumber(settings.plateStackGap) or 10) + 0.5))) - 10;
    local horizontalAllowance = math.max(0, math.min(80, math.floor((tonumber(settings.plateStackHorizontalOverlap) or 0) + 0.5)));
    local verticalAllowance = math.max(0, math.min(80, math.floor((tonumber(settings.plateStackVerticalOverlap) or 0) + 0.5)));
    local gap = 0;
    local stackEntries = {};

    for order, plate in ipairs(drawablePlates or {}) do
        local stackType = GetStackType(plate);
        local stackInfo = entriesByIndex[tonumber(plate.targetIndex) or 0];
        local entry = stackInfo ~= nil and stackInfo.clickEntry or nil;
        local isFixed = IsFixedStackAnchor(plate, targetIndex, subTargetIndex);

        if (
            stackType ~= nil and
            entry ~= nil and
            stackInfo.stackUnion ~= nil and
            (isFixed == true or stackTypes[stackType] == true)
        ) then
            local union = stackInfo.stackUnion;
            local x1 = (tonumber(union.x1) or 0) - stackPadding;
            local y1 = (tonumber(union.y1) or 0) - stackPadding;
            local x2 = (tonumber(union.x2) or 0) + stackPadding;
            local y2 = (tonumber(union.y2) or 0) + stackPadding;

            if (x2 <= x1) then
                local centerX = ((tonumber(union.x1) or 0) + (tonumber(union.x2) or 0)) * 0.5;
                x1 = centerX - 2;
                x2 = centerX + 2;
            end

            if (y2 <= y1) then
                local centerY = ((tonumber(union.y1) or 0) + (tonumber(union.y2) or 0)) * 0.5;
                y1 = centerY - 2;
                y2 = centerY + 2;
            end

            local stackX1 = x1;
            local stackX2 = x2;

            stackEntries[#stackEntries + 1] = {
                plate = plate,
                clickEntry = entry,
                stackType = stackType,
                priority = GetStackPriority(settings, stackType),
                order = order,
                fixed = isFixed,
                distance = tonumber(plate.distance) or 9999,
                x1 = stackX1,
                x2 = stackX2,
                baseX = stackX1,
                drawX = stackX1,
                baseY = y1,
                drawY = y1,
                width = stackX2 - stackX1,
                height = y2 - y1,
            };
        end
    end

    if (#stackEntries <= 1) then
        for _, entry in ipairs(stackEntries) do
            local offsetX, offsetY = worldMarkerProbe._ApplySmoothedStackOffset(entry.plate, 0, 0, dt, activeStackKeys, travelSpeed);
            ShiftStackClickEntry(entry.clickEntry, offsetX, offsetY);
        end

        for key in pairs(worldMarkerProbe._stackScreenOffsetState) do
            if (activeStackKeys[key] ~= true) then
                worldMarkerProbe._stackScreenOffsetState[key] = nil;
            end
        end

        return;
    end

    ApplySubtargetTargetSeparation(stackEntries, targetIndex, subTargetIndex, gap, 0, horizontalAllowance, verticalAllowance);

    table.sort(stackEntries, function(left, right)
        if (left.fixed ~= right.fixed) then
            return left.fixed == true;
        end

        if (left.priority ~= right.priority) then
            return left.priority < right.priority;
        end

        if (settings.plateStackClosestOnTop == true and left.distance ~= right.distance) then
            return left.distance < right.distance;
        end

        if (left.baseY ~= right.baseY) then
            return left.baseY > right.baseY;
        end

        return left.order < right.order;
    end);

    local placed = {};
    for _, entry in ipairs(stackEntries) do
        if (entry.fixed ~= true) then
            local changed = true;
            local guard = 0;

            while (changed == true and guard < 30) do
                changed = false;
                guard = guard + 1;

                for _, other in ipairs(placed) do
                    if (StackRectsOverlap(entry, other, horizontalAllowance, verticalAllowance) == true) then
                        if (entry.stackType ~= 'enemy') then
                            local maxSpread = 100000;

                            local nextX, nextXScore = FindBestHorizontalStackX(entry, placed, gap, horizontalAllowance, verticalAllowance, maxSpread);
                            local nextY, nextYScore = worldMarkerProbe._FindBestVerticalStackY(entry, placed, gap, horizontalAllowance, verticalAllowance);

                            if (nextX ~= nil and (nextY == nil or nextXScore <= nextYScore)) then
                                entry.drawX = nextX;
                                changed = true;
                                break;
                            end

                            if (nextY ~= nil) then
                                entry.drawX = entry.baseX;
                                entry.drawY = nextY;
                                changed = true;
                                break;
                            end
                        end

                        local nextY = other.drawY - entry.height - gap;

                        if (
                            nextY < entry.drawY
                        ) then
                            entry.drawX = entry.baseX;
                            entry.drawY = nextY;
                            changed = true;
                        end
                    end
                end
            end
        end

        local targetOffsetX = entry.drawX - entry.baseX;
        local targetOffsetY = entry.drawY - entry.baseY;
        local offsetX, offsetY = worldMarkerProbe._ApplySmoothedStackOffset(entry.plate, targetOffsetX, targetOffsetY, dt, activeStackKeys, travelSpeed);
        ShiftStackClickEntry(entry.clickEntry, offsetX, offsetY);
        placed[#placed + 1] = entry;
    end

    for key in pairs(worldMarkerProbe._stackScreenOffsetState) do
        if (activeStackKeys[key] ~= true) then
            worldMarkerProbe._stackScreenOffsetState[key] = nil;
        end
    end
end

local function NeedsDetailedFrameClickRects(plate, style)
    -- On-demand clicks build precise widget hitboxes only at click time.
    -- Retain live detailed rects where another live feature needs them:
    -- self, party, protected target/subtarget, non-PC plates, and mouse snap.
    if (worldMarkerProbe._collectFrameClickRects == true) then
        return true;
    end

    if (plate ~= nil and (plate.isSelf == true or plate.isProtectedPlate == true or plate.isPartyPlayer == true)) then
        return true;
    end

    if (style ~= nil and (style.protectedPlate == true or style.partyPlate == true or style.plateAlwaysOnTop == true)) then
        return true;
    end

    local targetType = tostring((style ~= nil and style.clickTargetType) or (plate ~= nil and plate.clickTargetType) or ''):lower();
    return targetType ~= 'pc';
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
    if (style.layoutStateName == nil) then
        style.layoutStateName = plate.layoutStateName or plate.stateName;
    end
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

    -- BeginScene performs a bounds/stacking pass followed by the actual draw
    -- pass.  Reuse the first anchor for ordinary actors.  Static objects are
    -- deliberately resolved again: FFXI can return a stale object offset on
    -- the first read until its render state has been refreshed.
    local isObjectPlate = tostring(plate.clickTargetType or ''):lower() == 'object';
    local resolvedAnchor =
        updateClickOnly ~= true and
        isObjectPlate ~= true and
        plate._resolvedAnchor or nil;
    local wx = nil;
    local wy = nil;
    local wz = nil;

    if (resolvedAnchor ~= nil and resolvedAnchor.actorPointer == actorPointer) then
        wx = resolvedAnchor.x;
        wy = resolvedAnchor.y;
        wz = resolvedAnchor.z;
        if (perfMeter ~= nil and perfMeter.Count ~= nil) then
            perfMeter.Count('world.anchor.reuse', 1);
        end
    else
        if (worldMarkerProbe._idleNpcAnchor.IsEligible(plate, isObjectPlate) == true) then
            wx, wy, wz = worldMarkerProbe._idleNpcAnchor.Resolve(targetIndex, actorPointer, getBone, style);
        else
            wx, wy, wz = GetAnchor(actorPointer, getBone, style);

            if (perfMeter ~= nil and perfMeter.Count ~= nil) then
                perfMeter.Count('world.anchor.resolve', 1);
            end
        end

        if (
            updateClickOnly == true and
            isObjectPlate ~= true and
            wx ~= nil and wy ~= nil and wz ~= nil
        ) then
            plate._resolvedAnchor = {
                actorPointer = actorPointer,
                x = wx,
                y = wy,
                z = wz,
            };
        end
    end

    if (wx == nil or wy == nil or wz == nil) then
        return;
    end

    if (isObjectPlate == true) then
        local entityX, entityY, entityZ = GetObjectEntityAnchor(entityManager, targetIndex);

        if (
            entityX ~= nil and entityY ~= nil and entityZ ~= nil and
            worldMarkerProbe._IsPlausibleObjectAnchor(plate, wx, wy, wz, entityX, entityY, entityZ) ~= true
        ) then
            -- The exact helper can briefly return an offset belonging to a
            -- different static object.  Prefer a plausible raw bone anchor;
            -- otherwise use the object's own stable entity position.
            local boneX, boneY, boneZ = getBone(actorPointer, plateAnchorBone);

            if (worldMarkerProbe._IsPlausibleObjectAnchor(plate, boneX, boneY, boneZ, entityX, entityY, entityZ) == true) then
                wx = boneX;
                wy = boneY;
                wz = boneZ;
            else
                wx = entityX;
                wy = entityY;
                wz = entityZ;
            end

            if (perfMeter ~= nil and perfMeter.Count ~= nil) then
                perfMeter.Count('world.anchor.objectImplausibleFallback', 1);
            end
        end
    end

    -- FFXI actor memory uses x/y/z; D3D world uses x/z/y.
    if (style.plateTextureId ~= nil) then
        local plateScale = GetPlateDistanceScale(style, targetIndex, plate.distance or style.distance);
        local plateWorldOffsetX = tonumber(style.plateWorldOffsetX) or 0;
        local plateWorldOffsetY = tonumber(style.plateWorldOffsetY) or tonumber(style.nameWorldOffsetY) or 0.78;
        if (style.pcBodyPlateOffsetEnabled == true) then
            local bodyOffset = GetPcBodyPlateOffset(actorPointer, targetIndex, entityManager);
            plateWorldOffsetY = plateWorldOffsetY + bodyOffset;
        end
        local plateWorldOffsetZ = tonumber(style.plateWorldOffsetZ) or 0;
        local plateX = wx + plateWorldOffsetX;
        local plateY = wz + verticalOffset + plateWorldOffsetY - nameVerticalOffset;
        local plateZ = wy + plateWorldOffsetZ;
        local plateWorldWidth = (tonumber(style.plateWorldWidth) or 0.84) * plateScale;
        local plateWorldHeight = (tonumber(style.plateWorldHeight) or 0.315) * plateScale;
        plateX, plateY, plateZ = worldMarkerProbe._ApplyCanvasCropWorldOffset(device, style.plateTextureId, plateX, plateY, plateZ, plateWorldWidth, plateWorldHeight);
        if (worldMarkerProbe._IsObjectWorldPointInFrontOfCamera(device, plate, plateX, plateY, plateZ) ~= true) then
            -- Some static door actors return a valid exact nameplate anchor
            -- for one frame and then a behind-camera offset while remaining
            -- targeted.  Fall back to the entity's stable world position.
            local fallbackX, fallbackY, fallbackZ = GetObjectEntityAnchor(entityManager, targetIndex);
            local fallbackApplied = false;

            if (fallbackX ~= nil and fallbackY ~= nil and fallbackZ ~= nil) then
                local nextPlateX = fallbackX + plateWorldOffsetX;
                local nextPlateY = fallbackZ + verticalOffset + plateWorldOffsetY - nameVerticalOffset;
                local nextPlateZ = fallbackY + plateWorldOffsetZ;
                nextPlateX, nextPlateY, nextPlateZ = worldMarkerProbe._ApplyCanvasCropWorldOffset(
                    device,
                    style.plateTextureId,
                    nextPlateX,
                    nextPlateY,
                    nextPlateZ,
                    plateWorldWidth,
                    plateWorldHeight
                );

                if (worldMarkerProbe._IsObjectWorldPointInFrontOfCamera(device, plate, nextPlateX, nextPlateY, nextPlateZ) == true) then
                    plateX = nextPlateX;
                    plateY = nextPlateY;
                    plateZ = nextPlateZ;
                    fallbackApplied = true;

                    if (perfMeter ~= nil and perfMeter.Count ~= nil) then
                        perfMeter.Count('world.anchor.objectEntityFallback', 1);
                    end
                end
            end

            if (fallbackApplied ~= true) then
                if (perfMeter ~= nil and perfMeter.Count ~= nil) then
                    perfMeter.Count('world.anchor.objectBehindCamera', 1);
                end
                return;
            end
        end

        do
            local marker = style.targetMarker;
            local isTacticalPlate =
                tostring(plate.stateName or '') ~= 'Idle' or
                (marker ~= nil and marker.enabled == true);

            if (isTacticalPlate == true and targeting.GetSettings().tacticalScreenClampEnabled == true) then
    local view, proj, viewport = worldMarkerProbe._GetProjectionState(device);

                if (view ~= nil and proj ~= nil and viewport ~= nil and viewport.Width ~= nil and viewport.Height ~= nil) then
                    local rx, ry, rz, ux, uy, uz = GetBillboardVectors(device);
                    local left = nil;
                    local top = nil;
                    local right = nil;
                    local bottom = nil;
                    local points = {
                        { plateWorldWidth * -0.5, plateWorldHeight * -0.5 },
                        { plateWorldWidth * 0.5, plateWorldHeight * -0.5 },
                        { plateWorldWidth * 0.5, plateWorldHeight * 0.5 },
                        { plateWorldWidth * -0.5, plateWorldHeight * 0.5 },
                    };

                    for _, point in ipairs(points) do
                        local sx, sy = ProjectBillboardPoint(view, proj, viewport, plateX, plateY, plateZ, rx, ry, rz, ux, uy, uz, point[1], point[2]);

                        if (sx ~= nil and sy ~= nil) then
                            left = (left == nil) and sx or math.min(left, sx);
                            top = (top == nil) and sy or math.min(top, sy);
                            right = (right == nil) and sx or math.max(right, sx);
                            bottom = (bottom == nil) and sy or math.max(bottom, sy);
                        end
                    end

                    local padding = GetScreenClampPadding(settings);

                    if (left ~= nil and top ~= nil and right ~= nil and bottom ~= nil) then
                        local centerX, centerY = ProjectWithZ(view, proj, viewport.Width, viewport.Height, plateX, plateY, plateZ);
                        local rightX, rightY = ProjectWithZ(
                            view,
                            proj,
                            viewport.Width,
                            viewport.Height,
                            plateX + (rx * 0.10),
                            plateY + (ry * 0.10),
                            plateZ + (rz * 0.10)
                        );
                        local upX, upY = ProjectWithZ(
                            view,
                            proj,
                            viewport.Width,
                            viewport.Height,
                            plateX + (ux * 0.10),
                            plateY + (uy * 0.10),
                            plateZ + (uz * 0.10)
                        );

                        if (centerX ~= nil and centerY ~= nil) then
                            local desiredDx = 0;
                            local desiredDy = 0;
                            local maxRight = (tonumber(viewport.Width) or 0) - padding.right;
                            local maxBottom = (tonumber(viewport.Height) or 0) - padding.bottom;

                            if (left < padding.left) then
                                desiredDx = padding.left - left;
                            elseif (right > maxRight) then
                                desiredDx = maxRight - right;
                            end

                            if (desiredDx ~= 0) then
                                local screenMidX = (tonumber(viewport.Width) or 0) * 0.5;
                                local nextCenterX = centerX + desiredDx;

                                if (centerX < screenMidX and nextCenterX > screenMidX) then
                                    desiredDx = screenMidX - centerX;
                                elseif (centerX > screenMidX and nextCenterX < screenMidX) then
                                    desiredDx = screenMidX - centerX;
                                end
                            end

                            if (top < padding.top) then
                                desiredDy = padding.top - top;
                            elseif (bottom > maxBottom) then
                                desiredDy = maxBottom - bottom;
                            end

                            if (desiredDx ~= 0 and rightX ~= nil and rightY ~= nil and rightX ~= centerX) then
                                local amount = desiredDx / ((rightX - centerX) / 0.10);
                                plateX = plateX + (rx * amount);
                                plateY = plateY + (ry * amount);
                                plateZ = plateZ + (rz * amount);
                            end

                            if (desiredDy ~= 0 and upX ~= nil and upY ~= nil and upY ~= centerY) then
                                local amount = desiredDy / ((upY - centerY) / 0.10);
                                plateX = plateX + (ux * amount);
                                plateY = plateY + (uy * amount);
                                plateZ = plateZ + (uz * amount);
                            end
                        end
                    end
                end
            end
        end

        local _, savePlateZFunc = device:GetRenderState(D3DRS_ZFUNC);
        local stackMoved = worldMarkerProbe._HasStackScreenOffset(plate) == true;

        if (stackMoved == true) then
            plateX, plateY, plateZ = worldMarkerProbe._ApplyStackScreenOffset(device, plateX, plateY, plateZ, plate);
        end

        if (stackMoved ~= true and ShouldHideProjectedBelowViewportPlate(device, entityManager, style, plateX, plateY, plateZ) == true) then
            return;
        end

        if (stackMoved ~= true and style.plateTacticalOverlayOnly ~= true) then
            -- BUGFIX: previously exempted anything not literally in
            -- 'Idle' state, which is far broader than "things the player
            -- shouldn't lose track of" -- it also covered other people's
            -- targets, general combat states, etc., letting genuinely
            -- off-screen entities through uncounted. This now checks
            -- specifically whether the plate IS the player's own current
            -- target/subtarget (by index) or has an active tactical
            -- marker, which is a precise definition of "never hide this"
            -- rather than a broad state guess.
            local targetIndex, subTargetIndex = targeting.GetCurrentTargetAndSubTargetIndexes();
            local plateIndex = tonumber(plate.targetIndex);
            local isOwnTarget =
                plateIndex ~= nil and
                (plateIndex == tonumber(targetIndex) or plateIndex == tonumber(subTargetIndex));
            local hasActiveMarker = style.targetMarker ~= nil and style.targetMarker.enabled == true;

            if (
                isOwnTarget ~= true and
                hasActiveMarker ~= true and
                worldMarkerProbe._offScreenCullEnabled == true and
                worldMarkerProbe._IsClearlyOffScreen(device, plateX, plateY, plateZ) == true
            ) then
                if (perfMeter ~= nil and perfMeter.Count ~= nil) then
                    perfMeter.Count('world.cull.offScreen', 1);
                end
                return;
            end
        end

        if (perfMeter ~= nil and perfMeter.Count ~= nil) then
            -- Distinct from queued/drawn (which count "processed without
            -- crashing", including early-returns from culling above).
            -- This only increments once a plate has passed every
            -- visibility gate and is genuinely about to be drawn/queued,
            -- so it's the counter to actually watch when checking whether
            -- culling is doing anything.
            perfMeter.Count('world.draw.actuallyVisible', 1);
        end

        style.clickTargetType = plate.clickTargetType or style.clickTargetType or (plate.isSelf == true and 'self' or 'enemy');
        style.serverId = plate.serverId or style.serverId;
        style.distance = plate.distance or style.distance;
        style.modelHitboxSize = plate.modelHitboxSize or style.modelHitboxSize;
        if (plate.trustIsMine ~= nil) then
            style.trustIsMine = plate.trustIsMine == true;
        end

        if (updateClickOnly == true) then
            local hasCanvasClickRects = style.plateClickRects ~= nil;
            local detailedFrameRects = NeedsDetailedFrameClickRects(plate, style) == true;
            local boundsOnly = detailedFrameRects ~= true;
            local previousCollectFrameClickRects = worldMarkerProbe._collectFrameClickRects;

            -- Keep detailed rects available for active/special plates even
            -- while ordinary idle PCs use the lightweight bounds prepass.
            if (detailedFrameRects == true) then
                worldMarkerProbe._collectFrameClickRects = true;
            end

            if (SetSelfClickRectsFromCanvas(device, targetIndex, plateX, plateY, plateZ, style, plateWorldWidth, plateWorldHeight, boundsOnly) ~= true) then
                if (plate.isSelf == true and hasCanvasClickRects ~= true) then
                    SetSelfClickRectFromBillboard(device, targetIndex, plateX, plateY, plateZ, plateWorldWidth, plateWorldHeight);
                end
            end

            worldMarkerProbe._collectFrameClickRects = previousCollectFrameClickRects;

            return;
        end

        if (showCanvasCenter == true) then
            DrawCanvasDebugWithState(device, plateX, plateY, plateZ, plateWorldWidth, plateWorldHeight, 0.035);
        end

        if (ShouldHardHidePlateByNoGoZone(plate.targetIndex) == true) then
            device:SetRenderState(D3DRS_ZFUNC, savePlateZFunc);
            return;
        end

        if (style.plateTacticalOverlayOnly == true) then
            return;
        end

        if (style.plateAlwaysOnTop == true and style.plateSuppressWorldWhenAlwaysOnTop == true) then
            return;
        end

        device:SetRenderState(D3DRS_ZFUNC, D3DCMP_LESSEQUAL);

        if (perfMeter ~= nil and perfMeter.CountDrawnCanvas ~= nil) then
            perfMeter.CountDrawnCanvas(
                style.clickTargetType or plate.clickTargetType or (plate.isSelf == true and 'self' or 'enemy'),
                style.plateTextureWidth,
                style.plateTextureHeight,
                plateWorldWidth,
                plateWorldHeight
            );
        end

        local textureDrawn, textureDeferred = DrawTextureWithState(
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
            style.plateAlwaysOnTop == true or stackMoved == true,
            -- EXPERIMENTAL: this was previously a hardcoded `false`, which
            -- meant the fully-built atlas batching system in
            -- world_plate_batch.lua never received a single plate to
            -- batch (confirmed via /lp perf report: world.batch.commands
            -- was always 0). That forced every visible plate to draw via
            -- its own individual SetTexture+DrawPrimitive call every
            -- frame. Flip worldMarkerProbe._experimentalPlateBatchingEnabled
            -- to false below to instantly revert to the old behavior if
            -- plates render incorrectly (wrong texture, flicker, wrong
            -- position) with this on.
            worldMarkerProbe._experimentalPlateBatchingEnabled == true
        );

        if (style.liveResourceBars == true) then
            if (textureDrawn == true and textureDeferred == true) then
                worldMarkerProbe._deferredLiveResourceBars[#worldMarkerProbe._deferredLiveResourceBars + 1] = {
                    plateX = plateX,
                    plateY = plateY,
                    plateZ = plateZ,
                    plate = plate,
                };
            else
                DrawSelfResourceBars(device, plateX, plateY, plateZ, plate);
            end
        end

        device:SetRenderState(D3DRS_ZFUNC, savePlateZFunc);

        return;
    end

    if (style.liveResourceBars == true) then
        local plateScale = GetPlateDistanceScale(style, targetIndex, plate.distance or style.distance);
        local plateWorldOffsetX = tonumber(style.plateWorldOffsetX) or 0;
        local plateWorldOffsetY = tonumber(style.plateWorldOffsetY) or tonumber(style.nameWorldOffsetY) or 0.78;
        if (style.pcBodyPlateOffsetEnabled == true) then
            local bodyOffset = GetPcBodyPlateOffset(actorPointer, targetIndex, entityManager);
            plateWorldOffsetY = plateWorldOffsetY + bodyOffset;
        end
        local plateWorldOffsetZ = tonumber(style.plateWorldOffsetZ) or 0;
        local plateX = wx + plateWorldOffsetX;
        local plateY = wz + verticalOffset + plateWorldOffsetY - nameVerticalOffset;
        local plateZ = wy + plateWorldOffsetZ;
        local plateWorldWidth = (tonumber(style.plateWorldWidth) or 0.84) * plateScale;
        local plateWorldHeight = (tonumber(style.plateWorldHeight) or 0.315) * plateScale;
        local _, savePlateZFunc = device:GetRenderState(D3DRS_ZFUNC);

        if (worldMarkerProbe._HasStackScreenOffset(plate) == true) then
            plateX, plateY, plateZ = worldMarkerProbe._ApplyStackScreenOffset(device, plateX, plateY, plateZ, plate);
        end

        if (worldMarkerProbe._HasStackScreenOffset(plate) ~= true and ShouldHideProjectedBelowViewportPlate(device, entityManager, style, plateX, plateY, plateZ) == true) then
            return;
        end

        if (worldMarkerProbe._HasStackScreenOffset(plate) ~= true and style.plateTacticalOverlayOnly ~= true) then
            local targetIndex, subTargetIndex = targeting.GetCurrentTargetAndSubTargetIndexes();
            local plateIndex = tonumber(plate.targetIndex);
            local isOwnTarget =
                plateIndex ~= nil and
                (plateIndex == tonumber(targetIndex) or plateIndex == tonumber(subTargetIndex));
            local hasActiveMarker = style.targetMarker ~= nil and style.targetMarker.enabled == true;

            if (
                isOwnTarget ~= true and
                hasActiveMarker ~= true and
                worldMarkerProbe._offScreenCullEnabled == true and
                worldMarkerProbe._IsClearlyOffScreen(device, plateX, plateY, plateZ) == true
            ) then
                if (perfMeter ~= nil and perfMeter.Count ~= nil) then
                    perfMeter.Count('world.cull.offScreen', 1);
                end
                return;
            end
        end

        if (perfMeter ~= nil and perfMeter.Count ~= nil) then
            perfMeter.Count('world.draw.actuallyVisible', 1);
        end

        style.clickTargetType = plate.clickTargetType or style.clickTargetType or (plate.isSelf == true and 'self' or 'enemy');
        style.serverId = plate.serverId or style.serverId;
        style.rawName = plate.rawName or style.rawName;
        style.distance = plate.distance or style.distance;
        style.modelHitboxSize = plate.modelHitboxSize or style.modelHitboxSize;

        if (updateClickOnly == true) then
            SetPlateClickRectFromBillboard(device, targetIndex, style.clickTargetType, plateX, plateY, plateZ, plateWorldWidth, plateWorldHeight, {
                targetIndex = targetIndex,
                targetType = style.clickTargetType,
                serverId = style.serverId,
                name = plate.clickName or style.clickName,
                rawName = plate.rawName or style.rawName,
                layoutStateName = style.layoutStateName,
            });
            return;
        end

        device:SetRenderState(D3DRS_ZFUNC, D3DCMP_LESSEQUAL);

        if (ShouldHardHidePlateByNoGoZone(plate.targetIndex) ~= true) then
            DrawSelfResourceBars(device, plateX, plateY, plateZ, plate);
            SetPlateClickRectFromBillboard(device, targetIndex, style.clickTargetType, plateX, plateY, plateZ, plateWorldWidth, plateWorldHeight, {
                targetIndex = targetIndex,
                targetType = style.clickTargetType,
                serverId = style.serverId,
                name = plate.clickName or style.clickName,
                rawName = plate.rawName or style.rawName,
                layoutStateName = style.layoutStateName,
            });
        end

        device:SetRenderState(D3DRS_ZFUNC, savePlateZFunc);

        return;
    end

    if (plate.isSelf == true) then
    local view, proj, viewport = worldMarkerProbe._GetProjectionState(device);

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

    if (updateClickOnly == true) then
        local nameY = wz + verticalOffset + (tonumber(style.nameWorldOffsetY) or 0.78) - nameVerticalOffset;
        local nameX = wx;
        local nameDrawY = nameY;
        local nameZ = wy;
        local metadata = {
            serverId = plate.serverId or style.serverId,
            name = plate.clickName or plate.name or style.clickName,
            layoutStateName = style.layoutStateName,
            trustIsMine = plate.trustIsMine,
            distance = plate.distance or style.distance,
            modelHitboxSize = plate.modelHitboxSize or style.modelHitboxSize,
            clickEnabled = style.plateClickTargetEnabled ~= false,
        };

        nameX, nameDrawY, nameZ = worldMarkerProbe._ApplyStackScreenOffset(device, nameX, nameDrawY, nameZ, plate);

        if (worldMarkerProbe._SetNameStackRect(device, targetIndex, style.clickTargetType or (plate.isSelf == true and 'self' or 'enemy'), plate.name, nameX, nameDrawY, nameZ, style, metadata) ~= true) then
            SetPlateClickRectFromBillboard(device, targetIndex, style.clickTargetType or (plate.isSelf == true and 'self' or 'enemy'), nameX, nameDrawY, nameZ, 0.42, 0.12, metadata);
        end

        return;
    end

    local barY = wz + verticalOffset;

    if (plate.isSelf ~= true) then
        barY = barY + (tonumber(style.hpBarWorldOffsetY) or 0);
    end

    local barX = wx;
    local barDrawY = barY;
    local barZ = wy;
    barX, barDrawY, barZ = worldMarkerProbe._ApplyStackScreenOffset(device, barX, barDrawY, barZ, plate);

    DrawWithState(device, barX, barDrawY, barZ, hpPercent, style, nil, plate);
    if (showText == true) then
        local nameY = wz + verticalOffset + (tonumber(style.nameWorldOffsetY) or 0.78) - nameVerticalOffset;
        local nameX = wx;
        local nameDrawY = nameY;
        local nameZ = wy;
        nameX, nameDrawY, nameZ = worldMarkerProbe._ApplyStackScreenOffset(device, nameX, nameDrawY, nameZ, plate);
        DrawCanvasIconWithState(device, nameX, nameDrawY, nameZ, style);
        local targetingSettings = targeting.GetSettings();
        if (targetingSettings.hideNativeNamesOnLoad == true or plate.forceName == true) then
            DrawNameWithState(device, plate.name, plate.distance, nameX, nameDrawY, nameZ, style);
        end
        if (plate.isSelf == true and plate.jobText ~= nil and tostring(plate.jobText or '') ~= '') then
            local jobY = wz + verticalOffset + (tonumber(style.jobWorldOffsetY) or 0.54) - nameVerticalOffset;
            local jobX = wx;
            local jobDrawY = jobY;
            local jobZ = wy;
            jobX, jobDrawY, jobZ = worldMarkerProbe._ApplyStackScreenOffset(device, jobX, jobDrawY, jobZ, plate);
            DrawJobWithState(device, plate, jobX, jobDrawY, jobZ, style);
        end

        if (showDistance == true and plate.isSelf ~= true) then
            local distanceX = wx;
            local distanceY = nameY - 0.12;
            local distanceZ = wy;
            distanceX, distanceY, distanceZ = worldMarkerProbe._ApplyStackScreenOffset(device, distanceX, distanceY, distanceZ, plate);
            DrawDistanceWithState(device, plate.distance, distanceX, distanceY, distanceZ, style);
        end
    end
end

local function GetPlateQueuePriority(plate, targetIndex, subTargetIndex)
    local index = tonumber(plate ~= nil and plate.targetIndex) or 0;
    local marker = plate ~= nil and plate.worldMarker ~= nil and plate.worldMarker.targetMarker or nil;
    local targetType = tostring(plate ~= nil and plate.clickTargetType or ''):lower();
    local playerEngaged = IsPlayerEngaged() == true;

    if (plate ~= nil and plate.isSelf == true) then
        return 0;
    end

    if (index ~= 0 and (index == tonumber(targetIndex) or index == tonumber(subTargetIndex))) then
        return 1;
    end

    if (marker ~= nil and marker.enabled == true) then
        return 2;
    end

    if (targetType == 'npc') then return 10; end
    if (targetType == 'object') then return 20; end
    if (targetType == 'enemy') then return playerEngaged == true and 30 or 40; end
    if (targetType == 'pc') then return playerEngaged == true and 40 or 30; end
    if (targetType == 'trust') then return 50; end
    if (targetType == 'pet') then return 60; end

    return 70;
end

-- ============================================================
-- Perf: hard cap on simultaneously visible plates ("overall" cap)
-- ============================================================
-- This is the THIRD, final layer of the max-plates system, and the
-- only one that operates on a true cross-type combined ranking:
--   1. pc.lua's own final loop caps ordinary players via
--      settings.maxVisiblePcPlates before the expensive per-player
--      build (QueuePlayer) ever runs.
--   2. npc.lua's own final loop caps ordinary NPCs/objects the same
--      way via settings.maxVisibleNpcPlates.
--   3. THIS function then applies settings.maxVisiblePlates (the
--      "overall" cap) across whatever survived steps 1-2, plus enemy/
--      trust/pet plates (which don't have their own per-type quota
--      yet), giving a real, predictable worst case on total plates
--      drawn regardless of how many entities are nearby.
--
-- Because steps 1-2 happen first, this function's own cost (and the
-- draw-side cost of anything it trims) is now bounded by however much
-- steps 1-2 already let through, not the full unfiltered entity count.
-- Note steps 1-2 don't coordinate with each other or with this cap, so
-- it's possible for more to be queued here than the overall cap allows
-- (e.g. maxVisiblePcPlates=10 + maxVisibleNpcPlates=10 both maxed out,
-- while maxVisiblePlates=15) -- the excess still gets its expensive
-- build paid for even though it won't be drawn, but that waste is
-- bounded by (maxVisiblePcPlates + maxVisibleNpcPlates - maxVisiblePlates)
-- rather than being unbounded like before any of these settings existed.
--
-- Reuses the exact same importance ranking SortDrawablePlatesForDraw
-- already uses for draw order (self > current target/subtarget > active
-- marker > by entity type), so what gets dropped under the cap is
-- consistent with what the addon already treats as "less important".
-- Within a priority tier, closer plates are kept over farther ones.
--
-- Controlled by settings.maxVisiblePlates (0 = unlimited, the default,
-- so this has zero effect and zero cost until explicitly enabled).
worldMarkerProbe._GetPlateKeepPriority = function(plate, drawPriority)
    if (drawPriority <= 2) then
        -- self / current target-subtarget / active tactical marker: same
        -- as draw order, always most important, never dropped first.
        return drawPriority;
    end

    -- GetPlateQueuePriority() above intentionally ranks NPCs ahead of
    -- ordinary players for DRAW ORDER (so a quest-giver/shop NPC paints
    -- on top and stays legible in a crowd). That's a sensible z-order
    -- rule, but reusing it for the KEEP/DROP decision under a hard
    -- population cap had the effect of preferring incidental town NPCs
    -- over nearby players, which isn't what most people mean by "limit
    -- how many plates I see" -- so this uses a separate ordering for
    -- that specific decision instead.
    local targetType = tostring(plate ~= nil and plate.clickTargetType or ''):lower();

    if (targetType == 'pc') then return 10; end
    if (targetType == 'trust') then return 15; end
    if (targetType == 'pet') then return 18; end
    if (targetType == 'enemy') then return 20; end
    if (targetType == 'npc') then return 30; end
    if (targetType == 'object') then return 40; end

    return 50;
end

worldMarkerProbe._ApplyMaxVisiblePlatesLimit = function(plates, entityManager, device)
    if (type(plates) ~= 'table') then
        return plates;
    end

    local settings = targeting.GetSettings();
    local limit = settings ~= nil and tonumber(settings.maxVisiblePlates) or 0;

    if (limit == nil or limit <= 0 or #plates <= limit) then
        if (perfMeter ~= nil and perfMeter.SetCounter ~= nil) then
            perfMeter.SetCounter('world.maxPlatesLimit.dropped', 0);
        end

        return plates;
    end

    local targetIndex, subTargetIndex = targeting.GetCurrentTargetAndSubTargetIndexes();

    -- BUGFIX: previously ranked candidates purely by priority+distance
    -- with no notion of whether they were actually in front of the
    -- camera. In a crowd, the "closest" handful can easily all be
    -- standing behind the player, and the earlier off-screen cull
    -- (world.cull.offScreen) would then reject every single one of
    -- them -- netting zero visible plates even though the cap was
    -- "working" by its own count. This does a cheap raw-position
    -- projection (not the expensive exact-anchor helper DrawOne uses)
    -- purely to bias selection toward plates likely to actually be
    -- visible.
    local view, proj, viewport = nil, nil, nil;

    if (device ~= nil) then
        view, proj, viewport = worldMarkerProbe._GetProjectionState(device);
    end

    local canCheckVisibility =
        entityManager ~= nil and
        view ~= nil and proj ~= nil and viewport ~= nil and
        viewport.Width ~= nil and viewport.Height ~= nil;

    local ranked = {};

    for order, plate in ipairs(plates) do
        local drawPriority = GetPlateQueuePriority(plate, targetIndex, subTargetIndex);
        local behindCamera = false;

        -- Protected plates (self/target/subtarget/active marker) are
        -- never visibility-checked here -- they're always kept
        -- regardless of facing, same as before.
        if (canCheckVisibility == true and drawPriority > 2) then
            local ex, ey, ez = GetObjectEntityAnchor(entityManager, tonumber(plate ~= nil and plate.targetIndex));

            if (ex ~= nil and ey ~= nil and ez ~= nil) then
                -- FFXI actor memory is x/y/z; D3D world here is x/z/y
                -- (z is FFXI's vertical axis). +1.0 is a rough head-height
                -- offset -- this only needs to be approximately right
                -- for ranking purposes, not pixel-accurate.
                local sx, sy = ProjectWithZ(view, proj, viewport.Width, viewport.Height, ex, ez + 1.0, ey);

                if (sx == nil or sy == nil) then
                    behindCamera = true;
                end
            end
        end

        ranked[#ranked + 1] = {
            plate = plate,
            priority = worldMarkerProbe._GetPlateKeepPriority(plate, drawPriority),
            behindCamera = behindCamera,
            distance = tonumber(plate ~= nil and plate.distance) or 9999,
            order = order,
        };
    end

    table.sort(ranked, function(left, right)
        if (left.priority ~= right.priority) then
            return left.priority < right.priority;
        end

        if (left.behindCamera ~= right.behindCamera) then
            -- Not-behind-camera sorts before behind-camera within the
            -- same priority tier.
            return right.behindCamera == true;
        end

        if (left.distance ~= right.distance) then
            return left.distance < right.distance;
        end

        return left.order < right.order;
    end);

    local kept = {};
    local keepCount = math.min(limit, #ranked);

    for i = 1, keepCount do
        kept[#kept + 1] = ranked[i].plate;
    end

    if (perfMeter ~= nil and perfMeter.SetCounter ~= nil) then
        perfMeter.SetCounter('world.maxPlatesLimit.dropped', #plates - #kept);
    end

    return kept;
end

local function SortDrawablePlatesForDraw(drawablePlates)
    if (type(drawablePlates) ~= 'table' or #drawablePlates <= 1) then
        return drawablePlates;
    end

    local targetIndex, subTargetIndex = targeting.GetCurrentTargetAndSubTargetIndexes();
    local sorted = {};

    for order, plate in ipairs(drawablePlates) do
        local index = tonumber(plate ~= nil and plate.targetIndex) or 0;
        local drawLayer = 0;

        if (index ~= 0 and index == tonumber(targetIndex)) then
            drawLayer = 1;
        elseif (index ~= 0 and index == tonumber(subTargetIndex)) then
            drawLayer = 2;
        end

        sorted[#sorted + 1] = {
            plate = plate,
            priority = GetPlateQueuePriority(plate, targetIndex, subTargetIndex),
            distance = tonumber(plate ~= nil and plate.distance) or 9999,
            drawLayer = drawLayer,
            order = order,
        };
    end

    table.sort(sorted, function(left, right)
        if (left.priority ~= right.priority) then
            return left.priority > right.priority;
        end

        if (left.drawLayer ~= right.drawLayer) then
            return left.drawLayer < right.drawLayer;
        end

        if (left.distance ~= right.distance) then
            return left.distance > right.distance;
        end

        return left.order < right.order;
    end);

    local result = {};

    for _, entry in ipairs(sorted) do
        result[#result + 1] = entry.plate;
    end

    return result;
end

function worldMarkerProbe.DrawQueued(getEntityManager, getBone)
    pass = pass + 1;

    if (enabled ~= true or getEntityManager == nil or getBone == nil) then
        return;
    end

    if (drawSuppressed == true) then
        if (pass == 2) then
            lastDrawCount = 0;
            queuedPlates = {};
            queuedStaticPlates = {};
            queuedPlateSet = {};
        end

        return;
    end

    local entityManager = getEntityManager();
    local device = d3d8.get_device();

    if (entityManager == nil or device == nil) then
        return;
    end

    -- BUGFIX: this refresh used to happen only after the "nothing
    -- queued" early-exit below, so it never ran at all in a scene with
    -- zero currently-visible plates -- exactly when the right-click
    -- fallback (which reads this same cache) is most needed. Moved
    -- earlier so it always runs whenever the addon is enabled, whether
    -- or not there's currently anything to actually draw.
    worldMarkerProbe._RefreshProjectionCache(device);

    if (#queuedPlates == 0 and #queuedStaticPlates == 0) then
        return;
    end

    if (pass == 1) then
        pendingSelfClickRect = nil;
        pendingSelfClickRects = nil;
        pendingClickRects = {};
        worldMarkerProbe._pendingStackRects = {};

        local drawablePlates = SortDrawablePlatesForDraw(worldMarkerProbe._ApplyMaxVisiblePlatesLimit(queuedPlates, entityManager, device));
        worldMarkerProbe._lastClickPlates = drawablePlates;
        worldMarkerProbe._lastClickGetEntityManager = getEntityManager;
        worldMarkerProbe._lastClickGetBone = getBone;

        local keepFrameClickRects = worldMarkerProbe._ShouldKeepFrameClickRects() == true;
        local settings = targeting.GetSettings();
        local needsFrameBounds = settings ~= nil and (
            settings.plateStackingEnabled == true or
            settings.plateClickNoGoZonesMask == true
        );
        worldMarkerProbe._collectFrameClickRects = keepFrameClickRects;

        if (keepFrameClickRects ~= true and needsFrameBounds ~= true) then
            clickRects = {};
            selfClickRect = nil;
            selfClickRects = nil;
            worldMarkerProbe._collectFrameClickRects = true;
            return;
        end

        for _, plate in ipairs(drawablePlates) do
            if (plate.worldMarker ~= nil) then
                pcall(function ()
                    DrawOne(plate, entityManager, getBone, device, true);
                end);
            end
        end

        ApplyScreenPlateStacking(drawablePlates);

        clickRects = pendingClickRects;
        selfClickRect = pendingSelfClickRect;
        selfClickRects = pendingSelfClickRects;
        worldMarkerProbe._collectFrameClickRects = true;

        if worldMarkerProbe.ApplyMouseSnap ~= nil then
            worldMarkerProbe.ApplyMouseSnap();
        end

        return;
    end

    if (pass ~= 2) then
        return;
    end

    lastDrawCount = 0;
    local drawablePlates = SortDrawablePlatesForDraw(worldMarkerProbe._ApplyMaxVisiblePlatesLimit(queuedPlates, entityManager, device));
    worldMarkerProbe._lastClickPlates = drawablePlates;
    worldMarkerProbe._lastClickGetEntityManager = getEntityManager;
    worldMarkerProbe._lastClickGetBone = getBone;
    worldMarkerProbe._deferredLiveResourceBars = {};
    if (worldMarkerProbe._plateBatch ~= nil and worldMarkerProbe._plateBatch.Begin ~= nil) then
        worldMarkerProbe._plateBatch.Begin();
    end

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

    local batchOk = false;
    local batchCommands = nil;

    if (worldMarkerProbe._plateBatch ~= nil and worldMarkerProbe._plateBatch.Flush ~= nil) then
        batchOk, batchCommands = worldMarkerProbe._plateBatch.Flush(device, worldMarkerProbe._atlasDrawSuppressed == true);
    end

    if (batchOk ~= true) then
        for _, command in ipairs(batchCommands or {}) do
            DrawTextureWithState(
                device,
                command.textureId,
                command.wx,
                command.wy,
                command.wz,
                command.width,
                0,
                0,
                0.00175,
                false,
                command.height,
                command.alwaysOnTop == true,
                false
            );
        end
    end

    if (worldMarkerProbe._atlasDrawSuppressed ~= true) then
        for _, entry in ipairs(worldMarkerProbe._deferredLiveResourceBars or {}) do
            local _, savedZFunc = device:GetRenderState(D3DRS_ZFUNC);
            device:SetRenderState(D3DRS_ZFUNC, D3DCMP_LESSEQUAL);
            DrawSelfResourceBars(device, entry.plateX, entry.plateY, entry.plateZ, entry.plate);
            device:SetRenderState(D3DRS_ZFUNC, savedZFunc);
        end
    end

    if (
        perfMeter ~= nil and
        perfMeter.SetCounter ~= nil and
        worldMarkerProbe._plateBatch ~= nil and
        worldMarkerProbe._plateBatch.GetStatus ~= nil
    ) then
        local batchStatus = worldMarkerProbe._plateBatch.GetStatus();
        perfMeter.SetCounter('world.batch.active', batchOk == true and 1 or 0);
        perfMeter.SetCounter('world.batch.commands', tonumber(batchStatus.commands) or 0);
        perfMeter.SetCounter('world.batch.drawCalls', tonumber(batchStatus.drawCalls) or 0);
        perfMeter.SetCounter('world.batch.atlasCopies', tonumber(batchStatus.atlasCopies) or 0);
        perfMeter.SetCounter('world.batch.atlasPages', tonumber(batchStatus.atlasPages) or 0);
    end

    for _, plate in ipairs(queuedStaticPlates) do
        local ok, err = pcall(function()
            DrawFixedScreenTexture(device, plate.textureId, plate.x, plate.y, plate.width, plate.height);
        end);

        if (ok == true) then
            lastDrawCount = lastDrawCount + 1;
        else
            lastError = tostring(err);
        end
    end

    queuedPlates = {};
    queuedStaticPlates = {};
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

function worldMarkerProbe._IsPointInSelfClickRectData(x, y, clickRect, clickRectList)
    if (clickRect == nil) then
        return false;
    end

    local mouseX = tonumber(x);
    local mouseY = tonumber(y);

    if (mouseX == nil or mouseY == nil) then
        return false;
    end

    local rects = clickRectList or { clickRect };

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

function worldMarkerProbe._FindClickRectInList(rectList, x, y)
    local mouseX = tonumber(x);
    local mouseY = tonumber(y);

    if (mouseX == nil or mouseY == nil) then
        return nil;
    end

    for i = #(rectList or {}), 1, -1 do
        local entry = rectList[i];

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

local function IsPointInSelfClickRect(x, y)
    return worldMarkerProbe._IsPointInSelfClickRectData(x, y, selfClickRect, selfClickRects);
end

local function FindClickRectAt(x, y)
    return worldMarkerProbe._FindClickRectInList(clickRects, x, y);
end

function worldMarkerProbe._BuildOnDemandClickRects()
    if (worldMarkerProbe._clickHitMode ~= 'ondemand' or worldMarkerProbe._ShouldKeepFrameClickRects() == true) then
        return nil, nil, nil;
    end

    if (worldMarkerProbe._lastClickPlates == nil or #worldMarkerProbe._lastClickPlates == 0 or worldMarkerProbe._lastClickGetEntityManager == nil or worldMarkerProbe._lastClickGetBone == nil) then
        return nil, nil, nil;
    end

    local entityManager = worldMarkerProbe._lastClickGetEntityManager();
    local device = d3d8.get_device();

    if (entityManager == nil or device == nil) then
        return nil, nil, nil;
    end

    local previousPendingClickRects = pendingClickRects;
    local previousPendingSelfClickRect = pendingSelfClickRect;
    local previousPendingSelfClickRects = pendingSelfClickRects;
    local previousPendingStackRects = worldMarkerProbe._pendingStackRects;
    local previousCollectFrameClickRects = worldMarkerProbe._collectFrameClickRects;

    pendingClickRects = {};
    pendingSelfClickRect = nil;
    pendingSelfClickRects = nil;
    worldMarkerProbe._pendingStackRects = {};
    worldMarkerProbe._collectFrameClickRects = true;

    for _, plate in ipairs(worldMarkerProbe._lastClickPlates) do
        if (plate.worldMarker ~= nil) then
            pcall(function ()
                DrawOne(plate, entityManager, worldMarkerProbe._lastClickGetBone, device, true);
            end);
        end
    end

    local builtClickRects = pendingClickRects;
    local builtSelfClickRect = pendingSelfClickRect;
    local builtSelfClickRects = pendingSelfClickRects;

    pendingClickRects = previousPendingClickRects;
    pendingSelfClickRect = previousPendingSelfClickRect;
    pendingSelfClickRects = previousPendingSelfClickRects;
    worldMarkerProbe._pendingStackRects = previousPendingStackRects;
    worldMarkerProbe._collectFrameClickRects = previousCollectFrameClickRects;

    return builtClickRects or {}, builtSelfClickRect, builtSelfClickRects;
end

function worldMarkerProbe._FindClickRectOnDemandAt(x, y)
    local rects, builtSelfClickRect, builtSelfClickRects = worldMarkerProbe._BuildOnDemandClickRects();

    if (rects == nil) then
        return nil;
    end

    local entry, rect = worldMarkerProbe._FindClickRectInList(rects, x, y);

    return entry, rect, builtSelfClickRect, builtSelfClickRects;
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
                return true, zone.name or ('Screen ' .. tostring(index));
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

function worldMarkerProbe._MouseSnapKinds(mode)
    if mode == 'Name' then return { name = true }; end
    if mode == 'HP bar' then return { hp = true }; end
    if mode == 'Name + HP bar' then return { name = true, hp = true }; end
    return nil;
end

function worldMarkerProbe.ApplyMouseSnap()
    if enabled ~= true or replacePlates ~= true or IsGameWindowFocused() ~= true then
        return;
    end

    local settings = targeting.GetSettings();
    local pcKinds = worldMarkerProbe._MouseSnapKinds(settings.pcMouseSnapMode);
    local enemyKinds = worldMarkerProbe._MouseSnapKinds(settings.enemyMouseSnapMode);

    if pcKinds == nil and enemyKinds == nil then
        return;
    end

    if IsImguiCapturingMouse() == true then
        return;
    end

    local lib = GetUser32();
    if lib == nil then
        return;
    end

    local buttonsDown = false;
    pcall(function()
        buttonsDown =
            bit.band(lib.GetAsyncKeyState(0x01), 0x8000) ~= 0 or
            bit.band(lib.GetAsyncKeyState(0x02), 0x8000) ~= 0 or
            bit.band(lib.GetAsyncKeyState(0x04), 0x8000) ~= 0;
    end);
    if buttonsDown == true then
        return;
    end

    local mouseX, mouseY = GetMousePosition();
    if mouseX == nil or mouseY == nil or IsPointInNoGoZone(mouseX, mouseY, settings) == true then
        return;
    end

    local best = nil;
    local captureDistance = 56;

    for _, entry in ipairs(clickRects or {}) do
        local targetType = tostring(entry.targetType or '');
        local allowedKinds = targetType == 'pc' and pcKinds or (targetType == 'enemy' and enemyKinds or nil);

        if allowedKinds ~= nil then
            for _, rect in ipairs(entry.rects or {}) do
                local kind = tostring(rect.kind or '');
                local x1 = tonumber(rect.x1);
                local y1 = tonumber(rect.y1);
                local x2 = tonumber(rect.x2);
                local y2 = tonumber(rect.y2);

                if rect.anchorOnly ~= true and allowedKinds[kind] == true and x1 ~= nil and y1 ~= nil and x2 ~= nil and y2 ~= nil then
                    local nearestX = math.max(x1, math.min(x2, mouseX));
                    local nearestY = math.max(y1, math.min(y2, mouseY));
                    local edgeDx = mouseX - nearestX;
                    local edgeDy = mouseY - nearestY;
                    local edgeDistance = math.sqrt((edgeDx * edgeDx) + (edgeDy * edgeDy));

                    if edgeDistance <= captureDistance and (best == nil or edgeDistance < best.distance) then
                        best = {
                            x = (x1 + x2) * 0.5,
                            y = (y1 + y2) * 0.5,
                            distance = edgeDistance,
                            targetType = targetType,
                        };
                    end
                end
            end
        end
    end

    if best == nil then
        return;
    end

    local strengthSetting = best.targetType == 'pc'
        and settings.pcMouseSnapStrength
        or settings.enemyMouseSnapStrength;
    local strength = math.max(1, math.min(5, tonumber(strengthSetting) or 5));
    local pull = 0.04 + (strength * 0.041);
    local nextX = mouseX + ((best.x - mouseX) * pull);
    local nextY = mouseY + ((best.y - mouseY) * pull);

    if math.abs(nextX - mouseX) < 0.5 and math.abs(nextY - mouseY) < 0.5 then
        return;
    end

    pcall(function()
        local point = ffi.new('lp_mouse_snap_point_t[1]');
        point[0].x = math.floor(nextX + 0.5);
        point[0].y = math.floor(nextY + 0.5);
        local window = lib.GetActiveWindow();

        if window ~= nil and lib.ClientToScreen(window, point) ~= 0 then
            lib.SetCursorPos(point[0].x, point[0].y);
        end
    end);
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
    local settings = targeting.GetSettings();

    for _, entry in ipairs(clickRects or {}) do
        if (entry.plateTextureId ~= nil and entry.plateOverlayRect ~= nil and entry.plateOverlayOnly == true) then
            local rect = entry.plateOverlayRect;

            if (RectIntersectsNoGoZone(rect.x1, rect.y1, rect.x2, rect.y2, settings) ~= true) then
                results[#results + 1] = {
                    targetIndex = entry.targetIndex,
                    targetType = entry.targetType,
                    clickName = entry.name,
                    rawName = entry.rawName,
                    textureId = entry.plateTextureId,
                    textureWidth = entry.plateTextureWidth,
                    textureHeight = entry.plateTextureHeight,
                    worldWidth = entry.plateWorldWidth,
                    worldHeight = entry.plateWorldHeight,
                    rect = entry.plateOverlayRect,
                    overlayOffsetX = entry.plateOverlayOffsetX,
                    overlayOffsetY = entry.plateOverlayOffsetY,
                    animatedTargetMarker = entry.animatedTargetMarker,
                };
            end
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

    if (worldMarkerProbe.ConsumeFocusPassthrough(e) == true) then
        return false;
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
    worldMarkerProbe._onDemandSelfClickRect = nil;
    worldMarkerProbe._onDemandSelfClickRects = nil;

    if (entry == nil and worldMarkerProbe._clickHitMode == 'ondemand') then
        entry, _, worldMarkerProbe._onDemandSelfClickRect, worldMarkerProbe._onDemandSelfClickRects = worldMarkerProbe._FindClickRectOnDemandAt(e.x, e.y);
    end

    worldMarkerProbe._fallbackSelfClickRect = worldMarkerProbe._onDemandSelfClickRect or selfClickRect;
    worldMarkerProbe._fallbackSelfClickRects = worldMarkerProbe._onDemandSelfClickRects or selfClickRects;

    if (entry == nil and worldMarkerProbe._IsPointInSelfClickRectData(e.x, e.y, worldMarkerProbe._fallbackSelfClickRect, worldMarkerProbe._fallbackSelfClickRects) == true) then
        entry = {
            targetIndex = worldMarkerProbe._fallbackSelfClickRect.targetIndex,
            targetType = 'self',
            serverId = worldMarkerProbe._fallbackSelfClickRect.serverId,
            name = worldMarkerProbe._fallbackSelfClickRect.name,
            rawName = worldMarkerProbe._fallbackSelfClickRect.rawName,
            layoutStateName = worldMarkerProbe._fallbackSelfClickRect.layoutStateName,
        };
    end

    -- Quick Menu without a visible plate: only for right-click (516/517),
    -- deliberately never touching left-click (513/514) targeting at all.
    -- Falls back to your current target when nothing was found via the
    -- normal plate-based click-rect lookup above.
    if (entry == nil and (message == 516 or message == 517)) then
        local okFallbackEntity, fallbackEntityManager = pcall(function()
            return AshitaCore:GetMemoryManager():GetEntity();
        end);

        if (okFallbackEntity == true and fallbackEntityManager ~= nil) then
            entry = worldMarkerProbe._BuildEntryForCurrentTarget(fallbackEntityManager);
        end
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

    if (entry.targetType == 'object' and message == 513) then
        local ok = false;

        pcall(function ()
            ok = selectTarget(entry.targetIndex, false);
        end);

        lastClickStatus = 'object left select ' .. tostring(ok) .. ' message=' .. tostring(message) .. ' x=' .. tostring(e.x) .. ' y=' .. tostring(e.y) .. ' target=' .. tostring(entry.targetIndex);

        if (ok == true) then
            suppressNextLeftRelease = true;
            e.blocked = true;
            return true;
        end

        lastClickStatus = 'object left native pass select-failed message=' .. tostring(message) .. ' x=' .. tostring(e.x) .. ' y=' .. tostring(e.y) .. ' target=' .. tostring(entry.targetIndex);
        return false;
    end

    if (entry.targetType == 'object' and message == 514) then
        lastClickStatus = 'object left release native pass message=' .. tostring(message) .. ' x=' .. tostring(e.x) .. ' y=' .. tostring(e.y) .. ' target=' .. tostring(entry.targetIndex);
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
        (entry.targetType == 'object' or targeting.IsGatheringTarget(entry.targetIndex, entry.name) == true)
    ) then
        local ok = false;
        local interactType = (targeting.IsGatheringTarget(entry.targetIndex, entry.name) == true) and 'object' or entry.targetType;

        pcall(function ()
            ok = interactTarget(entry.targetIndex, interactType, entry.distance);
        end);

        lastClickStatus = 'right interact ' .. tostring(ok) .. ' ' .. tostring(interactType) .. ' message=' .. tostring(message) .. ' target=' .. tostring(entry.targetIndex) .. ' distance=' .. tostring(entry.distance) .. ' name=' .. tostring(entry.name or '');

        if (ok == true) then
            return true;
        end

        if (targeting.IsGatheringTarget(entry.targetIndex, entry.name) == true) then
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
    clickDebugEnabled = (value == true);
    clickDebugVisible = (value == true);
    lastClickStatus = 'debugpath=' .. tostring(clickDebugEnabled) .. ' visible=' .. tostring(clickDebugVisible) .. ' plates=' .. tostring(clickRects ~= nil and #clickRects or 0);
end

function worldMarkerProbe.GetClickDebug()
    return clickDebugEnabled == true;
end

function worldMarkerProbe.GetClickBordersVisible()
    return clickDebugVisible == true;
end

function worldMarkerProbe.SetClickHitMode(mode)
    local value = tostring(mode or ''):lower();

    if (value == 'ondemand' or value == 'on-demand' or value == 'on_demand') then
        worldMarkerProbe._clickHitMode = 'ondemand';
    else
        worldMarkerProbe._clickHitMode = 'legacy';
    end

    clickRects = {};
    selfClickRect = nil;
    selfClickRects = nil;
    lastClickStatus = 'clickmode=' .. tostring(worldMarkerProbe._clickHitMode);
end

function worldMarkerProbe.GetClickHitMode()
    return worldMarkerProbe._clickHitMode;
end

function worldMarkerProbe.GetClickHitStatusText()
    local frameRects = worldMarkerProbe._ShouldKeepFrameClickRects() == true;

    return
        'clickmode=' .. tostring(worldMarkerProbe._clickHitMode) ..
        ' frameRects=' .. tostring(frameRects) ..
        ' reason=' .. tostring(worldMarkerProbe._clickFrameRectsReason or 'unknown') ..
        ' clickplates=' .. tostring(clickRects ~= nil and #clickRects or 0) ..
        ' candidates=' .. tostring(worldMarkerProbe._lastClickPlates ~= nil and #worldMarkerProbe._lastClickPlates or 0);
end

function worldMarkerProbe.DrawRawClickDebug()
    if (clickDebugEnabled ~= true or clickDebugVisible ~= true or imguiApi == nil) then
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
        local alpha = 0.65;
        local color = (entry.targetType == 'enemy') and { 1.0, 0.35, 0.0, alpha } or { 0.25, 0.9, 1.0, alpha };

        for _, rect in ipairs(entry.rects or {}) do
            drawList:AddRect(
                { rect.x1, rect.y1 },
                { rect.x2, rect.y2 },
                imguiApi.GetColorU32(color),
                0,
                0,
                2
            );
        end
    end
end

function worldMarkerProbe.GetStatusText()
    local batchStatus =
        worldMarkerProbe._plateBatch ~= nil and
        worldMarkerProbe._plateBatch.GetStatus ~= nil and
        worldMarkerProbe._plateBatch.GetStatus() or {};

    return 'enabled=' .. tostring(enabled) ..
        ' replace=' .. tostring(replacePlates) ..
        ' drawsuppressed=' .. tostring(drawSuppressed) ..
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
        ' clickmode=' .. tostring(worldMarkerProbe._clickHitMode) ..
        ' frameclick=' .. tostring(worldMarkerProbe._ShouldKeepFrameClickRects()) ..
        ' clickdebug=' .. tostring(clickDebugEnabled) ..
        ' clickvisible=' .. tostring(clickDebugVisible) ..
        ' clickver=' .. tostring(clickVersion) ..
        ' click=' .. tostring(lastClickStatus) ..
        ' batch=' .. tostring(batchStatus.status) ..
        ' batchcmd=' .. tostring(batchStatus.commands) ..
        ' batchdraw=' .. tostring(batchStatus.drawCalls) ..
        ' batchpages=' .. tostring(batchStatus.atlasPages) ..
        ' error=' .. tostring(lastError);
end

function worldMarkerProbe.GetPerfStats()
    local byType = {};

    for _, entry in ipairs(clickRects or {}) do
        local targetType = tostring(entry ~= nil and entry.targetType or 'unknown');
        byType[targetType] = (tonumber(byType[targetType]) or 0) + 1;
    end

    return {
        queued = tonumber(lastQueuedCount) or 0,
        drawn = tonumber(lastDrawCount) or 0,
        clickRects = clickRects ~= nil and #clickRects or 0,
        clickRectsSelf = tonumber(byType.self) or 0,
        clickRectsPc = tonumber(byType.pc) or 0,
        clickRectsEnemy = tonumber(byType.enemy) or 0,
        clickRectsNpc = tonumber(byType.npc) or 0,
        clickRectsObject = tonumber(byType.object) or 0,
        clickRectsTrust = tonumber(byType.trust) or 0,
        clickRectsPet = tonumber(byType.pet) or 0,
        clickRectsOther = tonumber(byType.other) or tonumber(byType.unknown) or 0,
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
