local d3d8 = require('d3d8');
local ffi = require('ffi');
local textureLoader = require('core.texture_loader');
local state = require('core.state');
local globalDefaults = require('config.global');

local statusIconTextures = {};
local cache = {};
local device = d3d8.get_device();
local packCache = nil;

local function PathExists(path)
    local ok, exists = pcall(function()
        return ashita.fs.exists(path);
    end);

    return ok == true and exists == true;
end

local function GetAddonPath()
    local installPath = tostring(AshitaCore:GetInstallPath() or '');
    local separator = installPath:sub(-1) == '\\' and '' or '\\';

    return installPath .. separator .. 'addons\\LibraPlates\\';
end

function statusIconTextures.GetPackFolderPath()
    return GetAddonPath() .. 'assets\\images\\status';
end

function statusIconTextures.OpenPackFolder()
    os.execute('start "" "' .. statusIconTextures.GetPackFolderPath() .. '"');
end

local function NormalizePack(iconPack)
    local pack = tostring(iconPack or 'Native');

    if (pack == '' or pack:lower() == 'native') then
        return 'Native';
    end

    return pack;
end

local function ScanLocalPacks()
    local packs = {};
    local root = GetAddonPath() .. 'assets\\images\\status\\';
    local seen = {};

    local function AddPack(value)
        local name = tostring(value or ''):gsub('[\\/]+$', ''):gsub('^.*[\\/]', '');

        if (name == '' or name == '.' or name == '..' or name:lower() == 'native') then
            return;
        end

        local key = name:lower();

        if (seen[key] == true) then
            return;
        end

        if (PathExists(root .. name .. '\\0.png') ~= true and PathExists(root .. name .. '\\1.png') ~= true) then
            return;
        end

        seen[key] = true;
        packs[#packs + 1] = name;
    end

    local ok, entries = pcall(function()
        if (ashita.fs.get_directory ~= nil) then
            return ashita.fs.get_directory(root, '.*');
        end

        if (ashita.fs.get_dir ~= nil) then
            return ashita.fs.get_dir(root, '.*');
        end

        return nil;
    end);

    if (ok == true and type(entries) == 'table') then
        for _, entry in ipairs(entries) do
            if (type(entry) == 'table') then
                AddPack(entry.name or entry.Name or entry.path or entry.Path);
            else
                AddPack(entry);
            end
        end
    end

    for _, name in ipairs({ 'HD', 'Tetsouou', 'xiPrime', 'XIView' }) do
        AddPack(name);
    end

    table.sort(packs, function(a, b)
        return tostring(a):lower() < tostring(b):lower();
    end);

    return packs;
end

local function GetLocalPacks()
    if (packCache == nil) then
        packCache = ScanLocalPacks();
    end

    return packCache;
end

local function GetPreferredLocalPack()
    local packs = GetLocalPacks();
    local preferred = { 'XIView', 'Tetsouou', 'xiPrime', 'HD' };

    for _, name in ipairs(preferred) do
        for _, pack in ipairs(packs) do
            if (tostring(pack):lower() == name:lower()) then
                return pack;
            end
        end
    end

    return packs[1];
end

local function ResolvePack(iconPack)
    local pack = NormalizePack(iconPack);

    if (pack == 'Native') then
        return GetPreferredLocalPack() or 'Native';
    end

    return pack;
end

local function GetGlobalPack()
    local global = state.GetGlobalSettings(globalDefaults);
    local statusIcons = global ~= nil and global.statusIcons or nil;

    return ResolvePack(statusIcons ~= nil and statusIcons.iconPack or globalDefaults.statusIcons.iconPack);
end

local function LoadFromPack(statusId, iconPack)
    iconPack = NormalizePack(iconPack);

    if (iconPack == 'Native') then
        return nil;
    end

    local path = GetAddonPath() .. 'assets\\images\\status\\' .. iconPack .. '\\' .. tostring(statusId) .. '.png';

    if (PathExists(path) ~= true) then
        return nil;
    end

    return textureLoader.Load(path);
end

local function LoadFromResource(statusId)
    statusId = tonumber(statusId) or 0;

    if (statusId <= 0 or statusId > 0x3FF or device == nil) then
        return nil;
    end

    local ok, texture = pcall(function()
        local icon = AshitaCore:GetResourceManager():GetStatusIconByIndex(statusId);

        if (icon == nil) then
            return nil;
        end

        local ptr = ffi.new('IDirect3DTexture8*[1]');

        if (ffi.C.D3DXCreateTextureFromFileInMemoryEx(
            device,
            icon.Bitmap,
            icon.ImageSize,
            0xFFFFFFFF,
            0xFFFFFFFF,
            1,
            0,
            ffi.C.D3DFMT_A8R8G8B8,
            ffi.C.D3DPOOL_MANAGED,
            ffi.C.D3DX_DEFAULT,
            ffi.C.D3DX_DEFAULT,
            0xFF000000,
            nil,
            nil,
            ptr
        ) == ffi.C.S_OK) then
            return d3d8.gc_safe_release(ffi.cast('IDirect3DTexture8*', ptr[0]));
        end

        return nil;
    end);

    if (ok ~= true) then
        return nil;
    end

    return texture;
end

function statusIconTextures.GetTextureId(statusId, iconPack)
    statusId = tonumber(statusId) or 0;
    iconPack = GetGlobalPack();

    if (statusId <= 0) then
        return nil;
    end

    local cacheKey = iconPack .. ':' .. tostring(statusId);

    if (cache[cacheKey] == false) then
        return nil;
    end

    if (cache[cacheKey] == nil) then
        cache[cacheKey] = LoadFromPack(statusId, iconPack) or LoadFromResource(statusId) or false;
    end

    if (cache[cacheKey] == false) then
        return nil;
    end

    return tonumber(ffi.cast('uint32_t', cache[cacheKey]));
end

function statusIconTextures.GetPackNames()
    local packs = {};
    local seen = {};

    local function AddPack(value)
        local name = tostring(value or ''):gsub('[\\/]+$', ''):gsub('^.*[\\/]', '');

        if (name == '' or name == '.' or name == '..') then
            return;
        end

        local key = name:lower();

        if (seen[key] == true) then
            return;
        end

        seen[key] = true;
        packs[#packs + 1] = name;
    end

    for _, pack in ipairs(GetLocalPacks()) do
        AddPack(pack);
    end

    table.sort(packs, function(a, b)
        return tostring(a):lower() < tostring(b):lower();
    end);

    return packs;
end

function statusIconTextures.GetDefaultPackName()
    return GetPreferredLocalPack() or 'Native';
end

function statusIconTextures.ResolvePackName(iconPack)
    return ResolvePack(iconPack);
end

return statusIconTextures;
