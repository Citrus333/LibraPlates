require('common');

local log = require('core.log');
local fieldManualData = require('data.warp.field_manual');

local fieldManualSupport = {};

local pending = nil;
local queue = {};
local debugEnabled = false;
local watchUntil = 0;
local knownActiveRegime = nil;
local statusKnown = false;
local lastFieldManualTarget = nil;

local function Now()
    return os.clock();
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
        log.Warn('Field Manual support packet failed ' .. tostring(description or '') .. ' id=0x' .. string.format('%03X', tonumber(id) or 0) .. ' err=' .. tostring(err));
        return false;
    end

    if (debugEnabled == true) then
        log.Info('Field Manual support sent packet ' .. tostring(description or '') .. ' id=0x' .. string.format('%03X', tonumber(id) or 0) .. ' bytes=' .. FormatBytes(packedData, 32));
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
    if (type(data) ~= 'string') then
        return false;
    end

    expectedEventId = tonumber(expectedEventId) or 0;
    if (expectedEventId <= 0) then
        return false;
    end

    for offset = 4, math.max(4, #data - 1) do
        local value = ReadU16LE(data, offset);
        if (value == expectedEventId) then
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

local function QueueSupportSequence(eventId)
    local active = pending;
    if (active == nil) then
        return;
    end

    local service = active.service or {};
    if (service.action == 'status') then
        pending = nil;
        return;
    end

    local option = tonumber(service.option);
    if (option == nil) then
        log.Warn('Field Manual support missing option for ' .. tostring(service.label or ''));
        pending = nil;
        return;
    end

    local unknown1 = tonumber(service.unknown1) or 0;
    if (service.repeatEnabled == true) then
        unknown1 = unknown1 + 0x8000;
    end

    QueueAction(0.12, function()
        SendOutgoingPacket(0x05B, BuildMenuPacket(active.targetId, active.targetIndex, active.zoneId, eventId, option, unknown1, service.update == true), 'select support');

        if (service.action == 'cancel') then
            knownActiveRegime = nil;
            statusKnown = true;
        elseif (service.page ~= nil) then
            knownActiveRegime = {
                zoneId = active.zoneId,
                page = service.page,
                regimeId = service.regimeId,
                repeatEnabled = service.repeatEnabled == true,
            };
            statusKnown = true;
        end

        if (debugEnabled == true) then
            log.Info('Field Manual support sent: ' .. tostring(service.label or '') .. ' option=' .. tostring(option));
        end
    end);

    pending = nil;
end

function fieldManualSupport.Request(service, context)
    context = context or {};

    local targetIndex = tonumber(context.targetIndex) or 0;
    local targetId = tonumber(context.targetId) or GetServerId(targetIndex);
    local zoneId = GetCurrentZoneId();
    local eventId = fieldManualData.eventIds[zoneId];

    if (targetIndex <= 0 or targetId <= 0) then
        log.Warn('Field Manual support failed: no valid Field Manual target.');
        return false;
    end

    if (eventId == nil) then
        log.Warn('Field Manual support failed: current zone does not have a known Field Manual event.');
        return false;
    end

    pending = {
        service = service,
        targetIndex = targetIndex,
        targetId = targetId,
        zoneId = zoneId,
        fallbackEventId = eventId,
        startedAt = Now(),
    };
    lastFieldManualTarget = {
        targetIndex = targetIndex,
        targetId = targetId,
        zoneId = zoneId,
        eventId = eventId,
    };
    queue = {};

    if (SendOutgoingPacket(0x01A, BuildNpcPokePacket(targetId, targetIndex), 'poke field manual') ~= true) then
        pending = nil;
        return false;
    end

    if (debugEnabled == true) then
        log.Info('Field Manual support queued: ' .. tostring(service.label or '') .. '. Waiting for menu.');
    end

    return true;
end

function fieldManualSupport.EmergencyExit()
    local active = pending or lastFieldManualTarget;
    if (active == nil) then
        log.Warn('Field Manual emergency exit failed: no recent Field Manual target.');
        return false;
    end

    local targetId = active.targetId;
    local targetIndex = active.targetIndex;
    local zoneId = active.zoneId or GetCurrentZoneId();
    local eventId = active.fallbackEventId or active.eventId or fieldManualData.eventIds[zoneId];

    if (targetId == nil or targetIndex == nil or eventId == nil) then
        log.Warn('Field Manual emergency exit failed: incomplete Field Manual target state.');
        return false;
    end

    pending = nil;
    queue = {};

    SendOutgoingPacket(0x05B, BuildMenuPacket(targetId, targetIndex, zoneId, eventId, 0, 16384, false), 'emergency exit');
    log.Info('Field Manual emergency exit sent.');
    return true;
end

function fieldManualSupport.RequestStatus(context)
    if (pending ~= nil and (pending.service or {}).action == 'status') then
        return false;
    end

    return fieldManualSupport.Request({ label = 'Training status check', action = 'status' }, context or {});
end

function fieldManualSupport.HandlePacketIn(e)
    if (pending == nil or e == nil or type(e.data) ~= 'string') then
        return;
    end

    if (debugEnabled == true and (e.id == 0x032 or e.id == 0x034 or e.id == 0x05C or e.id == 0x052)) then
        watchUntil = Now() + 12;
        log.Info('Field Manual support saw incoming id=0x' .. string.format('%03X', tonumber(e.id) or 0) .. ' size=' .. tostring(e.size or #e.data) .. ' bytes=' .. FormatPacketString(e.data_modified or e.data, 48));
    end

    if (e.id ~= 0x032 and e.id ~= 0x034) then
        return;
    end

    local eventId = pending.fallbackEventId;
    if (PacketHasEventId(e.data_modified or e.data, eventId) ~= true) then
        return;
    end

    e.blocked = true;
    if ((pending.service or {}).action == 'status') then
        local data = e.data_modified or e.data;
        local regimeId = ReadU32LE(data, 0x08 + (7 * 4));
        statusKnown = true;

        if (regimeId ~= nil and regimeId > 0) then
            knownActiveRegime = {
                zoneId = pending.zoneId,
                regimeId = regimeId,
            };
        else
            knownActiveRegime = nil;
        end

        local active = pending;
        QueueAction(0.12, function()
            SendOutgoingPacket(0x05B, BuildMenuPacket(active.targetId, active.targetIndex, active.zoneId, eventId, 0, 16384, false), 'cancel status check');
        end);

        if (debugEnabled == true) then
            log.Info('Field Manual status checked: regimeId=' .. tostring(regimeId));
        end

        pending = nil;
        return;
    end

    QueueSupportSequence(eventId);
end

function fieldManualSupport.HandlePacketOut(e)
    if (debugEnabled ~= true or e == nil or type(e.data) ~= 'string') then
        return;
    end

    if (pending ~= nil or Now() < (tonumber(watchUntil) or 0) or e.id == 0x01A) then
        if (e.id == 0x01A or e.id == 0x05B or e.id == 0x05C or e.id == 0x114 or e.id == 0x016) then
            log.Info('Field Manual support saw outgoing id=0x' .. string.format('%03X', tonumber(e.id) or 0) .. ' size=' .. tostring(e.size or #e.data) .. ' bytes=' .. FormatPacketString(e.data_modified or e.data, 48));
        end
    end
end

function fieldManualSupport.Update()
    if (pending ~= nil and (Now() - (tonumber(pending.startedAt) or 0)) > 4.0) then
        log.Warn('Field Manual support timed out waiting for menu.');
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

function fieldManualSupport.SetDebugEnabled(value)
    debugEnabled = value == true;
end

function fieldManualSupport.HasKnownActiveRegime()
    return knownActiveRegime ~= nil;
end

function fieldManualSupport.IsStatusKnown()
    return statusKnown == true;
end

function fieldManualSupport.IsStatusCheckPending()
    return pending ~= nil and (pending.service or {}).action == 'status';
end

function fieldManualSupport.GetKnownActiveRegime()
    return knownActiveRegime;
end

return fieldManualSupport;
