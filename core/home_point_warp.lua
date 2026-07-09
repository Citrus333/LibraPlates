require('common');

local bit = require('bit');
local log = require('core.log');
local state = require('core.state');
local globalDefaults = require('config.global');

local homePointWarp = {};

local pending = nil;
local queue = {};
local debugEnabled = false;
local watchUntil = 0;
local unlockStatus = {};
local unlockStatusKnown = false;
local unlockStatusReliable = false;
local unlockStatusReliabilityReason = 'not checked';
local unlockStatusParser = 'none';
local unlockStatusCheckedAt = 0;
local unlockStatusUnlockedCount = 0;
local unlockStatusTotalCount = 121;
local unlockStatusLoadedFromCache = false;
local unlockCacheVersion = 2;
local unlockParserName = 'event-num-menu-parameters';

local unavailableWarpIndexes = {
    [67] = true, -- Al Zahbi #1 exists in retail numbering but not in this server data.
};

local menuIds = {
    [8700] = true,
    [8701] = true,
    [8702] = true,
    [8703] = true,
    [8704] = true,
};

local function Now()
    return os.clock();
end

local function GetWarpSettings()
    local global = state.GetGlobalSettings(globalDefaults);
    global.quickMenu = global.quickMenu or {};
    global.quickMenu.warp = global.quickMenu.warp or {};

    return global.quickMenu.warp;
end

local function CountUnlocked(status)
    local unlocked = 0;

    for index = 0, 121 do
        if (unavailableWarpIndexes[index] ~= true and status[index] == true) then
            unlocked = unlocked + 1;
        end
    end

    return unlocked;
end

local function LoadUnlockCache()
    if (unlockStatusKnown == true) then
        return unlockStatusKnown == true;
    end

    local ok, cache = pcall(function()
        return GetWarpSettings().homePointUnlockCache;
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
            if (index ~= nil and index >= 0 and index <= 121 and unavailableWarpIndexes[index] ~= true) then
                loaded[index] = true;
            end
        end
    end

    local unlocked = CountUnlocked(loaded);
    if (unlocked <= 0) then
        return false;
    end

    unlockStatusLoadedFromCache = true;
    unlockStatus = loaded;
    unlockStatusKnown = true;
    unlockStatusReliable = cache.reliable == true;
    unlockStatusReliabilityReason = tostring(cache.reason or 'saved cache');
    unlockStatusParser = tostring(cache.parser or 'cache');
    unlockStatusCheckedAt = tonumber(cache.savedAt) or 0;
    unlockStatusUnlockedCount = unlocked;

    return true;
end

local function SaveUnlockCache()
    if (unlockStatusKnown ~= true or unlockStatusReliable ~= true) then
        return false;
    end

    local unlocked = {};
    for index = 0, 121 do
        if (unavailableWarpIndexes[index] ~= true and unlockStatus[index] == true) then
            unlocked[tostring(index)] = true;
        end
    end

    if (CountUnlocked(unlockStatus) <= 0) then
        return false;
    end

    local ok = pcall(function()
        local settings = GetWarpSettings();
        settings.homePointUnlockCache = {
            version = unlockCacheVersion,
            reliable = true,
            reason = unlockStatusReliabilityReason,
            parser = unlockStatusParser,
            savedAt = os.time(),
            total = unlockStatusTotalCount,
            unlocked = unlocked,
        };
        state.Save();
    end);

    return ok == true;
end

local function Read(data, format, offset)
    local ok, value = pcall(function()
        return struct.unpack(format, data, offset + 1);
    end);

    if (ok ~= true) then
        return nil;
    end

    return tonumber(value);
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
        log.Warn('Home Point warp packet failed ' .. tostring(description or '') .. ' id=0x' .. string.format('%03X', tonumber(id) or 0) .. ' err=' .. tostring(err));
        return false;
    end

    if (debugEnabled == true) then
        log.Info('Home Point warp sent packet ' .. tostring(description or '') .. ' id=0x' .. string.format('%03X', tonumber(id) or 0) .. ' bytes=' .. FormatBytes(packedData, 32));
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

local function GetEntityName(targetIndex)
    local name = nil;

    pcall(function()
        local entity = AshitaCore:GetMemoryManager():GetEntity();
        if (entity ~= nil and entity.GetName ~= nil) then
            name = entity:GetName(tonumber(targetIndex) or 0);
        end
    end);

    if (name ~= nil and tostring(name) ~= '') then
        return tostring(name);
    end

    pcall(function()
        local raw = AshitaCore:GetMemoryManager():GetEntity():GetEntity(tonumber(targetIndex) or 0);
        if (raw ~= nil and raw.Name ~= nil) then
            name = raw.Name;
        end
    end);

    return tostring(name or '');
end

local function GetCurrentTargetIndex()
    local targetIndex = nil;

    pcall(function()
        local target = AshitaCore:GetMemoryManager():GetTarget();
        if (target ~= nil and target.GetTargetIndex ~= nil) then
            targetIndex = target:GetTargetIndex(0);
            if (tonumber(targetIndex) == nil or tonumber(targetIndex) <= 0) then
                targetIndex = target:GetTargetIndex(1);
            end
        end
    end);

    targetIndex = tonumber(targetIndex) or 0;
    if (targetIndex <= 0) then
        return nil;
    end

    return targetIndex;
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

local function BuildMenuPacket(targetId, targetIndex, zoneId, menuId, optionIndex, unknown1, automated)
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
        tonumber(menuId) or 0
    ):totable();
