local textureLoader = require('core.texture_loader');

local jobIconTextures = {};
local cache = {};

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

local function NormalizeTheme(theme)
    local value = tostring(theme or 'FFXI'):gsub('[\\/]+$', ''):gsub('^.*[\\/]', '');

    if (value == '' or value == '.' or value == '..') then
        return 'FFXI';
    end

    return value;
end

function jobIconTextures.GetTextureId(jobText, theme)
    jobText = tostring(jobText or ''):lower();
    theme = NormalizeTheme(theme);

    if (jobText == '') then
        return nil;
    end

    local cacheKey = theme .. ':' .. jobText;

    if (cache[cacheKey] == false) then
        return nil;
    end

    if (cache[cacheKey] == nil) then
        local path = GetAddonPath() .. 'assets\\images\\jobs\\' .. theme .. '\\' .. jobText .. '.png';

        if (PathExists(path) == true) then
            cache[cacheKey] = textureLoader.ToTextureId(textureLoader.Load(path)) or false;
        else
            cache[cacheKey] = false;
        end
    end

    if (cache[cacheKey] == false) then
        return nil;
    end

    return cache[cacheKey];
end

function jobIconTextures.GetThemeNames()
    local themes = {};
    local seen = {};
    local root = GetAddonPath() .. 'assets\\images\\jobs\\';

    local function AddTheme(value)
        local name = tostring(value or ''):gsub('[\\/]+$', ''):gsub('^.*[\\/]', '');

        if (name == '' or name == '.' or name == '..') then
            return;
        end

        local key = name:lower();

        if (seen[key] == true) then
            return;
        end

        if (
            PathExists(root .. name .. '\\war.png') ~= true and
            PathExists(root .. name .. '\\blm.png') ~= true and
            PathExists(root .. name .. '\\whm.png') ~= true
        ) then
            return;
        end

        seen[key] = true;
        themes[#themes + 1] = name;
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
                AddTheme(entry.name or entry.Name or entry.path or entry.Path);
            else
                AddTheme(entry);
            end
        end
    end

    AddTheme('FFXI');
    table.sort(themes, function(a, b)
        if (a == 'FFXI') then return true; end
        if (b == 'FFXI') then return false; end
        return tostring(a):lower() < tostring(b):lower();
    end);

    return themes;
end

return jobIconTextures;
