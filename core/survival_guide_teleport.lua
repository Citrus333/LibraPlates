require('common');

local bit = require('bit');
local log = require('core.log');
local state = require('core.state');
local globalDefaults = require('config.global');
local survivalGuides = require('data.warp.survival_guides');

local survivalGuideTeleport = {};

local eventId = 8500;
local pending = nil;
local queue = {};
local debugEnabled = false;
local watchUntil = 0;
local unlockStatus = {};
local unlockStatusKnown = false;
local unlockStatusReliable = false;
local unlockStatusCheckedAt = 0;
local unlockStatusUnlockedCount = 0;
local unlockStatusTotalCount = #survivalGuides;
local unlockCacheVersion = 1;
local unlockParserName = 'event-num-teleport-table';

local function Now()
    return os.clock();
end

local function GetWarpSettings()
    local global = state.GetGlobalSettings(globalDefaults);
    global.quickMenu = global.quickMenu or {};
    global.quickMenu.warp = global.quickMenu.warp or {};

    return global.quickMenu.warp;
end

local function ReadU16LE(data, offset)
    local a = string.byte(data or '', offset + 1) or 0;
    local b = string.byte(data or '', offset + 2) or 0;

    return a + (b * 0x100);
end

local function ReadU32LE(data, offset)
    local a = string.byte(data or '', offset + 1) or 0;
    local b = string.byte(data or '', offset + 2) or 0;
    local c = string.byte(data or '', offset + 3) or 0;
    local d = string.byte(data or '', offset + 4) or 0;

    return a + (b * 0x100) + (c * 0x10000) + (d * 0x1000000);
end

