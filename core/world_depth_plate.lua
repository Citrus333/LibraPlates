local ffi = require('ffi');
local d3d = require('d3d8');
local canvasDefaults = require('config.canvas');
local entities = require('core.entities');
local state = require('core.state');

local worldDepthPlate = {};
local device = d3d.get_device();

ffi.cdef[[
    typedef struct {
        float x, y, z;
        unsigned int color;
    } lp_depth_plate_vertex_t;
]];

local D3DPT_TRIANGLELIST = 4;
local D3DFVF_XYZ_DIFFUSE = 0x042;
local D3DRS_ZENABLE = 7;
local D3DRS_ZWRITEENABLE = 14;
local D3DRS_ALPHATESTENABLE = 15;
local D3DRS_SRCBLEND = 19;
local D3DRS_DESTBLEND = 20;
local D3DRS_CULLMODE = 22;
local D3DRS_ZFUNC = 23;
local D3DRS_ALPHAREF = 24;
local D3DRS_ALPHAFUNC = 25;
local D3DRS_ALPHABLENDENABLE = 27;
local D3DRS_ZBIAS = 47;
local D3DRS_LIGHTING = 137;
local D3DCMP_LESSEQUAL = 4;
local D3DTS_WORLD = 256;
local D3DTSS_COLOROP = 1;
local D3DTSS_COLORARG1 = 2;
local D3DTSS_ALPHAOP = 4;
local D3DTSS_ALPHAARG1 = 5;
local D3DTOP_SELECTARG1 = 2;
local D3DTA_DIFFUSE = 0;

local verts = ffi.new('lp_depth_plate_vertex_t[6]');
local identity = ffi.new('D3DMATRIX');
identity._11 = 1;
identity._22 = 1;
identity._33 = 1;
identity._44 = 1;

local function Clamp01(value)
    local channel = tonumber(value) or 0;

    if (channel < 0) then return 0; end
    if (channel > 1) then return 1; end

    return channel;
end

local function ColorToD3D(color)
    local value = color or { 1.0, 1.0, 1.0, 1.0 };
    local red = math.floor(Clamp01(value[1]) * 255);
    local green = math.floor(Clamp01(value[2]) * 255);
    local blue = math.floor(Clamp01(value[3]) * 255);
    local alpha = math.floor(Clamp01(value[4] or 1.0) * 255);

    return (alpha * 0x1000000) + (red * 0x10000) + (green * 0x100) + blue;
end

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

local function GetBillboardVectors()
    local _, view = device:GetTransform(2);

    if (view == nil) then
        return 1, 0, 0, 0, -1, 0, 0, 0, 0;
    end

    local rx = tonumber(view._11) or 1;
    local ry = tonumber(view._21) or 0;
    local rz = tonumber(view._31) or 0;
    local ux = tonumber(view._12) or 0;
    local uy = tonumber(view._22) or -1;
    local uz = tonumber(view._32) or 0;
    local fx = -(tonumber(view._13) or 0);
    local fy = -(tonumber(view._23) or 0);
    local fz = -(tonumber(view._33) or 0);
    local rlen = math.sqrt((rx * rx) + (ry * ry) + (rz * rz));
    local ulen = math.sqrt((ux * ux) + (uy * uy) + (uz * uz));
    local flen = math.sqrt((fx * fx) + (fy * fy) + (fz * fz));

    if (rlen > 0.001) then rx = rx / rlen; ry = ry / rlen; rz = rz / rlen; end
    if (ulen > 0.001) then ux = ux / ulen; uy = uy / ulen; uz = uz / ulen; end
    if (flen > 0.001) then fx = fx / flen; fy = fy / flen; fz = fz / flen; end

    return rx, ry, rz, ux, uy, uz, fx, fy, fz;
end

local function DrawQuad(wx, wy, wz, rx, ry, rz, ux, uy, uz, halfWidth, halfHeight, color)
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

    device:DrawPrimitiveUP(D3DPT_TRIANGLELIST, 2, verts, 16);
end

