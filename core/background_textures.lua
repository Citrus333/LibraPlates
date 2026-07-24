local textureLoader = require('core.texture_loader');

local backgroundTextures = {};
local textureIds = {};
local filesCache = nil;
local avatarArtworkTextureIds = {};
local avatarArtworkFilesCache = nil;
local pupArtworkTextureIds = {};
local pupEquipmentArtworkTextureIds = {};
local pupElementTextureIds = {};

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

-- Avatar frame artwork is intentionally kept outside the generic backgrounds
-- folder.  It must never appear in a normal plate Background image picker.
function backgroundTextures.GetAvatarArtworkFolderPath()
    return GetAddonPath() .. 'assets\\images\\pet\\smn\\detached\\';
end

function backgroundTextures.GetPupArtworkFolderPath()
    return GetAddonPath() .. 'assets\\images\\pet\\pup\\detached\\';
end

function backgroundTextures.GetPupEquipmentArtworkFolderPath(layer)
    layer = string.lower(tostring(layer or ''));
    if (layer ~= 'heads' and layer ~= 'frames') then
        return nil;
    end

    return backgroundTextures.GetPupArtworkFolderPath() .. layer .. '\\';
end

function backgroundTextures.GetPupElementArtworkFolderPath()
    return backgroundTextures.GetPupArtworkFolderPath() .. 'elements\\';
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

function backgroundTextures.GetAvatarArtworkFiles()
    if (avatarArtworkFilesCache ~= nil) then
        return avatarArtworkFilesCache;
    end

    local files = T{};
    local folder = backgroundTextures.GetAvatarArtworkFolderPath();
    local pipe = io.popen('dir /b "' .. folder .. '*.png" 2>nul');

    if (pipe ~= nil) then
        for line in pipe:lines() do
            AddFile(files, line);
        end

        pipe:close();
    end

    table.sort(files, function(a, b)
        return string.lower(tostring(a)) < string.lower(tostring(b));
    end);

    avatarArtworkFilesCache = files;
    return avatarArtworkFilesCache;
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

function backgroundTextures.GetAvatarArtworkTextureId(fileName)
    fileName = tostring(fileName or ''):gsub('^.*[\\/]', '');

    if (fileName == '') then
        return nil;
    end

    local key = 'pet/smn/detached/' .. fileName;
    if (avatarArtworkTextureIds[key] ~= nil) then
        return avatarArtworkTextureIds[key];
    end

    avatarArtworkTextureIds[key] = textureLoader.ToTextureId(textureLoader.LoadPreserveAlpha(
        backgroundTextures.GetAvatarArtworkFolderPath() .. fileName
    ));

    return avatarArtworkTextureIds[key];
end

function backgroundTextures.GetPupArtworkTextureId(fileName)
    fileName = tostring(fileName or ''):gsub('^.*[\\/]', '');

    if (fileName == '') then
        return nil;
    end

    local key = 'pet/pup/detached/' .. fileName;
    if (pupArtworkTextureIds[key] ~= nil) then
        return pupArtworkTextureIds[key];
    end

    pupArtworkTextureIds[key] = textureLoader.ToTextureId(textureLoader.LoadPreserveAlpha(
        backgroundTextures.GetPupArtworkFolderPath() .. fileName
    ));

    return pupArtworkTextureIds[key];
end

function backgroundTextures.GetPupEquipmentArtworkTextureId(layer, fileName)
    layer = string.lower(tostring(layer or ''));
    fileName = tostring(fileName or ''):gsub('^.*[\\/]', '');

    local folder = backgroundTextures.GetPupEquipmentArtworkFolderPath(layer);
    if (folder == nil or fileName == '') then
        return nil;
    end

    local key = 'pet/pup/detached/' .. layer .. '/' .. fileName;
    if (pupEquipmentArtworkTextureIds[key] ~= nil) then
        return pupEquipmentArtworkTextureIds[key] ~= false
            and pupEquipmentArtworkTextureIds[key]
            or nil;
    end

    local textureId = textureLoader.ToTextureId(
        textureLoader.LoadPreserveAlpha(folder .. fileName)
    );
    pupEquipmentArtworkTextureIds[key] = textureId or false;
    return textureId;
end

function backgroundTextures.GetPupElementArtworkTextureId(fileName)
    fileName = tostring(fileName or ''):gsub('^.*[\\/]', '');
    if (fileName == '') then
        return nil;
    end

    local key = 'pet/pup/detached/elements/' .. fileName;
    if (pupElementTextureIds[key] ~= nil) then
        return pupElementTextureIds[key] ~= false
            and pupElementTextureIds[key]
            or nil;
    end

    local textureId = textureLoader.ToTextureId(textureLoader.LoadPreserveAlpha(
        backgroundTextures.GetPupElementArtworkFolderPath() .. fileName
    ));
    pupElementTextureIds[key] = textureId or false;
    return textureId;
end

return backgroundTextures;
