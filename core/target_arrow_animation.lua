local textureLoader = require('core.texture_loader');

local arrowAnimation = {};
local textureIds = {};
local frameCache = {};
local defaultSpriteFps = 12;
local legacyArrowNames = {
    ['arrow_classic.png'] = 'Classic.png',
    ['arrow_classic_01.png'] = 'Classic_01.png',
    ['arrow_classic_02.png'] = 'Classic_02.png',
    ['arrow_classic_03.png'] = 'Classic_03.png',
    ['arrow_classic_04.png'] = 'Classic_04.png',
    ['arrow_classic_05.png'] = 'Classic_05.png',
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

local function PathExists(path)
    local ok, exists = pcall(function()
        return ashita.fs.exists(path);
    end);

    return ok == true and exists == true;
end

local function CleanFileName(fileName)
    fileName = tostring(fileName or 'None'):gsub('^.*[\\/]', '');

    if (fileName == '' or fileName == 'None') then
        return 'None';
    end

    local legacyName = legacyArrowNames[string.lower(fileName)];
    if (legacyName ~= nil) then
        return legacyName;
    end

    local arrowPath = GetAddonPath() .. 'assets\\images\\target\\arrows\\';
    local unpaddedNumber = fileName:match('^arrow_0([1-9])%.png$');

    if (unpaddedNumber ~= nil and PathExists(arrowPath .. fileName) ~= true) then
        local candidate = 'arrow_' .. unpaddedNumber .. '.png';

        if (PathExists(arrowPath .. candidate) == true) then
            return candidate;
        end
    end

    return fileName;
end

local function GetAnimationParts(fileName)
    local prefix, digits, suffix = CleanFileName(fileName):match('^(.-)(%d%d)(%.png)$');

    if (prefix == nil or digits == nil or suffix == nil) then
        return nil, nil, nil;
    end

    return prefix, digits, suffix;
end

local function GetTextureId(fileName)
    fileName = CleanFileName(fileName);

    if (fileName == 'None') then
        return nil;
    end

    if (textureIds[fileName] ~= nil) then
        return textureIds[fileName];
    end

    textureIds[fileName] = textureLoader.ToTextureId(textureLoader.Load(
        GetAddonPath() .. 'assets\\images\\target\\arrows\\' .. fileName
    ));

    return textureIds[fileName];
end

local function GetSpriteFrames(fileName)
    fileName = arrowAnimation.GetAnimationBaseName(fileName);

    if (fileName == 'None') then
        return {};
    end

    if (frameCache[fileName] ~= nil) then
        return frameCache[fileName];
    end

    local prefix, digits, suffix = GetAnimationParts(fileName);
    local frames = {};

    if (prefix ~= nil and digits ~= nil and suffix ~= nil) then
        local width = string.len(digits);
        local folder = GetAddonPath() .. 'assets\\images\\target\\arrows\\';

        for i = 1, 24 do
            local candidate = prefix .. string.format('%0' .. tostring(width) .. 'd', i) .. suffix;

            if (PathExists(folder .. candidate) == true) then
                frames[#frames + 1] = candidate;
            elseif (#frames > 0) then
                break;
            end
        end
    end

    if (#frames == 0) then
        frames[1] = fileName;
    end

    frameCache[fileName] = frames;
    return frames;
end

function arrowAnimation.NormalizeFileName(fileName)
    return CleanFileName(fileName);
end

function arrowAnimation.GetAnimationBaseName(fileName)
    fileName = CleanFileName(fileName);

    if (fileName == 'None') then
        return 'None';
    end

    local prefix, digits, suffix = GetAnimationParts(fileName);

    if (prefix == nil or digits == nil or suffix == nil) then
        return fileName;
    end

    local firstFrame = prefix .. string.format('%0' .. tostring(string.len(digits)) .. 'd', 1) .. suffix;

    if (PathExists(GetAddonPath() .. 'assets\\images\\target\\arrows\\' .. firstFrame) == true) then
        return firstFrame;
    end

    return fileName;
end

function arrowAnimation.GetDropdownFileName(fileName)
    return arrowAnimation.GetAnimationBaseName(fileName);
end

function arrowAnimation.UpgradeLegacySettings(settings)
    if (type(settings) ~= 'table') then
        return settings;
    end

    if (settings.arrowAnimation == 'Classic' or settings.arrowAnimation == 'Native shimmer') then
        if (arrowAnimation.HasSpriteFrames(settings.arrowFile) ~= true) then
            settings.arrowFile = 'arrow_classic_01.png';
        end

        settings.arrowSprite = true;
        settings.arrowAnimationSpeed = tonumber(settings.arrowAnimationSpeed) or defaultSpriteFps;
        settings.arrowAnimation = nil;
    end

    return settings;
end

function arrowAnimation.HasImage(fileName)
    return arrowAnimation.NormalizeFileName(fileName) ~= 'None';
end

function arrowAnimation.HasSpriteFrames(fileName)
    return #GetSpriteFrames(fileName) > 1;
end

function arrowAnimation.GetSpriteFrameName(fileName, speed)
    local frames = GetSpriteFrames(fileName);

    if (#frames <= 1) then
        return arrowAnimation.NormalizeFileName(fileName);
    end

    local fps = math.max(1, math.min(60, tonumber(speed) or defaultSpriteFps));
    local index = (math.floor(os.clock() * fps) % #frames) + 1;

    return frames[index] or fileName;
end

function arrowAnimation.GetTextureId(fileName, useSprite, speed)
    fileName = CleanFileName(fileName);

    if (useSprite == true) then
        return GetTextureId(arrowAnimation.GetSpriteFrameName(fileName, speed));
    end

    return GetTextureId(fileName);
end

return arrowAnimation;
