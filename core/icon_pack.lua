local state = require('core.state');
local globalDefaults = require('config.global');

local iconPack = {};
local packNamesCache = nil;
local revision = 0;
local activePackName = nil;

local function GetAddonPath()
    local ok, path = pcall(function()
        return AshitaCore:GetInstallPath() .. '\\addons\\LibraPlates\\';
    end);

    if (ok == true and path ~= nil) then
        return tostring(path);
    end

    return '.\\';
end

local function PathExists(path)
    local ok, exists = pcall(function()
        return ashita.fs.exists(path) == true;
    end);

    return ok == true and exists == true;
end

local function NormalizePackName(value)
    local name = tostring(value or 'Built-in'):gsub('[\\/]+$', ''):gsub('^.*[\\/]', '');

    if (name == '' or name:lower() == 'built-in' or name:lower() == 'builtin') then
        return 'Built-in';
    end

    return name;
end

local function NormalizeRelativePath(value)
    return tostring(value or ''):gsub('/', '\\'):gsub('^[\\]+', '');
end

function iconPack.GetName()
    local global = state.GetGlobalSettings(globalDefaults);
    local selected = NormalizePackName(global ~= nil and global.assetIconPack or globalDefaults.assetIconPack);

    if (activePackName ~= selected) then
        activePackName = selected;
        revision = revision + 1;
    end

    return selected;
end

function iconPack.GetRevision()
    iconPack.GetName();
    return revision;
end

function iconPack.Invalidate()
    revision = revision + 1;
    activePackName = nil;
end

function iconPack.GetBuiltInRoot()
    return GetAddonPath() .. 'assets\\images\\';
end

function iconPack.GetPackRoot(packName)
    return iconPack.GetBuiltInRoot() .. 'packs\\' .. NormalizePackName(packName) .. '\\';
end

function iconPack.GetAssetPath(category, relativePath)
    category = NormalizeRelativePath(category):gsub('[\\]+$', '');
    relativePath = NormalizeRelativePath(relativePath);

    local builtInPath = iconPack.GetBuiltInRoot() .. category .. '\\' .. relativePath;
    local selectedPack = iconPack.GetName();

    if (selectedPack == 'Built-in' or category == '' or relativePath == '') then
        return builtInPath;
    end

    local packedPath = iconPack.GetPackRoot(selectedPack) .. category .. '\\' .. relativePath;

    if (PathExists(packedPath) == true) then
        return packedPath;
    end

    return builtInPath;
end

function iconPack.GetPackNames()
    if (packNamesCache ~= nil) then
        return packNamesCache;
    end

    local names = { 'Built-in' };
    local seen = { ['built-in'] = true };
    local root = iconPack.GetBuiltInRoot() .. 'packs\\';
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
            local rawName = type(entry) == 'table' and (entry.name or entry.Name or entry.path or entry.Path) or entry;
            local name = NormalizePackName(rawName);
            local key = name:lower();

            if (name ~= 'Built-in' and seen[key] ~= true) then
                seen[key] = true;
                names[#names + 1] = name;
            end
        end
    end

    table.sort(names, function(a, b)
        if (a == 'Built-in') then return true; end
        if (b == 'Built-in') then return false; end
        return tostring(a):lower() < tostring(b):lower();
    end);

    packNamesCache = names;
    return packNamesCache;
end

return iconPack;
