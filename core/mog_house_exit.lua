require('common');

local entities = require('core.entities');
local log = require('core.log');
local state = require('core.state');

local mogHouseExit = {};

local debugEnabled = false;
-- Default to the locked state so reloading the addon while already inside a
-- Mog House still shows useful quest guidance. The next 0x00A packet replaces
-- this with the server-authoritative value.
local currentExitBit = nil;

-- The server writes MyRoomExitBit into the 0x00A zone-in packet. It is 0 when
-- the character has not unlocked alternate exits for the current city, and is
-- the city's exit bit when the corresponding Mog House quest is complete.
local LOGIN_PACKET_ID = 0x00A;
local LOGIN_PACKET_MOG_HOUSE_EXIT_BIT_OFFSET = 0x0AE;

local cityGroups = {
    {
        bit = 1,
        unlockQuest = "Growing Flowers",
        zones = {
            { zoneId = 230, label = "Southern San d'Oria", mode = 1 },
            { zoneId = 231, label = "Northern San d'Oria", mode = 2 },
            { zoneId = 232, label = "Port San d'Oria", mode = 3 },
        },
    },
    {
        bit = 2,
        unlockQuest = "A Lady's Heart",
        zones = {
            { zoneId = 234, label = 'Bastok Mines', mode = 1 },
            { zoneId = 235, label = 'Bastok Markets', mode = 2 },
            { zoneId = 236, label = 'Port Bastok', mode = 3 },
        },
    },
    {
        bit = 3,
        unlockQuest = "Flower Child",
        zones = {
            { zoneId = 238, label = 'Windurst Waters', mode = 1 },
            { zoneId = 239, label = 'Windurst Walls', mode = 2 },
            { zoneId = 240, label = 'Port Windurst', mode = 3 },
            { zoneId = 241, label = 'Windurst Woods', mode = 4 },
        },
    },
    {
        bit = 4,
        unlockQuest = "Pretty Little Things",
        zones = {
            { zoneId = 243, label = "Ru'Lude Gardens", mode = 1 },
            { zoneId = 244, label = 'Upper Jeuno', mode = 2 },
            { zoneId = 245, label = 'Lower Jeuno', mode = 3 },
            { zoneId = 246, label = 'Port Jeuno', mode = 4 },
        },
    },
    {
        bit = 5,
        unlockQuest = "Keeping Notes",
        zones = {
            { zoneId = 49, label = 'Al Zahbi', mode = 1 },
            { zoneId = 50, label = 'Aht Urhgan Whitegate', mode = 2 },
        },
    },
    {
        bit = 9,
        zones = {
            { zoneId = 256, label = 'Western Adoulin', mode = 1 },
            { zoneId = 257, label = 'Eastern Adoulin', mode = 2 },
        },
    },
};

local zoneToGroup = {};
for _, group in ipairs(cityGroups) do
    for _, zone in ipairs(group.zones) do
        zoneToGroup[zone.zoneId] = group;
    end
end

local function GetStorage()
    local global = state.GetGlobalSettings({});
    if (type(global.mogHouseExit) ~= 'table') then
        global.mogHouseExit = {};
    end

    if (type(global.mogHouseExit.exitBitsByGroup) ~= 'table') then
        global.mogHouseExit.exitBitsByGroup = {};
    end

    return global.mogHouseExit.exitBitsByGroup;
end

local function GetStoredExitBit(group)
    if (group == nil or group.bit == nil) then
        return nil;
    end

    local storage = GetStorage();
    return tonumber(storage[tostring(group.bit)]);
end

local function StoreExitBit(group, value)
    if (group == nil or group.bit == nil or tonumber(value) == nil) then
        return;
    end

    local storage = GetStorage();
    storage[tostring(group.bit)] = tonumber(value) or 0;
    state.SaveThrottled(1.0);
end

local function GetCurrentExitBit(group)
    if (currentExitBit ~= nil) then
        return tonumber(currentExitBit) or 0;
    end

    return GetStoredExitBit(group);
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

local function GetCurrentZoneId()
    local zoneId = nil;

    pcall(function()
        zoneId = AshitaCore:GetMemoryManager():GetParty():GetMemberZone(0);
    end);

    return tonumber(zoneId) or 0;
end

