local d3d = require('d3d8');
local log = require('core.log');
local nativeDepthBridge = require('core.native_depth_bridge');

local occlusion = {};
local d3d8dev = d3d.get_device();
local deviceSet = false;
local statusPrinted = false;
local testErrorPrinted = false;

local nativeStatusNames = {
    [1] = 'ok',
    [-1] = 'no device',
    [-2] = 'get depth surface failed',
    [-3] = 'get depth desc failed',
    [-4] = 'sample out of bounds',
    [-5] = 'lock depth surface failed',
    [-6] = 'unsupported depth format',
};

local function FormatNativeStatus(nativeStatus)
    if (nativeStatus == nil) then
        return 'nativeStatus=nil';
    end

    local status = tonumber(nativeStatus.status);
    local statusName = nativeStatusNames[status] or 'unknown';

    return string.format(
        'nativeStatus=%s (%s) hresult=%s format=%s',
        tostring(status),
        tostring(statusName),
        tostring(nativeStatus.hresult),
        tostring(nativeStatus.format)
    );
end

local function EnsureDevice()
    if (d3d8dev == nil) then
        d3d8dev = d3d.get_device();
    end

    return d3d8dev;
end

function occlusion.IsScreenPointOccluded(screenX, screenY, screenZ, settings)
    if (settings == nil or settings.enabled ~= true) then
        return false;
    end

    if (screenX == nil or screenY == nil or screenZ == nil) then
        return false;
    end

    local bridgeStatus = nativeDepthBridge.Status();

    if (bridgeStatus == nil or bridgeStatus.loaded ~= true) then
        if (statusPrinted ~= true) then
            statusPrinted = true;
            log.Warn('Depth bridge not loaded; occlusion disabled.');
        end

        return false;
    end

    if (deviceSet ~= true) then
        local activeDevice = EnsureDevice();

        if (activeDevice == nil) then
            return false;
        end

        local ok, err = nativeDepthBridge.SetDevice(activeDevice);
        deviceSet = (ok == true);

        if (deviceSet ~= true) then
            if (statusPrinted ~= true) then
                statusPrinted = true;
                log.Warn('Depth bridge device setup failed: ' .. tostring(err));
            end

            return false;
        end
    end

    local result, err = nativeDepthBridge.TestOcclusion(
        screenX,
        screenY,
        screenZ,
        tonumber(settings.depthBias) or 0.0005
    );

    if (result == nil and testErrorPrinted ~= true) then
        testErrorPrinted = true;
        log.Warn('Depth bridge occlusion test failed: ' .. tostring(err) .. ' ' .. FormatNativeStatus(nativeDepthBridge.GetLastNativeStatus()));
    end

    return (result ~= nil and result.occluded == true);
end

function occlusion.TestScreenPoint(screenX, screenY, screenZ, settings)
    local bridgeStatus = nativeDepthBridge.Status();

    if (bridgeStatus == nil or bridgeStatus.loaded ~= true) then
        return nil, 'bridge not loaded', nativeDepthBridge.GetLastNativeStatus();
    end

    if (deviceSet ~= true) then
        local activeDevice = EnsureDevice();

        if (activeDevice == nil) then
            return nil, 'device unavailable', nativeDepthBridge.GetLastNativeStatus();
        end

        local ok, err = nativeDepthBridge.SetDevice(activeDevice);
        deviceSet = (ok == true);

        if (deviceSet ~= true) then
            return nil, 'setDevice failed: ' .. tostring(err), nativeDepthBridge.GetLastNativeStatus();
        end
    end

    local result, err = nativeDepthBridge.TestOcclusion(
        screenX,
        screenY,
        screenZ,
        tonumber(settings ~= nil and settings.depthBias) or 0.0005
    );

    return result, err, nativeDepthBridge.GetLastNativeStatus();
end

function occlusion.FormatNativeStatus(nativeStatus)
    return FormatNativeStatus(nativeStatus);
end

function occlusion.PrintStatus()
    local status = nativeDepthBridge.PrintStatus();
    local nativeStatus = nativeDepthBridge.GetLastNativeStatus();

    log.Info(FormatNativeStatus(nativeStatus));

    return status;
end

function occlusion.RefreshDevice()
    d3d8dev = d3d.get_device();
    deviceSet = false;
    statusPrinted = false;
    testErrorPrinted = false;
    return d3d8dev ~= nil;
end

function occlusion.ResetDevice()
    pcall(function()
        nativeDepthBridge.SetDevice(nil);
    end);
    d3d8dev = nil;
    deviceSet = false;
    statusPrinted = false;
    testErrorPrinted = false;
end

return occlusion;
