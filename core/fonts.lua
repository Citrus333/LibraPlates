local fonts = {};

local function StripExtension(fileName)
    return tostring(fileName or ''):gsub('%.[^%.]+$', '');
end

local function Trim(value)
    return tostring(value or ''):gsub('^%s+', ''):gsub('%s+$', '');
end

local function NormalizeFontChoice(value)
    if (type(value) ~= 'string') then
        return 'Default';
    end

    local text = Trim(value);

    if (text == '') then
        return 'Default';
    end

    return text;
end

local function TitleCase(value)
    return tostring(value or ''):gsub('(%a)([%w]*)', function(first, rest)
        return string.upper(first) .. string.lower(rest);
    end);
end

local function ReadU16(data, offset)
    local b1, b2 = string.byte(data, offset, offset + 1);

    if (b1 == nil or b2 == nil) then
        return nil;
    end

    return (b1 * 256) + b2;
end

local function ReadU32(data, offset)
    local b1, b2, b3, b4 = string.byte(data, offset, offset + 3);

    if (b1 == nil or b2 == nil or b3 == nil or b4 == nil) then
        return nil;
    end

    return (b1 * 16777216) + (b2 * 65536) + (b3 * 256) + b4;
end

local function DecodeUtf16Be(data)
    local result = {};

    for i = 1, #data - 1, 2 do
        local code = ReadU16(data, i);

        if (code ~= nil and code > 0 and code < 128) then
            result[#result + 1] = string.char(code);
        elseif (code ~= nil and code >= 128) then
            result[#result + 1] = '?';
        end
    end

    return table.concat(result);
end

local function DecodeNameString(data, platformId)
    if (tonumber(platformId) == 0 or tonumber(platformId) == 3) then
        return DecodeUtf16Be(data);
    end

    return data;
end

local function ReadFontNames(path)
    local names = {};

    if (type(path) ~= 'string' or path == '') then
        return names;
    end

    local file = io.open(path, 'rb');

    if (file == nil) then
        return names;
    end

    local data = file:read('*a');
    file:close();

    if (data == nil or #data < 12) then
        return names;
    end

    local tableCount = ReadU16(data, 5) or 0;
    local nameTableOffset = nil;

    for i = 0, tableCount - 1 do
        local offset = 13 + (i * 16);
        local tag = data:sub(offset, offset + 3);

        if (tag == 'name') then
            nameTableOffset = ReadU32(data, offset + 8);
            break;
        end
    end

    if (nameTableOffset == nil) then
        return names;
    end

    local base = nameTableOffset + 1;
    local recordCount = ReadU16(data, base + 2) or 0;
    local storageOffset = ReadU16(data, base + 4) or 0;

    for i = 0, recordCount - 1 do
        local recordOffset = base + 6 + (i * 12);
        local platformId = ReadU16(data, recordOffset);
        local nameId = ReadU16(data, recordOffset + 6);
        local length = ReadU16(data, recordOffset + 8);
        local offset = ReadU16(data, recordOffset + 10);

        if (
            platformId ~= nil and
            nameId ~= nil and
            length ~= nil and
            offset ~= nil and
            (nameId == 1 or nameId == 4 or nameId == 16) and
            length > 0
        ) then
            local stringStart = base + storageOffset + offset;
            local raw = data:sub(stringStart, stringStart + length - 1);
            local decoded = Trim(DecodeNameString(raw, platformId):gsub('%z', ''));

            if (decoded ~= '' and decoded:find('%?%?%?') == nil) then
                names[nameId] = names[nameId] or {};
                names[nameId][#names[nameId] + 1] = decoded;
            end
        end
    end

    return names;
end

local function CleanFamilyName(value)
    local name = StripExtension(value);

    name = name:gsub('([a-z])([A-Z])', '%1 %2');
    name = name:gsub('[%-%_]+', ' ');
    name = name:gsub('%s+', ' ');
    return TitleCase(Trim(name));
end

local function AddCandidate(result, seen, value)
    local name = Trim(value);

    if (name == '') then
        return;
    end

    local key = string.lower(name);

    if (seen[key] == true) then
        return;
    end

    seen[key] = true;
    result[#result + 1] = name;
end

local fontFileCache = {};

local function FindFontFile(value)
    local choice = StripExtension(NormalizeFontChoice(value));
    local key = string.lower(choice);

    if (choice == '' or choice == 'Default') then
        fontFileCache[key] = false;
        return nil;
    end

    if (fontFileCache[key] ~= nil) then
        return fontFileCache[key];
    end

    for _, kind in ipairs({ 'large', 'small' }) do
        local searchPath = fonts.GetFolderPath(kind);
        local ok, files = pcall(function()
            if (ashita.fs.get_directory ~= nil) then
                return ashita.fs.get_directory(searchPath, '.*');
            end

            if (ashita.fs.get_dir ~= nil) then
                return ashita.fs.get_dir(searchPath, '.*');
            end

            return nil;
        end);

        if (ok == true and files ~= nil) then
            for _, entry in ipairs(files) do
                local fileName = nil;

                if (type(entry) == 'table') then
                    fileName = entry.name or entry.Name or entry.file or entry.File or entry.path or entry.Path;
                else
                    fileName = entry;
                end

                fileName = tostring(fileName or ''):gsub('^.*[\\/]', '');

                if (string.lower(StripExtension(fileName)) == key) then
                    fontFileCache[key] = searchPath .. '\\' .. fileName;
                    return fontFileCache[key];
                end
            end
        end
    end

    fontFileCache[key] = false;
    return nil;
end

local function StripStyleName(value)
    local name = Trim(value);
    local lower = string.lower(name);
    local suffixes = {
        ' extra light',
        ' semi bold',
        ' extra bold',
        ' regular',
        ' medium',
        ' black',
        ' light',
        ' thin',
        ' bold',
    };

    for _, suffix in ipairs(suffixes) do
        if (lower:sub(-#suffix) == suffix) then
            name = name:sub(1, #name - #suffix);
            break;
        end
    end

    return Trim(name);
end

local function GetFontFlags(value)
    local lower = string.lower(NormalizeFontChoice(value));
    local flags = 0;

    if (lower:find('bold', 1, true) ~= nil or lower:find('black', 1, true) ~= nil) then
        flags = flags + 1;
    end

    if (lower:find('italic', 1, true) ~= nil) then
        flags = flags + 2;
    end

    return flags;
end

local function GetFamilyCandidates(value)
    local base = CleanFamilyName(NormalizeFontChoice(value));
    local noTrailingNumber = Trim(base:gsub('%s+[0-9]+$', ''));
    local noPointSize = Trim(noTrailingNumber:gsub('%s+[0-9]+pt%s*', ' '):gsub('%s+', ' '));
    local result = {};
    local seen = {};
    local strippedNoPointSize = StripStyleName(noPointSize);
    local strippedNoTrailingNumber = StripStyleName(noTrailingNumber);
    local fontFile = FindFontFile(value);

    if (type(fontFile) == 'string' and fontFile ~= '') then
        local metadata = ReadFontNames(fontFile);

        for _, name in ipairs(metadata[16] or {}) do
            AddCandidate(result, seen, name);
        end

        for _, name in ipairs(metadata[1] or {}) do
            AddCandidate(result, seen, name);
        end

        for _, name in ipairs(metadata[4] or {}) do
            AddCandidate(result, seen, StripStyleName(name));
        end
    end

    AddCandidate(result, seen, strippedNoPointSize);
    AddCandidate(result, seen, strippedNoTrailingNumber);
    AddCandidate(result, seen, noTrailingNumber);
    AddCandidate(result, seen, noPointSize);
    AddCandidate(result, seen, base);

    if (#result == 0) then
        AddCandidate(result, seen, 'Arial');
    end

    return result;
end

local function GetGdi()
    local ok, gdiText = pcall(function()
        return require('ui.gdi_text');
    end);

    if (ok ~= true or gdiText == nil or gdiText.GetGdi == nil) then
        return nil;
    end

    return gdiText.GetGdi();
end

local function IsFontAvailable(gdi, family)
    if (gdi == nil or gdi.get_font_available == nil) then
        return false;
    end

    local available = false;

    pcall(function()
        available = (gdi:get_font_available(family) == true);
    end);

    return available;
end

local function IsFontRenderable(family, flags)
    local ok, gdiTextTexture = pcall(function()
        return require('ui.gdi_text_texture');
    end);

    if (ok ~= true or gdiTextTexture == nil or gdiTextTexture.GetTexture == nil) then
        return false;
    end

    local textureId, textureWidth, textureHeight = gdiTextTexture.GetTexture('Libra', {
        fontFamily = family,
        fontFlags = tonumber(flags) or 0,
        fontSize = 16,
        color = { 1.0, 1.0, 1.0, 1.0 },
        outlineEnabled = false,
        disableFallback = true,
    });

    return (textureId ~= nil and tonumber(textureWidth) ~= nil and tonumber(textureWidth) > 0 and tonumber(textureHeight) ~= nil and tonumber(textureHeight) > 0);
end

local function ResolveStatus(value)
    local fontName = NormalizeFontChoice(value);
    local candidates = nil;

    if (fontName == 'Default') then
        candidates = { 'Arial' };
    else
        candidates = GetFamilyCandidates(fontName);
    end

    local flags = GetFontFlags(fontName);
    local gdi = GetGdi();
    local firstAvailable = nil;

    for _, family in ipairs(candidates) do
        if (IsFontAvailable(gdi, family) == true) then
            if (firstAvailable == nil) then
                firstAvailable = family;
            end

            if (IsFontRenderable(family, flags) == true) then
                return {
                    available = true,
                    renderable = true,
                    family = family,
                    flags = flags,
                };
            end
        end
    end

    if (firstAvailable ~= nil) then
        return {
            available = true,
            renderable = false,
            family = firstAvailable,
            flags = flags,
        };
    end

    return {
        available = false,
        renderable = false,
        family = candidates[1] or 'Arial',
        flags = flags,
    };
end

function fonts.GetFolderPath(kind)
    local root = AshitaCore:GetInstallPath();

    root = tostring(root or ''):gsub('[\\/]+$', '');

    return root .. '\\addons\\LibraPlates\\assets\\fonts\\' .. tostring(kind or 'large');
end

function fonts.GetRootFolderPath()
    local root = AshitaCore:GetInstallPath();

    root = tostring(root or ''):gsub('[\\/]+$', '');

    return root .. '\\addons\\LibraPlates\\assets\\fonts';
end

function fonts.OpenFolder(kind)
    local path = fonts.GetFolderPath(kind);

    os.execute('start "" "' .. path .. '"');
end

function fonts.OpenRootFolder()
    local path = fonts.GetRootFolderPath();

    os.execute('start "" "' .. path .. '"');
end

local function AddFontFiles(result, folder)
    local searchPath = fonts.GetFolderPath(folder);
    local ok, files = pcall(function()
        if (ashita.fs.get_directory ~= nil) then
            return ashita.fs.get_directory(searchPath, '.*');
        end

        if (ashita.fs.get_dir ~= nil) then
            return ashita.fs.get_dir(searchPath, '.*');
        end

        return nil;
    end);

    if (ok ~= true or files == nil) then
        return;
    end

    for _, entry in ipairs(files) do
        local fileName = nil;

        if (type(entry) == 'table') then
            fileName = entry.name or entry.Name or entry.file or entry.File or entry.path or entry.Path;
        else
            fileName = entry;
        end

        fileName = tostring(fileName or '');
        fileName = fileName:gsub('^.*[\\/]', '');

        local lower = string.lower(fileName);

        if (lower:match('%.ttf$') ~= nil or lower:match('%.otf$') ~= nil) then
            result[#result + 1] = StripExtension(fileName);
        end
    end
end

function fonts.GetChoices(kind)
    local result = { 'Default' };
    local seen = {};
    local compact = {};

    AddFontFiles(result, tostring(kind or 'large'));

    for _, fontName in ipairs(result) do
        local key = string.lower(tostring(fontName));

        if (seen[key] ~= true) then
            seen[key] = true;
            compact[#compact + 1] = fontName;
        end
    end

    return compact;
end

function fonts.Resolve(value)
    local status = ResolveStatus(NormalizeFontChoice(value));

    if (status.available == true) then
        return status.family;
    end

    return 'Arial';
end

function fonts.GetRole(globalSettings, useSmallFont)
    local font = (globalSettings ~= nil and globalSettings.font) or {};

    if (useSmallFont == true) then
        return fonts.Resolve(NormalizeFontChoice(font.smallFamily or font.family or 'Default'));
    end

    return fonts.Resolve(NormalizeFontChoice(font.largeFamily or font.family or 'Default'));
end

function fonts.GetRoleFlags(globalSettings, useSmallFont)
    local font = (globalSettings ~= nil and globalSettings.font) or {};
    local selected = NormalizeFontChoice(font.largeFamily or font.family or 'Default');

    if (useSmallFont == true) then
        selected = NormalizeFontChoice(font.smallFamily or font.family or 'Default');
    end

    return GetFontFlags(selected);
end

function fonts.IsAvailable(value)
    local fontName = NormalizeFontChoice(value);
    local candidates = nil;

    if (fontName == 'Default') then
        candidates = { 'Arial' };
    else
        candidates = GetFamilyCandidates(fontName);
    end

    local gdi = GetGdi();

    for _, family in ipairs(candidates) do
        if (IsFontAvailable(gdi, family) == true) then
            return true, family;
        end
    end

    return false, candidates[1] or 'Arial';
end

function fonts.GetStatus(value)
    return ResolveStatus(value);
end

return fonts;
