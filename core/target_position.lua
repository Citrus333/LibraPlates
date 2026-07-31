local d3d = require('d3d8');
local ffi = require('ffi');
local C = ffi.C;
local entities = require('core.entities');

local targetPosition = {};

local device = d3d.get_device();

local function MatrixMultiply(m1, m2)
    return ffi.new('D3DXMATRIX', {
        m1._11 * m2._11 + m1._12 * m2._21 + m1._13 * m2._31 + m1._14 * m2._41,
        m1._11 * m2._12 + m1._12 * m2._22 + m1._13 * m2._32 + m1._14 * m2._42,
        m1._11 * m2._13 + m1._12 * m2._23 + m1._13 * m2._33 + m1._14 * m2._43,
        m1._11 * m2._14 + m1._12 * m2._24 + m1._13 * m2._34 + m1._14 * m2._44,
        m1._21 * m2._11 + m1._22 * m2._21 + m1._23 * m2._31 + m1._24 * m2._41,
        m1._21 * m2._12 + m1._22 * m2._22 + m1._23 * m2._32 + m1._24 * m2._42,
        m1._21 * m2._13 + m1._22 * m2._23 + m1._23 * m2._33 + m1._24 * m2._43,
        m1._21 * m2._14 + m1._22 * m2._24 + m1._23 * m2._34 + m1._24 * m2._44,
        m1._31 * m2._11 + m1._32 * m2._21 + m1._33 * m2._31 + m1._34 * m2._41,
        m1._31 * m2._12 + m1._32 * m2._22 + m1._33 * m2._32 + m1._34 * m2._42,
        m1._31 * m2._13 + m1._32 * m2._23 + m1._33 * m2._33 + m1._34 * m2._43,
        m1._31 * m2._14 + m1._32 * m2._24 + m1._33 * m2._34 + m1._34 * m2._44,
        m1._41 * m2._11 + m1._42 * m2._21 + m1._43 * m2._31 + m1._44 * m2._41,
        m1._41 * m2._12 + m1._42 * m2._22 + m1._43 * m2._32 + m1._44 * m2._42,
        m1._41 * m2._13 + m1._42 * m2._23 + m1._43 * m2._33 + m1._44 * m2._43,
        m1._41 * m2._14 + m1._42 * m2._24 + m1._43 * m2._34 + m1._44 * m2._44,
    });
end

local function Vec4Transform(v, m)
    return ffi.new('D3DXVECTOR4', {
        m._11 * v.x + m._21 * v.y + m._31 * v.z + m._41 * v.w,
        m._12 * v.x + m._22 * v.y + m._32 * v.z + m._42 * v.w,
        m._13 * v.x + m._23 * v.y + m._33 * v.z + m._43 * v.w,
        m._14 * v.x + m._24 * v.y + m._34 * v.z + m._44 * v.w,
    });
end

local function WorldToScreen(x, y, z)
    if (device == nil) then
        return nil, nil, nil;
    end

    local _, viewport = device:GetViewport();
    local _, view = device:GetTransform(C.D3DTS_VIEW);
    local _, projection = device:GetTransform(C.D3DTS_PROJECTION);

    if (viewport == nil or view == nil or projection == nil) then
        return nil, nil, nil;
    end

    local vector = ffi.new('D3DXVECTOR4', { x, y, z, 1 });
    local camera = Vec4Transform(vector, MatrixMultiply(view, projection));

    if (camera.w == nil or math.abs(camera.w) < 0.0001) then
        return nil, nil, nil;
    end

    local rhw = 1 / camera.w;
    local ndcX = camera.x * rhw;
    local ndcY = camera.y * rhw;
    local ndcZ = camera.z * rhw;

    return
        math.floor((ndcX + 1) * 0.5 * viewport.Width),
        math.floor((1 - ndcY) * 0.5 * viewport.Height),
        ndcZ;
end

local function CallNumber(fn)
    local ok, value = pcall(fn);

    if (ok ~= true) then
        return nil;
    end

    return tonumber(value);
end

function targetPosition.Resolve(index)
    index = tonumber(index);

    if (index == nil or index == 0) then
        return nil;
    end

    local entityManager = AshitaCore:GetMemoryManager():GetEntity();

    if (entityManager == nil) then
        return nil;
    end

    local entityType = CallNumber(function() return entityManager:GetType(index); end) or 0;
    local renderFlags = CallNumber(function() return entityManager:GetRenderFlags0(index); end) or 0;
    local wx = nil;
    local wy = nil;
    local wz = nil;
    local source = 'none';

    if (entityType == 3) then
        wx = CallNumber(function() return entityManager:GetLocalPositionX(index); end);
        wy = CallNumber(function() return entityManager:GetLocalPositionY(index); end);
        wz = CallNumber(function() return entityManager:GetLocalPositionZ(index); end);
        source = 'local';
    elseif (renderFlags == 0 and entityType == 0) then
        wx = CallNumber(function() return entityManager:GetLastPositionX(index); end);
        wy = CallNumber(function() return entityManager:GetLastPositionY(index); end);
        wz = CallNumber(function() return entityManager:GetLastPositionZ(index); end);
        source = 'last';
    else
        local actorPointer = CallNumber(function() return entityManager:GetActorPointer(index); end);

        if (actorPointer ~= nil and actorPointer ~= 0) then
            local ok, bx, by, bz = pcall(function()
                return entities.GetBone(actorPointer, 2);
            end);

            if (ok == true) then
                wx = tonumber(bx);
                wy = tonumber(by);
                wz = tonumber(bz);
                source = 'bone';
            end
        end

        if (wx == nil or wy == nil or wz == nil) then
            wx = CallNumber(function() return entityManager:GetLastPositionX(index); end);
            wy = CallNumber(function() return entityManager:GetLastPositionY(index); end);
            wz = CallNumber(function() return entityManager:GetLastPositionZ(index); end);
            source = 'last-fallback';
        end
    end

    if (wx == nil or wy == nil or wz == nil) then
        return nil;
    end

    local screenX, screenY, screenZ = WorldToScreen(wx, wz, wy);

    if (screenX == nil or screenY == nil or screenZ == nil) then
        return nil;
    end

    return {
        x = screenX,
        y = screenY,
        z = screenZ,
        source = source,
        entityType = entityType,
        renderFlags = renderFlags,
    };
end

function targetPosition.RefreshDevice()
    device = d3d.get_device();
    return device ~= nil;
end

function targetPosition.ResetDevice()
    device = nil;
end

return targetPosition;
