require('common');

local ffi = require('ffi');
local d3d8 = require('d3d8');

ffi.cdef[[
    typedef struct {
        float x, y, z;
        unsigned int color;
        float tu, tv;
    } lp_world_plate_batch_vertex_t;

    typedef struct {
        long left, top, right, bottom;
    } lp_world_plate_batch_rect_t;

    typedef struct {
        long x, y;
    } lp_world_plate_batch_point_t;
]];

local C = ffi.C;
local batch = {};

local ATLAS_SIZE = 2048;
local ATLAS_PADDING = 2;
local MIN_BATCH_SIZE = 4;
local D3DUSAGE_RENDERTARGET = 1;
local D3DFMT_A8R8G8B8 = 21;
local D3DPOOL_DEFAULT = 0;
local D3DPT_TRIANGLELIST = 4;
local D3DFVF_XYZ_DIFFUSE_TEX1 = 0x142;
local D3DTS_WORLD = 256;
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
local D3DTSS_COLOROP = 1;
local D3DTSS_COLORARG1 = 2;
local D3DTSS_COLORARG2 = 3;
local D3DTSS_ALPHAOP = 4;
local D3DTSS_ALPHAARG1 = 5;
local D3DTSS_ADDRESSU = 13;
local D3DTSS_ADDRESSV = 14;
local D3DTSS_MAGFILTER = 16;
local D3DTSS_MINFILTER = 17;
local D3DTOP_SELECTARG1 = 2;
local D3DTA_TEXTURE = 2;
local D3DTEXF_LINEAR = 2;
local D3DTADDRESS_CLAMP = 3;
local VERTEX_SIZE = ffi.sizeof('lp_world_plate_batch_vertex_t');

local commands = {};
local atlasPages = {};
local layoutByToken = {};
local layoutSignature = nil;
local active = false;
local lastStatus = 'idle';
local lastDrawCalls = 0;
local lastAtlasCopies = 0;

local identity = ffi.new('D3DMATRIX');
identity._11 = 1;
identity._22 = 1;
identity._33 = 1;
identity._44 = 1;

local function ReleaseInterface(value)
    if (value ~= nil) then
        pcall(function()
            value:Release();
        end);
    end
end

local function CopyMatrix(value)
    if (value == nil) then
        return nil;
    end

    return {
        _11 = value._11, _12 = value._12, _13 = value._13, _14 = value._14,
        _21 = value._21, _22 = value._22, _23 = value._23, _24 = value._24,
        _31 = value._31, _32 = value._32, _33 = value._33, _34 = value._34,
        _41 = value._41, _42 = value._42, _43 = value._43, _44 = value._44,
    };
end

local function MatrixFromTable(value)
    if (value == nil) then
        return nil;
    end

    local result = ffi.new('D3DMATRIX');
    for key, entry in pairs(value) do
        result[key] = entry;
    end
    return result;
end

local function TextureToken(textureId, info)
    return table.concat({
        tostring(textureId),
        tostring(info ~= nil and info.revision or ''),
        tostring(info ~= nil and info.width or ''),
        tostring(info ~= nil and info.height or ''),
    }, ':');
end

local function ReleasePages()
    for _, page in ipairs(atlasPages) do
        ReleaseInterface(page.texture);
    end

    atlasPages = {};
    layoutByToken = {};
    layoutSignature = nil;
end

local function EnsurePage(device, pageIndex)
    if (atlasPages[pageIndex] ~= nil and atlasPages[pageIndex].texture ~= nil) then
        return atlasPages[pageIndex];
    end

    local ok, hr, texture = pcall(function()
        return device:CreateTexture(
            ATLAS_SIZE,
            ATLAS_SIZE,
            1,
            D3DUSAGE_RENDERTARGET,
            D3DFMT_A8R8G8B8,
            D3DPOOL_DEFAULT
        );
    end);

    if (ok ~= true or hr ~= C.S_OK or texture == nil) then
        lastStatus = 'atlas-create-failed:' .. tostring(hr);
        return nil;
    end

    atlasPages[pageIndex] = {
        texture = texture,
        textureId = tonumber(ffi.cast('uintptr_t', texture)),
    };

    return atlasPages[pageIndex];
end

