local ffi = require('ffi');
local textureLoader = require('core.texture_loader');
local statusIconTextures = require('core.status_icon_textures');
local spellStatusIds = require('data.spell_status_ids');

local spellIconTextures = {};
local missing = {};
local indiSpellStatusIds = {
    [768] = 539,
    [769] = 540,
    [770] = 541,
    [771] = 542,
    [772] = 543,
    [773] = 544,
    [774] = 545,
    [775] = 546,
    [776] = 547,
    [777] = 548,
    [778] = 549,
    [779] = 550,
    [780] = 551,
    [781] = 552,
    [782] = 553,
    [783] = 554,
    [784] = 555,
    [785] = 556,
    [786] = 557,
    [787] = 558,
    [788] = 559,
    [789] = 560,
    [790] = 561,
    [791] = 562,
    [792] = 563,
    [793] = 564,
    [794] = 565,
    [795] = 566,
    [796] = 567,
    [797] = 568,
    [798] = 539,
    [799] = 540,
    [800] = 541,
    [801] = 542,
    [802] = 543,
    [803] = 544,
    [804] = 545,
    [805] = 546,
    [806] = 547,
    [807] = 548,
    [808] = 549,
    [809] = 550,
    [810] = 551,
    [811] = 552,
    [812] = 553,
    [813] = 554,
    [814] = 555,
    [815] = 556,
    [816] = 557,
    [817] = 558,
    [818] = 559,
    [819] = 560,
    [820] = 561,
    [821] = 562,
    [822] = 563,
    [823] = 564,
    [824] = 565,
    [825] = 566,
    [826] = 567,
    [827] = 568,
};

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
    if (missing[path] == true) then
        return nil;
    end

    local texture = textureLoader.Load(path);

    if (texture == nil) then
        missing[path] = true;
        return nil;
    end

    return tonumber(ffi.cast('uint32_t', texture));
end

function spellIconTextures.GetStatusId(spellId)
    spellId = tonumber(spellId) or 0;

    if (spellId <= 0) then
        return nil;
    end

    return spellStatusIds[spellId] or indiSpellStatusIds[spellId];
end

function spellIconTextures.GetStatusTextureId(spellId)
    local statusId = spellIconTextures.GetStatusId(spellId);

    if (statusId == nil) then
        return nil;
    end

    return statusIconTextures.GetTextureId(statusId);
end

function spellIconTextures.GetGeoTextureId(spellId)
    return spellIconTextures.GetStatusTextureId(spellId);
end

return spellIconTextures;
