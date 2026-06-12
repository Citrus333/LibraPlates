local log = require('core.log');

local mogJobDebug = {};

local debugUntil = nil;
local captureFilePath = 'TEMP WORK FOLDER\\mog_job_debug.log';
local moogleTargetSeenUntil = nil;
local recentPacketKeys = {};
local ignoredPacketIds = {
    [0x015] = true,
    [0x016] = true,
    [0x017] = true,
    [0x01A] = true,
    [0x01B] = true,
    [0x01C] = true,
    [0x028] = true,
    [0x037] = true,
    [0x038] = true,
    [0x039] = true,
    [0x03A] = true,
    [0x03C] = true,
    [0x05A] = true,
    [0x05B] = true,
    [0x063] = true,
    [0x0DC] = true,
};

local function GetPacketData(e)
    return (e ~= nil) and (e.data_modified or e.data or e.data_raw) or nil;
end

local function GetPacketSize(e)
    return (e ~= nil and tonumber(e.size)) or 0;
end

local function GetNow()
    return os.clock();
end

local function IsEnabled()
    return tonumber(debugUntil) ~= nil and GetNow() < tonumber(debugUntil);
end

local function NormalizeName(name)
    return tostring(name or ''):gsub('\170', ''):lower();
end

local function FormatPacketBytes(data, maxBytes)
    if (type(data) ~= 'string' or data == '') then
        return '';
    end

    local size = math.min(#data, math.max(1, tonumber(maxBytes) or 24));
    local parts = {};

    for index = 1, size do
        parts[#parts + 1] = string.format('%02X', string.byte(data, index));
    end

    if (#data > size) then
        parts[#parts + 1] = '...';
    end

    return table.concat(parts, ' ');
end

local function GetTargetSummary()
    local targetIndex = nil;
    local targetName = nil;

    pcall(function()
        local target = AshitaCore:GetMemoryManager():GetTarget();
        targetIndex = target:GetTargetIndex(0);
    end);

    if (tonumber(targetIndex) ~= nil and tonumber(targetIndex) >= 0) then
        pcall(function()
            local entity = GetEntity(targetIndex);
            targetName = entity ~= nil and entity.Name or nil;
        end);
    end

    if (targetName ~= nil and tostring(targetName) ~= '') then
        return tostring(targetName):gsub('\170', '') .. '#' .. tostring(targetIndex);
    end

    return tostring(targetIndex);
end

local function GetTargetInfo()
    local targetIndex = nil;
    local targetName = nil;

    pcall(function()
        local target = AshitaCore:GetMemoryManager():GetTarget();
        targetIndex = target:GetTargetIndex(0);
    end);

    if (tonumber(targetIndex) ~= nil and tonumber(targetIndex) >= 0) then
        pcall(function()
            local entity = GetEntity(targetIndex);
            targetName = entity ~= nil and entity.Name or nil;
        end);
    end

    return targetIndex, tostring(targetName or ''):gsub('\170', '');
end

local function IsMoogleName(name)
    local clean = NormalizeName(name);
    return clean:find('moogle', 1, true) ~= nil;
end

local function ShouldCaptureNow()
    local _, targetName = GetTargetInfo();

    if (IsMoogleName(targetName) == true) then
        moogleTargetSeenUntil = GetNow() + 8;
        return true;
    end

    return tonumber(moogleTargetSeenUntil) ~= nil and GetNow() < tonumber(moogleTargetSeenUntil);
end

local function AppendLine(line)
    local file = io.open(captureFilePath, 'a');

    if (file == nil) then
        return;
    end

    file:write(tostring(line or ''), '\r\n');
    file:close();
end

local function LogPacket(direction, e)
    if (e == nil) then
        return;
    end

    local packetId = tonumber(e.id);

    if (packetId == nil or ignoredPacketIds[packetId] == true) then
        return;
    end

    if (ShouldCaptureNow() ~= true) then
        return;
    end

    local data = GetPacketData(e);
    local size = GetPacketSize(e);
    local bytesText = FormatPacketBytes(data, 32);
    local packetKey = tostring(direction) .. ':' .. string.format('%03X', packetId) .. ':' .. tostring(size) .. ':' .. bytesText;
    local now = GetNow();
    local lastSeen = recentPacketKeys[packetKey];

    if (tonumber(lastSeen) ~= nil and (now - tonumber(lastSeen)) < 1.25) then
        return;
    end

    recentPacketKeys[packetKey] = now;

    local line = string.format(
        '[%s] %s id=0x%03X size=%s target=%s bytes=%s',
        os.date('%H:%M:%S'),
        tostring(direction),
        packetId,
        tostring(size),
        GetTargetSummary(),
        bytesText
    );

    log.Info(line);
    AppendLine(line);
end

function mogJobDebug.EnableForSeconds(seconds)
    local duration = math.max(5, tonumber(seconds) or 20);
    debugUntil = GetNow() + duration;
    moogleTargetSeenUntil = nil;
    recentPacketKeys = {};

    local file = io.open(captureFilePath, 'w');
    if (file ~= nil) then
        file:write('LibraPlates mog job debug\r\n');
        file:write('Started: ', os.date('%Y-%m-%d %H:%M:%S'), '\r\n');
        file:close();
    end

    log.Info('Mog job debug on for ' .. tostring(duration) .. ' seconds. It will only log while a Moogle is targeted or just interacted with. Log: ' .. captureFilePath);
end

function mogJobDebug.SetEnabled(enabled)
    if (enabled == true) then
        mogJobDebug.EnableForSeconds(20);
        return;
    end

    debugUntil = nil;
    moogleTargetSeenUntil = nil;
    recentPacketKeys = {};
end

function mogJobDebug.GetDebugText()
    local remaining = 0;

    if (tonumber(debugUntil) ~= nil) then
        remaining = math.max(0, tonumber(debugUntil) - GetNow());
    end

    return 'Mog job debug enabled=' .. tostring(IsEnabled()) .. ' remaining=' .. string.format('%.1f', remaining) .. ' file=' .. captureFilePath;
end

function mogJobDebug.HandlePacketIn(e)
    if (IsEnabled() ~= true) then
        return;
    end

    LogPacket('IN ', e);
end

function mogJobDebug.HandlePacketOut(e)
    if (IsEnabled() ~= true) then
        return;
    end

    LogPacket('OUT', e);
end

return mogJobDebug;
