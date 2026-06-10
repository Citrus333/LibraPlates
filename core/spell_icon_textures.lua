local ffi = require('ffi');
local textureLoader = require('core.texture_loader');

local spellIconTextures = {};

local function GetAddonPath()
    local installPath = tostring(AshitaCore:GetInstallPath() or '');
    local separator = installPath:sub(-1) == '\\' and '' or '\\';

    return installPath .. separator .. 'addons\\LibraPlates\\';
end

function spellIconTextures.GetTextureId(spellIconId)
    spellIconId = tonumber(spellIconId) or 0;

    if (spellIconId <= 0) then
        return nil;
    end

    local path = GetAddonPath() .. 'assets\\images\\spells\\default\\' .. tostring(spellIconId) .. '.png';
    local texture = textureLoader.Load(path);

    if (texture == nil) then
        return nil;
    end

    return tonumber(ffi.cast('uint32_t', texture));
end

return spellIconTextures;