end

local function FindMenuId(data)
    if (type(data) ~= 'string') then
        return nil;
    end

    for offset = 4, math.max(4, #data - 1) do
        local value = Read(data, 'H', offset);
        if (menuIds[value] == true) then
            return value;
        end
    end

    return nil;
end

local function GetHomePointNumber(value)
    local text = tostring(value or ''):lower();

    return tonumber(text:match('home[%s_]*point[%s_]*#?[%s_]*(%d+)')
        or text:match('homepoint[%s_]*#?[%s_]*(%d+)')
        or text:match('(%d+)')) or 1;
end

local function IsHomePointName(value)
    local text = tostring(value or ''):lower();

    return text:match('home[%s_]*point') ~= nil or text:match('homepoint') ~= nil;
end

local function HasMenuParameterBit(data, bitIndex)
    if (type(data) ~= 'string') then
        return false;
    end

    -- 0x034 layout after the 4-byte packet header:
    -- UniqueNo at 0x04, then num[0..7] at 0x08. Windower/Superwarp's
    -- "Menu Parameters" field starts at num[0], so bit 32 is num[1] bit 0.
    local paramsOffset = 0x08;
    bitIndex = tonumber(bitIndex) or 0;

    local byteOffset = paramsOffset + math.floor(bitIndex / 8);
    local byte = string.byte(data, byteOffset + 1) or 0;
    local bitOffset = bitIndex % 8;
    local mask = bit.lshift(1, bitOffset);

    return bit.band(byte, mask) ~= 0;
end

local function BuildUnlockStatus(data)
    local unlockBitStart = 32;
    local status = {};
    local unlocked = 0;

    for index = 0, 121 do
        status[index] = HasMenuParameterBit(data, unlockBitStart + index);
        if (unavailableWarpIndexes[index] ~= true and status[index] == true) then
            unlocked = unlocked + 1;
        end
    end

    return status, unlocked;
end

local function UpdateUnlockStatus(data, anchorWarpIndex)
    anchorWarpIndex = tonumber(anchorWarpIndex);

    local selectedStatus, selectedUnlocked = BuildUnlockStatus(data);
    local selectedParser = unlockParserName;
    local selectedReliable = true;
    local selectedReason = 'server event parameters';

    unlockStatus = selectedStatus;

    if (selectedUnlocked <= 0) then
        unlockStatus = {};
        unlockStatusKnown = false;
        unlockStatusReliable = false;
        unlockStatusReliabilityReason = 'empty cache';
        unlockStatusParser = 'none';
        unlockStatusCheckedAt = Now();
        unlockStatusUnlockedCount = 0;
        log.Warn('Home Point unlock check returned 0 unlocked destinations, so LibraPlates ignored the cache.');
        return;
    end

    unlockStatusKnown = true;
    unlockStatusReliable = selectedReliable == true;
    unlockStatusReliabilityReason = selectedReason;
    unlockStatusParser = selectedParser;
    unlockStatusCheckedAt = os.time();
    unlockStatusUnlockedCount = selectedUnlocked;

    SaveUnlockCache();

    log.Info(
        'Home Point unlock cache updated: ' ..
        tostring(unlockStatusUnlockedCount) .. '/' .. tostring(unlockStatusTotalCount) ..
        ' parser=' .. tostring(unlockStatusParser) ..
        ' reliable=' .. tostring(unlockStatusReliable == true)
    );

    if (debugEnabled == true) then
        log.Info(
            'Home Point unlock cache parser=' .. tostring(unlockStatusParser) ..
            ' reliable=' .. tostring(unlockStatusReliable == true) ..
            ' unlocked=' .. tostring(unlockStatusUnlockedCount) .. '/' .. tostring(unlockStatusTotalCount) ..
            ' anchor=' .. tostring(anchorWarpIndex or '') ..
            ' anchorUnlocked=' .. tostring(anchorWarpIndex ~= nil and unlockStatus[anchorWarpIndex] == true or false) ..
            ' reason=' .. tostring(unlockStatusReliabilityReason)
        );
    end

end

local function QueueAction(delay, fn)
    queue[#queue + 1] = {
        at = Now() + math.max(0, tonumber(delay) or 0),
        fn = fn,
    };
end

local function QueueWarpSequence(menuId)
    local active = pending;
    if (active == nil) then
        return;
    end

    local destination = active.destination or {};
    local targetId = active.targetId;
    local targetIndex = active.targetIndex;
    local zoneId = active.zoneId;
    local destinationIndex = tonumber(destination.warpIndex);

    if (destinationIndex == nil) then
        log.Warn('Home Point warp missing destination index for ' .. tostring(destination.zone or '') .. ' #' .. tostring(destination.id or ''));
        pending = nil;
        return;
    end

    if (unlockStatusReliable == true and unlockStatus[destinationIndex] == false) then
        QueueAction(0.05, function()
            SendOutgoingPacket(0x05B, BuildMenuPacket(targetId, targetIndex, zoneId, menuId, 0, 16384, false), 'cancel locked destination');
            log.Warn('Home Point warp canceled: destination is not unlocked: ' .. tostring(destination.zone or '') .. ' #' .. tostring(destination.id or ''));
        end);
        pending = nil;
        return;
    end

    QueueAction(0.05, function()
        SendOutgoingPacket(0x05B, BuildMenuPacket(targetId, targetIndex, zoneId, menuId, 8, 0, true), 'menu change');
    end);

    QueueAction(0.25, function()
        SendOutgoingPacket(0x05B, BuildMenuPacket(targetId, targetIndex, zoneId, menuId, 2, destinationIndex, true), 'select destination');
    end);

    QueueAction(0.45, function()
        SendOutgoingPacket(0x05B, BuildMenuPacket(targetId, targetIndex, zoneId, menuId, 2, destinationIndex, false), 'confirm destination');
        if (debugEnabled == true) then
            log.Info('Home Point warp sent: ' .. tostring(destination.zone or '') .. ' #' .. tostring(destination.id or '') .. ' index=' .. tostring(destinationIndex));
        end
    end);

    pending = nil;
end

local function QueueCancelMenu(active, menuId, reason)
    QueueAction(0.05, function()
        SendOutgoingPacket(0x05B, BuildMenuPacket(active.targetId, active.targetIndex, active.zoneId, menuId, 0, 16384, false), reason or 'cancel menu');
    end);
end

function homePointWarp.Request(destination, context)
    context = context or {};

    local targetIndex = tonumber(context.targetIndex) or 0;
    local targetId = tonumber(context.targetId) or GetServerId(targetIndex);
    local zoneId = GetCurrentZoneId();

    if (targetIndex <= 0 or targetId <= 0) then
        log.Warn('Home Point warp failed: no valid Home Point target.');
        return false;
    end

    pending = {
        destination = destination,
        mode = 'warp',
        targetIndex = targetIndex,
        targetId = targetId,
        zoneId = zoneId,
        anchorWarpIndex = tonumber(context.currentWarpIndex),
        startedAt = Now(),
        fallbackMenuId = 8700 + math.max(0, math.min(4, GetHomePointNumber(context.homePointNumber) - 1)),
    };

    queue = {};

    if (debugEnabled == true) then
        log.Info(
            'Home Point warp request targetIndex=' .. tostring(targetIndex) ..
            ' targetId=' .. tostring(targetId) ..
            ' zoneId=' .. tostring(zoneId) ..
            ' hpNumber=' .. tostring(GetHomePointNumber(context.homePointNumber)) ..
            ' fallbackMenu=' .. tostring(8700 + math.max(0, math.min(4, GetHomePointNumber(context.homePointNumber) - 1))) ..
            ' destination=' .. tostring(destination.zone or '') ..
            ' #' .. tostring(destination.id or '') ..
            ' warpIndex=' .. tostring(destination.warpIndex)
        );
    end

    if (SendOutgoingPacket(0x01A, BuildNpcPokePacket(targetId, targetIndex), 'poke home point') ~= true) then
        pending = nil;
        return false;
    end

    if (debugEnabled == true) then
        log.Info('Home Point warp queued: ' .. tostring(destination.zone or '') .. ' #' .. tostring(destination.id or '') .. '. Waiting for menu.');
    end
    return true;
end

local function StartUnlockRefresh(context)
    if (pending ~= nil) then
        return false;
    end

    context = context or {};

    local targetIndex = tonumber(context.targetIndex) or 0;
    local targetId = tonumber(context.targetId) or GetServerId(targetIndex);
    local zoneId = GetCurrentZoneId();

    if (targetIndex <= 0 or targetId <= 0) then
        return false;
    end

    pending = {
        mode = 'refresh',
        targetIndex = targetIndex,
        targetId = targetId,
        zoneId = zoneId,
        anchorWarpIndex = tonumber(context.currentWarpIndex),
        startedAt = Now(),
        fallbackMenuId = 8700 + math.max(0, math.min(4, GetHomePointNumber(context.homePointNumber) - 1)),
    };

    queue = {};

    if (SendOutgoingPacket(0x01A, BuildNpcPokePacket(targetId, targetIndex), 'refresh home point unlocks') ~= true) then
        pending = nil;
        return false;
    end

    return true;
end

function homePointWarp.RefreshUnlocks(context)
    LoadUnlockCache();

    if (unlockStatusKnown == true) then
        return false;
    end

    return StartUnlockRefresh(context);
end

function homePointWarp.ForceRefreshUnlocks(context)
    if (pending ~= nil) then
        return false;
    end

    unlockStatusKnown = false;
    unlockStatusReliable = false;
    unlockStatusReliabilityReason = 'forced refresh';
    unlockStatusParser = 'none';
    unlockStatusLoadedFromCache = false;
    unlockStatus = {};

    return StartUnlockRefresh(context);
end

function homePointWarp.ForceRefreshFromCurrentTarget()
    local targetIndex = GetCurrentTargetIndex();
    if (targetIndex == nil) then
        return false, 'Target a Home Point crystal first.';
    end

    local name = GetEntityName(targetIndex);
    if (IsHomePointName(name) ~= true) then
        return false, 'Current target is not a Home Point.';
    end

    local ok = homePointWarp.ForceRefreshUnlocks({
        targetIndex = targetIndex,
        homePointNumber = name,
    });

    if (ok ~= true) then
        return false, 'Refresh could not start. Stand close to a Home Point and try again.';
    end

    return true, 'Checking Home Point unlocks...';
end

function homePointWarp.HandlePacketIn(e)
    if (pending == nil or e == nil or type(e.data) ~= 'string') then
        return;
    end

    if (debugEnabled == true and (e.id == 0x032 or e.id == 0x034 or e.id == 0x05C or e.id == 0x052)) then
        watchUntil = Now() + 12;
        log.Info('Home Point warp saw incoming id=0x' .. string.format('%03X', tonumber(e.id) or 0) .. ' size=' .. tostring(e.size or #e.data) .. ' bytes=' .. FormatPacketString(e.data_modified or e.data, 48));
    end

    if (e.id ~= 0x032 and e.id ~= 0x034) then
        return;
    end

    local data = e.data_modified or e.data;
    local menuId = FindMenuId(data) or pending.fallbackMenuId;

    if (menuIds[menuId] ~= true) then
        if (debugEnabled == true) then
            log.Info('Home Point warp ignored menu packet; menuId=' .. tostring(menuId));
        end
        return;
    end

    if (debugEnabled == true) then
        log.Info('Home Point warp menu detected menuId=' .. tostring(menuId));
    end

    UpdateUnlockStatus(data, pending.anchorWarpIndex);
    e.blocked = true;

    if (pending.mode == 'refresh') then
        QueueCancelMenu(pending, menuId, 'cancel unlock refresh');
        pending = nil;
        return;
    end

    QueueWarpSequence(menuId);
end

function homePointWarp.HandlePacketOut(e)
    if (debugEnabled ~= true or e == nil or type(e.data) ~= 'string') then
        return;
    end

    if (pending ~= nil or Now() < (tonumber(watchUntil) or 0) or e.id == 0x01A) then
        if (e.id == 0x01A or e.id == 0x05B or e.id == 0x05C or e.id == 0x114 or e.id == 0x016) then
            log.Info('Home Point warp saw outgoing id=0x' .. string.format('%03X', tonumber(e.id) or 0) .. ' size=' .. tostring(e.size or #e.data) .. ' bytes=' .. FormatPacketString(e.data_modified or e.data, 48));
        end
    end
end

function homePointWarp.Update()
    if (pending ~= nil and (Now() - (tonumber(pending.startedAt) or 0)) > 4.0) then
        log.Warn('Home Point warp timed out waiting for menu.');
        pending = nil;
        queue = {};
        return;
    end

    if (#queue == 0) then
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

function homePointWarp.Cancel()
    pending = nil;
    queue = {};
end

function homePointWarp.SetDebugEnabled(value)
    debugEnabled = value == true;
end

function homePointWarp.GetUnlockStatus(warpIndex)
    LoadUnlockCache();

    return unlockStatus[tonumber(warpIndex) or -1];
end

function homePointWarp.GetUnlockSnapshot()
    LoadUnlockCache();

    local status = {};
    if (unlockStatusKnown == true and unlockStatusReliable == true) then
        for index = 0, 121 do
            status[index] = unlockStatus[index] == true;
        end
    end

    return {
        known = unlockStatusKnown == true,
        reliable = unlockStatusReliable == true,
        reason = unlockStatusReliabilityReason,
        parser = unlockStatusParser,
        checkedAt = unlockStatusCheckedAt,
        unlocked = unlockStatusUnlockedCount,
        total = unlockStatusTotalCount,
        pending = pending ~= nil and pending.mode or nil,
        status = status,
    };
end

function homePointWarp.HasUnlockStatus()
    LoadUnlockCache();

    return unlockStatusKnown == true;
end

function homePointWarp.IsUnlockStatusReliable()
    LoadUnlockCache();

    return unlockStatusReliable == true;
end

function homePointWarp.GetUnlockSummary()
    LoadUnlockCache();

    return {
        known = unlockStatusKnown == true,
        reliable = unlockStatusReliable == true,
        reason = unlockStatusReliabilityReason,
        parser = unlockStatusParser,
        checkedAt = unlockStatusCheckedAt,
        unlocked = unlockStatusUnlockedCount,
        total = unlockStatusTotalCount,
        pending = pending ~= nil and pending.mode or nil,
    };
end

return homePointWarp;
