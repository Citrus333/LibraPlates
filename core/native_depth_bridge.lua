-- ==========================================================
-- = DEPENDENCIES =
-- ==========================================================

require('common');

local ffi = require('ffi');

pcall(function ()
    ffi.cdef[[
        typedef void* HMODULE;
        typedef const char* LPCSTR;
        typedef void* FARPROC;
        HMODULE __stdcall LoadLibraryA(LPCSTR lpLibFileName);
        FARPROC __stdcall GetProcAddress(HMODULE hModule, LPCSTR lpProcName);
        unsigned long __stdcall GetLastError(void);

        typedef int (__cdecl *LibraPlatesDepthBridgeGetVersionFn)(void);
        typedef int (__cdecl *LibraPlatesDepthBridgeSetDeviceFn)(void* device);
        typedef int (__cdecl *LibraPlatesDepthBridgeGetLastValueFn)(void);
        typedef int (__cdecl *LibraPlatesDepthBridgeSampleDepthFn)(float screenX, float screenY, float* sampledDepth);
        typedef int (__cdecl *LibraPlatesDepthBridgeIsOccludedFn)(float screenX, float screenY, float projectedDepth, float bias, int* occluded, float* sampledDepth);
    ]];
end);

-- ==========================================================
-- = MODULE =
-- ==========================================================

local nativeDepthBridge = {};

local defaultDllName = 'LibraPlatesDepthBridge.dll';
local state = {
    attempted = false,
    loaded = false,
    path = nil,
    handle = nil,
    lastError = nil,
    version = nil,
    exports = T{},
};

local exportNames = {
    getVersion = T{
        'LibraPlatesDepthBridge_GetVersion',
        'LPDepthBridge_GetVersion',
        'GetVersion',
    },
    sampleDepth = T{
        'LibraPlatesDepthBridge_SampleDepth',
        'LPDepthBridge_SampleDepth',
        'SampleDepth',
    },
    setDevice = T{
        'LibraPlatesDepthBridge_SetDevice',
        'LPDepthBridge_SetDevice',
        'SetDevice',
    },
    getLastStatus = T{
        'LibraPlatesDepthBridge_GetLastStatus',
        'LPDepthBridge_GetLastStatus',
        'GetLastStatus',
    },
    getLastHresult = T{
        'LibraPlatesDepthBridge_GetLastHresult',
        'LPDepthBridge_GetLastHresult',
        'GetLastHresult',
    },
    getLastFormat = T{
        'LibraPlatesDepthBridge_GetLastFormat',
        'LPDepthBridge_GetLastFormat',
        'GetLastFormat',
    },
    isOccluded = T{
        'LibraPlatesDepthBridge_IsOccluded',
        'LPDepthBridge_IsOccluded',
        'IsOccluded',
    },
};

local function SafeCall(fn, fallback)
    local ok, result = pcall(fn);

    if (ok == true) then
        return result;
    end

    return fallback;
end

local function GetAddonPath()
    return SafeCall(function ()
        return AshitaCore:GetInstallPath() .. '\\addons\\LibraPlates';
    end, '.');
end

local function FindExport(handle, names)
    if (handle == nil or handle == ffi.NULL) then
        return nil, nil;
    end

    for i = 1, #names do
        local name = tostring(names[i]);
        local proc = ffi.C.GetProcAddress(handle, name);

        if (proc ~= nil and proc ~= ffi.NULL) then
            return proc, name;
        end
    end

    return nil, nil;
end

local function ResetExports()
    state.exports = T{};
end

local function Load(path)
    if (state.attempted == true and (path == nil or path == state.path)) then
        return state.loaded;
    end

    state.attempted = true;
    state.loaded = false;
    state.path = path or (GetAddonPath() .. '\\native\\' .. defaultDllName);
    state.handle = nil;
    state.lastError = nil;
    state.version = nil;
    ResetExports();

    local handle = SafeCall(function ()
        return ffi.C.LoadLibraryA(state.path);
    end, nil);

    if (handle == nil or handle == ffi.NULL) then
        state.lastError = SafeCall(function () return tonumber(ffi.C.GetLastError()); end, nil);
        return false;
    end

    state.handle = handle;
    state.loaded = true;

    local versionProc, versionName = FindExport(handle, exportNames.getVersion);
    local sampleProc, sampleName = FindExport(handle, exportNames.sampleDepth);
    local setDeviceProc, setDeviceName = FindExport(handle, exportNames.setDevice);
    local statusProc, statusName = FindExport(handle, exportNames.getLastStatus);
    local hresultProc, hresultName = FindExport(handle, exportNames.getLastHresult);
    local formatProc, formatName = FindExport(handle, exportNames.getLastFormat);
    local occludedProc, occludedName = FindExport(handle, exportNames.isOccluded);

    if (versionProc ~= nil) then
        state.exports.getVersion = {
            name = versionName,
            fn = ffi.cast('LibraPlatesDepthBridgeGetVersionFn', versionProc),
        };

        state.version = SafeCall(function ()
            return tonumber(state.exports.getVersion.fn());
        end, nil);
    end

    if (sampleProc ~= nil) then
        state.exports.sampleDepth = {
            name = sampleName,
            fn = ffi.cast('LibraPlatesDepthBridgeSampleDepthFn', sampleProc),
        };
    end

    if (setDeviceProc ~= nil) then
        state.exports.setDevice = {
            name = setDeviceName,
            fn = ffi.cast('LibraPlatesDepthBridgeSetDeviceFn', setDeviceProc),
        };
    end

    if (statusProc ~= nil) then
        state.exports.getLastStatus = {
            name = statusName,
            fn = ffi.cast('LibraPlatesDepthBridgeGetLastValueFn', statusProc),
        };
    end

    if (hresultProc ~= nil) then
        state.exports.getLastHresult = {
            name = hresultName,
            fn = ffi.cast('LibraPlatesDepthBridgeGetLastValueFn', hresultProc),
        };
    end

    if (formatProc ~= nil) then
        state.exports.getLastFormat = {
            name = formatName,
            fn = ffi.cast('LibraPlatesDepthBridgeGetLastValueFn', formatProc),
        };
    end

    if (occludedProc ~= nil) then
        state.exports.isOccluded = {
            name = occludedName,
            fn = ffi.cast('LibraPlatesDepthBridgeIsOccludedFn', occludedProc),
        };
    end

    return true;
