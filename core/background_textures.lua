local textureLoader = require('core.texture_loader');

local backgroundTextures = {};
local textureIds = {};
local filesCache = nil;

local function GetAddonPath()
    local ok, path = pcall(function()
        return AshitaCore:GetInstallPath() .. '\\addons\\LibraPlates\\';
    end);

    if (ok == true and path ~= nil) then
        return tostring(path);
    end

    return '.\\';
end

local function AddFile(files, name)
    name = tostring(name or ''):gsub('^.*[\\/]', '');

    if (name == '' or string.lower(name):match('%.png$') == nil) then
        return;
    end

    for _, existing in ipairs(files) do
        if (existing == name) then
            return;
        end
    end

    files[#files + 1] = name;
end

function backgroundTextures.GetFolderPath()
    return GetAddonPath() .. 'assets\\images\\backgrounds\\';
end

function backgroundTextures.GetFiles()
    if (filesCache ~= nil) then
        return filesCache;
    end

    local files = T{ 'None' };
    local folder = backgroundTextures.GetFolderPath();
    local pipe = io.popen('dir /b "' .. folder .. '*.png" 2>nul');

    if (pipe ~= nil) then
        for line in pipe:lines() do
            AddFile(files, line);
        end

        pipe:close();
    end

    table.sort(files, function(a, b)
        if (a == 'None') then return true; end
        if (b == 'None') then return false; end
        return string.lower(tostring(a)) < string.lower(tostring(b));
    end);

    filesCache = files;
    return filesCache;
end

function backgroundTextures.GetTextureId(fileName)
    fileName = tostring(fileName or 'None'):gsub('^.*[\\/]', '');

    if (fileName == '' or fileName == 'None') then
        return nil;
    end

    local key = 'backgrounds/' .. fileName;

    if (textureIds[key] ~= nil) then
        return textureIds[key];
    end

    textureIds[key] = textureLoader.ToTextureId(textureLoader.Load(
        GetAddonPath() .. 'assets\\images\\backgrounds\\' .. fileName
    ));

    return textureIds[key];
end

return backgroundTextures;
