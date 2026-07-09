require('common');

local log = require('core.log');
local domenicData = require('data.warp.domenic');

local domenicTeleport = {};

local pending = nil;
local queue = {};
local debugEnabled = false;
local watchUntil = 0;

local function Now()
    return os.clock();
end

local function ReadU16LE(data, offset)
    local a = string.byte(data or '', offset + 1) or 0;
    local b = string.byte(data or '', offset + 2) or 0;

    return a + (b * 0x100);
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
        log.Warn('Domenic teleport packet failed ' .. tostring(description or '') .. ' id=0x' .. string.format('%03X', tonumber(id) or 0) .. ' err=' .. tostring(err));
        return false;
    end

    if (debugEnabled == true) then
        log.Info('Domenic teleport sent packet ' .. tostring(description or '') .. ' id=0x' .. string.format('%03X', tonumber(id) or 0) .. ' bytes=' .. FormatBytes(packedData, 32));
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

local function BuildMenuPacket(targetId, targetIndex, zoneId, eventId, optionIndex, unknown1, automated)
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
        tonumber(eventId) or 0
    ):totable();
end

local function PacketHasEventId(data, expectedEventId)
    expectedEventId = tonumber(expectedEventId) or 0;
    if (type(data) ~= 'string' or expectedEventId <= 0) then
        return false;
    end

    for offset = 4, math.max(4, #data - 1) do
        if (ReadU16LE(data, offset) == expectedEventId) then
            return true;
        end
    end

    return false;
end

local function QueueAction(delay, fn)
    queue[#queue + 1] = {
        at = Now() + math.max(0, tonumber(delay) or 0),
        fn = fn,
    };
end

local function QueueTeleportSequence(eventId)
    local active = pending;
    if (active == nil) then
        return;
    end

    local destination = active.destination or {};
    local option = tonumber(destination.option);
    if (option == nil) then
        log.Warn('Domenic teleport missing option for ' .. tostring(destination.name or ''));
        pending = nil;
        return;
    end

    QueueAction(0.12, function()
        SendOutgoingPacket(0x05B, BuildMenuPacket(active.targetId, active.targetIndex, active.zoneId, eventId, option, 0, false), 'select destination');
        if (debugEnabled == true) then
            log.Info('Domenic teleport sent: ' .. tostring(destination.name or '') .. ' option=' .. tostring(option));
        end
    end);

    pending = nil;
end

function domenicTeleport.Request(destination, context)
    context = context or {};

    local targetIndex = tonumber(context.targetIndex) or 0;
    local targetId = tonumber(context.targetId) or GetServerId(targetIndex);
    local zoneId = GetCurrentZoneId();
    local eventId = domenicData.eventIds[zoneId];

    if (targetIndex <= 0 or targetId <= 0) then
        log.Warn('Domenic teleport failed: no valid Domenic target.');
        return false;
    end

    if (eventId == nil) then
        log.Warn('Domenic teleport failed: current zone does not have a known Domenic event.');
        return false;
    end

    pending = {
        destination = destination,
        targetIndex = targetIndex,
        targetId = targetId,
        zoneId = zoneId,
        fallbackEventId = eventId,
        startedAt = Now(),
    };
    queue = {};

    if (SendOutgoingPacket(0x01A, BuildNpcPokePacket(targetId, targetIndex), 'poke Domenic') ~= true) then
        pending = nil;
        return false;
    end

    if (debugEnabled == true) then
        log.Info('Domenic teleport queued: ' .. tostring(destination.name or '') .. '. Waiting for menu.');
    end

    return true;
end

function domenicTeleport.HandlePacketIn(e)
    if (pending == nil or e == nil or type(e.data) ~= 'string') then
        return;
    end

    if (debugEnabled == true and (e.id == 0x032 or e.id == 0x034 or e.id == 0x05C or e.id == 0x052)) then
        watchUntil = Now() + 12;
        log.Info('Domenic teleport saw incoming id=0x' .. string.format('%03X', tonumber(e.id) or 0) .. ' size=' .. tostring(e.size or #e.data) .. ' bytes=' .. FormatPacketString(e.data_modified or e.data, 48));
    end

    if (e.id ~= 0x032 and e.id ~= 0x034) then
        return;
    end

    local eventId = pending.fallbackEventId;
    if (PacketHasEventId(e.data_modified or e.data, eventId) ~= true) then
        return;
    end

    e.blocked = true;
    QueueTeleportSequence(eventId);
end

function domenicTeleport.HandlePacketOut(e)
    if (debugEnabled ~= true or e == nil or type(e.data) ~= 'string') then
        return;
    end

    if (pending ~= nil or Now() < (tonumber(watchUntil) or 0) or e.id == 0x01A) then
        if (e.id == 0x01A or e.id == 0x05B or e.id == 0x05C or e.id == 0x114 or e.id == 0x016) then
            log.Info('Domenic teleport saw outgoing id=0x' .. string.format('%03X', tonumber(e.id) or 0) .. ' size=' .. tostring(e.size or #e.data) .. ' bytes=' .. FormatPacketString(e.data_modified or e.data, 48));
        end
    end
end

function domenicTeleport.Update()
    if (pending ~= nil and (Now() - (tonumber(pending.startedAt) or 0)) > 4.0) then
        log.Warn('Domenic teleport timed out waiting for menu.');
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

function domenicTeleport.SetDebugEnabled(value)
    debugEnabled = value == true;
end

return domenicTeleport;
