local alertSounds = {};
local filesCache = nil;
local ffiOk, ffi = pcall(require, 'ffi');
if (ffiOk ~= true) then
    ffi = nil;
end

if (ffi ~= nil) then
    ffi.cdef[[
typedef unsigned long DWORD;
typedef long          LONG;
typedef long          HRESULT;
typedef unsigned short WORD;
typedef void*         HWND;

typedef struct {
    DWORD         Data1;
    WORD          Data2;
    WORD          Data3;
    unsigned char Data4[8];
} GUID;

typedef struct {
    WORD  wFormatTag;
    WORD  nChannels;
    DWORD nSamplesPerSec;
    DWORD nAvgBytesPerSec;
    WORD  nBlockAlign;
    WORD  wBitsPerSample;
    WORD  cbSize;
} WAVEFORMATEX;

typedef struct {
    DWORD         dwSize;
    DWORD         dwFlags;
    DWORD         dwBufferBytes;
    DWORD         dwReserved;
    WAVEFORMATEX* lpwfxFormat;
    GUID          guid3DAlgorithm;
} DSBUFFERDESC;

typedef struct IDirectSoundBuffer IDirectSoundBuffer;
typedef struct {
    HRESULT       (__stdcall *QueryInterface)(void*, const GUID*, void**);
    unsigned long (__stdcall *AddRef)(void*);
    unsigned long (__stdcall *Release)(void*);
    HRESULT       (__stdcall *GetCaps)(void*, void*);
    HRESULT       (__stdcall *GetCurrentPosition)(void*, DWORD*, DWORD*);
    HRESULT       (__stdcall *GetFormat)(void*, void*, DWORD, DWORD*);
    HRESULT       (__stdcall *GetVolume)(void*, LONG*);
    HRESULT       (__stdcall *GetPan)(void*, LONG*);
    HRESULT       (__stdcall *GetFrequency)(void*, DWORD*);
    HRESULT       (__stdcall *GetStatus)(void*, DWORD*);
    HRESULT       (__stdcall *Initialize)(void*, void*, const DSBUFFERDESC*);
    HRESULT       (__stdcall *Lock)(void*, DWORD, DWORD, void**, DWORD*, void**, DWORD*, DWORD);
    HRESULT       (__stdcall *Play)(void*, DWORD, DWORD, DWORD);
    HRESULT       (__stdcall *SetCurrentPosition)(void*, DWORD);
    HRESULT       (__stdcall *SetFormat)(void*, const WAVEFORMATEX*);
    HRESULT       (__stdcall *SetVolume)(void*, LONG);
    HRESULT       (__stdcall *SetPan)(void*, LONG);
    HRESULT       (__stdcall *SetFrequency)(void*, DWORD);
    HRESULT       (__stdcall *Stop)(void*);
    HRESULT       (__stdcall *Unlock)(void*, void*, DWORD, void*, DWORD);
    HRESULT       (__stdcall *Restore)(void*);
} IDirectSoundBufferVtbl;
struct IDirectSoundBuffer {
    IDirectSoundBufferVtbl* lpVtbl;
};

typedef struct IDirectSound8 IDirectSound8;
typedef struct {
    HRESULT       (__stdcall *QueryInterface)(void*, const GUID*, void**);
    unsigned long (__stdcall *AddRef)(void*);
    unsigned long (__stdcall *Release)(void*);
    HRESULT       (__stdcall *CreateSoundBuffer)(void*, const DSBUFFERDESC*, IDirectSoundBuffer**, void*);
    HRESULT       (__stdcall *GetCaps)(void*, void*);
    HRESULT       (__stdcall *DuplicateSoundBuffer)(void*, void*, void**);
    HRESULT       (__stdcall *SetCooperativeLevel)(void*, HWND, DWORD);
    HRESULT       (__stdcall *Compact)(void*);
    HRESULT       (__stdcall *GetSpeakerConfig)(void*, DWORD*);
    HRESULT       (__stdcall *SetSpeakerConfig)(void*, DWORD);
    HRESULT       (__stdcall *Initialize)(void*, const GUID*);
} IDirectSound8Vtbl;
struct IDirectSound8 {
    IDirectSound8Vtbl* lpVtbl;
};

HRESULT __stdcall DirectSoundCreate8(const GUID*, IDirectSound8**, void*);
HWND    __stdcall GetDesktopWindow();
HWND    __stdcall GetForegroundWindow();
HWND    __stdcall FindWindowA(const char*, const char*);
]]
end

