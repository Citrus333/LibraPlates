require('common');

local d3d = require('d3d8');
local ffi = require('ffi');
local C = ffi.C;

pcall(ffi.cdef, [[
    typedef struct IDirect3DTexture8 IDirect3DTexture8;
    typedef struct IDirect3DDevice8 IDirect3DDevice8;
    int D3DXCreateTextureFromFileExA(
        IDirect3DDevice8* pDevice,
        const char* pSrcFile,
        unsigned int Width,
        unsigned int Height,
        unsigned int MipLevels,
        unsigned int Usage,
        int Format,
        int Pool,
        unsigned int Filter,
        unsigned int MipFilter,
        unsigned int ColorKey,
        void* pSrcInfo,
        void* pPalette,
        IDirect3DTexture8** ppTexture
    );
]]);

local textureLoader = {};
local cache = {};
local D3DFMT_A8R8G8B8 = 21;
local D3DPOOL_MANAGED = 1;
local D3DX_DEFAULT = 0xFFFFFFFF;
local DEFAULT_COLOR_KEY = 0xFF000000;
local S_OK = 0;

local function IsDetachedArtworkPath(path)
    local normalized = string.lower(tostring(path or '')):gsub('/', '\\');
    return string.find(normalized, '\\detached\\', 1, true) ~= nil;
end

local function LoadWithColorKey(path, colorKey, cacheKey)
    path = tostring(path or '');

    if (path == '') then
        return nil;
    end

    cacheKey = tostring(cacheKey or path);

    if (cache[cacheKey] ~= nil) then
        return cache[cacheKey];
    end

    local exists = false;

    pcall(function()
        exists = ashita.fs.exists(path);
    end);

    if (exists ~= true) then
        return nil;
    end

    local texturePointer = ffi.new('IDirect3DTexture8*[1]');
    local device = d3d.get_device();

    if (device == nil) then
        return nil;
    end

    local result = C.D3DXCreateTextureFromFileExA(
        device,
        path,
        D3DX_DEFAULT,
        D3DX_DEFAULT,
        1,
        0,
        D3DFMT_A8R8G8B8,
        D3DPOOL_MANAGED,
        D3DX_DEFAULT,
        D3DX_DEFAULT,
        colorKey,
        nil,
        nil,
        texturePointer
    );

    if (result ~= S_OK or texturePointer[0] == nil) then
        return nil;
    end

    cache[cacheKey] = d3d.gc_safe_release(ffi.cast('IDirect3DTexture8*', texturePointer[0]));
    return cache[cacheKey];
end

function textureLoader.ClearCache()
    cache = {};
end

function textureLoader.Load(path)
    if (IsDetachedArtworkPath(path)) then
        return LoadWithColorKey(path, 0, tostring(path or '') .. '|preserve-alpha');
    end

    return LoadWithColorKey(path, DEFAULT_COLOR_KEY, path);
end

-- PNG artwork already carries its own alpha channel. Loading it without the
-- legacy black color key preserves opaque black pixels in the artwork.
function textureLoader.LoadPreserveAlpha(path)
    return LoadWithColorKey(path, 0, tostring(path or '') .. '|preserve-alpha');
end

function textureLoader.ToTextureId(texture)
    if (texture == nil) then
        return nil;
    end

    return tonumber(ffi.cast('uint32_t', texture));
end

return textureLoader;