local function BuildLayout(items)
    table.sort(items, function(a, b)
        if (a.height == b.height) then
            return a.width > b.width;
        end
        return a.height > b.height;
    end);

    local result = {};
    local pageIndex = 1;
    local x = ATLAS_PADDING;
    local y = ATLAS_PADDING;
    local rowHeight = 0;

    for _, item in ipairs(items) do
        if (
            item.width <= 0 or
            item.height <= 0 or
            item.width + (ATLAS_PADDING * 2) > ATLAS_SIZE or
            item.height + (ATLAS_PADDING * 2) > ATLAS_SIZE
        ) then
            return nil, 'source-too-large';
        end

        if (x + item.width + ATLAS_PADDING > ATLAS_SIZE) then
            x = ATLAS_PADDING;
            y = y + rowHeight + ATLAS_PADDING;
            rowHeight = 0;
        end

        if (y + item.height + ATLAS_PADDING > ATLAS_SIZE) then
            pageIndex = pageIndex + 1;
            x = ATLAS_PADDING;
            y = ATLAS_PADDING;
            rowHeight = 0;
        end

        result[item.token] = {
            pageIndex = pageIndex,
            x = x,
            y = y,
            width = item.width,
            height = item.height,
            textureId = item.textureId,
            cropX = item.cropX or 0,
            cropY = item.cropY or 0,
        };

        x = x + item.width + ATLAS_PADDING;
        rowHeight = math.max(rowHeight, item.height);
    end

    return result, pageIndex;
end