end

local function ExportName(key)
    local export = state.exports[key];

    if (export == nil) then
        return 'missing';
    end

    return tostring(export.name or 'present');
end

local function ExplainLastError(lastError)
    lastError = tonumber(lastError);

    if (lastError == 126) then
        return 'module not found';
    elseif (lastError == 193) then
        return 'wrong dll architecture';
    elseif (lastError == 1114) then
        return 'dll initialization failed';
    end

    return nil;
end

function nativeDepthBridge.Status(path)
    Load(path);

    return {
        attempted = state.attempted,
        loaded = state.loaded,
        path = state.path,
        lastError = state.lastError,
        lastErrorText = ExplainLastError(state.lastError),
        version = state.version,
        getVersion = ExportName('getVersion'),
        setDevice = ExportName('setDevice'),
        sampleDepth = ExportName('sampleDepth'),
        isOccluded = ExportName('isOccluded'),
    };
end

function nativeDepthBridge.SetDevice(device, path)
    Load(path);

    if (state.loaded ~= true) then
        return false, 'bridge not loaded';
    end

    local export = state.exports.setDevice;

    if (export == nil or export.fn == nil) then
        return false, 'setDevice export missing';
    end

    local ok = SafeCall(function ()
        return tonumber(export.fn(ffi.cast('void*', device)));
    end, 0);

    return ok == 1, (ok == 1 and nil or 'setDevice returned ' .. tostring(ok));
end

function nativeDepthBridge.GetLastNativeStatus()
    local function getValue(key)
        local export = state.exports[key];

        if (export == nil or export.fn == nil) then
            return nil;
        end

        return SafeCall(function ()
            return tonumber(export.fn());
        end, nil);
    end

    return {
        status = getValue('getLastStatus'),
        hresult = getValue('getLastHresult'),
        format = getValue('getLastFormat'),
    };
end

function nativeDepthBridge.Sample(screenX, screenY, path)
    Load(path);

    if (state.loaded ~= true) then
        return nil, 'bridge not loaded';
    end

    local export = state.exports.sampleDepth;

    if (export == nil or export.fn == nil) then
        return nil, 'sampleDepth export missing';
    end

    local sampledDepth = ffi.new('float[1]', 0);
    local ok = SafeCall(function ()
        return tonumber(export.fn(tonumber(screenX) or 0, tonumber(screenY) or 0, sampledDepth));
    end, 0);

    if (ok ~= 1) then
        return nil, 'sampleDepth returned ' .. tostring(ok);
    end

    return tonumber(sampledDepth[0]), nil;
end

function nativeDepthBridge.TestOcclusion(screenX, screenY, projectedDepth, bias, path)
    Load(path);

    if (state.loaded ~= true) then
        return nil, 'bridge not loaded';
    end

    local export = state.exports.isOccluded;

    if (export == nil or export.fn == nil) then
        local sampledDepth, err = nativeDepthBridge.Sample(screenX, screenY, path);

        if (sampledDepth == nil) then
            return nil, err;
        end

        return {
            sampledDepth = sampledDepth,
            projectedDepth = tonumber(projectedDepth),
            bias = tonumber(bias) or 0.0005,
            occluded = sampledDepth < ((tonumber(projectedDepth) or 0) - (tonumber(bias) or 0.0005)),
            source = 'lua-compare',
        }, nil;
    end

    local sampledDepth = ffi.new('float[1]', 0);
    local occluded = ffi.new('int[1]', 0);
    local ok = SafeCall(function ()
        return tonumber(export.fn(
            tonumber(screenX) or 0,
            tonumber(screenY) or 0,
            tonumber(projectedDepth) or 0,
            tonumber(bias) or 0.0005,
            occluded,
            sampledDepth
        ));
    end, 0);

    if (ok ~= 1) then
        return nil, 'isOccluded returned ' .. tostring(ok);
    end

    return {
        sampledDepth = tonumber(sampledDepth[0]),
        projectedDepth = tonumber(projectedDepth),
        bias = tonumber(bias) or 0.0005,
        occluded = (tonumber(occluded[0]) or 0) ~= 0,
        source = 'native',
    }, nil;
end

function nativeDepthBridge.PrintStatus(path)
    local status = nativeDepthBridge.Status(path);

    print(string.format(
        '[LibraPlates] DepthBridge loaded=%s path=%s lastError=%s (%s) version=%s',
        tostring(status.loaded),
        tostring(status.path),
        tostring(status.lastError),
        tostring(status.lastErrorText or 'none'),
        tostring(status.version)
    ));

    print(string.format(
        '[LibraPlates] DepthBridge exports getVersion=%s setDevice=%s sampleDepth=%s isOccluded=%s',
        tostring(status.getVersion),
        tostring(status.setDevice),
        tostring(status.sampleDepth),
        tostring(status.isOccluded)
    ));

    return status;
end

return nativeDepthBridge;