local function FormatBytes(bytes, maxBytes)
    local output = {};
    local count = math.min(#(bytes or {}), math.max(1, tonumber(maxBytes) or 32));

    for index = 1, count do
        output[#output + 1] = string.format('%02X', tonumber(bytes[index]) or 0);
    end

    if (#(bytes or {}) > count) then
        output[#output + 1] = '...';
    end

    return table.concat(output, ' ');
end

local function FormatPacketString(data, maxBytes)
    if (type(data) ~= 'string') then
        return '';
    end

    local output = {};
    local count = math.min(#data, math.max(1, tonumber(maxBytes) or 48));

    for index = 1, count do
        output[#output + 1] = string.format('%02X', string.byte(data, index));
    end

    if (#data > count) then
        output[#output + 1] = '...';
    end

    return table.concat(output, ' ');
end

local function SendOutgoingPacket(id, packedData, description)
    if (packedData == nil) then
        return false;
    end

    local ok, err = pcall(function()
        AshitaCore:GetPacketManager():AddOutgoingPacket(id, packedData);
    end);

    if (ok ~= true) then
        log.Warn('Survival Guide teleport packet failed ' .. tostring(description or '') .. ' id=0x' .. string.format('%03X', tonumber(id) or 0) .. ' err=' .. tostring(err));
        return false;
    end

    if (debugEnabled == true) then
        log.Info('Survival Guide teleport sent packet ' .. tostring(description or '') .. ' id=0x' .. string.format('%03X', tonumber(id) or 0) .. ' bytes=' .. FormatBytes(packedData, 32));
    end

    return true;
end

local function GetCurrentZoneId()
    local zoneId = nil;

    pcall(function()
        zoneId = AshitaCore:GetMemoryManager():GetParty():GetMemberZone(0);
    end);

    return tonumber(zoneId) or 0;
end

local function GetServerId(targetIndex)
    local serverId = nil;

    pcall(function()
        serverId = AshitaCore:GetMemoryManager():GetEntity():GetServerId(tonumber(targetIndex) or 0);
    end);

    return tonumber(serverId) or 0;
end

local function BuildNpcPokePacket(serverId, targetIndex)
    return struct.pack(
        'bbbbihhhhfff',
        0x1A,
        0x07,
        0x00,
        0x00,
        tonumber(serverId) or 0,
        tonumber(targetIndex) or 0,
        0x00,
        0x00,
        0x00,
        0.0,
        0.0,
        0.0
    ):totable();
end

local function BuildMenuPacket(targetId, targetIndex, zoneId, optionIndex, unknown1, automated)
    return struct.pack(
        'bbbbiHHHBBHH',
        0x5B,
        0x05,
        0x00,
        0x00,
        tonumber(targetId) or 0,
        tonumber(optionIndex) or 0,
        tonumber(unknown1) or 0,
        tonumber(targetIndex) or 0,
        automated == true and 1 or 0,
        0x00,
        tonumber(zoneId) or 0,
        eventId
    ):totable();
end

local function FindEventId(data)
    if (type(data) ~= 'string') then
        return nil;
    end

    for offset = 4, math.max(4, #data - 1) do
        if (ReadU16LE(data, offset) == eventId) then
            return eventId;
        end
    end

    return nil;
end

local function CountUnlocked(status)
    local unlocked = 0;

    for _, guide in ipairs(survivalGuides) do
        if (status[tonumber(guide.index) or -1] == true) then
            unlocked = unlocked + 1;
        end
    end

    return unlocked;
end

local function LoadUnlockCache()
    if (unlockStatusKnown == true) then
        return true;
    end

    local ok, cache = pcall(function()
        return GetWarpSettings().survivalGuideUnlockCache;
    end);

    if (ok ~= true or type(cache) ~= 'table' or type(cache.unlocked) ~= 'table') then
        return false;
    end

    if (tonumber(cache.version) ~= unlockCacheVersion or tostring(cache.parser or '') ~= unlockParserName) then
        return false;
    end

    local loaded = {};
    for key, value in pairs(cache.unlocked) do
        if (value == true) then
            local index = tonumber(key);
            if (index ~= nil and index >= 0 and index <= 97) then
                loaded[index] = true;
            end
        end
    end

    local unlocked = CountUnlocked(loaded);
    if (unlocked <= 0) then
        return false;
    end

    unlockStatus = loaded;
    unlockStatusKnown = true;
    unlockStatusReliable = cache.reliable == true;
    unlockStatusCheckedAt = tonumber(cache.savedAt) or 0;
    unlockStatusUnlockedCount = unlocked;

    return true;
end

local function SaveUnlockCache()
    if (unlockStatusKnown ~= true or unlockStatusReliable ~= true) then
        return false;
    end

    local unlocked = {};
    for _, guide in ipairs(survivalGuides) do
        local index = tonumber(guide.index);
        if (index ~= nil and unlockStatus[index] == true) then
            unlocked[tostring(index)] = true;
        end
    end

    if (CountUnlocked(unlockStatus) <= 0) then
        return false;
    end

    local ok = pcall(function()
        local settings = GetWarpSettings();
        settings.survivalGuideUnlockCache = {
            version = unlockCacheVersion,
            reliable = true,
            parser = unlockParserName,
            savedAt = os.time(),
            total = unlockStatusTotalCount,
            unlocked = unlocked,
        };
        state.Save();
    end);

    return ok == true;
end

local function UpdateUnlockStatus(data)
    local groups = {
        [1] = ReadU32LE(data, 0x08 + (3 * 4)),
        [2] = ReadU32LE(data, 0x08 + (4 * 4)),
        [3] = ReadU32LE(data, 0x08 + (5 * 4)),
        [4] = ReadU32LE(data, 0x08 + (6 * 4)),
    };
    local status = {};

    for _, guide in ipairs(survivalGuides) do
        local value = groups[tonumber(guide.group) or 0] or 0;
        local mask = bit.lshift(1, tonumber(guide.bit) or 0);
        status[tonumber(guide.index) or -1] = bit.band(value, mask) ~= 0;
    end

    local unlocked = CountUnlocked(status);
    if (unlocked <= 0) then
        unlockStatus = {};
        unlockStatusKnown = false;
        unlockStatusReliable = false;
        unlockStatusUnlockedCount = 0;
        unlockStatusCheckedAt = os.time();
        log.Warn('Survival Guide unlock check returned 0 unlocked destinations, so LibraPlates ignored the cache.');
        return;
    end

    unlockStatus = status;
    unlockStatusKnown = true;
    unlockStatusReliable = true;
    unlockStatusCheckedAt = os.time();
    unlockStatusUnlockedCount = unlocked;
    SaveUnlockCache();

    if (debugEnabled == true) then
        log.Info('Survival Guide unlock cache updated: ' .. tostring(unlocked) .. '/' .. tostring(unlockStatusTotalCount));
    end
end

local function QueueAction(delay, fn)
    queue[#queue + 1] = {
        at = Now() + math.max(0, tonumber(delay) or 0),
        fn = fn,
    };
end

local function QueueTeleportSequence()
    local active = pending;
    if (active == nil) then
        return;
    end

    local destination = active.destination or {};
    local destinationIndex = tonumber(destination.index);

    if (destinationIndex == nil) then
        log.Warn('Survival Guide teleport missing destination index for ' .. tostring(destination.name or ''));
        pending = nil;
        return;
    end

    if (unlockStatusReliable == true and unlockStatus[destinationIndex] == false) then
        QueueAction(0.05, function()
            SendOutgoingPacket(0x05B, BuildMenuPacket(active.targetId, active.targetIndex, active.zoneId, 0, 16384, false), 'cancel locked destination');
            log.Warn('Survival Guide teleport canceled: destination is not unlocked: ' .. tostring(destination.name or ''));
        end);
        pending = nil;
        return;
    end

    QueueAction(0.08, function()
        SendOutgoingPacket(0x05B, BuildMenuPacket(active.targetId, active.targetIndex, active.zoneId, 1, destinationIndex, false), 'select destination');
        if (debugEnabled == true) then
            log.Info('Survival Guide teleport sent: ' .. tostring(destination.name or '') .. ' index=' .. tostring(destinationIndex));
        end
    end);

    pending = nil;
end

function survivalGuideTeleport.Request(destination, context)
    context = context or {};

    local targetIndex = tonumber(context.targetIndex) or 0;
    local targetId = tonumber(context.targetId) or GetServerId(targetIndex);
    local zoneId = GetCurrentZoneId();

    if (targetIndex <= 0 or targetId <= 0) then
        log.Warn('Survival Guide teleport failed: no valid Survival Guide target.');
        return false;
    end

    pending = {
        destination = destination,
        targetIndex = targetIndex,
        targetId = targetId,
        zoneId = zoneId,
        startedAt = Now(),
    };
    queue = {};

    if (SendOutgoingPacket(0x01A, BuildNpcPokePacket(targetId, targetIndex), 'poke survival guide') ~= true) then
        pending = nil;
        return false;
    end

    if (debugEnabled == true) then
        log.Info('Survival Guide teleport queued: ' .. tostring(destination.name or '') .. '. Waiting for menu.');
    end

    return true;
end

function survivalGuideTeleport.HandlePacketIn(e)
    if (pending == nil or e == nil or type(e.data) ~= 'string') then
        return;
    end

    if (debugEnabled == true and (e.id == 0x032 or e.id == 0x034 or e.id == 0x05C or e.id == 0x052)) then
        watchUntil = Now() + 12;
        log.Info('Survival Guide teleport saw incoming id=0x' .. string.format('%03X', tonumber(e.id) or 0) .. ' size=' .. tostring(e.size or #e.data) .. ' bytes=' .. FormatPacketString(e.data_modified or e.data, 48));
    end

    if (e.id ~= 0x032 and e.id ~= 0x034) then
        return;
    end

    local data = e.data_modified or e.data;
    if (FindEventId(data) ~= eventId) then
        return;
    end

    UpdateUnlockStatus(data);
    e.blocked = true;
    QueueTeleportSequence();
end

function survivalGuideTeleport.HandlePacketOut(e)
    if (debugEnabled ~= true or e == nil or type(e.data) ~= 'string') then
        return;
    end

    if (pending ~= nil or Now() < (tonumber(watchUntil) or 0) or e.id == 0x01A) then
        if (e.id == 0x01A or e.id == 0x05B or e.id == 0x05C or e.id == 0x114 or e.id == 0x016) then
            log.Info('Survival Guide teleport saw outgoing id=0x' .. string.format('%03X', tonumber(e.id) or 0) .. ' size=' .. tostring(e.size or #e.data) .. ' bytes=' .. FormatPacketString(e.data_modified or e.data, 48));
        end
    end
end

function survivalGuideTeleport.Update()
    if (pending ~= nil and (Now() - (tonumber(pending.startedAt) or 0)) > 4.0) then
        log.Warn('Survival Guide teleport timed out waiting for menu.');
        pending = nil;
        queue = {};
        return;
    end

    local now = Now();
    local index = 1;

    while index <= #queue do
        local action = queue[index];
        if (action ~= nil and now >= (tonumber(action.at) or 0)) then
            table.remove(queue, index);
            pcall(action.fn);
        else
            index = index + 1;
        end
    end
end

function survivalGuideTeleport.Cancel()
    pending = nil;
    queue = {};
end

function survivalGuideTeleport.SetDebugEnabled(value)
    debugEnabled = value == true;
end

function survivalGuideTeleport.GetUnlockSnapshot()
    LoadUnlockCache();

    local status = {};
    if (unlockStatusKnown == true and unlockStatusReliable == true) then
        for _, guide in ipairs(survivalGuides) do
            local index = tonumber(guide.index);
            if (index ~= nil) then
                status[index] = unlockStatus[index] == true;
            end
        end
    end

    return {
        known = unlockStatusKnown == true,
        reliable = unlockStatusReliable == true,
        checkedAt = unlockStatusCheckedAt,
        unlocked = unlockStatusUnlockedCount,
        total = unlockStatusTotalCount,
        pending = pending ~= nil,
        status = status,
    };
end

return survivalGuideTeleport;
