local textureLoader = require('core.texture_loader');

local backgroundTextures = {};
local textureIds = {};
local filesCache = nil;
local avatarArtworkFilesCache = nil;
local artworkEntries = {};
local artworkDecodedBytes = 0;
local artworkDecodedByteLimit = 64 * 1024 * 1024;

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

function backgroundTextures.GetDrgArtworkFolderPath()
    return GetAddonPath() .. 'assets\\images\\pet\\drg\\';
end

function backgroundTextures.GetBstArtworkFolderPath()
    return GetAddonPath() .. 'assets\\images\\pet\\bst\\';
end

function backgroundTextures.GetGeoArtworkFolderPath()
    return GetAddonPath() .. 'assets\\images\\pet\\geo\\';
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

local function EvictUnusedArtwork(currentKey)
    while artworkDecodedBytes > artworkDecodedByteLimit do
        local oldestKey = nil;
        local oldestUsed = nil;

        for key, entry in pairs(artworkEntries) do
            local lastUsed = tonumber(entry ~= nil and entry.lastUsed) or 0;

            if key ~= currentKey and (oldestUsed == nil or lastUsed < oldestUsed) then
                oldestKey = key;
                oldestUsed = lastUsed;
            end
        end

        if (oldestKey == nil) then
            break;
        end

        local entry = artworkEntries[oldestKey];
        artworkEntries[oldestKey] = nil;
        artworkDecodedBytes = math.max(
            0,
            artworkDecodedBytes - math.max(0, tonumber(entry ~= nil and entry.decodedBytes) or 0)
        );

        if (entry ~= nil and entry.path ~= nil) then
            textureLoader.Release(entry.path, true);
        end
    end
end

local function GetArtworkTextureId(key, path)
    key = tostring(key or '');
    path = tostring(path or '');

    if (key == '' or path == '') then
        return nil;
    end

    local texture = textureLoader.LoadPreserveAlpha(path);

    if (texture == nil) then
        return nil;
    end

    local decodedBytes = textureLoader.GetDecodedBytes(path, true);
    local entry = artworkEntries[key];

    if (entry == nil) then
        entry = {};
        artworkEntries[key] = entry;
        artworkDecodedBytes = artworkDecodedBytes + decodedBytes;
    elseif (tonumber(entry.decodedBytes) or 0) ~= decodedBytes then
        artworkDecodedBytes = math.max(
            0,
            artworkDecodedBytes - math.max(0, tonumber(entry.decodedBytes) or 0) + decodedBytes
        );
    end

    entry.path = path;
    entry.decodedBytes = decodedBytes;
    entry.lastUsed = os.clock();
    EvictUnusedArtwork(key);
    return textureLoader.ToTextureId(texture);
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
    return GetArtworkTextureId(key,
        backgroundTextures.GetAvatarArtworkFolderPath() .. fileName
    );
end

function backgroundTextures.GetPupArtworkTextureId(fileName)
    fileName = tostring(fileName or ''):gsub('^.*[\\/]', '');

    if (fileName == '') then
        return nil;
    end

    local key = 'pet/pup/detached/' .. fileName;
    return GetArtworkTextureId(key,
        backgroundTextures.GetPupArtworkFolderPath() .. fileName
    );
end

function backgroundTextures.GetDrgArtworkTextureId(fileName)
    fileName = tostring(fileName or ''):gsub('^.*[\\/]', '');

    if (fileName == '') then
        return nil;
    end

    local key = 'pet/drg/' .. fileName;
    return GetArtworkTextureId(key,
        backgroundTextures.GetDrgArtworkFolderPath() .. fileName
    );
end

function backgroundTextures.GetBstArtworkTextureId(fileName)
    fileName = tostring(fileName or ''):gsub('^.*[\\/]', '');

    if (fileName == '') then
        return nil;
    end

    local key = 'pet/bst/' .. fileName;
    return GetArtworkTextureId(key,
        backgroundTextures.GetBstArtworkFolderPath() .. fileName
    );
end

function backgroundTextures.GetGeoArtworkTextureId(fileName)
    fileName = tostring(fileName or ''):gsub('^.*[\\/]', '');

    if (fileName == '') then
        return nil;
    end

    local key = 'pet/geo/' .. fileName;
    return GetArtworkTextureId(key,
        backgroundTextures.GetGeoArtworkFolderPath() .. fileName
    );
end

function backgroundTextures.GetPupEquipmentArtworkTextureId(layer, fileName)
    layer = string.lower(tostring(layer or ''));
    fileName = tostring(fileName or ''):gsub('^.*[\\/]', '');

    local folder = backgroundTextures.GetPupEquipmentArtworkFolderPath(layer);
    if (folder == nil or fileName == '') then
        return nil;
    end

    local key = 'pet/pup/detached/' .. layer .. '/' .. fileName;
    return GetArtworkTextureId(key, folder .. fileName);
end

function backgroundTextures.GetPupElementArtworkTextureId(fileName)
    fileName = tostring(fileName or ''):gsub('^.*[\\/]', '');
    if (fileName == '') then
        return nil;
    end

    local key = 'pet/pup/detached/elements/' .. fileName;
    return GetArtworkTextureId(key,
        backgroundTextures.GetPupElementArtworkFolderPath() .. fileName
    );
end

function backgroundTextures.GetArtworkCacheStats()
    local count = 0;

    for _ in pairs(artworkEntries) do
        count = count + 1;
    end

    return {
        count = count,
        decodedBytes = artworkDecodedBytes,
        decodedByteLimit = artworkDecodedByteLimit,
    };
end

function backgroundTextures.Clear()
    for _, entry in pairs(artworkEntries) do
        if (entry ~= nil and entry.path ~= nil) then
            textureLoader.Release(entry.path, true);
        end
    end

    artworkEntries = {};
    artworkDecodedBytes = 0;
    textureIds = {};
end

return backgroundTextures;
