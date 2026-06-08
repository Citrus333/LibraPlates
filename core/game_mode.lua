local textureLoader = require('core.texture_loader');

local gameMode = {};
local textureCache = {};

local function Band(left, right)
    if (bit ~= nil and bit.band ~= nil) then
        return bit.band(left, right);
    end

    return 0;
end

function gameMode.Resolve(targetIndex, isTrust)
    if (targetIndex == nil or isTrust == true) then
        return '';
    end

    local entityManager = AshitaCore:GetMemoryManager():GetEntity();

    if (entityManager == nil) then
        return '';
    end

    local renderFlags1 = gameMode.ReadRenderFlag(targetIndex, 1);
    local renderFlags4 = gameMode.ReadRenderFlag(targetIndex, 4);
    local hasWewBit = (Band(renderFlags1, 0x02000000) ~= 0 and Band(renderFlags4, 0x00004000) ~= 0);
    local hasUcwBit = (Band(renderFlags1, 0x04000000) ~= 0);
    local hasCwBit = (Band(renderFlags4, 0x00001000) ~= 0);

    if (hasWewBit == true) then
        return 'WEW';
    end

    if (hasUcwBit == true) then
        return 'UCW';
    end

    if (hasCwBit == true) then
        return 'CW';
    end

    return 'ACE';
end

function gameMode.ReadRenderFlag(targetIndex, flagIndex)
    local entityManager = AshitaCore:GetMemoryManager():GetEntity();

    if (entityManager == nil or targetIndex == nil) then
        return 0;
    end

    local methodName = 'GetRenderFlags' .. tostring(flagIndex);

    if (entityManager[methodName] == nil) then
        return 0;
    end

    local ok, value = pcall(function()
        return entityManager[methodName](entityManager, targetIndex);
    end);

    if (ok ~= true) then
        return 0;
    end

    return tonumber(value) or 0;
end

function gameMode.GetIconTextureId(modeText)
    local key = string.lower(tostring(modeText or ''));

    if (key == '') then
        return nil;
    end

    if (textureCache[key] ~= nil) then
        return textureCache[key];
    end

    local path = AshitaCore:GetInstallPath() .. '\\addons\\LibraPlates\\assets\\images\\widget-icons\\' .. key .. '.png';
    local texture = textureLoader.Load(path);
    local textureId = textureLoader.ToTextureId(texture);

    textureCache[key] = textureId;
    return textureId;
end

return gameMode;