local function CopyLayout(device, layout, pageCount)
    local pageSurfaces = {};
    lastAtlasCopies = 0;
    local failureCount = 0;
    local successCount = 0;

    local function Cleanup()
        for _, surface in pairs(pageSurfaces) do
            ReleaseInterface(surface);
        end
    end

    for pageIndex = 1, pageCount do
        local page = EnsurePage(device, pageIndex);
        if (page == nil) then
            Cleanup();
            return false;
        end

        local ok, hr, surface = pcall(function()
            return page.texture:GetSurfaceLevel(0);
        end);

        if (ok ~= true or hr ~= C.S_OK or surface == nil) then
            lastStatus = 'atlas-surface-failed:' .. tostring(hr);
            Cleanup();
            return false;
        end

        pageSurfaces[pageIndex] = surface;
    end

    -- NOTE: iterating with pairs() and clearing the current key (layout[token]
    -- = nil) is explicitly documented as safe in the Lua reference manual;
    -- only ADDING new keys during traversal is undefined. We rely on that
    -- here to prune individual entries that fail without restarting or
    -- aborting the whole pass.
    for token, entry in pairs(layout) do
        local sourceTexture = ffi.cast(
            'IDirect3DTexture8*',
            ffi.cast('uintptr_t', tonumber(entry.textureId))
        );
        local ok, hr, sourceSurface = pcall(function()
            return sourceTexture:GetSurfaceLevel(0);
        end);

        local entryFailed = false;

        if (ok ~= true or hr ~= C.S_OK or sourceSurface == nil) then
            lastStatus = 'source-surface-failed:' .. tostring(hr);
            entryFailed = true;
        else
            -- Back to the known-good (0,0) origin copy. Two earlier
            -- attempts at a crop-aware offset both failed in different
            -- ways: first with an outright CopyRects error, then --
            -- after adding a GetDesc() call to query and clamp to the
            -- source surface's real dimensions -- with CopyRects
            -- reporting success while actually copying blank content.
            -- The second failure is the more informative one: since the
            -- copy rectangle here is unchanged from the known-good
            -- version, merely CALLING GetDesc() on the source surface
            -- (regardless of what's done with its result) appears able
            -- to leave the surface in a state where a subsequent
            -- CopyRects silently misbehaves without either call
            -- reporting an error. That's a real, separate risk from the
            -- crop-math question this was meant to diagnose, so
            -- GetDesc() is removed entirely here, not just unused --
            -- calling it at all is what's suspect, not just trusting its
            -- return value.
            local sourceRect = ffi.new('lp_world_plate_batch_rect_t[1]');
            sourceRect[0].left = 0;
            sourceRect[0].top = 0;
            sourceRect[0].right = entry.width;
            sourceRect[0].bottom = entry.height;

            local destination = ffi.new('lp_world_plate_batch_point_t[1]');
            destination[0].x = entry.x;
            destination[0].y = entry.y;

            local copyOk, copyHr = pcall(function()
                return device:CopyRects(
                    sourceSurface,
                    ffi.cast('const RECT*', sourceRect),
                    1,
                    pageSurfaces[entry.pageIndex],
                    ffi.cast('const POINT*', destination)
                );
            end);

            ReleaseInterface(sourceSurface);

            if (copyOk ~= true or copyHr ~= C.S_OK) then
                lastStatus = 'atlas-copy-failed:' .. tostring(copyHr) ..
                    ':size=' .. tostring(entry.width) .. 'x' .. tostring(entry.height);
                entryFailed = true;
            end
        end

        if (entryFailed == true) then
            failureCount = failureCount + 1;
            -- Drop just this one plate from the layout. BuildRuns() already
            -- skips any command whose token isn't in layoutByToken, so this
            -- plate simply won't be part of the batched draw this frame
            -- instead of taking every other plate down with it.
            layout[token] = nil;
        else
            successCount = successCount + 1;
            lastAtlasCopies = lastAtlasCopies + 1;
        end
    end

    Cleanup();

    if (successCount == 0 and failureCount > 0) then
        -- Nothing usable came out of this pass at all -- treat it as a
        -- real failure so the caller falls back cleanly rather than
        -- flushing an empty atlas.
        return false;
    end

    return true;
end

local function EnsureLayout(device)
    local unique = {};
    local items = {};

    for _, command in ipairs(commands) do
        if (unique[command.token] == nil) then
            unique[command.token] = true;
            items[#items + 1] = {
                token = command.token,
                textureId = command.textureId,
                width = command.sourceWidth,
                height = command.sourceHeight,
                cropX = command.cropX,
                cropY = command.cropY,
            };
        end
    end

    table.sort(items, function(a, b)
        return a.token < b.token;
    end);

    local signatureParts = {};
    for _, item in ipairs(items) do
        signatureParts[#signatureParts + 1] = item.token;
    end
    local signature = table.concat(signatureParts, '|');

    if (signature == layoutSignature and next(layoutByToken) ~= nil) then
        lastAtlasCopies = 0;
        return true;
    end

    local layout, pageCountOrError = BuildLayout(items);
    if (layout == nil) then
        lastStatus = tostring(pageCountOrError);
        return false;
    end

    if (CopyLayout(device, layout, pageCountOrError) ~= true) then
        ReleasePages();
        return false;
    end

    layoutByToken = layout;
    layoutSignature = signature;
    return true;
end

local function CaptureState(device)
    local saved = {};
    local ok, err = pcall(function()
        local _, rawWorld = device:GetTransform(D3DTS_WORLD);
        saved.world = CopyMatrix(rawWorld);
        _, saved.light = device:GetRenderState(D3DRS_LIGHTING);
        _, saved.z = device:GetRenderState(D3DRS_ZENABLE);
        _, saved.zWrite = device:GetRenderState(D3DRS_ZWRITEENABLE);
        _, saved.zFunc = device:GetRenderState(D3DRS_ZFUNC);
        _, saved.zBias = device:GetRenderState(D3DRS_ZBIAS);
        _, saved.blend = device:GetRenderState(D3DRS_ALPHABLENDENABLE);
        _, saved.src = device:GetRenderState(D3DRS_SRCBLEND);
        _, saved.dst = device:GetRenderState(D3DRS_DESTBLEND);
        _, saved.cull = device:GetRenderState(D3DRS_CULLMODE);
        _, saved.alphaTest = device:GetRenderState(D3DRS_ALPHATESTENABLE);
        _, saved.alphaRef = device:GetRenderState(D3DRS_ALPHAREF);
        _, saved.alphaFunc = device:GetRenderState(D3DRS_ALPHAFUNC);
        _, saved.fvf = device:GetVertexShader();
        _, saved.texture = device:GetTexture(0);
        _, saved.pixelShader = device:GetPixelShader();
        _, saved.colorOp = device:GetTextureStageState(0, D3DTSS_COLOROP);
        _, saved.colorArg1 = device:GetTextureStageState(0, D3DTSS_COLORARG1);
        _, saved.colorArg2 = device:GetTextureStageState(0, D3DTSS_COLORARG2);
        _, saved.alphaOp = device:GetTextureStageState(0, D3DTSS_ALPHAOP);
        _, saved.alphaArg1 = device:GetTextureStageState(0, D3DTSS_ALPHAARG1);
        _, saved.magFilter = device:GetTextureStageState(0, D3DTSS_MAGFILTER);
        _, saved.minFilter = device:GetTextureStageState(0, D3DTSS_MINFILTER);
        _, saved.addressU = device:GetTextureStageState(0, D3DTSS_ADDRESSU);
        _, saved.addressV = device:GetTextureStageState(0, D3DTSS_ADDRESSV);
    end);

    if (ok ~= true) then
        ReleaseInterface(saved.texture);
        return nil, tostring(err);
    end

    return saved;
end

local function RestoreState(device, saved)
    if (saved == nil) then
        return;
    end

    local function Restore(callback)
        pcall(callback);
    end

    if (saved.world ~= nil) then
        Restore(function() device:SetTransform(D3DTS_WORLD, MatrixFromTable(saved.world)); end);
    end
    Restore(function() device:SetTexture(0, saved.texture); end);
    Restore(function() device:SetRenderState(D3DRS_LIGHTING, saved.light); end);
    Restore(function() device:SetRenderState(D3DRS_ZENABLE, saved.z); end);
    Restore(function() device:SetRenderState(D3DRS_ZWRITEENABLE, saved.zWrite); end);
    Restore(function() device:SetRenderState(D3DRS_ZFUNC, saved.zFunc); end);
    Restore(function() device:SetRenderState(D3DRS_ZBIAS, saved.zBias); end);
    Restore(function() device:SetRenderState(D3DRS_ALPHABLENDENABLE, saved.blend); end);
    Restore(function() device:SetRenderState(D3DRS_SRCBLEND, saved.src); end);
    Restore(function() device:SetRenderState(D3DRS_DESTBLEND, saved.dst); end);
    Restore(function() device:SetRenderState(D3DRS_CULLMODE, saved.cull); end);
    Restore(function() device:SetRenderState(D3DRS_ALPHATESTENABLE, saved.alphaTest); end);
    Restore(function() device:SetRenderState(D3DRS_ALPHAREF, saved.alphaRef); end);
    Restore(function() device:SetRenderState(D3DRS_ALPHAFUNC, saved.alphaFunc); end);
    Restore(function() device:SetVertexShader(saved.fvf); end);
    if (saved.pixelShader ~= nil) then
        Restore(function() device:SetPixelShader(saved.pixelShader); end);
    end
    Restore(function() device:SetTextureStageState(0, D3DTSS_COLOROP, saved.colorOp); end);
    Restore(function() device:SetTextureStageState(0, D3DTSS_COLORARG1, saved.colorArg1); end);
    Restore(function() device:SetTextureStageState(0, D3DTSS_COLORARG2, saved.colorArg2); end);
    Restore(function() device:SetTextureStageState(0, D3DTSS_ALPHAOP, saved.alphaOp); end);
    Restore(function() device:SetTextureStageState(0, D3DTSS_ALPHAARG1, saved.alphaArg1); end);
    Restore(function() device:SetTextureStageState(0, D3DTSS_MAGFILTER, saved.magFilter); end);
    Restore(function() device:SetTextureStageState(0, D3DTSS_MINFILTER, saved.minFilter); end);
    Restore(function() device:SetTextureStageState(0, D3DTSS_ADDRESSU, saved.addressU); end);
    Restore(function() device:SetTextureStageState(0, D3DTSS_ADDRESSV, saved.addressV); end);
    ReleaseInterface(saved.texture);
end

local function ApplyState(device)
    device:SetVertexShader(D3DFVF_XYZ_DIFFUSE_TEX1);
    device:SetPixelShader(0);
    device:SetRenderState(D3DRS_LIGHTING, 0);
    device:SetRenderState(D3DRS_CULLMODE, 1);
    device:SetRenderState(D3DRS_ALPHABLENDENABLE, 1);
    device:SetRenderState(D3DRS_SRCBLEND, 5);
    device:SetRenderState(D3DRS_DESTBLEND, 6);
    device:SetRenderState(D3DRS_ZENABLE, 1);
    device:SetRenderState(D3DRS_ZWRITEENABLE, 1);
    device:SetRenderState(D3DRS_ZBIAS, 8);
    device:SetRenderState(D3DRS_ALPHATESTENABLE, 0);
    device:SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_SELECTARG1);
    device:SetTextureStageState(0, D3DTSS_COLORARG1, D3DTA_TEXTURE);
    device:SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_SELECTARG1);
    device:SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_TEXTURE);
    device:SetTextureStageState(0, D3DTSS_MAGFILTER, D3DTEXF_LINEAR);
    device:SetTextureStageState(0, D3DTSS_MINFILTER, D3DTEXF_LINEAR);
    device:SetTextureStageState(0, D3DTSS_ADDRESSU, D3DTADDRESS_CLAMP);
    device:SetTextureStageState(0, D3DTSS_ADDRESSV, D3DTADDRESS_CLAMP);
    device:SetTransform(D3DTS_WORLD, identity);
