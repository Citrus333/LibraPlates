local textureLoader = require('core.texture_loader');

local enmityIcons = {};
local textureIds = {};
local filesCache = nil;
local fallbackFiles = T{
    'eye-focus.png',
    'heart-crosshair.png',
    'heart-slash-crosshair.png',
    'heart-slash.png',
    'shield-alert.png',
    'warning-dimond.png',
};

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

function enmityIcons.GetFolderPath()
    return GetAddonPath() .. 'assets\\images\\enmity\\';
end

function enmityIcons.GetFiles()
    if (filesCache ~= nil) then
        return filesCache;
    end

    local files = T{};
    local folder = enmityIcons.GetFolderPath();
    local pipe = io.popen('dir /b "' .. folder .. '*.png" 2>nul');

    if (pipe ~= nil) then
        for line in pipe:lines() do
            AddFile(files, line);
        end

        pipe:close();
    end

    for _, fileName in ipairs(fallbackFiles) do
        AddFile(files, fileName);
    end

    table.sort(files, function(a, b)
        return string.lower(tostring(a)) < string.lower(tostring(b));
    end);

    filesCache = files;
    return filesCache;
end

function enmityIcons.ResolveFile(fileName, fallback)
    fileName = tostring(fileName or ''):gsub('^.*[\\/]', '');
    fallback = tostring(fallback or 'warning-dimond.png');

    for _, known in ipairs(enmityIcons.GetFiles()) do
        if (fileName == known) then
            return fileName;
        end
    end

    return fallback;
end

function enmityIcons.GetTextureId(fileName)
    fileName = enmityIcons.ResolveFile(fileName);

    if (textureIds[fileName] ~= nil) then
        return textureIds[fileName];
    end

    textureIds[fileName] = textureLoader.ToTextureId(textureLoader.Load(
        GetAddonPath() .. 'assets\\images\\enmity\\' .. fileName
    ));

    return textureIds[fileName];
end

return enmityIcons;