local function SendOutgoingPacket(id, packedData, description)
    if (packedData == nil) then
        return false;
    end

    local ok, err = pcall(function()
        AshitaCore:GetPacketManager():AddOutgoingPacket(id, packedData);
    end);

    if (ok ~= true) then
        log.Warn('Mog House Exit packet failed ' .. tostring(description or '') .. ' id=0x' .. string.format('%03X', tonumber(id) or 0) .. ' err=' .. tostring(err));
        return false;
    end

    if (debugEnabled == true) then
        log.Info('Mog House Exit sent packet ' .. tostring(description or '') .. ' id=0x' .. string.format('%03X', tonumber(id) or 0) .. ' bytes=' .. FormatBytes(packedData, 32));
    end

    return true;
end

local function BuildExitPacket(destination)
    return struct.pack(
        'bbbbc4fffHBB',
        0x5E,
        0x0C,
        0x00,
        0x00,
        'zmrq',
        0.0,
        0.0,
        0.0,
        0,
        tonumber(destination.bit) or 0,
        tonumber(destination.mode) or 0
    ):totable();
end

function mogHouseExit.SetDebugEnabled(value)
    debugEnabled = value == true;
end

function mogHouseExit.HandlePacketIn(e)
    if (e == nil or tonumber(e.id) ~= LOGIN_PACKET_ID) then
        return;
    end

    local packetData = e.data or e.data_modified;
    if (packetData == nil) then
        return;
    end

    local ok, value = pcall(struct.unpack, 'B', packetData, LOGIN_PACKET_MOG_HOUSE_EXIT_BIT_OFFSET + 1);
    if (ok == true and tonumber(value) ~= nil) then
        currentExitBit = tonumber(value);
        StoreExitBit(zoneToGroup[GetCurrentZoneId()], currentExitBit);
    end

    if (debugEnabled == true) then
        log.Info('Mog House Exit zone flag=' .. tostring(currentExitBit));
    end
end

function mogHouseExit.IsAvailable()
    if (entities.IsMogHouseObjectSuppressionArea() ~= true) then
        return false;
    end

    local group = zoneToGroup[GetCurrentZoneId()];
    if (group == nil) then
        return false;
    end

    return tonumber(GetCurrentExitBit(group)) == tonumber(group.bit);
end

function mogHouseExit.IsLocked()
    if (entities.IsMogHouseObjectSuppressionArea() ~= true) then
        return false;
    end

    local group = zoneToGroup[GetCurrentZoneId()];
    local exitBit = GetCurrentExitBit(group);
    return group ~= nil and group.unlockQuest ~= nil and (exitBit == nil or tonumber(exitBit) == 0);
end

function mogHouseExit.GetUnlockQuest()
    if (entities.IsMogHouseObjectSuppressionArea() ~= true) then
        return nil;
    end

    local group = zoneToGroup[GetCurrentZoneId()];
    return group ~= nil and group.unlockQuest or nil;
end

function mogHouseExit.GetDestinations()
    if (entities.IsMogHouseObjectSuppressionArea() ~= true) then
        return {};
    end

    local currentZoneId = GetCurrentZoneId();
    local group = zoneToGroup[currentZoneId];
    if (group == nil) then
        return {};
    end

    local destinations = {};

    for _, zone in ipairs(group.zones) do
        if (tonumber(zone.zoneId) == currentZoneId) then
            destinations[#destinations + 1] = {
                label = 'Area you entered from.',
                zoneId = zone.zoneId,
                bit = group.bit,
                mode = zone.mode,
            };
            break;
        end
    end

    for _, zone in ipairs(group.zones) do
        if (tonumber(zone.zoneId) ~= currentZoneId) then
            destinations[#destinations + 1] = {
                label = zone.label,
                zoneId = zone.zoneId,
                bit = group.bit,
                mode = zone.mode,
            };
        end
    end

    return destinations;
end

function mogHouseExit.Exit(destination)
    if (entities.IsMogHouseObjectSuppressionArea() ~= true) then
        return false, 'not inside a Mog House';
    end

    if (destination == nil) then
        return false, 'missing destination';
    end

    return SendOutgoingPacket(0x05E, BuildExitPacket(destination), tostring(destination.label or ''));
end

return mogHouseExit;