end

local function FillVertex(vertex, x, y, z, u, v)
    vertex.x = x;
    vertex.y = y;
    vertex.z = z;
    vertex.color = 0xFFFFFFFF;
    vertex.tu = u;
    vertex.tv = v;
end

local function BuildRuns()
    local grouped = {
        [D3DCMP_LESSEQUAL] = {},
        [D3DCMP_ALWAYS] = {},
    };
    local skipped = {};

    for _, command in ipairs(commands) do
        local layout = layoutByToken[command.token];

        if (layout == nil) then
            -- This specific plate's texture failed to copy into the atlas
            -- (see CopyLayout). Rather than aborting the whole batched
            -- draw over one bad texture, fall back to drawing just this
            -- one plate the old way; everything else still batches.
            skipped[#skipped + 1] = command;
        else
            local zMode = command.alwaysOnTop == true and D3DCMP_ALWAYS or D3DCMP_LESSEQUAL;
            local byPage = grouped[zMode];
            local current = byPage[layout.pageIndex];

            if (current == nil) then
                current = {
                    pageIndex = layout.pageIndex,
                    zMode = zMode,
                    entries = {},
                };
                byPage[layout.pageIndex] = current;
            end

            current.entries[#current.entries + 1] = {
                command = command,
                layout = layout,
            };
        end
    end

    local runs = {};
    for _, zMode in ipairs({ D3DCMP_LESSEQUAL, D3DCMP_ALWAYS }) do
        for pageIndex = 1, #atlasPages do
            local run = grouped[zMode][pageIndex];
            if (run ~= nil and #run.entries > 0) then
                runs[#runs + 1] = run;
            end
        end
    end

    return runs, skipped;
end

local function DrawRuns(device, runs)
    lastDrawCalls = 0;

    for _, run in ipairs(runs) do
        local page = atlasPages[run.pageIndex];
        if (page == nil or page.texture == nil) then
            error('atlas-page-missing');
        end

        local vertices = ffi.new('lp_world_plate_batch_vertex_t[?]', #run.entries * 6);
        local vertexIndex = 0;

        for _, entry in ipairs(run.entries) do
            local command = entry.command;
            local layout = entry.layout;
            local halfWidth = command.width * 0.5;
            local halfHeight = command.height * 0.5;
            local leftX = command.wx - (command.rx * halfWidth);
            local leftY = command.wy - (command.ry * halfWidth);
            local leftZ = command.wz - (command.rz * halfWidth);
            local rightX = command.wx + (command.rx * halfWidth);
            local rightY = command.wy + (command.ry * halfWidth);
            local rightZ = command.wz + (command.rz * halfWidth);
            local topLeftX = leftX + (command.ux * halfHeight);
            local topLeftY = leftY + (command.uy * halfHeight);
            local topLeftZ = leftZ + (command.uz * halfHeight);
            local topRightX = rightX + (command.ux * halfHeight);
            local topRightY = rightY + (command.uy * halfHeight);
            local topRightZ = rightZ + (command.uz * halfHeight);
            local bottomLeftX = leftX - (command.ux * halfHeight);
            local bottomLeftY = leftY - (command.uy * halfHeight);
            local bottomLeftZ = leftZ - (command.uz * halfHeight);
            local bottomRightX = rightX - (command.ux * halfHeight);
            local bottomRightY = rightY - (command.uy * halfHeight);
            local bottomRightZ = rightZ - (command.uz * halfHeight);
            local u1 = (layout.x + 0.5) / ATLAS_SIZE;
            local v1 = (layout.y + 0.5) / ATLAS_SIZE;
            local u2 = (layout.x + layout.width - 0.5) / ATLAS_SIZE;
            local v2 = (layout.y + layout.height - 0.5) / ATLAS_SIZE;

            FillVertex(vertices[vertexIndex + 0], topLeftX, topLeftY, topLeftZ, u1, v1);
            FillVertex(vertices[vertexIndex + 1], topRightX, topRightY, topRightZ, u2, v1);
            FillVertex(vertices[vertexIndex + 2], bottomLeftX, bottomLeftY, bottomLeftZ, u1, v2);
            FillVertex(vertices[vertexIndex + 3], topRightX, topRightY, topRightZ, u2, v1);
            FillVertex(vertices[vertexIndex + 4], bottomRightX, bottomRightY, bottomRightZ, u2, v2);
            FillVertex(vertices[vertexIndex + 5], bottomLeftX, bottomLeftY, bottomLeftZ, u1, v2);
            vertexIndex = vertexIndex + 6;
        end

        device:SetTexture(0, ffi.cast('IDirect3DBaseTexture8*', page.texture));
        device:SetRenderState(D3DRS_ZFUNC, run.zMode);
        device:DrawPrimitiveUP(
            D3DPT_TRIANGLELIST,
            #run.entries * 2,
            vertices,
            VERTEX_SIZE
        );
        lastDrawCalls = lastDrawCalls + 1;
    end
end

function batch.Begin()
    commands = {};
    active = true;
end

function batch.Queue(textureId, info, geometry)
    if (active ~= true or textureId == nil or info == nil or geometry == nil) then
        return false;
    end

    local sourceWidth = math.floor(tonumber(info.width) or 0);
    local sourceHeight = math.floor(tonumber(info.height) or 0);

    if (sourceWidth <= 0 or sourceHeight <= 0) then
        return false;
    end

    commands[#commands + 1] = {
        token = TextureToken(textureId, info),
        textureId = tonumber(textureId),
        sourceWidth = sourceWidth,
        sourceHeight = sourceHeight,
        -- BUGFIX: origin of the meaningful content within the (possibly
        -- shared/pooled) source texture. Previously unset, which meant
        -- CopyLayout always copied from the source texture's (0,0)
        -- corner regardless of where the actual plate content lived.
        cropX = math.max(0, math.floor(tonumber(info.cropX) or 0)),
        cropY = math.max(0, math.floor(tonumber(info.cropY) or 0)),
        wx = geometry.wx,
        wy = geometry.wy,
        wz = geometry.wz,
        rx = geometry.rx,
        ry = geometry.ry,
        rz = geometry.rz,
        ux = geometry.ux,
        uy = geometry.uy,
        uz = geometry.uz,
        width = geometry.width,
        height = geometry.height,
        alwaysOnTop = geometry.alwaysOnTop == true,
    };

    return true;
end

function batch.Flush(device, suppressDraw)
    active = false;

    if (#commands < MIN_BATCH_SIZE) then
        lastStatus = 'fallback-small';
        return false, commands;
    end

    if (EnsureLayout(device) ~= true) then
        return false, commands;
    end

    if (suppressDraw == true) then
        lastStatus = 'draw-suppressed';
        lastDrawCalls = 0;
        return true, {};
    end

    local runs, skipped = BuildRuns();

    local saved, captureError = CaptureState(device);
    if (saved == nil) then
        lastStatus = 'state-capture-failed:' .. tostring(captureError);
        return false, commands;
    end

    local ok, err = pcall(function()
        ApplyState(device);
        DrawRuns(device, runs);
    end);

    RestoreState(device, saved);

    if (ok ~= true) then
        lastStatus = 'draw-failed:' .. tostring(err);
        ReleasePages();
        return false, commands;
    end

    if (#skipped > 0) then
        lastStatus = 'active-partial:' .. tostring(#skipped) .. '/' .. tostring(#commands);
    else
        lastStatus = 'active';
    end

    -- true here means "the batch pass ran"; skipped (possibly empty) is
    -- what the caller still needs to draw individually. This used to
    -- return the full `commands` list on any per-texture failure, which
    -- silently meant every plate re-drew unbatched for the whole frame
    -- over a single bad texture.
    return true, skipped;
end

function batch.GetStatus()
    return {
        status = lastStatus,
        commands = #commands,
        drawCalls = lastDrawCalls,
        atlasCopies = lastAtlasCopies,
        atlasPages = #atlasPages,
    };
end

function batch.Shutdown()
    active = false;
    commands = {};
    ReleasePages();
    lastStatus = 'shutdown';
    lastDrawCalls = 0;
    lastAtlasCopies = 0;
end

return batch;
