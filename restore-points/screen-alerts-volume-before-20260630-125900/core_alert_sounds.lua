local alertSounds = {};
local filesCache = nil;
local fallbackFiles = T{
    'Alert01.wav',
    'Alert02.wav',
    'Alert03.wav',
    'Alert04.wav',
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

local function NormalizeName(name)
    name = tostring(name or ''):gsub('/', '\\');
    name = name:gsub('^%s+', ''):gsub('%s+$', '');

    if (name == '' or name == 'None') then
        return 'None';
    end

    if (name:find('%.%.', 1, true) ~= nil or name:match('^%a:[\\/]') ~= nil or name:match('^[\\/]') ~= nil) then
        return 'None';
    end

    if (string.lower(name):match('%.wav$') == nil and string.lower(name):match('%.mp3$') == nil and string.lower(name):match('%.ogg$') == nil) then
        return 'None';
    end

    return name;
end

local function AddFile(files, name)
    name = NormalizeName(name);

    if (name == 'None') then
        return;
    end

    for _, existing in ipairs(files) do
        if (existing == name) then
            return;
        end
    end

    files[#files + 1] = name;
end

local function AddFolderFiles(files, folder, prefix)
    local pipe = io.popen('dir /b "' .. folder .. '*.wav" "' .. folder .. '*.mp3" "' .. folder .. '*.ogg" 2>nul');

    if (pipe == nil) then
        return;
    end

    for line in pipe:lines() do
        AddFile(files, tostring(prefix or '') .. tostring(line or ''));
    end

    pipe:close();
end

function alertSounds.GetFiles()
    if (filesCache ~= nil) then
        return filesCache;
    end

    local files = T{ 'None' };
    local root = GetAddonPath() .. 'assets\\sounds\\';

    AddFolderFiles(files, root, '');
    AddFolderFiles(files, root .. 'extra\\', 'extra\\');

    for _, fileName in ipairs(fallbackFiles) do
        AddFile(files, fileName);
    end

    table.sort(files, function(a, b)
        if (a == 'None') then return true; end
        if (b == 'None') then return false; end
        return string.lower(tostring(a)) < string.lower(tostring(b));
    end);

    filesCache = files;
    return filesCache;
end

function alertSounds.ResolveFile(fileName, fallback)
    fileName = NormalizeName(fileName);
    fallback = NormalizeName(fallback or 'None');

    for _, known in ipairs(alertSounds.GetFiles()) do
        if (fileName == known) then
            return fileName;
        end
    end

    for _, known in ipairs(alertSounds.GetFiles()) do
        if (fallback == known) then
            return fallback;
        end
    end

    return 'None';
end

function alertSounds.GetPath(fileName)
    fileName = alertSounds.ResolveFile(fileName, 'None');

    if (fileName == 'None') then
        return nil;
    end

    return GetAddonPath() .. 'assets\\sounds\\' .. fileName;
end

function alertSounds.Play(fileName)
    local path = alertSounds.GetPath(fileName);

    if (path == nil or ashita == nil or ashita.misc == nil or ashita.misc.play_sound == nil) then
        return false;
    end

    local ok = pcall(ashita.misc.play_sound, path);
    return ok == true;
end

return alertSounds;