function worldDepthPlate.IsEnabled()
    return (
        state.GetWorldEnabled() == true and
        canvasDefaults.worldDepth ~= nil and
        canvasDefaults.worldDepth.enabled == true
    );
end

function worldDepthPlate.RenderSelf()
    if (worldDepthPlate.IsEnabled() ~= true) then
        return;
    end

    local center = entities.GetSelfCanvasCenter(canvasDefaults.offsetX, canvasDefaults.offsetY);

    if (center == nil or center.boneWorldX == nil or center.boneWorldY == nil or center.boneWorldZ == nil) then
        return;
    end

    if (center.visibleSkeleton ~= true) then
        return;
    end

    local settings = canvasDefaults.worldDepth;
    local background = canvasDefaults.background or {};
    local rx, ry, rz, ux, uy, uz, fx, fy, fz = GetBillboardVectors();
    local wx = center.boneWorldX + (fx * (tonumber(settings.modelDepthLift) or 0));
    local wy = center.boneWorldZ + (tonumber(settings.offsetY) or 0) + (fy * (tonumber(settings.modelDepthLift) or 0));
    local wz = center.boneWorldY + (fz * (tonumber(settings.modelDepthLift) or 0));
    local halfWidth = (tonumber(settings.width) or 0.72) * 0.5;
    local halfHeight = (tonumber(settings.height) or 0.18) * 0.5;
    local offsetX = tonumber(settings.offsetX) or 0;
    local color = ColorToD3D(background.color or { 0.02, 0.02, 0.02, 0.55 });

    wx = wx + (rx * offsetX);
    wy = wy + (ry * offsetX);
    wz = wz + (rz * offsetX);

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
    local _, saveAlphaOp = device:GetTextureStageState(0, D3DTSS_ALPHAOP);
    local _, saveAlphaArg1 = device:GetTextureStageState(0, D3DTSS_ALPHAARG1);

    local ok, err = pcall(function()
        device:SetTexture(0, nil);
        device:SetVertexShader(D3DFVF_XYZ_DIFFUSE);
        device:SetPixelShader(0);
        device:SetRenderState(D3DRS_LIGHTING, 0);
        device:SetRenderState(D3DRS_CULLMODE, 1);
        device:SetRenderState(D3DRS_ALPHABLENDENABLE, 1);
        device:SetRenderState(D3DRS_SRCBLEND, 5);
        device:SetRenderState(D3DRS_DESTBLEND, 6);
        device:SetRenderState(D3DRS_ZENABLE, 1);
        device:SetRenderState(D3DRS_ZWRITEENABLE, 0);
        device:SetRenderState(D3DRS_ZFUNC, D3DCMP_LESSEQUAL);
        device:SetRenderState(D3DRS_ZBIAS, 8);
        device:SetRenderState(D3DRS_ALPHATESTENABLE, 0);
        device:SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_SELECTARG1);
        device:SetTextureStageState(0, D3DTSS_COLORARG1, D3DTA_DIFFUSE);
        device:SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_SELECTARG1);
        device:SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_DIFFUSE);
        device:SetTransform(D3DTS_WORLD, identity);

        DrawQuad(wx, wy, wz, rx, ry, rz, ux, uy, uz, halfWidth, halfHeight, color);
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
    device:SetRenderState(D3DRS_ALPHAREF, saveAlphaRef);
    device:SetRenderState(D3DRS_ALPHAFUNC, saveAlphaFunc);
    device:SetVertexShader(saveFvf);

    if (savePixelShader ~= nil) then
        device:SetPixelShader(savePixelShader);
    end

    device:SetTextureStageState(0, D3DTSS_COLOROP, saveColorOp);
    device:SetTextureStageState(0, D3DTSS_COLORARG1, saveColorArg1);
    device:SetTextureStageState(0, D3DTSS_ALPHAOP, saveAlphaOp);
    device:SetTextureStageState(0, D3DTSS_ALPHAARG1, saveAlphaArg1);

    if (ok ~= true) then
        error(err);
    end
end

return worldDepthPlate;