local DSSCL_NORMAL         = 0x1;
local DSBCAPS_STATIC       = 0x4;
local DSBCAPS_LOCSOFTWARE  = 0x8;
local DSBCAPS_CTRLVOLUME   = 0x80;
local DSBCAPS_GLOBALFOCUS  = 0x8000;
local DSBVOLUME_MIN        = -10000;
local WAVE_FORMAT_PCM      = 0x0001;
local flagTries = {
    DSBCAPS_CTRLVOLUME + DSBCAPS_STATIC + DSBCAPS_GLOBALFOCUS + DSBCAPS_LOCSOFTWARE,
    DSBCAPS_CTRLVOLUME + DSBCAPS_STATIC + DSBCAPS_LOCSOFTWARE,
    DSBCAPS_CTRLVOLUME + DSBCAPS_LOCSOFTWARE,
    DSBCAPS_CTRLVOLUME + DSBCAPS_STATIC,
    DSBCAPS_CTRLVOLUME,
};

local soundState = {
    initialized = false,
    failed = false,
    ds8 = nil,
    buffers = {},
};

local dsound = nil;
local user32 = nil;
if (ffi ~= nil) then
    local ok, mod = pcall(ffi.load, 'dsound');
    if (ok == true) then dsound = mod; end
    ok, mod = pcall(ffi.load, 'user32');
    if (ok == true) then user32 = mod; end
end

local fallbackFiles = T{
    'Alert01.wav',
    'Alert02.wav',
    'Alert03.wav',
    'Alert04.wav',
};

local function ReadU16(data, index)
    return data:byte(index) + (data:byte(index + 1) * 256);
end

local function ReadU32(data, index)
    return data:byte(index)
        + (data:byte(index + 1) * 256)
        + (data:byte(index + 2) * 65536)
        + (data:byte(index + 3) * 16777216);
end

local function ReleaseDirectSoundObject(object)
    if (object ~= nil) then
        object.lpVtbl.Release(object);
    end
end

local function VolumeToDb(volume)
    volume = tonumber(volume) or 100;
    if (volume <= 0) then return DSBVOLUME_MIN; end
    if (volume >= 100) then return 0; end

    local db = 2000 * math.log10(volume / 100);
    if (db < DSBVOLUME_MIN) then
        return DSBVOLUME_MIN;
    end

    return math.floor(db);
end

