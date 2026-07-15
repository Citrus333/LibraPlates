local textureLoader = require('core.texture_loader');
local arrowAnimation = require('core.target_arrow_animation');

local targetTextures = {};
local textureIds = {};
local filesCache = {};
local frameCache = {};
local defaultSpriteFps = 12;
local legacyTextureNames = {
    backgrounds = {
        ['glow-100.png'] = 'Soft_Glow_Rectangle.png',
        ['glow_100.png'] = 'Soft_Glow_Rectangle.png',
        ['background_01.png'] = 'Soft_Glow_Rectangle.png',
        ['brackets.png'] = 'Brackets_Short.png',
    },
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

    return fileName;
end

local function GetAnimationParts(fileName)
    local prefix, digits, suffix = CleanFileName(fileName):match('^(.-)(%d%d)(%.png)$');

    if (prefix == nil or digits == nil or suffix == nil) then
        return nil, nil, nil;
    end

    return prefix, digits, suffix;
end

local function GetAnimationBaseName(category, fileName)
    category = tostring(category or '');
    fileName = CleanFileName(fileName);

    if (fileName == 'None') then
        return 'None';
    end

    if (category == 'arrows') then
        return arrowAnimation.GetAnimationBaseName(fileName);
    end

    local prefix, digits, suffix = GetAnimationParts(fileName);

    if (prefix == nil or digits == nil or suffix == nil) then
        return fileName;
    end

    local firstFrame = prefix .. string.format('%0' .. tostring(string.len(digits)) .. 'd', 1) .. suffix;

    if (PathExists(GetAddonPath() .. 'assets\\images\\target\\' .. category .. '\\' .. firstFrame) == true) then
        return firstFrame;
    end

    return fileName;
end

local function AddFile(files, category, name)
    name = tostring(name or ''):gsub('^.*[\\/]', '');

    if (name == '' or string.lower(name):match('%.png$') == nil) then
        return;
    end

    if (category == 'arrows' and arrowAnimation.GetDropdownFileName(name) ~= name) then
        return;
    end

    if (category ~= 'arrows' and GetAnimationBaseName(category, name) ~= name) then
        return;
    end

    for _, existing in ipairs(files) do
        if (existing == name) then
            return;
        end
    end

    files[#files + 1] = name;
end

function targetTextures.GetFolderPath(category)
    return GetAddonPath() .. 'assets\\images\\target\\' .. tostring(category or 'arrows') .. '\\';
end

function targetTextures.GetFiles(category)
    category = tostring(category or 'arrows');

    if (filesCache[category] ~= nil) then
        return filesCache[category];
    end

    local files = T{ 'None' };
    local folder = targetTextures.GetFolderPath(category);
    local pipe = io.popen('dir /b "' .. folder .. '*.png" 2>nul');

    if (pipe ~= nil) then
        for line in pipe:lines() do
            AddFile(files, category, line);
        end

        pipe:close();
    end

    table.sort(files, function(a, b)
        if (a == 'None') then return true; end
        if (b == 'None') then return false; end
        return string.lower(tostring(a)) < string.lower(tostring(b));
    end);

    filesCache[category] = files;
    return filesCache[category];
end

local function GetSpriteFrames(category, fileName)
    category = tostring(category or '');
    fileName = GetAnimationBaseName(category, fileName);

    if (fileName == 'None') then
        return {};
    end

    local cacheKey = category .. '/' .. fileName;

    if (frameCache[cacheKey] ~= nil) then
        return frameCache[cacheKey];
    end

    local prefix, digits, suffix = GetAnimationParts(fileName);
    local frames = {};

    if (prefix ~= nil and digits ~= nil and suffix ~= nil) then
        local width = string.len(digits);
        local folder = GetAddonPath() .. 'assets\\images\\target\\' .. category .. '\\';

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

    frameCache[cacheKey] = frames;
    return frameCache[cacheKey];
end

local function FilterArrowFiles(wantAnimation)
    local cacheKey = wantAnimation == true and 'arrows:animations' or 'arrows:stills';

    if (filesCache[cacheKey] ~= nil) then
        return filesCache[cacheKey];
    end

    local files = T{ 'None' };

    for _, file in ipairs(targetTextures.GetFiles('arrows')) do
        if (file ~= 'None') then
            local animated = arrowAnimation.HasSpriteFrames(file) == true;

            if (animated == (wantAnimation == true)) then
                files[#files + 1] = file;
            end
        end
    end

    filesCache[cacheKey] = files;
    return filesCache[cacheKey];
end

local function FilterSpriteFiles(category, wantAnimation)
    category = tostring(category or '');

    if (category == 'arrows') then
        return FilterArrowFiles(wantAnimation);
    end

    local cacheKey = category .. (wantAnimation == true and ':animations' or ':stills');

    if (filesCache[cacheKey] ~= nil) then
        return filesCache[cacheKey];
    end

    local files = T{ 'None' };

    for _, file in ipairs(targetTextures.GetFiles(category)) do
        if (file ~= 'None') then
            local animated = #GetSpriteFrames(category, file) > 1;

            if (animated == (wantAnimation == true)) then
                files[#files + 1] = file;
            end
        end
    end

    filesCache[cacheKey] = files;
    return filesCache[cacheKey];
end

function targetTextures.GetArrowStillFiles()
    return FilterArrowFiles(false);
end

function targetTextures.GetArrowAnimationFiles()
    return FilterArrowFiles(true);
end

function targetTextures.GetStillFiles(category)
    return FilterSpriteFiles(category, false);
end

function targetTextures.GetAnimationFiles(category)
    return FilterSpriteFiles(category, true);
end

function targetTextures.HasSpriteFrames(category, fileName)
    if (tostring(category or '') == 'arrows') then
        return arrowAnimation.HasSpriteFrames(fileName);
    end

    return #GetSpriteFrames(category, fileName) > 1;
end

function targetTextures.GetSpriteFrameName(category, fileName, speed)
    category = tostring(category or '');

    if (category == 'arrows') then
        return arrowAnimation.GetSpriteFrameName(fileName, speed);
    end

    local frames = GetSpriteFrames(category, fileName);

    if (#frames <= 1) then
        return CleanFileName(fileName);
    end

    local fps = math.max(1, math.min(60, tonumber(speed) or defaultSpriteFps));
    local index = (math.floor(os.clock() * fps) % #frames) + 1;

    return frames[index] or fileName;
end

local function LoadTextureId(category, fileName)
    local key = category .. '/' .. fileName;

    if (textureIds[key] ~= nil) then
        return textureIds[key];
    end

    textureIds[key] = textureLoader.ToTextureId(textureLoader.Load(
        GetAddonPath() .. 'assets\\images\\target\\' .. category .. '\\' .. fileName
    ));

    return textureIds[key];
end

function targetTextures.GetTextureId(category, fileName)
    category = tostring(category or 'arrows');
    fileName = tostring(fileName or 'None'):gsub('^.*[\\/]', '');

    if (fileName == '' or fileName == 'None') then
        return nil;
    end

    if (category == 'arrows') then
        fileName = arrowAnimation.GetDropdownFileName(fileName);
    elseif (targetTextures.HasSpriteFrames(category, fileName) == true) then
        fileName = GetAnimationBaseName(category, fileName);
    else
        local legacyCategory = legacyTextureNames[category];
        if (legacyCategory ~= nil) then
            fileName = legacyCategory[string.lower(fileName)] or fileName;
        end
    end

    return LoadTextureId(category, fileName);
end

function targetTextures.GetAnimatedTextureId(category, fileName, useSprite, speed)
    category = tostring(category or '');

    if (category == 'arrows') then
        return arrowAnimation.GetTextureId(fileName, useSprite, speed);
    end

    if (useSprite == true) then
        return LoadTextureId(category, targetTextures.GetSpriteFrameName(category, fileName, speed));
    end

    return targetTextures.GetTextureId(category, fileName);
end

return targetTextures;