local function ParseWav(data)
    if (data == nil or #data < 44) then return nil, 'file too short'; end
    if (data:sub(1, 4) ~= 'RIFF' or data:sub(9, 12) ~= 'WAVE') then
        return nil, 'not a RIFF/WAVE file';
    end

    local format = nil;
    local dataOffset = nil;
    local dataLength = nil;
    local pos = 13;

    while (pos + 8 <= #data) do
        local chunkId = data:sub(pos, pos + 3);
        local chunkSize = ReadU32(data, pos + 4);
        local bodyStart = pos + 8;

        if (chunkId == 'fmt ') then
            if (chunkSize < 16) then return nil, 'fmt chunk too small'; end
            format = {
                wFormatTag = ReadU16(data, bodyStart),
                nChannels = ReadU16(data, bodyStart + 2),
                nSamplesPerSec = ReadU32(data, bodyStart + 4),
                nAvgBytesPerSec = ReadU32(data, bodyStart + 8),
                nBlockAlign = ReadU16(data, bodyStart + 12),
                wBitsPerSample = ReadU16(data, bodyStart + 14),
            };
        elseif (chunkId == 'data') then
            dataOffset = bodyStart;
            dataLength = chunkSize;
            break;
        end

        pos = bodyStart + chunkSize + (chunkSize % 2);
    end

    if (format == nil) then return nil, 'no fmt chunk'; end
    if (dataOffset == nil) then return nil, 'no data chunk'; end
    if (format.wFormatTag ~= WAVE_FORMAT_PCM) then return nil, 'not PCM'; end

    return format, dataOffset, dataLength;
end

local function EnsureDirectSound()
    if (soundState.initialized == true) then
        return soundState.ds8 ~= nil;
    end

    soundState.initialized = true;
    if (ffi == nil or dsound == nil or user32 == nil) then
        soundState.failed = true;
        return false;
    end

    local dsOut = ffi.new('IDirectSound8*[1]');
    local hr = dsound.DirectSoundCreate8(nil, dsOut, nil);
    if (hr ~= 0) then
        soundState.failed = true;
        return false;
    end

    local ds8 = dsOut[0];
    local hwnd = user32.FindWindowA('FFXiClass', nil);
    if (hwnd == nil) then hwnd = user32.GetForegroundWindow(); end
    if (hwnd == nil) then hwnd = user32.GetDesktopWindow(); end

    hr = ds8.lpVtbl.SetCooperativeLevel(ds8, hwnd, DSSCL_NORMAL);
    if (hr ~= 0) then
        ReleaseDirectSoundObject(ds8);
        soundState.failed = true;
        return false;
    end

    soundState.ds8 = ds8;
    return true;
end

local function LoadDirectSoundBuffer(path)
    if (EnsureDirectSound() ~= true) then
        return nil;
    end

    local file = io.open(path, 'rb');
    if (file == nil) then return nil; end
    local data = file:read('*all');
    file:close();

    local format, dataOffset, dataLength = ParseWav(data);
    if (format == nil) then return nil; end

    local waveFormat = ffi.new('WAVEFORMATEX');
    waveFormat.wFormatTag = format.wFormatTag;
    waveFormat.nChannels = format.nChannels;
    waveFormat.nSamplesPerSec = format.nSamplesPerSec;
    waveFormat.nAvgBytesPerSec = format.nAvgBytesPerSec;
    waveFormat.nBlockAlign = format.nBlockAlign;
    waveFormat.wBitsPerSample = format.wBitsPerSample;
    waveFormat.cbSize = 0;

    local desc = ffi.new('DSBUFFERDESC');
    desc.dwSize = ffi.sizeof('DSBUFFERDESC');
    desc.dwBufferBytes = dataLength;
    desc.dwReserved = 0;
    desc.lpwfxFormat = waveFormat;

    local bufferOut = ffi.new('IDirectSoundBuffer*[1]');
    local hr = nil;
    for _, flags in ipairs(flagTries) do
        desc.dwFlags = flags;
        hr = soundState.ds8.lpVtbl.CreateSoundBuffer(soundState.ds8, desc, bufferOut, nil);
        if (hr == 0) then break; end
    end
    if (hr ~= 0) then return nil; end

    local buffer = bufferOut[0];
    local pcmData = data:sub(dataOffset, dataOffset + dataLength - 1);
    local pcmBuffer = ffi.new('uint8_t[?]', dataLength);
    ffi.copy(pcmBuffer, pcmData, dataLength);

    local p1 = ffi.new('void*[1]');
    local len1 = ffi.new('DWORD[1]');
    local p2 = ffi.new('void*[1]');
    local len2 = ffi.new('DWORD[1]');
    hr = buffer.lpVtbl.Lock(buffer, 0, dataLength, p1, len1, p2, len2, 0);
    if (hr ~= 0) then
        ReleaseDirectSoundObject(buffer);
        return nil;
    end

    local n1 = tonumber(len1[0]) or 0;
    local n2 = tonumber(len2[0]) or 0;
    if (n1 > 0) then
        ffi.copy(p1[0], pcmBuffer, n1);
    end
    if (n2 > 0 and p2[0] ~= nil) then
        ffi.copy(p2[0], pcmBuffer + n1, n2);
    end
    buffer.lpVtbl.Unlock(buffer, p1[0], len1[0], p2[0], len2[0]);

    return buffer;
end

local function PlayDirectSound(fileName, path, volume)
    local bufferKey = tostring(fileName);
    local buffer = soundState.buffers[bufferKey];
    if (buffer == false) then
        return false;
    end
    if (buffer == nil) then
        buffer = LoadDirectSoundBuffer(path);
        soundState.buffers[bufferKey] = buffer or false;
    end
    if (buffer == nil or buffer == false) then
        return false;
    end

    local ok = pcall(function()
        buffer.lpVtbl.SetVolume(buffer, VolumeToDb(volume));
        buffer.lpVtbl.SetCurrentPosition(buffer, 0);
        buffer.lpVtbl.Play(buffer, 0, 0, 0);
    end);

    return ok == true;
end

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

function alertSounds.GetFolderPath()
    return GetAddonPath() .. 'assets\\sounds\\';
end

function alertSounds.OpenFolder()
    os.execute('start "" "' .. alertSounds.GetFolderPath() .. '"');
end

function alertSounds.Play(fileName, volume)
    local path = alertSounds.GetPath(fileName);
    local resolved = alertSounds.ResolveFile(fileName, 'None');
    volume = tonumber(volume) or 100;
    volume = math.max(0, math.min(100, volume));

    if (volume <= 0) then
        return false;
    end

    if (path == nil or ashita == nil or ashita.misc == nil or ashita.misc.play_sound == nil) then
        return false;
    end

    if (volume < 100 and PlayDirectSound(resolved, path, volume) == true) then
        return true;
    end

    local ok = pcall(ashita.misc.play_sound, path);
    return ok == true;
end

function alertSounds.Cleanup()
    for key, buffer in pairs(soundState.buffers) do
        if (buffer ~= false) then
            ReleaseDirectSoundObject(buffer);
        end
        soundState.buffers[key] = nil;
    end
    if (soundState.ds8 ~= nil) then
        ReleaseDirectSoundObject(soundState.ds8);
        soundState.ds8 = nil;
    end
    soundState.initialized = false;
    soundState.failed = false;
end

return alertSounds;
